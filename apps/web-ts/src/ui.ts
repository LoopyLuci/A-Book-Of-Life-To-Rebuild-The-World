/**
 * Tiny DOM helpers.
 *
 * The app builds its interface with real DOM nodes rather than HTML strings.
 * The single exception is the Markdown body, which is rendered by the
 * sanitising renderer in `markdown.ts` and is therefore safe to insert.
 *
 * @module ui
 */

/** Options accepted by {@link createElement}. */
export interface ElementOptions {
  /** Class names to add to the element. */
  className?: string;
  /** Text content of the element. */
  text?: string;
  /**
   * Pre-rendered HTML. Only ever pass markup produced by the Markdown
   * renderer, which escapes every piece of source text.
   */
  html?: string;
  /** Attributes to set. `false`, `null` and `undefined` are skipped. */
  attrs?: Record<string, string | number | boolean | null | undefined>;
  /** Data attributes to set. */
  data?: Record<string, string | number | undefined>;
}

/**
 * Create an element.
 *
 * @param tag The tag name.
 * @param options Element options.
 * @param children Child nodes or strings.
 * @returns The new element.
 */
export function createElement<K extends keyof HTMLElementTagNameMap>(
  tag: K,
  options: ElementOptions = {},
  children: Array<Node | string | null | undefined> = [],
): HTMLElementTagNameMap[K] {
  const node = document.createElement(tag);
  if (options.className !== undefined) node.className = options.className;
  if (options.text !== undefined) node.textContent = options.text;
  if (options.html !== undefined) node.innerHTML = options.html;
  if (options.attrs) {
    for (const [name, value] of Object.entries(options.attrs)) {
      if (value === null || value === undefined || value === false) continue;
      node.setAttribute(name, value === true ? '' : String(value));
    }
  }
  if (options.data) {
    for (const [name, value] of Object.entries(options.data)) {
      if (value === undefined) continue;
      node.dataset[name] = String(value);
    }
  }
  for (const child of children) {
    if (child === null || child === undefined) continue;
    node.appendChild(typeof child === 'string' ? document.createTextNode(child) : child);
  }
  return node;
}

/**
 * Remove every child of a node.
 *
 * @param node The node to empty.
 */
export function clear(node: Node): void {
  while (node.firstChild) node.removeChild(node.firstChild);
}

/**
 * Replace the children of a node.
 *
 * @param node The node to fill.
 * @param children New children.
 */
export function replaceChildren(node: Element, children: Array<Node | string | null | undefined>): void {
  clear(node);
  for (const child of children) {
    if (child === null || child === undefined) continue;
    node.appendChild(typeof child === 'string' ? document.createTextNode(child) : child);
  }
}

/**
 * Query an element, throwing when it is missing. Use for elements the app
 * cannot work without.
 *
 * @param selector A CSS selector.
 * @returns The first matching element.
 */
export function requireElement<T extends Element = HTMLElement>(selector: string): T {
  const element = document.querySelector<T>(selector);
  if (!element) throw new Error(`Missing required element: ${selector}`);
  return element;
}

/**
 * Build a text node containing highlighted ranges.
 *
 * @param text The text.
 * @param marks Ranges to highlight, in order and non-overlapping.
 * @returns A document fragment.
 */
export function highlightedText(text: string, marks: Array<{ start: number; end: number }>): DocumentFragment {
  const fragment = document.createDocumentFragment();
  let cursor = 0;
  for (const mark of marks) {
    if (mark.start > cursor) fragment.appendChild(document.createTextNode(text.slice(cursor, mark.start)));
    const strong = document.createElement('mark');
    strong.textContent = text.slice(mark.start, mark.end);
    fragment.appendChild(strong);
    cursor = mark.end;
  }
  if (cursor < text.length) fragment.appendChild(document.createTextNode(text.slice(cursor)));
  return fragment;
}
