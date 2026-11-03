/**
 * Instant, offline search over the knowledge base.
 *
 * Ranking is deliberately simple and explainable: a title match always beats a
 * tag match, which always beats a body match. Matching is case-insensitive
 * and substring based so that partial words ("purif") find "Purification"
 * while the search is still being typed.
 *
 * @module search
 */

import type { Entry } from './types.js';

/** The minimum shape the search engine needs from an entry. */
export interface SearchDocument {
  id: string;
  title: string;
  tags: string[];
  /** Searchable text; Markdown syntax should already be removed. */
  body: string;
  domain: string;
}

/** A highlighted range inside a snippet. */
export interface SearchMark {
  start: number;
  end: number;
}

/** One search hit. */
export interface SearchResult {
  id: string;
  score: number;
  title: string;
  domain: string;
  /** Textual snippet around the first match. */
  snippet: string;
  /** Ranges inside `snippet` that matched the query. */
  marks: SearchMark[];
  /** The query terms that matched. */
  matchedTerms: string[];
}

/** Weights used for ranking. Exported so the tests can assert on them. */
export const WEIGHTS = {
  titleTerm: 30,
  titleWord: 12,
  titlePhrase: 60,
  tagExact: 20,
  tagTerm: 9,
  bodyTerm: 3,
  bodyTermCap: 4,
  bodyPhrase: 8,
  allTerms: 25,
  domainTerm: 6,
} as const;

/** Maximum number of results returned by {@link searchEntries}. */
export const DEFAULT_LIMIT = 50;

/**
 * Split a query into lower-cased terms.
 *
 * @param query The raw query.
 * @returns The terms, in the order they appear, without duplicates.
 */
export function tokenize(query: string): string[] {
  const matches = String(query).toLowerCase().match(/[\p{L}\p{N}]+/gu);
  if (!matches) return [];
  const seen = new Set<string>();
  /** @type {string[]} */
  const terms: string[] = [];
  for (const term of matches) {
    if (term === '' || seen.has(term)) continue;
    seen.add(term);
    terms.push(term);
  }
  return terms;
}

/**
 * Remove Markdown syntax so that searches match prose rather than markup.
 *
 * @param markdown Markdown source.
 * @returns Plain text.
 */
export function stripMarkdown(markdown: string): string {
  return String(markdown)
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/`([^`]*)`/g, '$1')
    .replace(/!\[([^\]]*)\]\([^)]*\)/g, '$1')
    .replace(/\[([^\]]*)\]\([^)]*\)/g, '$1')
    .replace(/^#{1,6}\s+/gm, '')
    .replace(/^\s{0,3}>\s?/gm, '')
    .replace(/^\s*([-*+]|\d{1,9}[.)])\s+/gm, '')
    .replace(/^\s*\|/gm, ' ')
    .replace(/[*_~]{1,3}/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Build a short, meaningful summary of an entry.
 *
 * Every entry repeats the same metadata blockquote and the same disclaimer
 * paragraph; both are skipped so that the summary shows the actual content.
 *
 * @param markdown Markdown source.
 * @param length Maximum length of the summary.
 * @returns Plain text.
 */
export function entrySummary(markdown: string, length = 220): string {
  const source = String(markdown).replace(/\r\n?/g, '\n');
  const paragraphs = source.split(/\n\s*\n/);
  const kept = paragraphs.filter((paragraph) => {
    const trimmed = paragraph.trim();
    if (trimmed.startsWith('>')) return false;
    if (trimmed.includes('Reference material only')) return false;
    return true;
  });
  // The title and the first section heading are shown elsewhere.
  while (kept.length > 0 && /^\s*#{1,6}\s+[\s\S]*$/.test(kept[0] ?? '')) kept.shift();
  const text = stripMarkdown(kept.join('\n\n'));
  if (text.length <= length) return text;
  const cut = text.slice(0, length);
  const lastSpace = cut.lastIndexOf(' ');
  const head = lastSpace > length * 0.6 ? cut.slice(0, lastSpace) : cut;
  return `${head.trimEnd()}…`;
}

/**
 * Convert entries into search documents.
 *
 * @param entries The entries to index.
 * @returns Search documents.
 */
export function toSearchDocuments(entries: Entry[]): SearchDocument[] {
  return entries.map((entry) => ({
    id: entry.id,
    title: entry.title,
    tags: entry.tags,
    body: stripMarkdown(entry.body),
    domain: entry.domain,
  }));
}

/**
 * Count non-overlapping, case-insensitive occurrences of `needle`.
 *
 * @param haystack Text to search.
 * @param needle Lower-cased term.
 * @returns The number of occurrences.
 */
export function countOccurrences(haystack: string, needle: string): number {
  if (needle === '') return 0;
  let count = 0;
  let index = haystack.indexOf(needle);
  while (index !== -1) {
    count += 1;
    index = haystack.indexOf(needle, index + needle.length);
  }
  return count;
}

/**
 * Whether `needle` occurs in `haystack` at a word boundary.
 *
 * @param haystack Text to search.
 * @param needle Lower-cased term.
 * @returns True when a word-boundary match exists.
 */
export function hasWordMatch(haystack: string, needle: string): boolean {
  if (needle === '') return false;
  let index = haystack.indexOf(needle);
  while (index !== -1) {
    const before = index > 0 ? (haystack[index - 1] ?? '') : '';
    const after = haystack[index + needle.length] ?? '';
    if (!isWordCharacter(before) && !isWordCharacter(after)) return true;
    index = haystack.indexOf(needle, index + 1);
  }
  return false;
}

/**
 * @param char Character to test.
 * @returns True when the character is a letter or a digit.
 */
function isWordCharacter(char: string): boolean {
  return /[\p{L}\p{N}]/u.test(char);
}

/**
 * Find every occurrence of the given terms in a piece of text.
 *
 * @param text The text to scan.
 * @param terms Lower-cased terms.
 * @returns Sorted, merged ranges.
 */
export function findMarks(text: string, terms: string[]): SearchMark[] {
  const lower = text.toLowerCase();
  /** @type {SearchMark[]} */
  const marks: SearchMark[] = [];
  for (const term of terms) {
    if (term === '') continue;
    let index = lower.indexOf(term);
    while (index !== -1) {
      marks.push({ start: index, end: index + term.length });
      index = lower.indexOf(term, index + term.length);
    }
  }
  marks.sort((a, b) => (a.start - b.start) || (a.end - b.end));
  /** @type {SearchMark[]} */
  const merged: SearchMark[] = [];
  for (const mark of marks) {
    const last = merged[merged.length - 1];
    if (last && mark.start <= last.end) {
      last.end = Math.max(last.end, mark.end);
    } else {
      merged.push({ ...mark });
    }
  }
  return merged;
}

/**
 * Build a snippet around the first match of any term.
 *
 * @param body The searchable body text.
 * @param terms Lower-cased query terms.
 * @param radius Half-width of the snippet window.
 * @returns The snippet and the ranges to highlight inside it.
 */
export function buildSnippet(body: string, terms: string[], radius = 90): { snippet: string; marks: SearchMark[] } {
  const lower = body.toLowerCase();
  let first = -1;
  for (const term of terms) {
    if (term === '') continue;
    const index = lower.indexOf(term);
    if (index !== -1 && (first === -1 || index < first)) first = index;
  }
  if (first === -1) {
    const snippet = body.slice(0, radius * 2).trim();
    return { snippet, marks: [] };
  }
  let start = Math.max(0, first - radius);
  let end = Math.min(body.length, first + radius);
  if (start > 0) {
    const space = body.indexOf(' ', start);
    if (space !== -1 && space < first) start = space + 1;
  }
  if (end < body.length) {
    const space = body.lastIndexOf(' ', end);
    if (space > first) end = space;
  }
  const snippet = body.slice(start, end).trim();
  const offset = body.slice(start, end).indexOf(snippet);
  const shift = offset === -1 ? 0 : offset;
  const marks = findMarks(snippet, terms).map((mark) => ({
    start: mark.start + shift,
    end: mark.end + shift,
  }));
  return { snippet, marks };
}

/**
 * Score a single document against the given terms.
 *
 * @param doc The document to score.
 * @param terms Lower-cased query terms.
 * @param phrase The full lower-cased query, used for phrase bonuses.
 * @returns The score and the terms that matched.
 */
export function scoreDocument(
  doc: SearchDocument,
  terms: string[],
  phrase: string,
): { score: number; matchedTerms: string[] } {
  const title = doc.title.toLowerCase();
  const body = doc.body.toLowerCase();
  const domain = doc.domain.toLowerCase();
  const tags = doc.tags.map((tag) => tag.toLowerCase());

  let score = 0;
  /** @type {string[]} */
  const matchedTerms: string[] = [];

  for (const term of terms) {
    let termScore = 0;
    if (title.includes(term)) {
      termScore += WEIGHTS.titleTerm;
      if (hasWordMatch(title, term)) termScore += WEIGHTS.titleWord;
    }
    for (const tag of tags) {
      if (tag === term) {
        termScore += WEIGHTS.tagExact;
        break;
      }
    }
    for (const tag of tags) {
      if (tag.includes(term)) {
        termScore += WEIGHTS.tagTerm;
        break;
      }
    }
    if (body.includes(term)) {
      termScore += WEIGHTS.bodyTerm * Math.min(countOccurrences(body, term), WEIGHTS.bodyTermCap);
    }
    if (domain.includes(term)) {
      termScore += WEIGHTS.domainTerm;
    }
    if (termScore > 0) matchedTerms.push(term);
    score += termScore;
  }

  if (phrase !== '' && title === phrase) score += WEIGHTS.titlePhrase;
  else if (phrase !== '' && title.includes(phrase)) score += WEIGHTS.titlePhrase / 2;
  else if (phrase !== '' && body.includes(phrase)) score += WEIGHTS.bodyPhrase;

  if (terms.length > 1 && matchedTerms.length === terms.length) score += WEIGHTS.allTerms;

  return { score, matchedTerms };
}

/**
 * Search the documents.
 *
 * Entries that match every term are always included; if that yields nothing,
 * the search falls back to entries matching at least one term so the user
 * still gets something useful.
 *
 * @param docs The documents to search.
 * @param query The raw query.
 * @param limit Maximum number of results.
 * @returns The ranked results.
 */
export function searchEntries(docs: SearchDocument[], query: string, limit = DEFAULT_LIMIT): SearchResult[] {
  const terms = tokenize(query);
  if (terms.length === 0) return [];
  const phrase = String(query).trim().toLowerCase();

  /** @type {Array<{doc: SearchDocument, score: number, matchedTerms: string[]}>} */
  const scored: Array<{ doc: SearchDocument; score: number; matchedTerms: string[] }> = [];
  for (const doc of docs) {
    const { score, matchedTerms } = scoreDocument(doc, terms, phrase);
    if (score > 0) scored.push({ doc, score, matchedTerms });
  }

  const complete = scored.filter((item) => item.matchedTerms.length === terms.length);
  const pool = complete.length > 0 ? complete : scored;

  pool.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    const title = a.doc.title.localeCompare(b.doc.title);
    if (title !== 0) return title;
    return a.doc.id.localeCompare(b.doc.id);
  });

  return pool.slice(0, Math.max(0, limit)).map((item) => {
    const { snippet, marks } = buildSnippet(item.doc.body, item.matchedTerms.length > 0 ? item.matchedTerms : terms);
    return {
      id: item.doc.id,
      score: item.score,
      title: item.doc.title,
      domain: item.doc.domain,
      snippet,
      marks,
      matchedTerms: item.matchedTerms,
    };
  });
}
