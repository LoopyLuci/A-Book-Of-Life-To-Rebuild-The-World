/**
 * A small, self-contained Markdown renderer.
 *
 * The renderer never trusts its input: every piece of text is HTML-escaped
 * before any markup is produced, so a knowledge entry can never inject markup
 * into the page. Only the tags emitted by this module end up in the output.
 *
 * Supported syntax: ATX headings, paragraphs, ordered and unordered lists
 * (including nesting), fenced and indented code blocks, inline code,
 * blockquotes, horizontal rules, pipe tables, links, bold, italic and
 * strikethrough emphasis.
 *
 * @module markdown
 */

/** Options accepted by {@link renderMarkdown} and {@link renderInline}. */
export interface MarkdownOptions {
  /**
   * Resolves a link target. Return the href to use, or `null` to render the
   * link as plain text. Used by the app to turn corpus-relative `.md` links
   * into in-app navigation.
   */
  linkResolver?: (href: string) => string | null;
}

type Align = 'left' | 'center' | 'right' | null;

interface HeadingBlock {
  kind: 'heading';
  level: number;
  text: string;
}

interface ParagraphBlock {
  kind: 'paragraph';
  text: string;
}

interface CodeBlock {
  kind: 'code';
  language: string;
  content: string;
}

interface QuoteBlock {
  kind: 'quote';
  children: Block[];
}

interface RuleBlock {
  kind: 'rule';
}

interface ListItem {
  children: Block[];
}

interface ListBlock {
  kind: 'list';
  ordered: boolean;
  start: number;
  tight: boolean;
  items: ListItem[];
}

interface TableBlock {
  kind: 'table';
  header: string[];
  align: Align[];
  rows: string[][];
}

type Block = HeadingBlock | ParagraphBlock | CodeBlock | QuoteBlock | RuleBlock | ListBlock | TableBlock;

const ESCAPES: Record<string, string> = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;',
};

const PLACEHOLDER_START = '\uE000';
const PLACEHOLDER_END = '\uE001';

const ALLOWED_SCHEMES = new Set(['http:', 'https:', 'mailto:']);

const HEADING = /^(#{1,6})[ \t]+(.*?)[ \t]*#*[ \t]*$/;
const RULE = /^ {0,3}([-*_])[ \t]*(?:\1[ \t]*){2,}$/;
const LIST_ITEM = /^([ \t]*)([-*+]|\d{1,9}[.)])[ \t]+(.*)$/;
const FENCE = /^([ \t]*)(`{3,}|~{3,})[ \t]*([^\s`]*)[ \t]*$/;
const QUOTE = /^ {0,3}>[ ]?/;
const TABLE_DELIMITER = /^[ \t]*\|?[ \t]*:?-+:?[ \t]*(?:\|[ \t]*:?-+:?[ \t]*)*\|?[ \t]*$/;

/**
 * Escape the five characters that matter inside HTML text and attributes.
 *
 * @param text Text to escape.
 * @returns The escaped text.
 */
export function escapeHtml(text: string): string {
  return text.replace(/[&<>"']/g, (char) => ESCAPES[char] ?? char);
}

/**
 * Return a link target that is safe to put in an `href` attribute, or `null`
 * when the target uses a scheme that could execute code.
 *
 * @param raw Raw (already escaped) link target.
 * @returns The target, or `null` when it must not be linked.
 */
export function safeHref(raw: string): string | null {
  const trimmed = raw.trim();
  if (trimmed === '') return null;
  const probe = trimmed.replace(/[\s\u0000-\u001f\u007f]/g, '');
  const scheme = /^([a-zA-Z][a-zA-Z0-9+.-]*):/.exec(probe);
  if (scheme && scheme[1]) {
    if (!ALLOWED_SCHEMES.has(`${scheme[1].toLowerCase()}:`)) return null;
    return trimmed;
  }
  if (probe.startsWith('//')) return null;
  return trimmed;
}

/**
 * Turn a heading into a stable anchor id.
 *
 * @param text Heading text.
 * @returns A slug suitable for an `id` attribute.
 */
export function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\u00c0-\u024f]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

/**
 * Render Markdown to an HTML string.
 *
 * @param markdown The Markdown source.
 * @param options Rendering options.
 * @returns An HTML fragment.
 */
export function renderMarkdown(markdown: string, options: MarkdownOptions = {}): string {
  const source = String(markdown).replace(/\r\n?/g, '\n').replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f]/g, '');
  const lines = source.split('\n');
  const cursor = { i: 0 };
  const blocks = parseBlocks(lines, cursor);
  return blocks.map((block) => renderBlock(block, options)).join('\n');
}

/**
 * Render the inline (span level) part of a Markdown string.
 *
 * @param text The inline source.
 * @param options Rendering options.
 * @returns An HTML fragment.
 */
export function renderInline(text: string, options: MarkdownOptions = {}): string {
  const stashed: string[] = [];
  const stash = (html: string): string => {
    stashed.push(html);
    return `${PLACEHOLDER_START}${stashed.length - 1}${PLACEHOLDER_END}`;
  };

  let out = escapeHtml(text);
  out = extractCodeSpans(out, stash);
  out = extractLinks(out, stash, options);
  out = applyEmphasis(out);
  return out.replace(
    new RegExp(`${PLACEHOLDER_START}(\\d+)${PLACEHOLDER_END}`, 'g'),
    (_match, index: string) => stashed[Number(index)] ?? '',
  );
}

/* ------------------------------------------------------------------ */
/* Inline parsing                                                      */
/* ------------------------------------------------------------------ */

/**
 * @param text Escaped text.
 * @param stash Callback used to park already-rendered HTML.
 * @returns The text with code spans replaced by placeholders.
 */
function extractCodeSpans(text: string, stash: (html: string) => string): string {
  let out = '';
  let index = 0;
  while (index < text.length) {
    const char = text[index] ?? '';
    if (char !== '`') {
      out += char;
      index += 1;
      continue;
    }
    let runEnd = index;
    while (text[runEnd] === '`') runEnd += 1;
    const runLength = runEnd - index;
    const closing = text.indexOf('`'.repeat(runLength), runEnd);
    if (closing === -1) {
      out += text.slice(index, runEnd);
      index = runEnd;
      continue;
    }
    let code = text.slice(runEnd, closing);
    if (code.length > 1 && code.startsWith(' ') && code.endsWith(' ') && code.trim() !== '') {
      code = code.slice(1, -1);
    }
    out += stash(`<code>${code}</code>`);
    index = closing + runLength;
  }
  return out;
}

/**
 * @param text Escaped text.
 * @param stash Callback used to park already-rendered HTML.
 * @param options Rendering options.
 * @returns The text with links replaced by placeholders.
 */
function extractLinks(text: string, stash: (html: string) => string, options: MarkdownOptions): string {
  let out = '';
  let index = 0;
  while (index < text.length) {
    const char = text[index] ?? '';
    if (char !== '[') {
      out += char;
      index += 1;
      continue;
    }
    const labelEnd = findClosing(text, index, '[', ']');
    if (labelEnd === -1) {
      out += char;
      index += 1;
      continue;
    }
    const afterLabel = text[labelEnd + 1] ?? '';
    if (afterLabel !== '(') {
      out += text.slice(index, labelEnd + 1);
      index = labelEnd + 1;
      continue;
    }
    const targetEnd = findClosing(text, labelEnd + 1, '(', ')');
    if (targetEnd === -1) {
      out += text.slice(index, labelEnd + 1);
      index = labelEnd + 1;
      continue;
    }
    const label = text.slice(index + 1, labelEnd);
    const destination = text.slice(labelEnd + 2, targetEnd).trim();
    const href = destination.startsWith('<') && destination.endsWith('>')
      ? destination.slice(1, -1)
      : destination.split(/\s+/)[0] ?? '';

    const resolved = options.linkResolver ? options.linkResolver(href) : safeHref(href);
    if (resolved === null) {
      out += stash(`<span class="md-link-unresolved">${renderInline(label, options)}</span>`);
    } else if (resolved.startsWith('#')) {
      out += stash(`<a href="${resolved}">${renderInline(label, options)}</a>`);
    } else {
      const external = safeHref(resolved) !== null && /^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(resolved);
      const attrs = external ? ' target="_blank" rel="noopener noreferrer"' : '';
      out += stash(`<a href="${resolved}"${attrs}>${renderInline(label, options)}</a>`);
    }
    index = targetEnd + 1;
  }
  return out;
}

/**
 * Find the index of the bracket that closes the one at `start`.
 *
 * @param text Text to scan.
 * @param start Index of the opening bracket.
 * @param open Opening bracket character.
 * @param close Closing bracket character.
 * @returns The index of the closing bracket, or -1.
 */
function findClosing(text: string, start: number, open: string, close: string): number {
  let depth = 0;
  for (let index = start; index < text.length; index += 1) {
    const char = text[index];
    if (char === open) depth += 1;
    else if (char === close) {
      depth -= 1;
      if (depth === 0) return index;
    }
  }
  return -1;
}

/**
 * Apply emphasis rules to text that has no code spans or links left.
 *
 * @param text Escaped text.
 * @returns The text with emphasis markup applied.
 */
function applyEmphasis(text: string): string {
  return text
    .replace(/\*\*\*([^*]+)\*\*\*/g, '<strong><em>$1</em></strong>')
    .replace(/\*\*([^*\n]+)\*\*/g, '<strong>$1</strong>')
    .replace(/__([^_\n]+)__/g, '<strong>$1</strong>')
    .replace(/\*([^*\n]+)\*/g, '<em>$1</em>')
    .replace(/(^|[^\w])_([^_\n]+)_(?![\w])/g, '$1<em>$2</em>')
    .replace(/~~([^~\n]+)~~/g, '<del>$1</del>');
}

/* ------------------------------------------------------------------ */
/* Block parsing                                                       */
/* ------------------------------------------------------------------ */

/**
 * @param lines Source lines.
 * @param cursor Shared read cursor.
 * @returns The parsed blocks.
 */
function parseBlocks(lines: string[], cursor: { i: number }): Block[] {
  /** @type {Block[]} */
  const blocks: Block[] = [];
  while (cursor.i < lines.length) {
    const line = lines[cursor.i] ?? '';
    if (line.trim() === '') {
      cursor.i += 1;
      continue;
    }

    const fence = FENCE.exec(line);
    if (fence) {
      blocks.push(parseFencedCode(lines, cursor, fence[2] ?? '', fence[3] ?? ''));
      continue;
    }

    const heading = HEADING.exec(line);
    if (heading) {
      cursor.i += 1;
      blocks.push({ kind: 'heading', level: (heading[1] ?? '#').length, text: heading[2] ?? '' });
      continue;
    }

    if (RULE.test(line)) {
      cursor.i += 1;
      blocks.push({ kind: 'rule' });
      continue;
    }

    if (QUOTE.test(line)) {
      blocks.push(parseQuote(lines, cursor));
      continue;
    }

    if (line.includes('|') && isTableDelimiter(lines[cursor.i + 1] ?? '')) {
      blocks.push(parseTable(lines, cursor));
      continue;
    }

    if (LIST_ITEM.test(line)) {
      blocks.push(parseList(lines, cursor));
      continue;
    }

    blocks.push(parseParagraph(lines, cursor));
  }
  return blocks;
}

/**
 * @param lines Source lines.
 * @param cursor Shared read cursor.
 * @param marker Fence marker.
 * @param language Info string.
 * @returns A code block.
 */
function parseFencedCode(lines: string[], cursor: { i: number }, marker: string, language: string): CodeBlock {
  cursor.i += 1;
  const closing = new RegExp(`^ {0,3}${marker[0] === '`' ? '`' : '~'}{${marker.length},}[ \\t]*$`);
  /** @type {string[]} */
  const content: string[] = [];
  while (cursor.i < lines.length) {
    const current = lines[cursor.i] ?? '';
    if (closing.test(current)) {
      cursor.i += 1;
      break;
    }
    content.push(current);
    cursor.i += 1;
  }
  return { kind: 'code', language, content: content.join('\n') };
}

/**
 * @param lines Source lines.
 * @param cursor Shared read cursor.
 * @returns A blockquote block.
 */
function parseQuote(lines: string[], cursor: { i: number }): QuoteBlock {
  /** @type {string[]} */
  const inner: string[] = [];
  while (cursor.i < lines.length) {
    const line = lines[cursor.i] ?? '';
    if (!QUOTE.test(line)) break;
    inner.push(line.replace(QUOTE, ''));
    cursor.i += 1;
  }
  const innerCursor = { i: 0 };
  return { kind: 'quote', children: parseBlocks(inner, innerCursor) };
}

/**
 * @param lines Source lines.
 * @param cursor Shared read cursor.
 * @returns A paragraph block.
 */
function parseParagraph(lines: string[], cursor: { i: number }): ParagraphBlock {
  /** @type {string[]} */
  const parts: string[] = [];
  while (cursor.i < lines.length) {
    const line = lines[cursor.i] ?? '';
    if (line.trim() === '') break;
    if (parts.length > 0 && startsNewBlock(line, lines[cursor.i + 1] ?? '')) break;
    parts.push(line.trim());
    cursor.i += 1;
  }
  return { kind: 'paragraph', text: parts.join('\n') };
}

/**
 * Whether a line interrupts an open paragraph.
 *
 * @param line Current line.
 * @param next Following line.
 * @returns True when the line starts a different block.
 */
function startsNewBlock(line: string, next: string): boolean {
  if (HEADING.test(line)) return true;
  if (RULE.test(line)) return true;
  if (FENCE.test(line)) return true;
  if (QUOTE.test(line)) return true;
  if (LIST_ITEM.test(line)) return true;
  if (line.includes('|') && isTableDelimiter(next)) return true;
  return false;
}

/**
 * @param line Candidate delimiter row.
 * @returns True when the line is a table delimiter row.
 */
function isTableDelimiter(line: string): boolean {
  return line.trim() !== '' && line.includes('-') && TABLE_DELIMITER.test(line);
}

/**
 * @param lines Source lines.
 * @param cursor Shared read cursor.
 * @returns A table block.
 */
function parseTable(lines: string[], cursor: { i: number }): TableBlock {
  const header = splitRow(lines[cursor.i] ?? '');
  cursor.i += 1;
  const delimiter = splitRow(lines[cursor.i] ?? '');
  cursor.i += 1;
  const align = delimiter.map((cell) => {
    const left = cell.startsWith(':');
    const right = cell.endsWith(':');
    if (left && right) return 'center';
    if (right) return 'right';
    if (left) return 'left';
    return null;
  });
  /** @type {string[][]} */
  const rows: string[][] = [];
  while (cursor.i < lines.length) {
    const line = lines[cursor.i] ?? '';
    if (line.trim() === '' || !line.includes('|')) break;
    rows.push(splitRow(line));
    cursor.i += 1;
  }
  return { kind: 'table', header, align, rows };
}

/**
 * Split a table row into cells, ignoring pipes inside code spans and escaped
 * pipes.
 *
 * @param line Raw row.
 * @returns The cell texts.
 */
function splitRow(line: string): string[] {
  let text = line.trim();
  if (text.startsWith('|')) text = text.slice(1);
  if (text.endsWith('|') && !text.endsWith('\\|')) text = text.slice(0, -1);
  /** @type {string[]} */
  const cells: string[] = [];
  let current = '';
  let inCode = false;
  for (let index = 0; index < text.length; index += 1) {
    const char = text[index] ?? '';
    if (char === '\\' && text[index + 1] === '|') {
      current += '|';
      index += 1;
      continue;
    }
    if (char === '`') inCode = !inCode;
    if (char === '|' && !inCode) {
      cells.push(current.trim());
      current = '';
      continue;
    }
    current += char;
  }
  cells.push(current.trim());
  return cells;
}

/**
 * @param lines Source lines.
 * @param cursor Shared read cursor.
 * @returns A list block.
 */
function parseList(lines: string[], cursor: { i: number }): ListBlock {
  const firstMatch = LIST_ITEM.exec(lines[cursor.i] ?? '');
  const listIndent = (firstMatch?.[1] ?? '').length;
  const ordered = /\d/.test(firstMatch?.[2] ?? '');
  const start = ordered ? Number.parseInt(firstMatch?.[2] ?? '1', 10) : 1;
  const markerChar = (firstMatch?.[2] ?? '-').replace(/[0-9.]/g, '');

  /** @type {ListItem[]} */
  const items: ListItem[] = [];
  let tight = true;

  while (cursor.i < lines.length) {
    const line = lines[cursor.i] ?? '';
    if (line.trim() === '') {
      const look = skipBlank(lines, cursor.i);
      const after = look < lines.length ? (lines[look] ?? '') : null;
      if (after !== null && LIST_ITEM.test(after) && indentWidth(after) === listIndent) {
        tight = false;
        cursor.i = look;
        continue;
      }
      break;
    }

    const match = LIST_ITEM.exec(line);
    if (!match) break;
    const marker = match[2] ?? '';
    if ((/\d/.test(marker)) !== ordered) break;
    if (marker.replace(/[0-9.]/g, '') !== markerChar) break;
    const indent = indentWidth(line);
    if (indent !== listIndent) break;

    const content = match[3] ?? '';
    const afterMarker = line.slice(indent + marker.length);
    const contentColumn = indent + marker.length + (afterMarker.length - afterMarker.trimStart().length);

    /** @type {string[]} */
    const itemLines: string[] = [content];
    cursor.i += 1;

    while (cursor.i < lines.length) {
      const next = lines[cursor.i] ?? '';
      if (next.trim() === '') {
        const look = skipBlank(lines, cursor.i);
        const after = look < lines.length ? (lines[look] ?? '') : null;
        if (after !== null && indentWidth(after) > indent) {
          for (let index = cursor.i; index < look; index += 1) itemLines.push('');
          cursor.i = look;
          tight = false;
          continue;
        }
        break;
      }
      const nextIndent = indentWidth(next);
      if (nextIndent > indent) {
        itemLines.push(next.slice(Math.min(nextIndent, contentColumn)));
        cursor.i += 1;
        continue;
      }
      if (nextIndent === indent && LIST_ITEM.test(next)) break;
      itemLines.push(next.trim());
      cursor.i += 1;
    }

    const itemCursor = { i: 0 };
    items.push({ children: parseBlocks(itemLines, itemCursor) });
  }

  return { kind: 'list', ordered, start, tight, items };
}

/**
 * @param lines Source lines.
 * @param from Index to start looking from.
 * @returns The index of the next non-blank line.
 */
function skipBlank(lines: string[], from: number): number {
  let index = from;
  while (index < lines.length && (lines[index] ?? '').trim() === '') index += 1;
  return index;
}

/**
 * @param line Source line.
 * @returns The number of leading spaces.
 */
function indentWidth(line: string): number {
  return line.length - line.trimStart().length;
}

/* ------------------------------------------------------------------ */
/* Block rendering                                                     */
/* ------------------------------------------------------------------ */

/**
 * @param block Block to render.
 * @param options Rendering options.
 * @returns An HTML fragment.
 */
function renderBlock(block: Block, options: MarkdownOptions): string {
  switch (block.kind) {
    case 'heading': {
      const level = Math.min(Math.max(block.level, 1), 6);
      const id = slugify(block.text);
      return `<h${level} id="${id}">${renderInline(block.text, options)}</h${level}>`;
    }
    case 'paragraph':
      return `<p>${renderInline(block.text, options)}</p>`;
    case 'code': {
      const language = block.language.replace(/[^A-Za-z0-9_+-]/g, '');
      const className = language ? ` class="language-${language}"` : '';
      return `<pre><code${className}>${escapeHtml(block.content)}</code></pre>`;
    }
    case 'quote':
      return `<blockquote>${block.children.map((child) => renderBlock(child, options)).join('\n')}</blockquote>`;
    case 'rule':
      return '<hr />';
    case 'list': {
      const tag = block.ordered ? 'ol' : 'ul';
      const startAttr = block.ordered && block.start !== 1 ? ` start="${block.start}"` : '';
      const items = block.items.map((item) => renderListItem(item, block.tight, options)).join('\n');
      return `<${tag}${startAttr}>\n${items}\n</${tag}>`;
    }
    case 'table': {
      const head = block.header
        .map((cell, index) => `<th${alignAttr(block.align[index])}>${renderInline(cell, options)}</th>`)
        .join('');
      const body = block.rows
        .map((row) => {
          const cells = block.header
            .map((_, index) => `<td${alignAttr(block.align[index])}>${renderInline(row[index] ?? '', options)}</td>`)
            .join('');
          return `<tr>${cells}</tr>`;
        })
        .join('\n');
      return `<div class="table-scroll"><table><thead><tr>${head}</tr></thead><tbody>\n${body}\n</tbody></table></div>`;
    }
    default:
      return '';
  }
}

/**
 * @param align Alignment for a cell.
 * @returns The `style` attribute, or an empty string.
 */
function alignAttr(align: Align | undefined): string {
  return align ? ` style="text-align:${align}"` : '';
}

/**
 * @param item List item.
 * @param tight Whether the list is tight.
 * @param options Rendering options.
 * @returns An HTML fragment.
 */
function renderListItem(item: ListItem, tight: boolean, options: MarkdownOptions): string {
  const parts = item.children.map((child, index) => {
    if (child.kind === 'paragraph' && tight && index === 0) {
      return `<p class="md-tight">${renderInline(child.text, options)}</p>`;
    }
    return renderBlock(child, options);
  });
  return `<li>${parts.join('\n')}</li>`;
}
