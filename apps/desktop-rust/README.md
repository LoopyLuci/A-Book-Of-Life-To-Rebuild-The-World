# A Book Of Life — Rust desktop app

A native, offline desktop reader for the *A Book Of Life To Rebuild The
World* knowledge base.

**The whole interface is Rust.** There is no web view, no embedded HTML and
no JavaScript: the app is a native window that draws its own widgets with
`egui` and `eframe`.

It works entirely offline. The corpus is read from the repository; nothing
is ever fetched.

## Build

Requirements: a Rust toolchain (1.75 or newer) and a C toolchain for the
native dependencies.

```bash
cd apps/desktop-rust
cargo build --release
```

The binary is written to `target/release/abook-desktop`, or to
`$CARGO_TARGET_DIR/release/abook-desktop` when that variable is set. The
project's `scripts/env.ps1` and `scripts/env.sh` point it at the X drive.

## Run

```bash
cd apps/desktop-rust
cargo run --release
```

The repository root is found from the working directory. To point the app at
a checkout elsewhere, set `ABOOK_ROOT`:

```bash
ABOOK_ROOT=/path/to/A-Book-Of-Life-To-Rebuild-The-World cargo run --release
```

## Features

- **Domain pane** with entry counts, and a filter for the domain.
- **Search** that filters as you type. A title match ranks above a tag
  match, which ranks above a body match, and the matching text is shown
  under each result.
- **Filters** for the safety level and the difficulty.
- **Entry view** with the full body, the tags, the verification status and
  the cited sources, each with its licence.
- **Nine interface languages**, switched at runtime: English, Spanish,
  French, German, Portuguese, Hindi, Arabic, Swahili and Simplified
  Chinese. An unknown language falls back to English.
- **Light and dark themes.**
- **Recently read**, kept in the reader's settings file.
- **About window** with the version and the disclaimer, quoted from
  `docs/DISCLAIMER.md`.

## Verify without a display

```bash
cargo run -- --selftest
```

This loads the corpus, runs a few searches, checks the language fallback and
the disclaimer, and exits. It is how the app is checked on a build machine
with no screen.

## Test

```bash
cargo test
cargo clippy --all-targets -- -D warnings
cargo fmt --check
```

The unit tests cover the corpus loader, the search ranking, the language
fallback and the settings. The integration tests build a small corpus in a
temporary directory and read it end to end.

## Layout

| File | What it holds |
|------|---------------|
| `src/lib.rs` | The crate: the modules, and the documentation. |
| `src/main.rs` | The entry point: the window, the self-test, the help. |
| `src/corpus.rs` | Reading the sidecars and the Markdown bodies. |
| `src/search.rs` | The ranking and the filters. |
| `src/i18n.rs` | The interface strings. |
| `src/settings.rs` | The reader's preferences. |
| `src/ui.rs` | The widgets and the layout. |
| `tests/integration.rs` | End-to-end tests over a temporary corpus. |

## License

Code: MIT. Content: CC BY-SA 4.0. See the repository root for the
disclaimer that applies to everything the app shows.
