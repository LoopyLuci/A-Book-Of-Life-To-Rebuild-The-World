/**
 * A small, dependency-free TOML reader for the subset used by this
 * repository's `manifest.toml`.
 *
 * Supported: tables (`[a.b]`), `key = value` pairs, basic and literal
 * strings, integers, floats, booleans, and arrays of those (arrays may span
 * multiple lines). Dates and inline tables are not needed by the manifest and
 * are reported as an error rather than being guessed at.
 *
 * @module scripts/lib/toml
 */

/** @typedef {import('./types.js').TomlValue} TomlValue */
/** @typedef {import('./types.js').TomlScalar} TomlScalar */

/**
 * Error thrown when the input is not valid for the supported TOML subset.
 */
export class TomlParseError extends Error {
  /**
   * @param {string} message
   * @param {number} [line] Zero-based line number in the source document.
   */
  constructor(message, line) {
    super(line === undefined ? message : `${message} (line ${line + 1})`);
    this.name = 'TomlParseError';
    /** @type {number|undefined} */
    this.line = line;
  }
}

/**
 * Parse a TOML document.
 *
 * @param {string} source
 * @returns {{[key: string]: TomlValue}}
 */
export function parseToml(source) {
  /** @type {{[key: string]: TomlValue}} */
  const root = {};
  let table = root;
  const lines = String(source).split(/\r?\n/);
  for (let i = 0; i < lines.length; i += 1) {
    const line = (lines[i] ?? '').trim();
    if (line === '' || line.startsWith('#')) continue;
    if (line.startsWith('[')) {
      const close = line.indexOf(']');
      if (close === -1) throw new TomlParseError('unterminated table header', i);
      const path = line.slice(1, close).trim().split('.').map((part) => part.trim().replace(/^"|"$/g, ''));
      table = ensureTable(root, path);
      continue;
    }
    const equals = line.indexOf('=');
    if (equals === -1) throw new TomlParseError(`expected "key = value" but found "${line}"`, i);
    const key = line.slice(0, equals).trim().replace(/^"|"$/g, '');
    let valueText = line.slice(equals + 1).trim();
    if (valueText.startsWith('[') && !isBalanced(valueText)) {
      while (i + 1 < lines.length) {
        i += 1;
        valueText = ` ${valueText} ${(lines[i] ?? '').trim()}`;
        if (isBalanced(valueText)) break;
      }
    }
    table[key] = parseValue(valueText, i);
  }
  return root;
}

/**
 * @param {{[key: string]: TomlValue}} root
 * @param {string[]} path
 * @returns {{[key: string]: TomlValue}}
 */
function ensureTable(root, path) {
  /** @type {{[key: string]: TomlValue}} */
  let table = root;
  for (const part of path) {
    const existing = table[part];
    if (existing === undefined) {
      /** @type {{[key: string]: TomlValue}} */
      const created = {};
      table[part] = created;
      table = created;
    } else if (typeof existing === 'object' && !Array.isArray(existing)) {
      table = /** @type {{[key: string]: TomlValue}} */ (existing);
    } else {
      throw new TomlParseError(`cannot redefine "${part}" as a table`);
    }
  }
  return table;
}

/**
 * @param {string} text
 * @returns {boolean}
 */
function isBalanced(text) {
  let depth = 0;
  let quote = '';
  for (const char of text) {
    if (quote !== '') {
      if (char === quote) quote = '';
      continue;
    }
    if (char === '"' || char === "'") {
      quote = char;
      continue;
    }
    if (char === '[') depth += 1;
    if (char === ']') depth -= 1;
  }
  return depth === 0;
}

/**
 * @param {string} text
 * @param {number} line
 * @returns {TomlValue}
 */
function parseValue(text, line) {
  const trimmed = text.trim();
  if (trimmed === '') throw new TomlParseError('missing value', line);
  if (trimmed.startsWith('[')) {
    if (!trimmed.endsWith(']')) throw new TomlParseError('unterminated array', line);
    const inner = trimmed.slice(1, -1).trim();
    if (inner === '') return [];
    return splitArrayItems(inner).map((item) => parseValue(item.trim(), line));
  }
  if (trimmed.startsWith('"')) {
    if (!trimmed.endsWith('"') || trimmed.length < 2) throw new TomlParseError('unterminated string', line);
    return trimmed.slice(1, -1);
  }
  if (trimmed.startsWith("'")) {
    if (!trimmed.endsWith("'") || trimmed.length < 2) throw new TomlParseError('unterminated string', line);
    return trimmed.slice(1, -1);
  }
  if (trimmed === 'true') return true;
  if (trimmed === 'false') return false;
  if (/^-?\d+$/.test(trimmed)) return Number(trimmed);
  if (/^-?(?:\d+\.\d*|\.\d+)$/.test(trimmed)) return Number(trimmed);
  throw new TomlParseError(`unsupported value "${trimmed}"`, line);
}

/**
 * @param {string} inner
 * @returns {string[]}
 */
function splitArrayItems(inner) {
  /** @type {string[]} */
  const items = [];
  let current = '';
  let depth = 0;
  let quote = '';
  for (const char of inner) {
    if (quote !== '') {
      current += char;
      if (char === quote) quote = '';
      continue;
    }
    if (char === '"' || char === "'") {
      quote = char;
      current += char;
      continue;
    }
    if (char === '[') depth += 1;
    if (char === ']') depth -= 1;
    if (char === ',' && depth === 0) {
      items.push(current);
      current = '';
      continue;
    }
    current += char;
  }
  if (current.trim() !== '') items.push(current);
  return items;
}
