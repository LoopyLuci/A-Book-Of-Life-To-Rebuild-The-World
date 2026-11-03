/**
 * Browser state that survives a reload: theme preference, language and the
 * list of recently read entries.
 *
 * All access is defensive: when storage is unavailable (private browsing,
 * a `file://` origin with storage disabled) the app keeps working with an
 * in-memory fallback instead of throwing.
 *
 * @module store
 */

import type { ResolvedTheme, ThemePreference } from './types.js';

/** Keys used in `localStorage`. */
export const STORAGE_KEYS = {
  theme: 'abook.theme',
  language: 'abook.language',
  recent: 'abook.recent',
} as const;

/** Maximum number of recently read entries kept. */
export const RECENT_LIMIT = 20;

/** One recently read entry. */
export interface RecentEntry {
  id: string;
  title: string;
  /** Unix timestamp in milliseconds. */
  at: number;
}

/**
 * A `localStorage`-like store that never throws.
 */
interface SafeStorage {
  get(key: string): string | null;
  set(key: string, value: string): void;
  remove(key: string): void;
}

/**
 * Build a storage adapter around `localStorage`, falling back to an
 * in-memory map when the browser refuses access.
 *
 * @returns A storage adapter.
 */
function createStorage(): SafeStorage {
  /** @type {Map<string, string>} */
  const memory = new Map();
  let backend: Storage | null = null;
  try {
    const probe = '__abook_probe__';
    window.localStorage.setItem(probe, '1');
    window.localStorage.removeItem(probe);
    backend = window.localStorage;
  } catch {
    backend = null;
  }
  return {
    get(key) {
      try {
        return backend ? backend.getItem(key) : (memory.get(key) ?? null);
      } catch {
        return memory.get(key) ?? null;
      }
    },
    set(key, value) {
      try {
        if (backend) {
          backend.setItem(key, value);
          return;
        }
      } catch {
        /* fall through to the in-memory store */
      }
      memory.set(key, value);
    },
    remove(key) {
      try {
        if (backend) {
          backend.removeItem(key);
          return;
        }
      } catch {
        /* fall through to the in-memory store */
      }
      memory.delete(key);
    },
  };
}

const storage = createStorage();

/**
 * Read the stored theme preference.
 *
 * @returns The preference, defaulting to `system`.
 */
export function loadThemePreference(): ThemePreference {
  const value = storage.get(STORAGE_KEYS.theme);
  if (value === 'light' || value === 'dark' || value === 'system') return value;
  return 'system';
}

/**
 * Store the theme preference.
 *
 * @param preference The preference to store.
 */
export function saveThemePreference(preference: ThemePreference): void {
  storage.set(STORAGE_KEYS.theme, preference);
}

/**
 * Read the stored language.
 *
 * @returns The language code, or `null` when nothing is stored.
 */
export function loadLanguage(): string | null {
  const value = storage.get(STORAGE_KEYS.language);
  return value !== null && value !== '' ? value : null;
}

/**
 * Store the language.
 *
 * @param language The language code to store.
 */
export function saveLanguage(language: string): void {
  storage.set(STORAGE_KEYS.language, language);
}

/**
 * Read the recently read entries, most recent first.
 *
 * @returns The stored entries.
 */
export function loadRecent(): RecentEntry[] {
  const raw = storage.get(STORAGE_KEYS.recent);
  if (raw === null) return [];
  try {
    const parsed: unknown = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    /** @type {RecentEntry[]} */
    const entries: RecentEntry[] = [];
    for (const item of parsed) {
      if (item === null || typeof item !== 'object') continue;
      const record = /** @type {Record<string, unknown>} */ (item);
      const id = record['id'];
      const title = record['title'];
      const at = record['at'];
      if (typeof id !== 'string' || typeof title !== 'string' || typeof at !== 'number') continue;
      entries.push({ id, title, at });
    }
    return entries.slice(0, RECENT_LIMIT);
  } catch {
    return [];
  }
}

/**
 * Store the recently read entries.
 *
 * @param entries The entries to store, most recent first.
 */
export function saveRecent(entries: RecentEntry[]): void {
  storage.set(STORAGE_KEYS.recent, JSON.stringify(entries.slice(0, RECENT_LIMIT)));
}

/**
 * Add an entry to the recently read list.
 *
 * @param id The entry id.
 * @param title The entry title.
 * @returns The updated list.
 */
export function pushRecent(id: string, title: string): RecentEntry[] {
  const existing = loadRecent().filter((entry) => entry.id !== id);
  const updated: RecentEntry[] = [{ id, title, at: Date.now() }, ...existing].slice(0, RECENT_LIMIT);
  saveRecent(updated);
  return updated;
}

/**
 * Remove every recently read entry.
 */
export function clearRecent(): void {
  storage.remove(STORAGE_KEYS.recent);
}

/**
 * Turn a preference into the theme that is actually applied.
 *
 * @param preference The stored preference.
 * @param systemPrefersDark Whether the system asks for a dark theme.
 * @returns The theme to apply.
 */
export function resolveTheme(preference: ThemePreference, systemPrefersDark: boolean): ResolvedTheme {
  if (preference === 'light' || preference === 'dark') return preference;
  return systemPrefersDark ? 'dark' : 'light';
}
