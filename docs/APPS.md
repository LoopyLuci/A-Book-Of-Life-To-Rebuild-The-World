# The applications

Six independent front-ends read the same corpus, in six different languages and
toolchains. They exist so that no single dependency can lock a reader out of
the book: an old laptop with only Python, a phone with only a browser, a
Windows desktop with no runtime installed, a locked-down machine that only has
a shell, a developer who wants the fastest native window, and a team that
prefers a conventional web server.

Every front-end reads `domains/` and `sidecars/` from the checkout it lives in
and works with the network unplugged. None of them owns content: if a
front-end and the corpus disagree, the corpus is right.

| App | Directory | Toolchain | Interface |
|-----|-----------|-----------|-----------|
| Desktop reader (Python) | [`apps/desktop-python`](../apps/desktop-python) | CPython 3.11+, `tkinter`, no third-party packages | Native desktop window |
| Desktop reader (Rust) | [`apps/desktop-rust`](../apps/desktop-rust) | Rust + `egui`/`eframe` | Native desktop window, no web view |
| Web reader (TypeScript) | [`apps/web-ts`](../apps/web-ts) | Node 20+, TypeScript, no framework | Browser, one static bundle |
| Web reader (Rails) | [`apps/web-rails`](../apps/web-rails) | Ruby 3.2+, Rails 8 | Server-rendered pages, no JavaScript required |
| Terminal reader (PowerShell) | [`apps/powershell`](../apps/powershell) | PowerShell 7+ | Terminal |
| Terminal reader (POSIX shell) | [`apps/shell`](../apps/shell) | `sh`, `awk`, `find`, `sort` | Terminal |

There are two further device front-ends outside `apps/`:

- [`android/`](../android) — Kotlin + Jetpack Compose, ships the whole corpus
  inside the APK and updates itself from the latest GitHub release.
- [`mobile/`](../mobile) — React Native shell for the same content.

## Running each one

Every app runs from a checkout, with no configuration file and no network
access.

```bash
# Python desktop reader
python apps/desktop-python/abook.py

# Rust desktop reader
cargo run --manifest-path apps/desktop-rust/Cargo.toml --release

# TypeScript web reader (build once, then open the bundle)
npm --prefix apps/web-ts install
npm --prefix apps/web-ts run build
npm --prefix apps/web-ts start

# Rails web reader
cd apps/web-rails && bundle install && bin/rails server

# PowerShell terminal reader
pwsh -NoProfile -File apps/powershell/abook.ps1

# POSIX shell terminal reader
sh apps/shell/abook.sh
```

Each app has its own README with the details of its interface, its keyboard
shortcuts and its state directory.

## What each app guarantees

The six apps are not copies of one design, but they answer the same questions
the same way. Every one of them:

- **Finds the corpus from any working directory** by walking up to
  `manifest.toml`, so it can be launched from a shortcut, a menu entry or a
  different directory.
- **Parses the sidecars itself**, without a YAML library, and refuses a
  document it does not understand rather than guessing at a value.
- **Searches offline** with a title-first ranking, so an exact title beats a
  word that happens to appear in a body, and results carry the sentence that
  matched.
- **Switches language at runtime** across every catalogue in `i18n/strings/`,
  falling back to English for any key a translation has not reached yet.
- **Shows the safety level and the verification status** of an entry, and the
  reference-material notice, before the instructions.
- **Keeps the reader's state out of the corpus** — bookmarks, history and
  preferences live in the user's own state directory, never in the checkout.

## Tests

Each app has its own suite, and the local pipeline runs all six as one
`apps` stage:

| App | Command | What it checks |
|-----|---------|----------------|
| `desktop-python` | `python -m pytest apps/desktop-python/tests -q` | YAML reader parity with PyYAML over the whole corpus, corpus loading, search ranking, i18n fallback, version comparison, renderer |
| `desktop-rust` | `cargo test --manifest-path apps/desktop-rust/Cargo.toml` | Corpus parsing, search, i18n, state, rendering |
| `web-ts` | `npm --prefix apps/web-ts run test` and `run build` | Parser, search, i18n, Markdown rendering, and that the bundle builds |
| `web-rails` | `ruby -Capps/web-rails bin/rails test` | Corpus loading, translation, controllers, views, search |
| `powershell` | `pwsh -NoProfile -File apps/powershell/tests/run-tests.ps1` | Hand-written YAML parser, corpus, search, i18n, version comparison, interaction |
| `shell` | `sh apps/shell/tests/run-tests.sh` | awk-based YAML parser, corpus cache, search, i18n, renderer, self test |

From the repository root, run `python scripts/local_pipeline.py --stage apps`
to run the app suites supported by the local toolchains; `make test-apps` is a
convenience alias where `make` is installed. GitHub CI runs all six app suites
on its dedicated reader job. A local missing toolchain is reported as
uncovered; it is not evidence that the corresponding reader passed.

A missing toolchain is not a failure: the `apps` stage tests the apps the
machine can build and reports which surfaces it covered. The summary line and
`logs/local_pipeline/summary.txt` name the commands that actually ran.

### Windows and the POSIX shell

On Windows, `sh`, `awk`, `find` and `sort` come from a POSIX layer (MSYS2, Git
Bash, Cygwin), and the inherited `PATH` usually lists `C:\Windows\System32`
first. That makes `sort` and `find` resolve to the Windows programs of the same
name, which take different options and print different output — the corpus
cache silently comes out empty and every search returns nothing. The shell
reader therefore moves the directory that holds the POSIX `awk` to the front of
`PATH` when it starts, so the POSIX tools win. If the tests fail with
`Input file specified two times.`, that is the symptom, and the fix is already
in `apps/shell/lib/config.sh`.

## Adding a seventh front-end

A new front-end is welcome if it:

1. reads the corpus from disk and needs no network,
2. parses `schemas/sidecar.schema.json` documents without silently guessing,
3. honours `language` and falls back to English,
4. shows the safety level, the verification status and the reference-material
   notice,
5. ships a test suite, and can be run by a single command from the repository
   root.

Add it under `apps/<name>/`, document it with a `README.md`, add its test
command to `app_stage_commands()` in [`scripts/local_pipeline.py`](../scripts/local_pipeline.py),
and add a row to the table at the top of this document.
