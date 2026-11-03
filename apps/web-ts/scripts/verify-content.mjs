import { readFileSync, existsSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * @typedef {object} ContentEntry
 * @property {string} id
 * @property {string} title
 * @property {string} domain
 * @property {string[]} tags
 * @property {string} difficulty
 * @property {string} safety
 * @property {{status: string}} verification
 * @property {unknown[]} sources
 * @property {string} body
 */

/**
 * @typedef {object} ContentDomain
 * @property {string} id
 * @property {number} entryCount
 */

/**
 * @typedef {object} ContentPayload
 * @property {string} manifestVersion
 * @property {ContentEntry[]} entries
 * @property {ContentDomain[]} domains
 * @property {Record<string, Record<string, string>>} strings
 * @property {{markdown: string}} disclaimer
 */

const appDir = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const contentPath = join(appDir, 'dist', 'content.json');

/**
 * Record a check.
 *
 * @param {boolean} condition The result of the check.
 * @param {string} message What was checked.
 */
function assert(condition, message) {
  if (!condition) {
    console.error(`FAIL: ${message}`);
    process.exitCode = 1;
  } else {
    console.log(`ok   ${message}`);
  }
}

assert(existsSync(join(appDir, 'dist', 'index.html')), 'dist/index.html exists');
assert(existsSync(join(appDir, 'dist', 'main.js')), 'dist/main.js exists');
assert(existsSync(join(appDir, 'dist', 'content.json')), 'dist/content.json exists');

const payload = /** @type {ContentPayload} */ (JSON.parse(readFileSync(contentPath, 'utf8')));

assert(Array.isArray(payload.entries), 'content.json has an entries array');
assert(payload.entries.length === 207, `content.json contains 207 entries (found ${payload.entries.length})`);
assert(Array.isArray(payload.domains), 'content.json has a domains array');
assert(payload.domains.length === 16, `content.json contains 16 domains (found ${payload.domains.length})`);

const domainIds = payload.domains.map((domain) => domain.id).sort();
const expected = [
  'agriculture', 'biology', 'chemistry', 'computers', 'construction', 'energy',
  'health', 'knowledge', 'materials', 'quantum', 'ship', 'silicon', 'society',
  'survival', 'transport', 'water',
];
assert(JSON.stringify(domainIds) === JSON.stringify(expected), `the 16 domain ids are present: ${domainIds.join(', ')}`);

const counted = new Map();
for (const entry of payload.entries) counted.set(entry.domain, (counted.get(entry.domain) ?? 0) + 1);
let countsMatch = true;
for (const domain of payload.domains) {
  if (counted.get(domain.id) !== domain.entryCount) countsMatch = false;
}
assert(countsMatch, 'every domain entry count matches the number of entries it holds');

const languages = Object.keys(payload.strings).sort();
assert(
  JSON.stringify(languages) === JSON.stringify(['ar', 'de', 'en', 'es', 'fr', 'hi', 'pt', 'sw', 'zh']),
  `all nine languages are present: ${languages.join(', ')}`,
);

assert(typeof payload.manifestVersion === 'string' && payload.manifestVersion.length > 0, `the manifest version is exported (${payload.manifestVersion})`);
assert(payload.disclaimer.markdown.includes('Reference material only'), 'the disclaimer is exported verbatim');

const everyEntryHasABody = payload.entries.every((entry) => typeof entry.body === 'string' && entry.body.length > 0);
assert(everyEntryHasABody, 'every entry carries its Markdown body');

const everyEntryHasMetadata = payload.entries.every((entry) =>
  typeof entry.id === 'string' && entry.id.startsWith('pnk:')
  && typeof entry.title === 'string' && entry.title.length > 0
  && Array.isArray(entry.tags) && entry.tags.length > 0
  && typeof entry.difficulty === 'string' && typeof entry.safety === 'string'
  && entry.verification && typeof entry.verification.status === 'string'
  && Array.isArray(entry.sources));
assert(everyEntryHasMetadata, 'every entry carries its sidecar metadata');

console.log(`\n${payload.entries.length} entries, ${payload.domains.length} domains, ${languages.length} languages.`);
