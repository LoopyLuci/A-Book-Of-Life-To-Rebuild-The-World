/**
 * Runtime localisation.
 *
 * UI strings are exported from the corpus (`i18n/strings/<lang>.yaml`) and
 * merged with the app's own chrome strings. Every lookup falls back to
 * English, so a partially translated language never leaves a blank label on
 * screen.
 *
 * @module i18n
 */

import type { StringTable } from './types.js';

/** The language every other language falls back to. */
export const FALLBACK_LANGUAGE = 'en';

/** Languages that are written right to left. */
const RTL_LANGUAGES = new Set(['ar', 'fa', 'he', 'ur']);

/**
 * Merge a language's strings over the English fallback table.
 *
 * @param language The requested language code.
 * @param allStrings Every language's strings, keyed by language code.
 * @param fallback The language used when a key is missing.
 * @returns A complete string table.
 */
export function resolveStrings(
  language: string,
  allStrings: Record<string, StringTable>,
  fallback: string = FALLBACK_LANGUAGE,
): StringTable {
  const base = allStrings[fallback] ?? {};
  const requested = allStrings[language];
  if (requested === undefined) return { ...base };

  /** @type {StringTable} */
  const resolved: StringTable = { ...base };
  for (const [key, value] of Object.entries(requested)) {
    if (typeof value === 'string' && value !== '') resolved[key] = value;
  }
  return resolved;
}

/**
 * Look up a string and interpolate `{placeholder}` markers.
 *
 * @param table The string table to read from.
 * @param key The string key.
 * @param params Values for the placeholders.
 * @returns The translated string, or the key itself when it is missing.
 */
export function translate(
  table: StringTable,
  key: string,
  params: Record<string, string | number> = {},
): string {
  const template = table[key];
  if (typeof template !== 'string' || template === '') return key;
  return template.replace(/\{(\w+)\}/g, (match, name: string) => {
    const value = params[name];
    return value === undefined ? match : String(value);
  });
}

/**
 * Pick the best supported language for the given preferences.
 *
 * @param preferred Preferred language tags, most preferred first.
 * @param supported The languages the app can display.
 * @returns A supported language code.
 */
export function detectLanguage(preferred: readonly string[] | undefined, supported: readonly string[]): string {
  const available = supported.length > 0 ? [...supported] : [FALLBACK_LANGUAGE];
  for (const candidate of preferred ?? []) {
    const tag = candidate.toLowerCase();
    const exact = available.find((lang) => lang.toLowerCase() === tag);
    if (exact) return exact;
    const base = tag.split('-')[0] ?? '';
    const partial = available.find((lang) => (lang.toLowerCase().split('-')[0] ?? '') === base);
    if (partial) return partial;
  }
  if (available.includes(FALLBACK_LANGUAGE)) return FALLBACK_LANGUAGE;
  return available[0] ?? FALLBACK_LANGUAGE;
}

/**
 * The text direction for a language.
 *
 * @param language The language code.
 * @returns `rtl` or `ltr`.
 */
export function directionFor(language: string): 'rtl' | 'ltr' {
  const base = (language.toLowerCase().split('-')[0] ?? '') as string;
  return RTL_LANGUAGES.has(base) ? 'rtl' : 'ltr';
}
