/**
 * Shared types for the A Book Of Life static web app.
 *
 * The shapes here mirror `public/content.json`, which is produced by
 * `scripts/export-content.mjs` from the knowledge base corpus.
 */

/** A knowledge domain, e.g. `survival`. */
export interface Domain {
  /** Slug used in URLs and in the corpus directory name. */
  id: string;
  /** Human readable name. */
  title: string;
  /** One line summary of the domain. */
  description: string;
  /** Accent colour as a hex string. */
  color: string;
  /** Accent hue in degrees, used to derive theme-aware colours in CSS. */
  hue: number;
  /** Number of entries in the domain. */
  entryCount: number;
}

/** A citation attached to an entry. */
export interface Source {
  title: string;
  author: string;
  url: string;
  license: string;
  year: number;
}

/** The verification record of an entry. */
export interface Verification {
  status: string;
  date: string;
  reviewers: string[];
  testedBy: string;
  location: string;
  notes: string;
}

/** Optional, domain-specific metadata carried by some entries. */
export interface EntryExtras {
  yield: string;
  season: string;
  storage: string;
  cost: string;
  lifespan: string;
  maintenance: string;
  resourceBudget: {
    batch: string;
    laborHours: number;
    energyKwh: number;
    waterLiters: number;
  };
}

/** A single knowledge entry. */
export interface Entry {
  /** Stable identifier, e.g. `pnk:01HZX.../survival/basic-first-aid`. */
  id: string;
  /** Slug of the entry within its domain. */
  slug: string;
  /** Domain slug the entry belongs to. */
  domain: string;
  /** Human readable title. */
  title: string;
  /** Free-form topical tags. */
  tags: string[];
  /** `novice`, `apprentice`, `journeyman` or `master`. */
  difficulty: string;
  /** `green`, `yellow` or `red`. */
  safety: string;
  /** Coarse duration label, e.g. `hours`. */
  timeToComplete: string;
  verification: Verification;
  sources: Source[];
  /** Ids of entries this one is related to. */
  links: string[];
  /** Ids of entries that should be read first. */
  prerequisites: string[];
  materials: string[];
  tools: string[];
  hazards: string[];
  limits: string[];
  geographicApplicability: string[];
  /** BCP 47 language of the entry body. */
  language: string;
  media: Array<Record<string, unknown>>;
  extras: EntryExtras;
  /** The raw Markdown body of the entry. */
  body: string;
}

/** Metadata about the knowledge base itself. */
export interface SiteInfo {
  name: string;
  description: string;
  homepage: string;
  repository: string;
  licenseContent: string;
  licenseCode: string;
}

/** The disclaimer, quoted verbatim from `docs/DISCLAIMER.md`. */
export interface Disclaimer {
  title: string;
  markdown: string;
}

/** The complete exported payload. */
export interface ContentPayload {
  /** Version from `manifest.toml`. */
  manifestVersion: string;
  schemaVersion: string;
  defaultLanguage: string;
  supportedLanguages: string[];
  generatedAt: string;
  site: SiteInfo;
  disclaimer: Disclaimer;
  domains: Domain[];
  entries: Entry[];
  strings: Record<string, Record<string, string>>;
}

/** A flat map of UI strings for one language. */
export type StringTable = Record<string, string>;

/** Theme preference. `system` follows the operating system setting. */
export type ThemePreference = 'system' | 'light' | 'dark';

/** The theme actually applied to the document. */
export type ResolvedTheme = 'light' | 'dark';

/** The difficulty levels used across the corpus, in ascending order. */
export const DIFFICULTY_LEVELS = ['novice', 'apprentice', 'journeyman', 'master'] as const;

/** The safety levels used across the corpus, from safest to most dangerous. */
export const SAFETY_LEVELS = ['green', 'yellow', 'red'] as const;

/** The verification lifecycle states used across the corpus. */
export const VERIFICATION_STATUSES = ['draft', 'peer-reviewed', 'field-tested', 'deprecated'] as const;

/** One of the difficulty levels. */
export type Difficulty = (typeof DIFFICULTY_LEVELS)[number];

/** One of the safety levels. */
export type SafetyLevel = (typeof SAFETY_LEVELS)[number];

/** One of the verification states. */
export type VerificationStatus = (typeof VERIFICATION_STATUSES)[number];
