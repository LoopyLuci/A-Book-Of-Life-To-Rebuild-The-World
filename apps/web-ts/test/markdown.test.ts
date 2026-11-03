import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { escapeHtml, renderInline, renderMarkdown, safeHref, slugify } from '../src/markdown.js';

describe('markdown escaping', () => {
  it('escapes the characters that can change the meaning of HTML', () => {
    assert.equal(escapeHtml('<b>'), '&lt;b&gt;');
    assert.equal(escapeHtml('a & b'), 'a &amp; b');
    assert.equal(escapeHtml('"quoted"'), '&quot;quoted&quot;');
    assert.equal(escapeHtml("it's"), 'it&#39;s');
  });

  it('never emits raw markup from the source text', () => {
    const html = renderMarkdown('# <script>alert("xss")</script>\n\nText <img src=x onerror=alert(1)>.');
    assert.ok(!html.includes('<script>'), 'script tag must not survive');
    assert.ok(!html.includes('<img'), 'no element may be created from the source text');
    assert.ok(html.includes('&lt;script&gt;'), 'the text must be escaped instead');
    assert.ok(html.includes('&lt;img src=x onerror=alert(1)&gt;'), 'the whole tag must be escaped as text');
  });

  it('escapes markup inside code blocks and inline code', () => {
    const html = renderMarkdown('```\n<b>not bold</b>\n```\n\nUse `<b>` carefully.');
    assert.ok(html.includes('&lt;b&gt;not bold&lt;/b&gt;'));
    assert.ok(html.includes('<code>&lt;b&gt;</code>'));
    assert.ok(!html.includes('<b>'));
  });

  it('escapes markup inside table cells', () => {
    const html = renderMarkdown('| a | b |\n|---|---|\n| <script>x</script> | y |');
    assert.ok(!html.includes('<script>'));
    assert.ok(html.includes('&lt;script&gt;'));
  });
});

describe('markdown headings', () => {
  it('renders every heading level', () => {
    const source = '# One\n\n## Two\n\n### Three\n\n#### Four\n\n##### Five\n\n###### Six';
    const html = renderMarkdown(source);
    for (const level of [1, 2, 3, 4, 5, 6]) {
      assert.ok(html.includes(`<h${level}`), `expected an h${level}`);
    }
  });

  it('gives headings a stable anchor id', () => {
    const html = renderMarkdown('## Safety Notes');
    assert.ok(html.includes('<h2 id="safety-notes">Safety Notes</h2>'));
    assert.equal(slugify('Safety Notes'), 'safety-notes');
  });

  it('does not treat a hash without a space as a heading', () => {
    const html = renderMarkdown('#NotAHeading');
    assert.ok(!html.includes('<h1'));
  });

  it('renders emphasis', () => {
    const html = renderMarkdown('**bold** and *italic* and ***both*** and `code`');
    assert.ok(html.includes('<strong>bold</strong>'));
    assert.ok(html.includes('<em>italic</em>'));
    assert.ok(html.includes('<strong><em>both</em></strong>'));
    assert.ok(html.includes('<code>code</code>'));
  });

  it('renders paragraphs and horizontal rules', () => {
    const html = renderMarkdown('First paragraph.\n\nSecond paragraph.\n\n---\n\nAfter the rule.');
    assert.ok(html.includes('<p>First paragraph.</p>'));
    assert.ok(html.includes('<p>Second paragraph.</p>'));
    assert.ok(html.includes('<hr />'));
  });
});

describe('markdown lists', () => {
  it('renders unordered lists', () => {
    const html = renderMarkdown('- Clean cloth\n- Boiled water\n- Improvised splints');
    assert.ok(html.includes('<ul>'));
    assert.equal(html.match(/<li>/g)?.length, 3);
    assert.ok(html.includes('Clean cloth'));
  });

  it('renders ordered lists', () => {
    const html = renderMarkdown('1. Airway\n2. Breathing\n3. Circulation');
    assert.ok(html.includes('<ol>'));
    assert.equal(html.match(/<li>/g)?.length, 3);
    assert.ok(html.includes('Circulation'));
  });

  it('renders nested lists', () => {
    const html = renderMarkdown('- Outer item\n  - Inner item\n  - Another inner\n- Second outer');
    assert.equal(html.match(/<ul>/g)?.length, 2);
    assert.equal(html.match(/<li>/g)?.length, 4);
    assert.ok(html.includes('Inner item'));
  });

  it('keeps the continuation of a list item', () => {
    const html = renderMarkdown('1. 30 chest compressions at 100–120/min.\n2. 2 rescue breaths.');
    assert.ok(html.includes('30 chest compressions'));
    assert.ok(html.includes('2 rescue breaths'));
  });
});

describe('markdown tables', () => {
  it('renders a table with a header and rows', () => {
    const html = renderMarkdown([
      '| Level | Meaning |',
      '|-------|---------|',
      '| `green` | Ordinary care. |',
      '| `red` | Serious risk. |',
    ].join('\n'));
    assert.ok(html.includes('<table>'));
    assert.ok(html.includes('<thead>'));
    assert.ok(html.includes('<th>Level</th>'));
    assert.ok(html.includes('<tbody>'));
    assert.equal(html.match(/<tr>/g)?.length, 3);
    assert.ok(html.includes('<code>green</code>'));
  });

  it('honours the alignment row', () => {
    const html = renderMarkdown('| a | b | c |\n|:--|:-:|--:|\n| 1 | 2 | 3 |');
    assert.ok(html.includes('style="text-align:left"'));
    assert.ok(html.includes('style="text-align:center"'));
    assert.ok(html.includes('style="text-align:right"'));
  });

  it('pads short rows', () => {
    const html = renderMarkdown('| a | b |\n|---|---|\n| 1 |');
    assert.equal(html.match(/<td/g)?.length, 2);
  });
});

describe('markdown quotes and code', () => {
  it('renders blockquotes', () => {
    const html = renderMarkdown('> **Domain:** survival | **Difficulty:** novice');
    assert.ok(html.includes('<blockquote>'));
    assert.ok(html.includes('<strong>Domain:</strong>'));
  });

  it('renders fenced code with a language', () => {
    const html = renderMarkdown('```python\nprint("hi")\n```');
    assert.ok(html.includes('<pre><code class="language-python">'));
    assert.ok(html.includes('print(&quot;hi&quot;)'));
  });

  it('renders fenced code without a language', () => {
    const html = renderMarkdown('```\nplain\n```');
    assert.ok(html.includes('<pre><code>plain</code></pre>'));
  });
});

describe('markdown links', () => {
  it('links to external pages', () => {
    const html = renderMarkdown('See [the manual](https://example.com/manual).');
    assert.ok(html.includes('<a href="https://example.com/manual"'));
    assert.ok(html.includes('rel="noopener noreferrer"'));
  });

  it('refuses dangerous schemes', () => {
    const html = renderMarkdown('[click](javascript:alert(1))');
    assert.ok(!html.includes('javascript:'), 'the javascript scheme must not be linked');
    assert.ok(html.includes('md-link-unresolved'));
  });

  it('refuses data URLs', () => {
    assert.equal(safeHref('data:text/html;base64,PHNjcmlwdD4='), null);
    assert.equal(safeHref('https://example.com'), 'https://example.com');
    assert.equal(safeHref('mailto:someone@example.com'), 'mailto:someone@example.com');
    assert.equal(safeHref('#anchor'), '#anchor');
    assert.equal(safeHref(''), null);
  });

  it('uses the link resolver when one is supplied', () => {
    const html = renderMarkdown('[Making Fire](../survival/making-fire.md)', {
      linkResolver: (href) => (href.endsWith('making-fire.md') ? '#/entry/survival/making-fire' : null),
    });
    assert.ok(html.includes('href="#/entry/survival/making-fire"'));
  });

  it('renders unresolvable links as plain text', () => {
    const html = renderMarkdown('[Gone](nowhere.md)', { linkResolver: () => null });
    assert.ok(!html.includes('<a '));
    assert.ok(html.includes('Gone'));
  });
});

describe('inline rendering', () => {
  it('escapes before applying inline rules', () => {
    assert.equal(renderInline('a < b & c'), 'a &lt; b &amp; c');
  });

  it('does not emphasise across word boundaries with underscores', () => {
    assert.equal(renderInline('snake_case_name'), 'snake_case_name');
  });
});
