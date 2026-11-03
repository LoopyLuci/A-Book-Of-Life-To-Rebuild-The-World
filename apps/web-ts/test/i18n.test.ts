import assert from 'node:assert/strict';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { describe, it } from 'node:test';
import { fileURLToPath } from 'node:url';

import { FALLBACK_LANGUAGE, detectLanguage, directionFor, resolveStrings, translate } from '../src/i18n.js';
import { APP_STRINGS, APP_STRING_KEYS } from '../src/ui-strings.js';
import type { StringTable } from '../src/types.js';

const APP_DIR = findAppRoot(dirname(fileURLToPath(import.meta.url)));
const CORPUS_STRINGS_DIR = join(APP_DIR, '..', '..', 'i18n', 'strings');

/**
 * Every language the corpus publishes UI strings for.
 *
 * Reading the directory keeps the assertions true when a language is added,
 * instead of pinning a count that silently drifts.
 *
 * @returns The language codes, sorted.
 */
function corpusLanguages(): string[] {
  if (!existsSync(CORPUS_STRINGS_DIR)) return [];
  return readdirSync(CORPUS_STRINGS_DIR)
    .filter((name) => name.endsWith('.yaml'))
    .map((name) => name.slice(0, -'.yaml'.length))
    .sort();
}

/**
 * Walk up the directory tree until the application folder is found.
 *
 * @param start The directory to start from.
 * @returns The application folder.
 */
function findAppRoot(start: string): string {
  let current = start;
  for (let depth = 0; depth < 8; depth += 1) {
    if (existsSync(join(current, 'package.json'))) return current;
    const parent = dirname(current);
    if (parent === current) break;
    current = parent;
  }
  return start;
}

const TABLES: Record<string, StringTable> = {
  en: { site_name: 'A Book Of Life', tagline: 'Offline', entries: 'Entries' },
  es: { site_name: 'Un Libro De Vida', entries: 'Entradas' },
  fr: { site_name: 'Un Livre De Vie' },
};

describe('string resolution', () => {
  it('falls back to English for keys a language does not define', () => {
    const resolved = resolveStrings('es', TABLES);
    assert.equal(resolved['site_name'], 'Un Libro De Vida');
    assert.equal(resolved['entries'], 'Entradas');
    assert.equal(resolved['tagline'], 'Offline', 'the missing Spanish key falls back to English');
  });

  it('falls back to English for a language that does not exist at all', () => {
    const resolved = resolveStrings('xx', TABLES);
    assert.equal(resolved['site_name'], 'A Book Of Life');
    assert.equal(resolved['entries'], 'Entries');
  });

  it('treats an empty translation as missing', () => {
    const resolved = resolveStrings('fr', { ...TABLES, fr: { site_name: '', entries: 'Entrées' } });
    assert.equal(resolved['site_name'], 'A Book Of Life');
    assert.equal(resolved['entries'], 'Entrées');
  });

  it('can use another fallback language', () => {
    const resolved = resolveStrings('xx', TABLES, 'es');
    assert.equal(resolved['site_name'], 'Un Libro De Vida');
    assert.equal(resolved['entries'], 'Entradas');
  });

  it('does not mutate the source tables', () => {
    const before = { ...TABLES['es'] };
    resolveStrings('es', TABLES);
    assert.deepEqual(TABLES['es'], before);
  });
});

describe('translation', () => {
  it('interpolates placeholders', () => {
    assert.equal(
      translate({ search_placeholder: 'Search {count} entries…' }, 'search_placeholder', { count: 207 }),
      'Search 207 entries…',
    );
  });

  it('leaves unknown placeholders alone', () => {
    assert.equal(translate({ a: 'x {y}' }, 'a', {}), 'x {y}');
  });

  it('returns the key when the string is missing', () => {
    assert.equal(translate({}, 'missing_key'), 'missing_key');
  });
});

describe('language detection', () => {
  it('matches an exact language', () => {
    assert.equal(detectLanguage(['fr'], ['en', 'fr', 'de']), 'fr');
  });

  it('matches the base of a regional tag', () => {
    assert.equal(detectLanguage(['fr-CA'], ['en', 'fr', 'de']), 'fr');
    assert.equal(detectLanguage(['en-GB'], ['en', 'fr']), 'en');
  });

  it('falls back to English', () => {
    assert.equal(detectLanguage(['ja'], ['en', 'fr']), 'en');
    assert.equal(detectLanguage([], ['en', 'fr']), 'en');
    assert.equal(detectLanguage(undefined, ['en', 'fr']), 'en');
  });

  it('uses the first supported language when English is unavailable', () => {
    assert.equal(detectLanguage(['ja'], ['fr', 'de']), 'fr');
  });
});

describe('text direction', () => {
  it('marks Arabic as right to left', () => {
    assert.equal(directionFor('ar'), 'rtl');
    assert.equal(directionFor('ar-EG'), 'rtl');
    assert.equal(directionFor('en'), 'ltr');
    assert.equal(directionFor('zh'), 'ltr');
  });
});

describe('application strings', () => {
  it('defines the same keys in every language', () => {
    const languages = Object.keys(APP_STRINGS);
    assert.deepEqual(languages.slice().sort(), corpusLanguages());
    for (const language of languages) {
      const table = APP_STRINGS[language]!;
      const keys = Object.keys(table).sort();
      assert.deepEqual(keys, [...APP_STRING_KEYS].sort(), `the "${language}" table is incomplete`);
    }
  });

  it('covers every language of the corpus', () => {
    for (const language of corpusLanguages()) {
      assert.ok(APP_STRINGS[language], `missing application strings for ${language}`);
    }
  });

  it('never leaves a string empty', () => {
    for (const [language, table] of Object.entries(APP_STRINGS)) {
      for (const [key, value] of Object.entries(table)) {
        assert.ok(value.trim().length > 0, `"${language}.${key}" is empty`);
      }
    }
  });
});

describe('exported corpus strings', () => {
  const contentPath = join(APP_DIR, 'public', 'content.json');

  it('carries every language of the corpus', { skip: !existsSync(contentPath) }, () => {
    const payload = JSON.parse(readFileSync(contentPath, 'utf8')) as {
      strings: Record<string, StringTable>;
    };
    const languages = Object.keys(payload.strings).sort();
    assert.deepEqual(languages, corpusLanguages());
  });

  it('resolves every corpus string with the English fallback', { skip: !existsSync(contentPath) }, () => {
    const payload = JSON.parse(readFileSync(contentPath, 'utf8')) as {
      strings: Record<string, StringTable>;
    };
    const english = payload.strings[FALLBACK_LANGUAGE] ?? {};
    assert.ok(Object.keys(english).length > 0, 'the corpus must provide English strings');
    for (const [language, table] of Object.entries(payload.strings)) {
      const resolved = resolveStrings(language, payload.strings);
      for (const key of Object.keys(table)) {
        assert.ok(resolved[key], `"${language}" is missing "${key}"`);
      }
      for (const key of Object.keys(english)) {
        assert.ok(resolved[key], `"${language}" is missing "${key}"`);
      }
    }
  });
});
