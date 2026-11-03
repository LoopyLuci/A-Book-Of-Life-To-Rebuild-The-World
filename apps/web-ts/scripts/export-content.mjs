#!/usr/bin/env node
/**
 * Export the knowledge base into a single JSON payload for the static web app.
 *
 * Reads, from the repository root:
 *   - `domains/<domain>/<slug>.md`      entry bodies (Markdown)
 *   - `sidecars/<domain>/<slug>.pnk.yaml` entry metadata
 *   - `i18n/strings/<lang>.yaml`        UI strings for every language
 *   - `manifest.toml`                   version and canonical domain order
 *   - `domains/README.md`               domain descriptions
 *   - `docs/DISCLAIMER.md`              the disclaimer, quoted verbatim
 *
 * Writes `public/content.json` in this app's folder. The script is offline,
 * deterministic (apart from the `generatedAt` stamp) and safe to re-run.
 *
 * Usage: node scripts/export-content.mjs [--out <file>] [--quiet]
 */

import { readFileSync, writeFileSync, readdirSync, statSync, mkdirSync } from 'node:fs';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

import { parseYamlMapping } from './lib/yaml.mjs';
import { parseToml } from './lib/toml.mjs';
import { DOMAIN_SEEDS, domainColor } from './lib/domains.mjs';

const APP_DIR = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const ROOT = resolve(APP_DIR, '..', '..');
const DOMAINS_DIR = join(ROOT, 'domains');
const SIDECARS_DIR = join(ROOT, 'sidecars');
const STRINGS_DIR = join(ROOT, 'i18n', 'strings');
const MANIFEST_PATH = join(ROOT, 'manifest.toml');
const DISCLAIMER_PATH = join(ROOT, 'docs', 'DISCLAIMER.md');

/**
 * @typedef {object} ExportOptions
 * @property {string} out Output file for the JSON payload.
 * @property {boolean} quiet Suppress the summary.
 */

/**
 * @typedef {object} SourcePayload
 * @property {string} title
 * @property {string} author
 * @property {string} url
 * @property {string} license
 * @property {number} year
 */

/**
 * @typedef {object} VerificationPayload
 * @property {string} status
 * @property {string} date
 * @property {string[]} reviewers
 * @property {string} testedBy
 * @property {string} location
 * @property {string} notes
 */

/**
 * @typedef {object} EntryPayload
 * @property {string} id
 * @property {string} slug
 * @property {string} domain
 * @property {string} title
 * @property {string[]} tags
 * @property {string} difficulty
 * @property {string} safety
 * @property {string} timeToComplete
 * @property {VerificationPayload} verification
 * @property {SourcePayload[]} sources
 * @property {string[]} links
 * @property {string[]} prerequisites
 * @property {string[]} materials
 * @property {string[]} tools
 * @property {string[]} hazards
 * @property {string[]} limits
 * @property {string[]} geographicApplicability
 * @property {string} language
 * @property {Array<Record<string, unknown>>} media
 * @property {Record<string, unknown>} extras
 * @property {string} body
 */

/**
 * @typedef {object} DomainPayload
 * @property {string} id
 * @property {string} title
 * @property {string} description
 * @property {string} color
 * @property {number} hue
 * @property {number} entryCount
 */

/**
 * @param {string[]} argv
 * @returns {ExportOptions}
 */
function parseArgs(argv) {
  /** @type {ExportOptions} */
  const options = { out: join(APP_DIR, 'public', 'content.json'), quiet: false };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--out') {
      const value = argv[i + 1];
      if (value === undefined) throw new Error('--out requires a path');
      options.out = resolve(APP_DIR, value);
      i += 1;
    } else if (arg === '--quiet') {
      options.quiet = true;
    } else {
      throw new Error(`unknown argument "${arg}"`);
    }
  }
  return options;
}

/**
 * Recursively list files with the given extension under a directory.
 *
 * @param {string} dir
 * @param {string} extension
 * @returns {string[]} Absolute paths, sorted.
 */
function listFiles(dir, extension) {
  /** @type {string[]} */
  const found = [];
  /** @param {string} current */
  const walk = (current) => {
    let entries;
    try {
      entries = readdirSync(current, { withFileTypes: true });
    } catch {
      return;
    }
    for (const entry of entries) {
      const full = join(current, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.name.endsWith(extension)) found.push(full);
    }
  };
  walk(dir);
  return found.sort();
}

/**
 * @param {unknown} value
 * @returns {string[]}
 */
function asStringArray(value) {
  if (!Array.isArray(value)) return [];
  return value.filter((item) => typeof item === 'string');
}

/**
 * @param {unknown} value
 * @returns {number}
 */
function asNumber(value) {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

/**
 * @param {unknown} value
 * @returns {string}
 */
function asString(value) {
  return typeof value === 'string' ? value : '';
}

/**
 * @param {unknown} value
 * @returns {Record<string, unknown>}
 */
function asRecord(value) {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) return {};
  return /** @type {Record<string, unknown>} */ (value);
}

/**
 * Build the per-entry payload from a sidecar and its Markdown body.
 *
 * @param {Record<string, unknown>} sidecar
 * @param {string} body
 * @param {string} slug
 * @param {string} domain
 * @returns {EntryPayload}
 */
function buildEntry(sidecar, body, slug, domain) {
  const verification = asRecord(sidecar['verification']);
  const budget = asRecord(sidecar['resource_budget']);
  const sources = Array.isArray(sidecar['sources']) ? sidecar['sources'] : [];
  return {
    id: asString(sidecar['id']),
    slug,
    domain,
    title: asString(sidecar['title']),
    tags: asStringArray(sidecar['tags']),
    difficulty: asString(sidecar['difficulty']),
    safety: asString(sidecar['safety']),
    timeToComplete: asString(sidecar['time_to_complete']),
    verification: {
      status: asString(verification['status']),
      date: asString(verification['date']),
      reviewers: asStringArray(verification['reviewers']),
      testedBy: asString(verification['tested_by']),
      location: asString(verification['location']),
      notes: asString(verification['notes']),
    },
    sources: sources.map((raw) => {
      const source = asRecord(raw);
      return {
        title: asString(source['title']),
        author: asString(source['author']),
        url: asString(source['url']),
        license: asString(source['license']),
        year: typeof source['year'] === 'number' ? source['year'] : 0,
      };
    }),
    links: asStringArray(sidecar['links']),
    prerequisites: asStringArray(sidecar['prerequisites']),
    materials: asStringArray(sidecar['materials_required']),
    tools: asStringArray(sidecar['tools_required']),
    hazards: asStringArray(sidecar['hazards']),
    limits: asStringArray(sidecar['limits']),
    geographicApplicability: asStringArray(sidecar['geographic_applicability']),
    language: asString(sidecar['language']) || 'en',
    media: Array.isArray(sidecar['media']) ? sidecar['media'] : [],
    extras: {
      yield: asString(sidecar['yield']),
      season: asString(sidecar['season']),
      storage: asString(sidecar['storage']),
      cost: asString(sidecar['cost']),
      lifespan: asString(sidecar['lifespan']),
      maintenance: asString(sidecar['maintenance']),
      resourceBudget: {
        batch: asString(budget['batch']),
        laborHours: asNumber(budget['labor_hours']),
        energyKwh: asNumber(budget['energy_kwh']),
        waterLiters: asNumber(budget['water_liters']),
      },
    },
    body,
  };
}

/**
 * Read the domain description table from `domains/README.md`.
 *
 * @returns {Map<string, string>}
 */
function readDomainDescriptions() {
  /** @type {Map<string, string>} */
  const descriptions = new Map();
  let text = '';
  try {
    text = readFileSync(join(DOMAINS_DIR, 'README.md'), 'utf8');
  } catch {
    return descriptions;
  }
  for (const line of text.split(/\r?\n/)) {
    const match = /^\|\s*\[([a-z0-9-]+)\]\([^)]*\)\s*\|\s*(.*?)\s*\|\s*[^|]*\|\s*$/.exec(line);
    if (match && match[1] && match[2]) descriptions.set(match[1], match[2]);
  }
  return descriptions;
}

/**
 * Read the human title of a domain from its `README.md` heading.
 *
 * @param {string} domain
 * @returns {string}
 */
function readDomainTitle(domain) {
  try {
    const text = readFileSync(join(DOMAINS_DIR, domain, 'README.md'), 'utf8');
    for (const line of text.split(/\r?\n/)) {
      const heading = /^#\s+(.+?)\s*$/.exec(line);
      if (heading && heading[1]) return heading[1];
    }
  } catch {
    /* fall through to the seeded title */
  }
  return '';
}

/**
 * Run the export.
 *
 * @param {ExportOptions} options
 * @returns {{payload: object, entryCount: number, domainCount: number}}
 */
export function exportContent(options) {
  const manifest = parseToml(readFileSync(MANIFEST_PATH, 'utf8'));
  const project = asRecord(manifest['project']);
  const knowledgeBase = asRecord(manifest['knowledge_base']);
  const manifestDomains = asStringArray(asRecord(manifest['domains'])['list']);

  const descriptions = readDomainDescriptions();
  const seeds = new Map(DOMAIN_SEEDS.map((seed) => [seed.id, seed]));
  const orderedDomainIds = manifestDomains.length > 0 ? manifestDomains : DOMAIN_SEEDS.map((seed) => seed.id);

  /** @type {EntryPayload[]} */
  const entries = [];
  for (const sidecarPath of listFiles(SIDECARS_DIR, '.pnk.yaml')) {
    const rel = relative(SIDECARS_DIR, sidecarPath);
    const parts = rel.split(sep);
    if (parts.length !== 2) continue;
    const [domain, fileName] = parts;
    if (domain === undefined || fileName === undefined) continue;
    const slug = fileName.replace(/\.pnk\.yaml$/, '');
    const bodyPath = join(DOMAINS_DIR, domain, `${slug}.md`);
    let body = '';
    try {
      body = readFileSync(bodyPath, 'utf8');
    } catch {
      continue; // a sidecar without a body is not an entry (same rule as scripts/build_index.py)
    }
    const sidecar = parseYamlMapping(readFileSync(sidecarPath, 'utf8'));
    entries.push(buildEntry(sidecar, body, slug, domain));
  }

  const domainOrder = new Map(orderedDomainIds.map((id, index) => [id, index]));
  entries.sort((a, b) => {
    const domainDelta = (domainOrder.get(a.domain) ?? 999) - (domainOrder.get(b.domain) ?? 999);
    if (domainDelta !== 0) return domainDelta;
    return a.title.localeCompare(b.title);
  });

  const counts = new Map();
  for (const entry of entries) counts.set(entry.domain, (counts.get(entry.domain) ?? 0) + 1);

  /** @type {DomainPayload[]} */
  const domains = [];
  for (const id of orderedDomainIds) {
    const seed = seeds.get(id);
    const title = readDomainTitle(id) || seed?.fallbackTitle || id;
    const description = descriptions.get(id) || seed?.fallbackDescription || '';
    const hue = seed?.hue ?? 210;
    domains.push({
      id,
      title,
      description,
      color: domainColor(hue),
      hue,
      entryCount: counts.get(id) ?? 0,
    });
  }
  // Any domain present in the corpus but missing from the manifest list.
  for (const id of [...counts.keys()].sort()) {
    if (domains.some((domain) => domain.id === id)) continue;
    const seed = seeds.get(id);
    const hue = seed?.hue ?? 210;
    domains.push({
      id,
      title: readDomainTitle(id) || seed?.fallbackTitle || id,
      description: descriptions.get(id) || seed?.fallbackDescription || '',
      color: domainColor(hue),
      hue,
      entryCount: counts.get(id) ?? 0,
    });
  }

  /** @type {{[lang: string]: {[key: string]: string}}} */
  const strings = {};
  for (const file of listFiles(STRINGS_DIR, '.yaml')) {
    const lang = file.slice(STRINGS_DIR.length + 1).replace(/\.yaml$/, '');
    const parsed = parseYamlMapping(readFileSync(file, 'utf8'));
    /** @type {{[key: string]: string}} */
    const table = {};
    for (const [key, value] of Object.entries(parsed)) {
      table[key] = typeof value === 'string' ? value : String(value ?? '');
    }
    strings[lang] = table;
  }

  let disclaimerMarkdown = '';
  let disclaimerTitle = 'Disclaimer';
  try {
    disclaimerMarkdown = readFileSync(DISCLAIMER_PATH, 'utf8');
    const heading = /^#\s+(.+?)\s*$/m.exec(disclaimerMarkdown);
    if (heading && heading[1]) disclaimerTitle = heading[1];
  } catch {
    disclaimerMarkdown = '';
  }

  const payload = {
    manifestVersion: asString(project['version']),
    schemaVersion: asString(knowledgeBase['schema_version']),
    defaultLanguage: asString(knowledgeBase['default_language']) || 'en',
    supportedLanguages: asStringArray(knowledgeBase['supported_languages']),
    generatedAt: new Date().toISOString(),
    site: {
      name: asString(project['name']),
      description: asString(project['description']),
      homepage: asString(project['homepage']),
      repository: asString(project['repository']),
      licenseContent: asString(project['license_content']),
      licenseCode: asString(project['license_code']),
    },
    disclaimer: { title: disclaimerTitle, markdown: disclaimerMarkdown },
    domains,
    entries,
    strings,
  };

  mkdirSync(dirname(options.out), { recursive: true });
  writeFileSync(options.out, `${JSON.stringify(payload, null, 2)}\n`, 'utf8');

  return { payload, entryCount: entries.length, domainCount: domains.length };
}

const invokedDirectly = process.argv[1] !== undefined
  && resolve(process.argv[1]) === resolve(fileURLToPath(import.meta.url));

if (invokedDirectly) {
  const options = parseArgs(process.argv.slice(2));
  const { entryCount, domainCount } = exportContent(options);
  if (!options.quiet) {
    const bytes = statSync(options.out).size;
    process.stdout.write(
      `Exported ${entryCount} entries across ${domainCount} domains -> ${relative(APP_DIR, options.out)} (${(bytes / 1024).toFixed(1)} KiB)\n`,
    );
  }
}
