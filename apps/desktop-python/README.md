# A Book Of Life — Desktop Reader (Python)

An offline desktop reader for the knowledge base of
[A Book Of Life To Rebuild The World](https://github.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World).
It reads the corpus of the repository it lives in — the Markdown bodies in
`domains/` and the metadata sidecars in `sidecars/` — and never touches the
network.

The interface is built with the **standard library only**: `tkinter` for the
widgets, `sqlite3` for the optional pre-built index, `tomllib` for the
manifest and a bundled YAML reader for the sidecars. There are no runtime
dependencies, so the reader runs on a bare CPython 3.11 with `tkinter`
installed.

## Requirements

- Python 3.11 or newer (the version the repository itself targets).
- `tkinter`, which ships with CPython on Windows and macOS. On Debian and
  Ubuntu it is a separate package: `sudo apt install python3-tk`.
- The repository checkout, because the reader reads the corpus from disk.

## Run it

From the repository root:

```bash
python apps/desktop-python/abook.py
```

The window opens immediately and the corpus is loaded on a background thread;
the status bar shows the progress.

Useful flags:

```bash
python apps/desktop-python/abook.py --lang fr      # start in French
python apps/desktop-python/abook.py --theme dark   # start in the dark theme
python apps/desktop-python/abook.py --root /path/to/checkout
python apps/desktop-python/abook.py --version      # print the version
```

The application finds the repository by walking up from its own location until
it finds a `manifest.toml`, so it can be started from any working directory.

## Verify it

The reader ships with a self-test that exercises the corpus loader, the search
ranking, the translation fallback and the version, and exits without opening a
window. This is how the application is checked on a machine without a display:

```bash
python apps/desktop-python/abook.py --selftest
```

It prints a report and exits with `0` when every check passed.

The test suite covers the same ground in more detail:

```bash
python -m pytest apps/desktop-python/tests -q
```

## Install it (optional)

The reader is usable straight from the checkout. To install it as a command:

```bash
pip install ./apps/desktop-python
abook-desktop --selftest
```

The install pulls in nothing: `pyproject.toml` declares no runtime
dependencies. The version in `pyproject.toml` mirrors `[project] version` in the
repository `manifest.toml` (`0.1.0-alpha`); note that PEP 440 normalises that
to `0.1.0a0` when the distribution is built.

## Features

- **Domain tree.** The sixteen domains of `manifest.toml` with the number of
  entries each one has, counted from the sidecars. Selecting a domain shows an
  overview of its entries and the description from `domains/README.md`.
- **Reader pane.** The selected entry with its title, a domain / difficulty /
  safety / verification line, its tags and its Markdown body. Headings, bullet
  and numbered lists, block quotes, horizontal rules, fenced code blocks,
  inline emphasis and links are preserved and styled with the tag system of a
  plain `tkinter` `Text` widget — no web view, no HTML.
- **Instant search.** Type in the search field and the top fifty matches appear
  as you type. The ranking is BM25-flavoured over the title, the tags and the
  body, with the fields weighted so that a title match always comes first,
  then a tag match, then a body match. Whole-phrase and prefix matches are
  rewarded, so `water purif` finds *Water Purification*.
- **Filters.** A domain filter and a safety filter (`green`, `yellow`, `red`)
  narrow the tree and the search results at the same time.
- **Languages.** The interface switches at runtime between the nine languages
  of the repository — English, Spanish, French, German, Portuguese, Hindi,
  Arabic, Swahili and Chinese — using the catalogues in `i18n/strings/`.
  A missing or unreadable catalogue falls back to English.
- **Themes.** A light and a dark theme, switched from the toolbar. The choice
  is remembered between runs.
- **Recently read.** The entries you open are listed at the top of the tree and
  are remembered between runs.
- **About box.** The version from `manifest.toml` and the summary section of
  `docs/DISCLAIMER.md`, quoted verbatim, with a checkbox that has to be ticked
  before the box can be closed.
- **Keyboard shortcuts.** `Ctrl+F` focuses the search, `Ctrl+K` opens the
  quick-jump palette, `F1` opens the about box and `Ctrl+Q` quits.
- **Resilient.** A missing or stale `build/index.db` is not a problem: the
  reader falls back to scanning the corpus directly. A missing translation
  falls back to English. The corpus is loaded on a background thread, so the
  window appears immediately.

## Where things live

```
apps/desktop-python/
├── abook.py              entry point: python abook.py
├── pyproject.toml        the project declaration, no runtime dependencies
├── abook/
│   ├── __init__.py       package metadata, logging, repository discovery
│   ├── cli.py            argument handling and the self-test
│   ├── corpus.py         loading the sidecars and the Markdown bodies
│   ├── i18n.py           the translation catalogues and the language switcher
│   ├── search.py         the BM25-flavoured ranking
│   ├── settings.py       the persisted preferences
│   ├── theme.py          the light and dark palettes
│   ├── ui.py             the tkinter widgets
│   ├── yamlmini.py       a dependency-free reader for the YAML subset used
│   └── __main__.py       lets the package be started with python -m abook
└── tests/
    ├── test_corpus.py    corpus loading, ranking, translations, version
    └── test_yamlmini.py  the YAML reader against PyYAML
```

## How it finds the data

| What | Where it comes from |
|---|---|
| Version, domains, languages | `manifest.toml` |
| Entry metadata | `sidecars/<domain>/<slug>.pnk.yaml` |
| Entry body | `domains/<domain>/<slug>.md` |
| Interface strings | `i18n/strings/<lang>.yaml` |
| Disclaimer | `docs/DISCLAIMER.md`, section 12 |
| Search index (optional) | `build/index.db` |
| Preferences and log | `~/.abook-desktop/settings.json`, `~/.abook-desktop/abook.log` |

Set `ABOOK_HOME` to keep the preferences and the log somewhere else.

## A note on the content

The knowledge base is reference material. It is published for reference,
education and research, it is not professional advice, and no entry is a
complete or sole source of information. Read
[`docs/DISCLAIMER.md`](../../docs/DISCLAIMER.md) before you rely on anything
here.
