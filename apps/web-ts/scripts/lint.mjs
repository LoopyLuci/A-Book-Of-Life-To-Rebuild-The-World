#!/usr/bin/env node
/**
 * A small, dependency-free linter for this application.
 *
 * The rules encode the guarantees this app makes, so a violation is a real
 * defect rather than a style preference:
 *
 *   - no network access at runtime (the app must work offline)
 *   - no `eval`, `new Function` or `document.write`
 *   - `innerHTML` may only be written in one place, from pre-sanitised markup
 *   - no `console` noise in the application sources
 *   - every language defines the same set of application strings
 *
 * Usage: node scripts/lint.mjs
 */

import { readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const APP_DIR = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const SRC_DIR = join(APP_DIR, 'src');

/** @type {string[]} */
const problems = [];

/**
 * List every file under a directory.
 *
 * @param {string} dir The directory to walk.
 * @param {string} [extension] Only return files with this extension.
 * @returns {string[]} Absolute paths.
 */
function listFiles(dir, extension) {
  /** @type {string[]} */
  const found = [];
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) found.push(...listFiles(full, extension));
    else if (extension === undefined || entry.endsWith(extension)) found.push(full);
  }
  return found.sort();
}

/**
 * Report a problem.
 *
 * @param {string} file The file the problem is in.
 * @param {number} line The one-based line number.
 * @param {string} message The description.
 */
function report(file, line, message) {
  problems.push(`${relative(APP_DIR, file)}:${line}: ${message}`);
}

/**
 * The network related APIs the application is not allowed to use.
 */
const NETWORK_PATTERNS = [
  { pattern: /\bXMLHttpRequest\b/, message: 'XMLHttpRequest is not allowed; the app must work offline' },
  { pattern: /\bWebSocket\b/, message: 'WebSocket is not allowed; the app must work offline' },
  { pattern: /\bEventSource\b/, message: 'EventSource is not allowed; the app must work offline' },
  { pattern: /navigator\.sendBeacon/, message: 'sendBeacon is not allowed; the app must work offline' },
  { pattern: /import\s*\(\s*['"]https?:/, message: 'dynamic imports over HTTP are not allowed' },
];

const sources = listFiles(SRC_DIR, '.ts');

for (const file of sources) {
  const lines = readFileSync(file, 'utf8').split(/\r?\n/);
  const isContentModule = file.endsWith(join('src', 'content.ts'));

  lines.forEach((text, index) => {
    const lineNumber = index + 1;
    const code = text.replace(/\/\/.*$/, '').replace(/\/\*.*?\*\//g, '');

    for (const rule of NETWORK_PATTERNS) {
      if (rule.pattern.test(code)) report(file, lineNumber, rule.message);
    }

    if (/\bfetch\s*\(/.test(code) && !isContentModule) {
      report(file, lineNumber, 'fetch() is only allowed in src/content.ts, and only for the local payload');
    }

    if (/\beval\s*\(/.test(code)) report(file, lineNumber, 'eval() is not allowed');
    if (/new\s+Function\s*\(/.test(code)) report(file, lineNumber, 'new Function() is not allowed');
    if (/document\.write\s*\(/.test(code)) report(file, lineNumber, 'document.write() is not allowed');

    if (/\binnerHTML\b/.test(code) && !file.endsWith(join('src', 'ui.ts'))) {
      report(file, lineNumber, 'innerHTML may only be used in src/ui.ts, from pre-sanitised markup');
    }

    if (/\bconsole\.(log|debug|info)\s*\(/.test(code)) {
      report(file, lineNumber, 'console output is not allowed in the application sources');
    }
  });
}

// The application strings must be complete for every language.
const uiStrings = readFileSync(join(SRC_DIR, 'ui-strings.ts'), 'utf8');
const languageBlocks = [...uiStrings.matchAll(/^ {2}(\w+):\s*\{([\s\S]*?)^ {2}\},?$/gm)];
if (languageBlocks.length === 0) {
  problems.push('src/ui-strings.ts: no language tables found');
} else {
  const keyPattern = /^ {4}([a-z_]+):/gm;
  const englishKeys = [...(languageBlocks[0]?.[2] ?? '').matchAll(keyPattern)].map((match) => match[1]);
  for (const [, language, body] of languageBlocks) {
    const keys = [...(body ?? '').matchAll(keyPattern)].map((match) => match[1]);
    const missing = englishKeys.filter((key) => !keys.includes(key));
    const extra = keys.filter((key) => !englishKeys.includes(key));
    if (missing.length > 0) {
      problems.push(`src/ui-strings.ts: the "${language}" table is missing: ${missing.join(', ')}`);
    }
    if (extra.length > 0) {
      problems.push(`src/ui-strings.ts: the "${language}" table has unknown keys: ${extra.join(', ')}`);
    }
  }
}

if (problems.length > 0) {
  process.stderr.write(`Lint failed with ${problems.length} problem(s):\n`);
  for (const problem of problems) process.stderr.write(`  ${problem}\n`);
  process.exitCode = 1;
} else {
  const keyCount = languageBlocks.length > 0
    ? [...(languageBlocks[0]?.[2] ?? '').matchAll(/^ {4}([a-z_]+):/gm)].length
    : 0;
  process.stdout.write(
    `Lint passed: ${sources.length} source files, ${languageBlocks.length} languages, ${keyCount} UI strings checked.\n`,
  );
}
