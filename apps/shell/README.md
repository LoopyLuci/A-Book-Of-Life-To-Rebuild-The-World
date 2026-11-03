# A Book Of Life — Shell Reader

An interactive terminal reader for the knowledge base of
[A Book Of Life To Rebuild The World](https://github.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World).
It reads the corpus of the repository it lives in — the metadata sidecars in
`sidecars/` and the Markdown bodies in `domains/` — and never touches the
network.

The reader is written in **portable POSIX shell**. It needs nothing but a
standard POSIX toolset: `awk`, `sed`, `grep`, `cut`, `tr`, `dd` and `stty`.
There is no build step, no package to install and no runtime dependency, so
it runs on a bare Linux or macOS machine with `/bin/sh` (dash or bash in
POSIX mode).

## Requirements

- A POSIX shell (`/bin/sh`), `awk`, `sed`, `grep`, `cut`, `tr`, `dd` and
  `stty`. All of them are part of every Linux and macOS installation.
- The repository checkout, because the reader reads the corpus from disk.

## Install it

The reader is used straight from the checkout. To use it from anywhere, put
a small launcher in your `PATH`:

```sh
#!/bin/sh
exec sh "/path/to/A-Book-Of-Life-To-Rebuild-The-World/apps/shell/abook.sh" "$@"
```

## Run it

From the repository root:

```sh
sh apps/shell/abook.sh
```

The application finds the repository by walking up from its own location
until it finds a `manifest.toml`, so it can be started from any working
directory.

Useful flags:

```sh
sh apps/shell/abook.sh --lang fr      # start in French
sh apps/shell/abook.sh --theme dark   # start in the dark theme
sh apps/shell/abook.sh --root /path/to/checkout
sh apps/shell/abook.sh --version      # print the version
```

The reader refuses to open its interface when it is not attached to a
terminal. It says so and leaves with a non-zero code, instead of drawing
into a pipe:

```
abook: This program needs an interactive terminal. Run it from a terminal, or use --selftest for the headless checks.
```

## Verify it

The reader ships with a self-test that exercises the corpus loader, the
search ranking, the translation fallback, the version and the key reader,
and exits without opening the interface. This is how the application is
checked on a machine without a display:

```sh
sh apps/shell/abook.sh --selftest
```

It prints a report and exits with `0` when every check passed.

The test suite covers the same ground in more detail, and adds the YAML
parser, the renderer and the program itself:

```sh
sh apps/shell/tests/run-tests.sh
```

It prints one line per check and exits with a non-zero code when a check
failed.

The sources are plain POSIX shell and can be checked with `shellcheck`:

```sh
shellcheck -x -s sh apps/shell/abook.sh apps/shell/lib/*.sh apps/shell/tests/run-tests.sh
```

## The interface

```
┌────────────────────────────────────────────────────────────────────────────────────────────┐
│ A Book Of Life To Rebuild The World                                v0.1.0-alpha  English  [dark] │
├───────────────────────────────┬────────────────────────────────────────────────────────────┤
│Domains (16)                   │Making Fire                                                      │
│  survival                   13│survival  -  Difficulty: novice  -  Safety: yellow               │
│  water                       6│Verification: draft  -  Time to complete: hours                  │
│  agriculture                11│Tags: fire, ignition, warmth, cooking, survival                  │
│  ...                         │                                                                  │
│Results (207)                  │Fire provides warmth, light, cooking, water purification, and    │
│▸ Making Fire                 │protection.                                                     │
│  Map Making                  │                                                                  │
└───────────────────────────────┴────────────────────────────────────────────────────────────┘
│207 results | English | dark  Ctrl+F — focus search  Ctrl+K — quick jump  F1 — about  Ctrl+Q — quit│
│Search:                                                                                      │
│:                                                                                           │
└────────────────────────────────────────────────────────────────────────────────────────────┘
```

- **The left pane** lists the sixteen domains of `manifest.toml` with the
  number of entries each one has, and below them the entries that match the
  current search and filters. The selected row carries a marker and is drawn
  in the selection colour.
- **The right pane** shows the selected entry: its title, its domain,
  difficulty, safety level, verification status and time to complete, its
  tags, its Markdown body and the path of the file it came from.
- **The status bar** shows the filters that are set, the number of results,
  the language, the theme and the keys.
- **The search line** filters the corpus as you type.
- **The command line** takes the commands of the reader.

The boxes are drawn with UTF-8 box drawing characters when the terminal can
show them and with plain `+`, `-` and `|` when it cannot. The same goes for
the bullet, the marker and the ellipsis.

## Keyboard

| Key | What it does |
|---|---|
| `Ctrl+F` | focus the search line, which filters as you type |
| `Ctrl+K` | open the quick jump palette, which matches titles, slugs and tags |
| `F1` | open the about screen: the version, the index and the disclaimer |
| `Ctrl+Q` | leave the reader |
| `Up`, `Down` | move the selection in the left pane, or scroll the entry when the reader has the focus |
| `PageUp`, `PageDown` | scroll the entry by a page |
| `Home`, `End` | jump to the top or to the bottom of the entry |
| `Tab`, `Left`, `Right` | switch between the navigator and the reader |
| `Enter` | filter by the selected domain, or remember the selected entry as read |
| `Escape` | leave the input line, or clear the search and the filters |
| `:` | focus the command line |
| `Ctrl+T` | switch between the light and the dark theme |
| `Ctrl+L` | switch to the next language |
| `Ctrl+U` | clear the search line |
| `Backspace` | delete the last character |

## Commands

| Command | What it does |
|---|---|
| `:help` | the help screen |
| `:about` | the about screen |
| `:search <text>` | search for text |
| `:domain <name>` | filter by domain, for example `:domain survival` |
| `:safety <level>` | filter by safety level: `green`, `yellow` or `red` |
| `:difficulty <level>` | filter by difficulty: `novice`, `apprentice`, `journeyman` or `master` |
| `:lang <code>` | switch the interface language |
| `:theme <name>` | switch the theme: `light` or `dark` |
| `:recent` | show the entries that were read recently |
| `:open <slug>` | open an entry by its slug, for example `:open making-fire` |
| `:clear` | clear the search and the filters |
| `:quit` | leave the reader |

## Features

- **Two panes.** The sixteen domains with their entry counts on the left,
  the selected entry on the right, a status bar and a command line below.
- **Instant search.** Type in the search line and the matches appear as you
  type. The ranking puts a title match first, then a tag match, then a body
  match, and a whole phrase or a prefix of a title is rewarded, so
  `water pur` finds *Water Purification*.
- **Filters.** A domain filter, a safety filter and a difficulty filter
  narrow the results at the same time.
- **Languages.** The interface switches at runtime between the nine
  languages of the repository — English, Spanish, French, German,
  Portuguese, Hindi, Arabic, Swahili and Chinese — using the catalogues in
  `i18n/strings/`. A missing or unreadable catalogue falls back to English,
  and a key that a catalogue does not carry falls back to the English
  catalogue and then to the built-in English strings.
- **Themes.** A light and a dark theme, switched with `Ctrl+T`. The choice
  is remembered between runs.
- **Recently read.** The entries you open are remembered between runs, in
  the state file, and are listed with the `:recent` command.
- **About screen.** The version from `manifest.toml` and the summary
  section of `docs/DISCLAIMER.md`, quoted verbatim, with the list of the
  keys.
- **Resilient.** A missing or stale `build/index.db` is not a problem: the
  reader scans the sidecars and the bodies of the repository instead. A
  missing translation falls back to English. A missing corpus is reported
  clearly instead of crashing.
- **Portable.** Written for `/bin/sh`. It runs under dash, under bash in
  POSIX mode and under the other POSIX shells.

## Where things live

```
apps/shell/
├── abook.sh              the entry point and the interactive loop
├── lib/
│   ├── config.sh         paths, terminal capabilities, preferences, versions
│   ├── theme.sh          the light and the dark palettes, the box characters
│   ├── corpus.sh         the YAML parser, the corpus loader and its cache
│   ├── search.sh         the ranking of the results
│   ├── i18n.sh           the catalogues of the interface strings
│   └── render.sh         the panes, the boxes, the colours and the keys
└── tests/
    └── run-tests.sh      the test suite
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
| Preferences and cache | `~/.abook/settings.json`, `~/.abook/cache/` |

Set `ABOOK_HOME` to keep the preferences and the cache somewhere else.

The sidecars are parsed by the awk reader in `lib/corpus.sh`, which handles
the subset of YAML the repository uses: block mappings, block sequences,
sequences of mappings, inline `[a, b]` lists, plain, single-quoted and
double-quoted scalars, numbers, booleans, `null`, comments and files with
Windows line endings. The parsed corpus is cached under `~/.abook/cache/`,
so the second run starts at once.

## A note on the content

The knowledge base is reference material. It is published for reference,
education and research, it is not professional advice, and no entry is a
complete or sole source of information. Read
[`docs/DISCLAIMER.md`](../../docs/DISCLAIMER.md) before you rely on anything
here.
