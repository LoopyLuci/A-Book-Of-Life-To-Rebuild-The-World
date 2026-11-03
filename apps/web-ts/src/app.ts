/**
 * The A Book Of Life web application.
 *
 * The app is a single page that runs entirely offline: it loads one JSON
 * payload, renders Markdown locally and searches with an in-memory index.
 *
 * @module app
 */

import { renderMarkdown, safeHref } from './markdown.js';
import { searchEntries, entrySummary, toSearchDocuments, type SearchDocument, type SearchResult } from './search.js';
import { detectLanguage, directionFor, resolveStrings, translate, FALLBACK_LANGUAGE } from './i18n.js';
import { APP_STRINGS } from './ui-strings.js';
import {
  clearRecent,
  loadLanguage,
  loadRecent,
  loadThemePreference,
  pushRecent,
  resolveTheme,
  saveLanguage,
  saveThemePreference,
  type RecentEntry,
} from './store.js';
import { createElement, highlightedText, replaceChildren, requireElement } from './ui.js';
import {
  DIFFICULTY_LEVELS,
  SAFETY_LEVELS,
  VERIFICATION_STATUSES,
  type ContentPayload,
  type Domain,
  type Entry,
  type StringTable,
  type ThemePreference,
} from './types.js';

/** The languages offered by the selector, with their endonyms. */
const LANGUAGE_NAMES: Record<string, string> = {
  en: 'English',
  es: 'Español',
  fr: 'Français',
  de: 'Deutsch',
  pt: 'Português',
  hi: 'हिन्दी',
  ar: 'العربية',
  sw: 'Kiswahili',
  zh: '中文',
};

/** The route currently shown. */
type Route =
  | { kind: 'list'; domain: string | null; query: string }
  | { kind: 'entry'; key: string };

interface AppState {
  payload: ContentPayload;
  entriesById: Map<string, Entry>;
  entriesByKey: Map<string, Entry>;
  docs: SearchDocument[];
  strings: StringTable;
  language: string;
  theme: ThemePreference;
  recent: RecentEntry[];
  route: Route;
  domain: string | null;
  difficulty: string | null;
  safety: string | null;
  query: string;
}

/**
 * Format a difficulty level for display.
 *
 * @param level The raw level.
 * @returns A capitalised label.
 */
function formatLevel(level: string): string {
  return level.charAt(0).toUpperCase() + level.slice(1);
}

/**
 * Remove the leading heading of an entry when it only repeats the title that
 * the page already shows.
 *
 * @param body The Markdown body.
 * @param title The entry title.
 * @returns The body without the duplicated heading.
 */
export function bodyWithoutDuplicateTitle(body: string, title: string): string {
  const source = String(body).replace(/\r\n?/g, '\n');
  const heading = /^[ \t]*#[ \t]+(.+?)[ \t]*$/m.exec(source);
  if (heading === null || heading[1] === undefined) return source;
  if (heading[1].trim().toLowerCase() !== title.trim().toLowerCase()) return source;
  return source.replace(/^[ \t]*#[ \t]+.*(?:\n)?/, '');
}

/**
 * Parse the location hash into a route.
 *
 * @param hash The hash, including the leading `#`.
 * @param entriesByKey Entries keyed by `domain/slug`.
 * @returns The route.
 */
export function parseRoute(hash: string, entriesByKey: Map<string, Entry>): Route {
  const raw = hash.replace(/^#\/?/, '');
  if (raw === '') return { kind: 'list', domain: null, query: '' };
  const [pathPart = '', queryPart = ''] = raw.split('?');
  const segments = pathPart.split('/').filter((segment) => segment !== '').map(decodeURIComponent);
  const params = new URLSearchParams(queryPart);
  if (segments[0] === 'entry' && segments[1] !== undefined && segments[2] !== undefined) {
    const key = `${segments[1]}/${segments[2]}`;
    if (entriesByKey.has(key)) return { kind: 'entry', key };
  }
  if (segments[0] === 'domain' && segments[1] !== undefined) {
    return { kind: 'list', domain: segments[1], query: params.get('q') ?? '' };
  }
  return { kind: 'list', domain: null, query: params.get('q') ?? '' };
}

/**
 * Build and run the application.
 *
 * @param payload The exported content payload.
 * @returns A handle that can be used by the entry point.
 */
export function createApp(payload: ContentPayload): { start(): void } {
  /** @type {Map<string, Entry>} */
  const entriesById = new Map();
  /** @type {Map<string, Entry>} */
  const entriesByKey = new Map();
  for (const entry of payload.entries) {
    entriesById.set(entry.id, entry);
    entriesByKey.set(`${entry.domain}/${entry.slug}`, entry);
  }

  /** @type {Record<string, StringTable>} */
  const allStrings: Record<string, StringTable> = {};
  const languages = [...new Set([
    ...Object.keys(payload.strings),
    ...Object.keys(APP_STRINGS),
  ])].filter((language) => language !== '');
  for (const language of languages) {
    const corpus = payload.strings[language] ?? {};
    const app = APP_STRINGS[language] ?? APP_STRINGS[FALLBACK_LANGUAGE] ?? {};
    allStrings[language] = { ...app, ...corpus };
  }

  const storedLanguage = loadLanguage();
  const preferred = typeof navigator !== 'undefined' ? navigator.languages ?? [navigator.language] : [];
  const language = storedLanguage ?? detectLanguage(preferred, languages);

  /** @type {AppState} */
  const state: AppState = {
    payload,
    entriesById,
    entriesByKey,
    docs: toSearchDocuments(payload.entries),
    strings: resolveStrings(language, allStrings),
    language,
    theme: loadThemePreference(),
    recent: loadRecent(),
    route: { kind: 'list', domain: null, query: '' },
    domain: null,
    difficulty: null,
    safety: null,
    query: '',
  };

  const searchInput = requireElement<HTMLInputElement>('#search-input');
  const languageSelect = requireElement<HTMLSelectElement>('#language-select');
  const themeToggle = requireElement<HTMLButtonElement>('#theme-toggle');
  const aboutButton = requireElement<HTMLButtonElement>('#about-button');
  const shortcutsButton = requireElement<HTMLButtonElement>('#shortcuts-button');
  const paletteButton = requireElement<HTMLButtonElement>('#palette-button');
  const domainList = requireElement<HTMLUListElement>('#domain-list');
  const recentList = requireElement<HTMLUListElement>('#recent-list');
  const clearRecentButton = requireElement<HTMLButtonElement>('#clear-recent');
  const difficultyFilter = requireElement<HTMLSelectElement>('#difficulty-filter');
  const safetyFilter = requireElement<HTMLSelectElement>('#safety-filter');
  const clearFiltersButton = requireElement<HTMLButtonElement>('#clear-filters');
  const view = requireElement<HTMLElement>('#view');
  const liveRegion = requireElement<HTMLElement>('#live-region');
  const aboutDialog = requireElement<HTMLDialogElement>('#about-dialog');
  const shortcutsDialog = requireElement<HTMLDialogElement>('#shortcuts-dialog');
  const paletteDialog = requireElement<HTMLDialogElement>('#palette-dialog');
  const paletteInput = requireElement<HTMLInputElement>('#palette-input');
  const paletteList = requireElement<HTMLUListElement>('#palette-list');
  const siteTitle = requireElement<HTMLElement>('#site-title');
  const siteTagline = requireElement<HTMLElement>('#site-tagline');
  const footerNote = requireElement<HTMLElement>('#footer-note');
  const skipLink = requireElement<HTMLElement>('#skip-link');
  const searchLabel = requireElement<HTMLElement>('#search-label');
  const languageLabel = requireElement<HTMLElement>('#language-label');
  const paletteLabel = requireElement<HTMLElement>('#palette-label');
  const domainsHeading = requireElement<HTMLElement>('#domains-heading');
  const filtersHeading = requireElement<HTMLElement>('#filters-heading');
  const recentHeading = requireElement<HTMLElement>('#recent-heading');
  const difficultyLabel = requireElement<HTMLElement>('#difficulty-label');
  const safetyLabel = requireElement<HTMLElement>('#safety-label');
  const aboutTitle = requireElement<HTMLElement>('#about-dialog-title');
  const shortcutsTitle = requireElement<HTMLElement>('#shortcuts-dialog-title');
  const paletteTitle = requireElement<HTMLElement>('#palette-dialog-title');
  const closeButtons = document.querySelectorAll<HTMLElement>('[data-close-dialog]');

  let paletteSelection = 0;
  let paletteMatches: Entry[] = [];
  let lastRecentKey: string | null = null;

  /* ---------------------------------------------------------------- */
  /* Helpers                                                           */
  /* ---------------------------------------------------------------- */

  /**
   * Translate a key with the current language.
   *
   * @param key The string key.
   * @param params Interpolation values.
   * @returns The translated string.
   */
  function t(key: string, params: Record<string, string | number> = {}): string {
    return translate(state.strings, key, params);
  }

  /**
   * The label of a verification status, falling back to the raw value for
   * statuses the UI does not know about.
   *
   * @param status The verification status.
   * @returns The translated label.
   */
  function verificationLabel(status: string): string {
    const known = VERIFICATION_STATUSES.find((value) => value === status);
    if (known === undefined) return status;
    return t(`status_${known.replace('-', '_')}`);
  }

  /**
   * Resolve a link inside an entry body to an in-app route.
   *
   * @param href The raw link target.
   * @param currentDomain The domain of the entry being rendered.
   * @returns The href to use, or `null` to render plain text.
   */
  function resolveBodyLink(href: string, currentDomain: string): string | null {
    const trimmed = href.trim();
    if (trimmed === '') return null;
    if (trimmed.startsWith('#')) return trimmed;
    if (/^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(trimmed)) return safeHref(trimmed);
    if (!/\.md$/i.test(trimmed)) return safeHref(trimmed);

    const segments = trimmed.split('/').filter((segment) => segment !== '' && segment !== '.');
    const file = segments[segments.length - 1] ?? '';
    const parent = segments.length >= 2 ? (segments[segments.length - 2] ?? '') : '';
    const domain = parent !== '' ? parent : currentDomain;
    const name = file.replace(/\.md$/i, '');
    if (/^readme$/i.test(name)) return `#/domain/${encodeURIComponent(domain)}`;
    const target = entriesByKey.get(`${domain}/${name}`);
    return target ? `#/entry/${encodeURIComponent(domain)}/${encodeURIComponent(target.slug)}` : null;
  }

  /**
   * The domain object for a slug.
   *
   * @param id The domain slug.
   * @returns The domain, or `undefined`.
   */
  function findDomain(id: string): Domain | undefined {
    return payload.domains.find((domain) => domain.id === id);
  }

  /**
   * Whether an entry passes the active filters.
   *
   * @param entry The entry to test.
   * @returns True when the entry should be shown.
   */
  function passesFilters(entry: Entry): boolean {
    if (state.domain !== null && entry.domain !== state.domain) return false;
    if (state.difficulty !== null && entry.difficulty !== state.difficulty) return false;
    if (state.safety !== null && entry.safety !== state.safety) return false;
    return true;
  }

  /**
   * The entries shown by the list view.
   *
   * @returns Entries with an optional search result.
   */
  function visibleEntries(): Array<{ entry: Entry; result: SearchResult | null }> {
    const query = state.query.trim();
    if (query !== '') {
      const docs = state.docs.filter((doc) => {
        const entry = entriesById.get(doc.id);
        return entry !== undefined && passesFilters(entry);
      });
      const results = searchEntries(docs, query, 50);
      return results
        .map((result) => {
          const entry = entriesById.get(result.id);
          return entry === undefined ? null : { entry, result };
        })
        .filter((item): item is { entry: Entry; result: SearchResult } => item !== null);
    }
    return payload.entries
      .filter(passesFilters)
      .map((entry) => ({ entry, result: null }));
  }

  /* ---------------------------------------------------------------- */
  /* Theme, language, routing                                          */
  /* ---------------------------------------------------------------- */

  /**
   * Apply the theme to the document.
   */
  function applyTheme(): void {
    const systemDark = typeof window.matchMedia === 'function'
      ? window.matchMedia('(prefers-color-scheme: dark)').matches
      : false;
    const resolved = resolveTheme(state.theme, systemDark);
    document.documentElement.dataset['theme'] = resolved;
    document.documentElement.style.colorScheme = resolved;
    const label = t(`theme_${state.theme}`);
    themeToggle.textContent = label;
    themeToggle.setAttribute('aria-label', `${t('theme')}: ${label}`);
    themeToggle.dataset['state'] = state.theme;
  }

  /**
   * Apply the language to the document.
   */
  function applyLanguage(): void {
    state.strings = resolveStrings(state.language, allStrings);
    document.documentElement.lang = state.language;
    document.documentElement.dir = directionFor(state.language);
    document.title = t('site_name');
  }

  /**
   * Navigate to a route.
   *
   * @param route The route to show.
   * @param replace Whether to replace the history entry.
   */
  function navigate(route: Route, replace = false): void {
    state.route = route;
    state.domain = route.kind === 'list' ? route.domain : null;
    state.query = route.kind === 'list' ? route.query : '';
    searchInput.value = state.query;
    const hash = routeToHash(route);
    if (replace) {
      window.history.replaceState(null, '', hash);
    } else if (window.location.hash !== hash) {
      window.location.hash = hash;
    }
    render();
    window.scrollTo({ top: 0 });
  }

  /**
   * Build the hash for a route.
   *
   * @param route The route.
   * @returns The hash.
   */
  function routeToHash(route: Route): string {
    if (route.kind === 'entry') return `#/entry/${route.key.split('/').map(encodeURIComponent).join('/')}`;
    const query = route.query === '' ? '' : `?q=${encodeURIComponent(route.query)}`;
    if (route.domain === null) return `#/${query}`;
    return `#/domain/${encodeURIComponent(route.domain)}${query}`;
  }

  /**
   * Handle a hash change.
   */
  function onHashChange(): void {
    const route = parseRoute(window.location.hash, entriesByKey);
    state.route = route;
    state.domain = route.kind === 'list' ? route.domain : null;
    state.query = route.kind === 'list' ? route.query : '';
    searchInput.value = state.query;
    render();
  }

  /* ---------------------------------------------------------------- */
  /* Rendering                                                         */
  /* ---------------------------------------------------------------- */

  /**
   * Render the whole interface.
   */
  function render(): void {
    applyLanguage();
    applyTheme();
    renderStaticText();
    renderSidebar();
    renderMain();
    renderFooter();
  }

  /**
   * Translate the parts of the page that come from the HTML template.
   */
  function renderStaticText(): void {
    siteTitle.textContent = t('site_name');
    siteTagline.textContent = t('tagline');
    skipLink.textContent = t('skip_to_content');
    searchLabel.textContent = t('search');
    languageLabel.textContent = t('language');
    paletteLabel.textContent = t('jump_placeholder');
    domainsHeading.textContent = t('domains');
    filtersHeading.textContent = t('filters');
    recentHeading.textContent = t('recently_read');
    difficultyLabel.textContent = t('difficulty');
    safetyLabel.textContent = t('safety');
    aboutTitle.textContent = t('about');
    shortcutsTitle.textContent = t('shortcuts');
    paletteTitle.textContent = t('quick_jump');
    clearFiltersButton.textContent = t('clear_filters');
    clearRecentButton.textContent = t('clear');
    aboutButton.setAttribute('aria-label', t('about'));
    shortcutsButton.setAttribute('aria-label', t('shortcuts'));
    paletteButton.setAttribute('aria-label', t('quick_jump'));
    for (const button of closeButtons) button.textContent = t('close');
    searchInput.placeholder = t('search_placeholder', { count: payload.entries.length });
    paletteInput.placeholder = t('jump_placeholder');
    rebuildFilterOptions();
  }

  /**
   * Rebuild the options of the filter selects so that they stay translated.
   */
  function rebuildFilterOptions(): void {
    const difficultyValue = difficultyFilter.value;
    const safetyValue = safetyFilter.value;
    replaceChildren(difficultyFilter, [
      createElement('option', { text: `${t('difficulty')}: ${t('all')}`, attrs: { value: '' } }),
      ...DIFFICULTY_LEVELS.map((level) => createElement('option', { text: formatLevel(level), attrs: { value: level } })),
    ]);
    replaceChildren(safetyFilter, [
      createElement('option', { text: `${t('safety')}: ${t('all')}`, attrs: { value: '' } }),
      ...SAFETY_LEVELS.map((level) => createElement('option', { text: t(`safety_${level}`), attrs: { value: level } })),
    ]);
    difficultyFilter.value = difficultyValue;
    safetyFilter.value = safetyValue;
  }

  /**
   * Render the sidebar: domains, filters and recently read entries.
   */
  function renderSidebar(): void {
    const domainItems = payload.domains.map((domain) => {
      const active = state.domain === domain.id;
      const button = createElement('button', {
        className: `domain-item${active ? ' is-active' : ''}`,
        attrs: {
          type: 'button',
          'aria-pressed': active ? 'true' : 'false',
          'data-domain': domain.id,
          title: domain.title,
          style: `--domain-color:${domain.color}`,
        },
      }, [
        createElement('span', { className: 'domain-swatch', attrs: { 'aria-hidden': 'true' } }),
        createElement('span', { className: 'domain-name', text: domain.title }),
        createElement('span', { className: 'domain-count', text: String(domain.entryCount) }),
      ]);
      const item = createElement('li', {}, [button]);
      return item;
    });

    const allButton = createElement('button', {
      className: `domain-item${state.domain === null ? ' is-active' : ''}`,
      attrs: { type: 'button', 'aria-pressed': state.domain === null ? 'true' : 'false', 'data-domain': '' },
    }, [
      createElement('span', { className: 'domain-swatch domain-swatch-all', attrs: { 'aria-hidden': 'true' } }),
      createElement('span', { className: 'domain-name', text: t('all_entries') }),
      createElement('span', { className: 'domain-count', text: String(payload.entries.length) }),
    ]);

    replaceChildren(domainList, [
      createElement('li', {}, [allButton]),
      ...domainItems,
    ]);

    const recentItems = state.recent.length === 0
      ? [createElement('li', { className: 'recent-empty', text: t('no_recent') })]
      : state.recent.slice(0, 6).map((recent) => {
        const entry = entriesByKey.get(recent.id) ?? entriesById.get(recent.id);
        const key = entry ? `${entry.domain}/${entry.slug}` : recent.id;
        const link = createElement('a', {
          className: 'recent-link',
          text: recent.title,
          attrs: { href: `#/entry/${key.split('/').map(encodeURIComponent).join('/')}` },
        });
        return createElement('li', {}, [link]);
      });
    replaceChildren(recentList, recentItems);
  }

  /**
   * Render the main area.
   */
  function renderMain(): void {
    if (state.route.kind === 'entry') {
      const entry = entriesByKey.get(state.route.key) ?? entriesById.get(state.route.key);
      if (entry) {
        renderEntry(entry);
        return;
      }
    }
    renderList();
  }

  /**
   * Render the list of entries.
   */
  function renderList(): void {
    const items = visibleEntries();
    const heading = createElement('h2', { className: 'list-heading' });
    if (state.query.trim() !== '') {
      heading.textContent = `${items.length} ${t('results')}`;
    } else if (state.domain !== null) {
      const domain = findDomain(state.domain);
      heading.textContent = domain ? domain.title : t('all_entries');
    } else {
      heading.textContent = t('all_entries');
    }

    const description = createElement('p', { className: 'list-description' });
    if (state.query.trim() !== '') {
      description.textContent = `${t('search')}: ${state.query.trim()}`;
    } else if (state.domain !== null) {
      description.textContent = findDomain(state.domain)?.description ?? '';
    } else {
      description.textContent = t('tagline');
    }

    const list = createElement('ul', { className: 'entry-grid', attrs: { 'aria-label': t('entries') } });
    for (const item of items) {
      list.appendChild(createElement('li', {}, [renderCard(item.entry, item.result)]));
    }

    const empty = createElement('p', { className: 'empty-state', text: t('no_results') });

    replaceChildren(view, [heading, description]);
    if (items.length === 0) {
      view.appendChild(empty);
    } else {
      view.appendChild(list);
    }
    liveRegion.textContent = `${items.length} ${t('results')}`;
  }

  /**
   * Render one entry card.
   *
   * @param entry The entry.
   * @param result The search result, when the list came from a search.
   * @returns The card element.
   */
  function renderCard(entry: Entry, result: SearchResult | null): HTMLElement {
    const domain = findDomain(entry.domain);
    const titleLink = createElement('a', {
      className: 'card-title',
      text: entry.title,
      attrs: { href: `#/entry/${encodeURIComponent(entry.domain)}/${encodeURIComponent(entry.slug)}` },
    });

    const meta = createElement('p', { className: 'card-meta' }, [
      createElement('span', {
        className: 'chip chip-domain',
        text: domain?.title ?? entry.domain,
        attrs: { style: `--domain-color:${domain?.color ?? '#6b6b6b'}` },
      }),
      createElement('span', { className: 'chip', text: formatLevel(entry.difficulty) }),
      createElement('span', { className: `chip chip-safety chip-safety-${entry.safety}`, text: t(`safety_${entry.safety}`) }),
    ]);

    const snippetText = result !== null
      ? result.snippet
      : entrySummary(entry.body);
    const snippet = createElement('p', { className: 'card-snippet' });
    if (result !== null && result.marks.length > 0) {
      snippet.appendChild(highlightedText(snippetText, result.marks));
    } else {
      snippet.textContent = snippetText;
    }

    return createElement('article', { className: 'card', data: { domain: entry.domain } }, [
      createElement('h3', {}, [titleLink]),
      meta,
      snippet,
      renderTags(entry),
    ]);
  }

  /**
   * Render the tag list of an entry.
   *
   * @param entry The entry.
   * @returns The element.
   */
  function renderTags(entry: Entry): HTMLElement {
    if (entry.tags.length === 0) return createElement('div');
    const list = createElement('ul', { className: 'tag-list', attrs: { 'aria-label': t('tags') } });
    for (const tag of entry.tags) {
      list.appendChild(createElement('li', { className: 'tag', text: tag }));
    }
    return list;
  }

  /**
   * Render a full entry.
   *
   * @param entry The entry.
   */
  function renderEntry(entry: Entry): void {
    const domain = findDomain(entry.domain);
    const meta = createElement('p', { className: 'entry-meta' }, [
      createElement('a', {
        className: 'entry-domain',
        text: domain?.title ?? entry.domain,
        attrs: { href: `#/domain/${encodeURIComponent(entry.domain)}` },
      }),
      createElement('span', { className: 'sep', attrs: { 'aria-hidden': 'true' }, text: '·' }),
      createElement('span', { className: 'entry-difficulty', text: `${t('difficulty')}: ${formatLevel(entry.difficulty)}` }),
      createElement('span', { className: 'sep', attrs: { 'aria-hidden': 'true' }, text: '·' }),
      createElement('span', { className: `entry-safety chip-safety-${entry.safety}`, text: `${t('safety')}: ${t(`safety_${entry.safety}`)}` }),
      entry.timeToComplete !== ''
        ? createElement('span', { className: 'sep', attrs: { 'aria-hidden': 'true' }, text: '·' })
        : null,
      entry.timeToComplete !== ''
        ? createElement('span', { className: 'entry-time', text: `${t('time_to_complete')}: ${entry.timeToComplete}` })
        : null,
    ]);

    const badge = createElement('span', {
      className: `verification-badge verification-${entry.verification.status}`,
      text: verificationLabel(entry.verification.status),
    });

    const body = createElement('div', {
      className: 'entry-body markdown',
      html: renderMarkdown(bodyWithoutDuplicateTitle(entry.body, entry.title), {
        linkResolver: (href) => resolveBodyLink(href, entry.domain),
      }),
    });

    const sources = renderSources(entry);
    const related = renderRelated(entry);
    const extras = renderExtras(entry);

    const back = createElement('a', {
      className: 'back-link',
      text: `← ${t('back_to_entries')}`,
      attrs: { href: `#/domain/${encodeURIComponent(entry.domain)}` },
    });

    replaceChildren(view, [
      createElement('article', { className: 'entry' }, [
        createElement('header', { className: 'entry-header' }, [
          createElement('h1', { className: 'entry-title', text: entry.title }),
          meta,
          createElement('div', { className: 'entry-badges' }, [
            badge,
            entry.verification.date !== ''
              ? createElement('span', { className: 'verification-date', text: entry.verification.date })
              : null,
          ]),
          renderTags(entry),
        ]),
        body,
        extras,
        sources,
        related,
      ]),
      back,
    ]);

    const recentKey = `${entry.domain}/${entry.slug}`;
    if (lastRecentKey !== recentKey) {
      lastRecentKey = recentKey;
      state.recent = pushRecent(recentKey, entry.title);
    }
    renderSidebar();
  }

  /**
   * Render the sources of an entry.
   *
   * @param entry The entry.
   * @returns The element.
   */
  function renderSources(entry: Entry): HTMLElement {
    const section = createElement('section', { className: 'entry-section' }, [
      createElement('h2', { text: t('sources') }),
    ]);
    if (entry.sources.length === 0) return section;
    const list = createElement('ul', { className: 'source-list' });
    for (const source of entry.sources) {
      const label = source.url !== '' ? safeHref(source.url) : null;
      const title = label !== null
        ? createElement('a', { text: source.title, attrs: { href: label, target: '_blank', rel: 'noopener noreferrer' } })
        : createElement('span', { text: source.title });
      const details: string[] = [];
      if (source.author !== '') details.push(source.author);
      if (source.year > 0) details.push(String(source.year));
      if (source.license !== '') details.push(source.license);
      list.appendChild(createElement('li', {}, [
        title,
        details.length > 0 ? createElement('span', { className: 'source-meta', text: ` — ${details.join(' · ')}` }) : null,
      ]));
    }
    section.appendChild(list);
    return section;
  }

  /**
   * Render the related entries of an entry.
   *
   * @param entry The entry.
   * @returns The element.
   */
  function renderRelated(entry: Entry): HTMLElement {
    const section = createElement('section', { className: 'entry-section' }, [
      createElement('h2', { text: t('related_entries') }),
    ]);
    const groups: Array<{ label: string; ids: string[] }> = [
      { label: t('prerequisites'), ids: entry.prerequisites },
      { label: t('see_also'), ids: entry.links },
    ];
    let rendered = 0;
    for (const group of groups) {
      const targets = group.ids
        .map((id) => entriesById.get(id))
        .filter((target): target is Entry => target !== undefined);
      if (targets.length === 0) continue;
      rendered += 1;
      const list = createElement('ul', { className: 'related-list' });
      for (const target of targets) {
        list.appendChild(createElement('li', {}, [
          createElement('a', {
            text: target.title,
            attrs: { href: `#/entry/${encodeURIComponent(target.domain)}/${encodeURIComponent(target.slug)}` },
          }),
          createElement('span', { className: 'related-domain', text: findDomain(target.domain)?.title ?? target.domain }),
        ]));
      }
      section.appendChild(createElement('h3', { className: 'related-heading', text: group.label }));
      section.appendChild(list);
    }
    if (rendered === 0) {
      section.appendChild(createElement('p', { className: 'muted', text: '—' }));
    }
    return section;
  }

  /**
   * Render the optional metadata block of an entry.
   *
   * @param entry The entry.
   * @returns The element, or an empty element when there is nothing to show.
   */
  function renderExtras(entry: Entry): HTMLElement {
    const groups: Array<{ label: string; items: string[] }> = [
      { label: t('materials'), items: [...entry.materials, ...entry.tools] },
      { label: t('hazards'), items: entry.hazards },
      { label: t('limits'), items: entry.limits },
    ];
    const visible = groups.filter((group) => group.items.length > 0);
    if (visible.length === 0) return createElement('div');
    const section = createElement('section', { className: 'entry-section entry-extras' });
    for (const group of visible) {
      section.appendChild(createElement('h2', { text: group.label }));
      const list = createElement('ul', { className: 'plain-list' });
      for (const item of group.items) list.appendChild(createElement('li', { text: item }));
      section.appendChild(list);
    }
    return section;
  }

  /**
   * Render the footer note.
   */
  function renderFooter(): void {
    footerNote.textContent = t('disclaimer_note');
  }

  /* ---------------------------------------------------------------- */
  /* Dialogs                                                           */
  /* ---------------------------------------------------------------- */

  /**
   * Populate and open the About dialog.
   */
  function openAbout(): void {
    const body = aboutDialog.querySelector('.dialog-body');
    if (body) {
      replaceChildren(body, [
        createElement('p', { className: 'about-version' }, [
          createElement('strong', { text: `${t('version')}: ${payload.manifestVersion}` }),
          createElement('span', { className: 'muted', text: ` · schema ${payload.schemaVersion} · ${payload.entries.length} ${t('entries')}` }),
        ]),
        createElement('p', { className: 'about-licence', text: `${payload.site.licenseContent} · ${payload.site.licenseCode}` }),
        createElement('h2', { text: payload.disclaimer.title }),
        createElement('div', {
          className: 'markdown disclaimer-text',
          html: renderMarkdown(payload.disclaimer.markdown),
        }),
      ]);
    }
    if (!aboutDialog.open) aboutDialog.showModal();
  }

  /**
   * Populate and open the keyboard shortcut dialog.
   */
  function openShortcuts(): void {
    const body = shortcutsDialog.querySelector('.dialog-body');
    const shortcuts: Array<[string, string]> = [
      ['/', t('shortcut_search')],
      ['Ctrl + F', t('shortcut_search')],
      ['Ctrl + K', t('shortcut_palette')],
      ['?', t('shortcut_help')],
      ['Esc', t('shortcut_close')],
    ];
    if (body) {
      replaceChildren(body, [
        createElement('table', { className: 'shortcut-table' }, [
          createElement('tbody', {}, shortcuts.map(([keys, description]) => createElement('tr', {}, [
            createElement('th', { attrs: { scope: 'row' } }, [createElement('kbd', { text: keys })]),
            createElement('td', { text: description }),
          ]))),
        ]),
      ]);
    }
    if (!shortcutsDialog.open) shortcutsDialog.showModal();
  }

  /**
   * Open the quick-jump palette.
   */
  function openPalette(): void {
    paletteInput.value = '';
    updatePalette('');
    if (!paletteDialog.open) paletteDialog.showModal();
    paletteInput.focus();
  }

  /**
   * Update the palette results.
   *
   * @param query The typed text.
   */
  function updatePalette(query: string): void {
    const needle = query.trim().toLowerCase();
    const matches = payload.entries
      .filter((entry) => {
        if (needle === '') return true;
        return entry.title.toLowerCase().includes(needle)
          || entry.tags.some((tag) => tag.toLowerCase().includes(needle));
      })
      .slice(0, 8);
    paletteMatches = matches;
    paletteSelection = 0;
    replaceChildren(paletteList, matches.map((entry, index) => {
      const link = createElement('a', {
        className: `palette-item${index === 0 ? ' is-selected' : ''}`,
        attrs: { href: `#/entry/${encodeURIComponent(entry.domain)}/${encodeURIComponent(entry.slug)}` },
      }, [
        createElement('span', { className: 'palette-title', text: entry.title }),
        createElement('span', { className: 'palette-domain', text: findDomain(entry.domain)?.title ?? entry.domain }),
      ]);
      return createElement('li', {}, [link]);
    }));
  }

  /**
   * Move the palette selection.
   *
   * @param delta The number of steps.
   */
  function movePaletteSelection(delta: number): void {
    if (paletteMatches.length === 0) return;
    paletteSelection = (paletteSelection + delta + paletteMatches.length) % paletteMatches.length;
    const items = paletteList.querySelectorAll<HTMLElement>('.palette-item');
    items.forEach((item, index) => item.classList.toggle('is-selected', index === paletteSelection));
    items[paletteSelection]?.scrollIntoView({ block: 'nearest' });
  }

  /* ---------------------------------------------------------------- */
  /* Events                                                            */
  /* ---------------------------------------------------------------- */

  /**
   * Wire up every listener.
   */
  function bindEvents(): void {
    searchInput.addEventListener('input', () => {
      state.query = searchInput.value;
      const route: Route = { kind: 'list', domain: state.domain, query: state.query };
      state.route = route;
      window.history.replaceState(null, '', routeToHash(route));
      renderMain();
    });

    searchInput.addEventListener('keydown', (event) => {
      if (event.key === 'Enter') {
        event.preventDefault();
        navigate({ kind: 'list', domain: state.domain, query: searchInput.value }, true);
      }
      if (event.key === 'Escape') {
        searchInput.value = '';
        state.query = '';
        renderMain();
      }
    });

    domainList.addEventListener('click', (event) => {
      const target = (event.target as HTMLElement).closest<HTMLElement>('[data-domain]');
      if (!target) return;
      const domain = target.dataset['domain'] ?? '';
      navigate({ kind: 'list', domain: domain === '' ? null : domain, query: state.query });
    });

    difficultyFilter.addEventListener('change', () => {
      state.difficulty = difficultyFilter.value === '' ? null : difficultyFilter.value;
      navigate({ kind: 'list', domain: state.domain, query: state.query });
    });

    safetyFilter.addEventListener('change', () => {
      state.safety = safetyFilter.value === '' ? null : safetyFilter.value;
      navigate({ kind: 'list', domain: state.domain, query: state.query });
    });

    clearFiltersButton.addEventListener('click', () => {
      state.difficulty = null;
      state.safety = null;
      state.domain = null;
      state.query = '';
      searchInput.value = '';
      difficultyFilter.value = '';
      safetyFilter.value = '';
      navigate({ kind: 'list', domain: null, query: '' });
    });

    languageSelect.addEventListener('change', () => {
      state.language = languageSelect.value;
      saveLanguage(state.language);
      render();
    });

    themeToggle.addEventListener('click', () => {
      const order: ThemePreference[] = ['system', 'light', 'dark'];
      const index = order.indexOf(state.theme);
      state.theme = order[(index + 1) % order.length] ?? 'system';
      saveThemePreference(state.theme);
      render();
    });

    aboutButton.addEventListener('click', openAbout);
    shortcutsButton.addEventListener('click', openShortcuts);
    paletteButton.addEventListener('click', openPalette);

    clearRecentButton.addEventListener('click', () => {
      clearRecent();
      state.recent = [];
      lastRecentKey = null;
      renderSidebar();
    });

    document.querySelectorAll<HTMLElement>('[data-close-dialog]').forEach((button) => {
      button.addEventListener('click', () => {
        const dialog = button.closest('dialog');
        if (dialog) dialog.close();
      });
    });

    paletteInput.addEventListener('input', () => updatePalette(paletteInput.value));
    paletteInput.addEventListener('keydown', (event) => {
      if (event.key === 'ArrowDown') {
        event.preventDefault();
        movePaletteSelection(1);
      } else if (event.key === 'ArrowUp') {
        event.preventDefault();
        movePaletteSelection(-1);
      } else if (event.key === 'Enter') {
        event.preventDefault();
        const entry = paletteMatches[paletteSelection];
        if (entry) {
          paletteDialog.close();
          navigate({ kind: 'entry', key: `${entry.domain}/${entry.slug}` });
        }
      }
    });
    paletteList.addEventListener('click', (event) => {
      const link = (event.target as HTMLElement).closest('a');
      if (link) paletteDialog.close();
    });

    document.addEventListener('keydown', (event) => {
      const target = event.target as HTMLElement | null;
      const typing = target !== null
        && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.tagName === 'SELECT' || target.isContentEditable);

      if (event.key === 'Escape') {
        if (paletteDialog.open) {
          paletteDialog.close();
          event.preventDefault();
        }
        return;
      }

      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault();
        openPalette();
        return;
      }

      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'f') {
        event.preventDefault();
        searchInput.focus();
        searchInput.select();
        return;
      }

      if (typing) return;

      if (event.key === '/') {
        event.preventDefault();
        searchInput.focus();
        return;
      }

      if (event.key === '?') {
        event.preventDefault();
        openShortcuts();
      }
    });

    window.addEventListener('hashchange', onHashChange);

    if (typeof window.matchMedia === 'function') {
      const media = window.matchMedia('(prefers-color-scheme: dark)');
      const listener = () => {
        if (state.theme === 'system') applyTheme();
      };
      if (typeof media.addEventListener === 'function') media.addEventListener('change', listener);
    }
  }

  /**
   * Build the static controls that do not depend on the payload.
   */
  function buildControls(): void {
    replaceChildren(languageSelect, languages.map((code) => createElement('option', {
      text: LANGUAGE_NAMES[code] ?? code,
      attrs: { value: code },
    })));
    languageSelect.value = state.language;
  }

  /**
   * Start the application.
   */
  function start(): void {
    buildControls();
    bindEvents();
    onHashChange();
    render();
  }

  return { start };
}
