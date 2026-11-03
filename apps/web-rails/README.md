# A Book Of Life To Rebuild The World — web reader

A server-rendered Ruby on Rails application that reads the knowledge base of
*A Book Of Life To Rebuild The World* and serves it as a browsable, searchable
web site.

The application is **completely offline**. It calls no external API at
runtime, it needs **no database**, and it ships **no JavaScript**. Every page
is rendered on the server and every feature — the language switcher, the
light and dark themes, the recently read list — works with plain HTML, CSS
and cookies.

---

## What it reads

The knowledge base lives in the repository, two directories above this one:

| Path | What |
|---|---|
| `sidecars/<domain>/<slug>.pnk.yaml` | the metadata of an entry: id, title, domain, tags, difficulty, safety, time to complete, prerequisites, materials, tools, sources, verification status and links |
| `domains/<domain>/<slug>.md` | the Markdown body of an entry |
| `i18n/strings/<lang>.yaml` | the interface strings; `en.yaml` is the canonical catalogue |
| `manifest.toml` | the version, the domain list, the safety and difficulty levels |
| `docs/DISCLAIMER.md` | the disclaimer, quoted verbatim on the about page |

The repository root is found by walking up from `Rails.root` until
`manifest.toml` turns up, so the application works from any checkout layout.
Set `ABOOK_ROOT` to point it at a different checkout.

## Requirements

* Ruby 3.2 or newer (developed and verified on Ruby 4.0.5)
* Bundler

## Setup

```bash
cd apps/web-rails
bundle install
```

There is **no database to prepare**. `rails db:prepare` is not needed and
there is no `config/database.yml`; see [`db/README.md`](db/README.md) for the
reason and for what to do if a database is ever added.

## Run

```bash
bin/rails server          # http://localhost:3000
```

On Windows, where PowerShell will not execute an extension-less script
directly:

```bash
ruby bin/rails server
```

For a production-style run:

```bash
SECRET_KEY_BASE=<64 random hex characters> RAILS_ENV=production bin/rails server
```

## Verify

```bash
bin/rails routes           # the routes of the application
bin/rails test             # the test suite
ruby -c <file>             # a syntax check of one Ruby file
```

On Windows use `ruby bin/rails routes` and `ruby bin/rails test`.

---

## The pages

| Route | What it shows |
|---|---|
| `GET /` | the sixteen domains with their entry counts, and the recently read entries |
| `GET /domains` | the same list of domains, as an index |
| `GET /domains/:slug` | one domain and the entries it holds |
| `GET /entries/:domain/:slug` | one entry: its metadata, its body, its tags, its sources, its verification badge and the entries it relates to |
| `GET /search` | the search page, with filters for the domain, the safety level and the difficulty |
| `GET /about` | the version of the knowledge base and the disclaimer, quoted verbatim |
| `POST /settings/language` | the language switcher |
| `POST /settings/theme` | the theme switcher |
| `GET /sitemap.xml`, `GET /robots.txt` | for the search engines |
| `GET /up` | the health check |

## How it is put together

```
app/
├── models/
│   ├── domain.rb          the value object of a domain
│   ├── entry.rb           the value object of an entry
│   ├── source.rb          one cited source of an entry
│   └── verification.rb    the verification state of an entry
├── services/
│   ├── corpus.rb          reads the sidecars and the bodies, keeps them in memory
│   ├── search.rb          the BM25 flavoured ranking over title, tags and body
│   ├── translator.rb      the interface strings and their English fallback
│   └── manifest_reader.rb a small reader for the subset of TOML the manifest uses
├── helpers/
│   ├── markdown.rb        the safe Markdown renderer
│   ├── markdown_helper.rb the view helpers around the renderer
│   └── application_helper.rb
├── controllers/           home, domains, entries, search, about, settings, static
└── views/                 the server-rendered templates
```

### The corpus

`Corpus` walks up from `Rails.root` until it finds `manifest.toml`, reads every
`sidecars/<domain>/<slug>.pnk.yaml` and the matching
`domains/<domain>/<slug>.md`, and keeps the result in memory. It is loaded
once at boot and never written to. There is no Active Record model for the
corpus: the content is read-only and lives on disk.

### The search

`Search` builds an inverted index over three fields — the title, the tags and
the body — and scores them with BM25. The fields are weighted so that a title
match always outranks a tag match, and a tag match always outranks a body
match; the results are grouped by that tier, so a title match is always
first. A substring bonus finds "water pur" → *Water Purification*. A query
returns at most **50** results, and the results can be narrowed by domain,
safety level and difficulty.

### The Markdown renderer

`Markdown` is a small renderer written for this application. It handles
headings, paragraphs, ordered and unordered lists (including nesting),
blockquotes, fenced code, inline code, emphasis, horizontal rules, pipe
tables and links.

It is **safe by construction**: every piece of text is HTML-escaped *before*
any markup is produced, so an entry can never inject markup into the page.
Links are only turned into anchors for the `http`, `https` and `mailto`
schemes; a `javascript:`, `data:` or relative target is rendered as plain
text and never reaches an `href` attribute.

### The languages

`Translator` reads `i18n/strings/<lang>.yaml` at runtime. The nine languages
of the repository — `en`, `es`, `fr`, `de`, `pt`, `hi`, `ar`, `sw` and `zh` —
are offered. A key that the active language does not define falls back to the
English catalogue, then to the built-in English defaults, and finally to the
key itself, so a missing translation is visible but never fatal. The active
language is written to a cookie and is reflected in the `lang` and `dir`
attributes of the document (`dir="rtl"` for Arabic).

### The theme

The palette follows the preference of the operating system through
`prefers-color-scheme`. The theme switcher writes a cookie, and the server
renders `data-theme="light"` or `data-theme="dark"` on the root element; the
manual override always wins over the system preference. Without an override
the element carries `data-theme="system"` and the system preference applies.

### The recently read list

The twelve most recently read entries are stored in a cookie and shown in the
header and on the home page.

## Accessibility

* semantic HTML: `header`, `nav`, `main`, `article`, `section`, `footer`
* a skip link to `#main`, visible when it is focused
* a label on every input and select
* a visible focus outline on every interactive element (`:focus-visible`)
* `lang` and `dir` set correctly on the root element, including `dir="rtl"`
  for Arabic
* the layout uses logical CSS properties, so it mirrors for right to left
  languages
* colour is never the only signal: the safety level and the verification
  status are written out as well

## SEO

The pages are server-rendered, with a title, a meta description, a canonical
`<html lang>`, a breadcrumb trail and semantic headings. `sitemap.xml` lists
every domain and every entry, and `robots.txt` points at it.

## Security

* a strict content security policy is sent with every response; the
  application ships no script at all
* no database, no external calls, no user accounts
* the preference cookies are `HttpOnly` and `SameSite=Lax`
* the switchers only redirect to a path inside the application
* the corpus can never inject markup, because the renderer escapes it

## Tests

```bash
bin/rails test
```

The suite covers the corpus loader, the search ranking, the Markdown renderer
(including its escaping and its link rules), the language fallback, the
manifest reader, and the pages themselves.

## Notes on this machine

* The `GEM_HOME` of this machine points at a directory that holds no Ruby of
  its own. The native extensions of the newest `date` and `json` releases do
  not load here, so the `Gemfile` pins the versions that ship with this Ruby.
* The application is a self-contained addition to the repository; it does not
  change the corpus and it does not need the corpus to be regenerated.
