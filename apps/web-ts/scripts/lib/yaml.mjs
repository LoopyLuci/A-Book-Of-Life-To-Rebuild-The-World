/**
 * A small, dependency-free YAML reader for the subset of YAML used by this
 * repository (sidecar metadata and UI string catalogues).
 *
 * The subset is deliberately narrow and is documented here so that the tests
 * can assert on it:
 *
 *   - block mappings (`key: value`), including nested mappings
 *   - block sequences (`- item`), both indented under their key and at the
 *     same indentation as their key
 *   - sequences of mappings (`- title: X` followed by `  license: Y`)
 *   - flow sequences (`[a, b, c]`) and flow mappings (`{a: 1}`)
 *   - plain, single-quoted and double-quoted scalars
 *   - `null` / `~`, booleans, integers and floats
 *
 * Anything outside that subset raises {@link YamlParseError} rather than
 * silently producing a wrong value.
 *
 * @module scripts/lib/yaml
 */

/** @typedef {import('./types.js').YamlValue} YamlValue */
/** @typedef {import('./types.js').YamlScalar} YamlScalar */

/**
 * Error thrown when the input is not valid for the supported YAML subset.
 */
export class YamlParseError extends Error {
  /**
   * @param {string} message
   * @param {number} [line] Zero-based line number in the source document.
   */
  constructor(message, line) {
    super(line === undefined ? message : `${message} (line ${line + 1})`);
    this.name = 'YamlParseError';
    /** @type {number|undefined} */
    this.line = line;
  }
}

/** A plain (unquoted) mapping key, e.g. `time_to_complete`. */
const PLAIN_KEY = /^[A-Za-z_][A-Za-z0-9_.-]*$/;

/**
 * One significant (non-blank, non-comment) line of the document.
 *
 * @typedef {{indent: number, text: string, raw: string, number: number}} Line
 */

/**
 * Parse a YAML document from the supported subset.
 *
 * @param {string} source
 * @returns {YamlValue}
 */
export function parseYaml(source) {
  const lines = readLines(String(source));
  const first = lines[0];
  if (first === undefined) return null;
  const state = { index: 0 };
  const value = parseBlock(lines, state, first.indent);
  const leftover = lines[state.index];
  if (leftover !== undefined) {
    throw new YamlParseError(`unexpected content "${leftover.text}"`, leftover.number);
  }
  return value;
}

/**
 * Parse a YAML document and assert that the result is a mapping.
 *
 * @param {string} source
 * @returns {{[key: string]: YamlValue}}
 */
export function parseYamlMapping(source) {
  const value = parseYaml(source);
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    throw new YamlParseError('expected a mapping at the document root');
  }
  return /** @type {{[key: string]: YamlValue}} */ (value);
}

/**
 * @param {string} source
 * @returns {Line[]}
 */
function readLines(source) {
  /** @type {Line[]} */
  const lines = [];
  const rawLines = source.split(/\r?\n/);
  for (let n = 0; n < rawLines.length; n += 1) {
    const raw = rawLines[n] ?? '';
    if (raw.trim() === '') continue;
    const text = raw.trim();
    if (text.startsWith('#')) continue;
    lines.push({ indent: raw.length - raw.trimStart().length, text, raw, number: n });
  }
  return lines;
}

/**
 * Parse whatever block starts at the current line.
 *
 * @param {Line[]} lines
 * @param {{index: number}} state
 * @param {number} indent
 * @returns {YamlValue}
 */
function parseBlock(lines, state, indent) {
  const line = lines[state.index];
  if (line === undefined) return null;
  if (isSequenceItem(line.text)) return parseSequence(lines, state, indent);
  if (splitKey(line.text) !== null) return parseMapping(lines, state, indent);
  state.index += 1;
  return parseScalar(line.text, line.number);
}

/**
 * @param {string} text
 * @returns {boolean}
 */
function isSequenceItem(text) {
  return text === '-' || text.startsWith('- ');
}

/**
 * @param {Line[]} lines
 * @param {{index: number}} state
 * @param {number} indent
 * @returns {{[key: string]: YamlValue}}
 */
function parseMapping(lines, state, indent) {
  /** @type {{[key: string]: YamlValue}} */
  const map = {};
  while (state.index < lines.length) {
    const line = lines[state.index];
    if (line === undefined) break;
    if (line.indent < indent) break;
    if (line.indent > indent) {
      throw new YamlParseError(`unexpected indentation in "${line.text}"`, line.number);
    }
    if (isSequenceItem(line.text)) break;
    const parts = splitKey(line.text);
    if (parts === null) {
      throw new YamlParseError(`expected "key: value" but found "${line.text}"`, line.number);
    }
    state.index += 1;
    map[parts.key] = parts.rest === '' ? parseChildBlock(lines, state, indent) : parseScalar(parts.rest, line.number);
  }
  return map;
}

/**
 * Parse the value that belongs to a key whose value starts on the next line.
 *
 * @param {Line[]} lines
 * @param {{index: number}} state
 * @param {number} parentIndent
 * @returns {YamlValue}
 */
function parseChildBlock(lines, state, parentIndent) {
  const next = lines[state.index];
  if (next === undefined) return null;
  if (next.indent > parentIndent) return parseBlock(lines, state, next.indent);
  // YAML also allows a sequence to sit at the same indentation as its key.
  if (next.indent === parentIndent && isSequenceItem(next.text)) return parseSequence(lines, state, next.indent);
  return null;
}

/**
 * @param {Line[]} lines
 * @param {{index: number}} state
 * @param {number} indent
 * @returns {YamlValue[]}
 */
function parseSequence(lines, state, indent) {
  /** @type {YamlValue[]} */
  const items = [];
  while (state.index < lines.length) {
    const line = lines[state.index];
    if (line === undefined) break;
    if (line.indent !== indent) break;
    if (!isSequenceItem(line.text)) break;
    const contentColumn = dashContentColumn(line);
    const rest = line.text === '-' ? '' : line.text.slice(2).trim();
    state.index += 1;
    if (rest === '') {
      items.push(parseChildBlock(lines, state, indent));
      continue;
    }
    const parts = splitKey(rest);
    if (parts !== null && PLAIN_KEY.test(parts.key)) {
      items.push(parseInlineMapping(lines, state, contentColumn, parts, line));
      continue;
    }
    items.push(parseScalar(rest, line.number));
  }
  return items;
}

/**
 * Column at which the content of a `-` item starts (used as the indentation
 * of the mapping that follows an inline `- key: value` item).
 *
 * @param {Line} line
 * @returns {number}
 */
function dashContentColumn(line) {
  let column = line.indent + 1;
  while (column < line.raw.length && line.raw[column] === ' ') column += 1;
  return column;
}

/**
 * Parse a mapping whose first key was written on the `- ` line itself.
 *
 * @param {Line[]} lines
 * @param {{index: number}} state
 * @param {number} indent
 * @param {{key: string, rest: string}} first
 * @param {Line} firstLine
 * @returns {{[key: string]: YamlValue}}
 */
function parseInlineMapping(lines, state, indent, first, firstLine) {
  /** @type {{[key: string]: YamlValue}} */
  const map = {};
  map[first.key] = first.rest === '' ? parseChildBlock(lines, state, indent) : parseScalar(first.rest, firstLine.number);
  while (state.index < lines.length) {
    const line = lines[state.index];
    if (line === undefined) break;
    if (line.indent !== indent) break;
    if (isSequenceItem(line.text)) break;
    const parts = splitKey(line.text);
    if (parts === null) {
      throw new YamlParseError(`expected "key: value" but found "${line.text}"`, line.number);
    }
    state.index += 1;
    map[parts.key] = parts.rest === '' ? parseChildBlock(lines, state, indent) : parseScalar(parts.rest, line.number);
  }
  return map;
}

/**
 * Split `key: value` into its parts.
 *
 * Returns `null` when the text is not a mapping entry. A colon only separates
 * a key from a value when it is followed by a space or ends the line, which is
 * what keeps identifiers such as `pnk:01HZX0K8J9Q7R3VY6T2M4B8N1W` intact.
 *
 * @param {string} text
 * @returns {{key: string, rest: string}|null}
 */
function splitKey(text) {
  if (text.startsWith('"') || text.startsWith("'")) return null;
  for (let i = 0; i < text.length; i += 1) {
    if (text[i] !== ':') continue;
    if (i === text.length - 1) return { key: text.slice(0, i).trim(), rest: '' };
    if (text[i + 1] === ' ') return { key: text.slice(0, i).trim(), rest: text.slice(i + 2).trim() };
  }
  return null;
}

/**
 * Parse a scalar or a flow collection.
 *
 * @param {string} text
 * @param {number} lineNumber
 * @returns {YamlValue}
 */
function parseScalar(text, lineNumber) {
  if (text === '') return null;
  if (text.length >= 2 && text.startsWith('"') && text.endsWith('"')) {
    return unescapeDoubleQuoted(text.slice(1, -1));
  }
  if (text.length >= 2 && text.startsWith("'") && text.endsWith("'")) {
    return text.slice(1, -1).replace(/''/g, "'");
  }
  if (text.startsWith('[')) return parseFlowSequence(text, lineNumber);
  if (text.startsWith('{')) return parseFlowMapping(text, lineNumber);
  if (text === 'null' || text === '~') return null;
  if (text === 'true') return true;
  if (text === 'false') return false;
  if (/^-?\d+$/.test(text)) return Number(text);
  if (/^-?(?:\d+\.\d*|\.\d+)$/.test(text)) return Number(text);
  return text;
}

/**
 * @param {string} text
 * @param {number} lineNumber
 * @returns {YamlValue[]}
 */
function parseFlowSequence(text, lineNumber) {
  if (!text.endsWith(']')) throw new YamlParseError('unterminated flow sequence', lineNumber);
  const inner = text.slice(1, -1).trim();
  if (inner === '') return [];
  return splitFlowItems(inner).map((item) => parseScalar(item.trim(), lineNumber));
}

/**
 * @param {string} text
 * @param {number} lineNumber
 * @returns {{[key: string]: YamlValue}}
 */
function parseFlowMapping(text, lineNumber) {
  if (!text.endsWith('}')) throw new YamlParseError('unterminated flow mapping', lineNumber);
  const inner = text.slice(1, -1).trim();
  /** @type {{[key: string]: YamlValue}} */
  const map = {};
  if (inner === '') return map;
  for (const item of splitFlowItems(inner)) {
    const parts = splitKey(item.trim());
    if (parts === null) throw new YamlParseError('expected "key: value" in flow mapping', lineNumber);
    map[parts.key] = parseScalar(parts.rest, lineNumber);
  }
  return map;
}

/**
 * Split a flow collection body on commas that are not inside quotes or nested
 * collections.
 *
 * @param {string} inner
 * @returns {string[]}
 */
function splitFlowItems(inner) {
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
    if (char === '[' || char === '{') depth += 1;
    if (char === ']' || char === '}') depth -= 1;
    if (char === ',' && depth === 0) {
      items.push(current);
      current = '';
      continue;
    }
    current += char;
  }
  items.push(current);
  return items;
}

/**
 * @param {string} value
 * @returns {string}
 */
function unescapeDoubleQuoted(value) {
  let out = '';
  for (let i = 0; i < value.length; i += 1) {
    const char = value[i];
    if (char !== '\\') {
      out += char;
      continue;
    }
    const next = value[i + 1];
    i += 1;
    switch (next) {
      case 'n': out += '\n'; break;
      case 't': out += '\t'; break;
      case 'r': out += '\r'; break;
      case '"': out += '"'; break;
      case '\\': out += '\\'; break;
      case '/': out += '/'; break;
      case 'u': {
        const hex = value.slice(i + 1, i + 5);
        if (/^[0-9a-fA-F]{4}$/.test(hex)) {
          out += String.fromCharCode(parseInt(hex, 16));
          i += 4;
        }
        break;
      }
      default:
        out += next === undefined ? '\\' : next;
        break;
    }
  }
  return out;
}
