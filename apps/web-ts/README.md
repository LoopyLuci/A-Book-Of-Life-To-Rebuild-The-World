# abook-web — static web app for *A Book Of Life To Rebuild The World*

A dependency-free, offline-first web application for the knowledge base in this
repository. It renders the corpus of Markdown entries with its own Markdown
parser, searches it in the browser, and never talks to the network at runtime.

The whole application is a static bundle: open `dist/index.html` from the
filesystem or serve `dist/` from any web server. There is no backend, no
database and no build-time service dependency.

---

## Quick start

```bash
cd apps/web-ts
npm install          # dev dependencies only: typescript + @types/node
npm run build        # exports the corpus and writes dist/
npm test             # unit tests (node:test)
npm run typecheck    # tsc --noEmit, strict mode
npm run lint         # project-specific lint rules
npm run verify       # asserts the shape of the built dist/content.json
```

Then open `dist/index.html` in a browser, or serve the folder:

```bash
npm run dev          # builds, serves dist/ on http://localhost:5173, rebuilds on change
```

> **Requires Node 18.17 or newer.** The app has **zero runtime dependencies** —
> `typescript` and `@types/node` are compile-time only, and the unit tests run
> on Node's built-in `node:test` runner.

---

## What it does

| Feature | Where |
|---|---|
| Sidebar with the 16 domains and their entry counts | `src/app.ts` → `renderSidebar()` |
| Instant search, ranked *title > tags > body*, capped at 50 results | `src/search.ts` |
| Highlighted match snippets | `src/search.ts` → `buildSnippet()`, `src/ui.ts` → `highlightedText()` |
| Entry view: metadata, rendered Markdown, tags, verification badge, sources, related entries | `src/app.ts` → `renderEntry()` |
| Filters for domain, difficulty and safety | `src/app.ts` → `renderSidebar()` |
| Language selector for en, es, fr, de, pt, hi, ar, sw, zh | `src/i18n.ts`, `src/ui-strings.ts` |
| Light / dark theme, following the system by default | `src/store.ts` → `resolveTheme()` |
| Recently read list | `src/store.ts` → `pushRecent()` |
| Markdown renderer that escapes before rendering | `src/markdown.ts` |
| About dialog with the version and the verbatim disclaimer | `src/app.ts` → `openAbout()` |
| Keyboard shortcuts | `src/app.ts` → `bindEvents()` |

### Keyboard shortcuts

| Keys | Action |
|---|---|
| `/` or `Ctrl`/`Cmd` + `F` | Focus the search box |
| `Ctrl`/`Cmd` + `K` | Open the quick-jump palette |
| `?` | Open the keyboard shortcut help |
| `Esc` | Close the open dialog, or clear the search box |
| `↑` / `↓` | Move the selection in the quick-jump palette |
| `Enter` | Open the selected entry |

### Accessibility

* Semantic landmarks: `header`, `nav`, `main`, `footer`, `article`, `section`.
* A skip link, visible focus rings (`:focus-visible`), and full keyboard
  operability — every control is a real `button`, `a`, `input` or `select`.
* `aria-pressed` on the domain filter buttons, `aria-live` status region for
  the result count, `aria-label`/`aria-labelledby` on the dialogs, and
  `role="status"` for announcements.
* The layout uses CSS logical properties, so the right-to-left languages
  (`ar`) mirror correctly; `dir` is set from the active language.

---

## Architecture

```
apps/web-ts/
├── index.html            page template (copied to dist/index.html)
├── package.json
├── tsconfig.json         base + typecheck (strict)
├── tsconfig.build.json   src/      -> dist/      (ES2020 modules)
├── tsconfig.cjs.json     src/      -> .build/cjs (CommonJS, for the file:// bundle)
├── tsconfig.test.json    src+test  -> .build/test
├── public/content.json   generated payload (gitignored)
├── scripts/
│   ├── build.mjs         the build: tsc, bundle, copy, export
│   ├── dev.mjs           dev server with rebuild-on-change
│   ├── export-content.mjs corpus -> public/content.json
│   ├── lint.mjs          project-specific lint rules
│   ├── test.mjs          compile the tests, then run node --test
│   ├── clean.mjs
│   └── lib/
│       ├── yaml.mjs      minimal YAML reader for the corpus subset
│       ├── toml.mjs      minimal TOML reader for manifest.toml
│       ├── domains.mjs   domain catalogue (order, accent colours)
│       └── types.d.ts    shared types for the tooling
├── src/
│   ├── main.ts           entry point
│   ├── app.ts            the application: state, routing, rendering
│   ├── markdown.ts       the Markdown renderer
│   ├── search.ts         ranking, snippets, highlighting
│   ├── i18n.ts           string resolution and fallbacks
│   ├── ui-strings.ts     app chrome strings in the nine languages
│   ├── store.ts          localStorage: theme, language, recently read
│   ├── content.ts        payload loading (fetch with an embedded fallback)
│   ├── ui.ts             DOM helpers
│   ├── types.ts          shared types
│   └── styles.css        the stylesheet
└── test/                 node:test unit tests
```

### The data pipeline

`scripts/export-content.mjs` reads the corpus and writes a single payload:

* `domains/<domain>/<slug>.md` — the Markdown body (verbatim).
* `sidecars/<domain>/<slug>.pnk.yaml` — the metadata: id, title, domain,
  tags, difficulty, safety, time to complete, sources, verification, links,
  prerequisites, materials, tools, hazards, limits, resource budget.
* `i18n/strings/<lang>.yaml` — the UI strings of all nine languages.
* `manifest.toml` — the version, the schema version and the canonical domain
  order.
* `domains/README.md` and `domains/<domain>/README.md` — the domain titles
  and descriptions.
* `docs/DISCLAIMER.md` — quoted verbatim into the payload.

The script is offline, deterministic apart from the `generatedAt` stamp, and
safe to re-run. The payload contains 207 entries across 16 domains.

The YAML and TOML readers are hand-written and cover exactly the subset the
corpus uses; anything outside that subset raises an error instead of silently
producing a wrong value. The YAML reader was validated against PyYAML over all
216 corpus YAML files.

---

## How the build produces a `file://`-capable app

Browsers refuse two things that a static app normally relies on:

1. **Module scripts on `file://` origins.** `<script type="module">` is
   blocked by the file-origin CORS rules, so `dist/main.js` (the real ES2020
   module build) cannot be loaded from the filesystem.
2. **`fetch()` of a neighbouring file on `file://` origins.** `fetch` of
   `content.json` fails with a network error.

The build solves both without a third-party bundler:

* `dist/app.bundle.js` is the same sources compiled to CommonJS and stitched
  into one classic script by a ~30 line loader in `scripts/build.mjs`. The
  page loads it when `location.protocol === 'file:'`.
* `dist/content.embedded.js` holds the payload as a classic script that
  assigns `window.__ABOOK_CONTENT__`. The loader in `src/content.ts` tries
  `fetch('./content.json')` first and falls back to the embedded copy.

`dist/index.html` picks the right script at runtime, so the same folder works
over HTTP (ES modules, `fetch`) and from the filesystem (classic script,
embedded payload).

```
dist/
├── index.html
├── main.js  app.js  content.js  i18n.js  markdown.js  search.js
├── store.js  types.js  ui.js  ui-strings.js        ← ES2020 modules
├── app.bundle.js                                       ← classic bundle for file://
├── content.json                                        ← the payload
├── content.embedded.js                                 ← the payload, inlined
├── styles.css
└── *.map                                                ← source maps
```

---

## Security notes

* **The Markdown renderer escapes before it renders.** Every piece of source
  text is HTML-escaped before any markup is produced, so an entry can never
  inject markup into the page. Only the tags the renderer itself emits appear
  in the output. Code spans, code blocks, table cells and link targets are
  escaped too.
* **Link targets are filtered.** Only `http:`, `https:`, `mailto:` and
  relative targets are linkified; `javascript:`, `data:` and protocol-relative
  URLs are rendered as plain text.
* **No network access at runtime.** `npm run lint` fails the build if any code
  outside `src/content.ts` reaches for `fetch`, `XMLHttpRequest`, `WebSocket`,
  `EventSource` or `sendBeacon`, and if `eval`, `new Function` or
  `document.write` appear anywhere.
* **`innerHTML` has exactly one home**, `src/ui.ts`, and it is only ever fed
  markup produced by the sanitising renderer.

---

## Testing

```bash
npm test
```

`node:test` unit tests cover the Markdown renderer (escaping, headings, lists,
tables, links, code), the search ranking and snippet highlighting, the
language fallback, the YAML and TOML readers, the route parsing and the
content loader's fallback behaviour.

The application has also been verified end to end in headless Chromium, over
`http://` and over `file://`: 207 cards rendered, search filtering and
highlighting, domain/difficulty/safety filtering, entry rendering, related
entries, sources, the language switch (including right-to-left), the theme
toggle, the About and shortcut dialogs, the quick-jump palette and the
keyboard shortcuts.

---

## Licence

Application code: MIT. Content: CC BY-SA 4.0, as quoted in the About dialog.
