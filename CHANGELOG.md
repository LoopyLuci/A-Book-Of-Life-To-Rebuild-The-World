# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **100 new entries** across six new domains, bringing the book to 207 entries
  in 16 domains: `chemistry` (18), `biology` (17), `silicon` (13), `ship` (18),
  `computers` (18) and `quantum` (16).
- **938 recorded sources**, a mean of 4.5 per entry, every one carrying a
  licence: the 328 original sources now all have one, plus **610 multilingual
  sources** resolved through the MediaWiki language-links API, so every entry
  cites at least one non-English source. The sidecar schema gained a `language`
  field and a wider licence vocabulary (`CC-BY-SA-3.0-IGO`,
  `CC-BY-NC-SA-3.0-IGO`, `CC-BY-NC-4.0`, `permission-granted`).
- **Six app front-ends** under `apps/`, all tested by the pipeline: a Python
  `tkinter` desktop reader, a Rust `egui` desktop reader, a TypeScript web
  reader, a Rails 8 web reader, a PowerShell terminal reader and a POSIX shell
  terminal reader. Each finds the corpus from any directory, parses the
  sidecars itself, searches offline and switches language at runtime.
  Documented in `docs/APPS.md`.
- `scripts/install.py` with `install.ps1` and `install.sh`: a transactional
  installer, updater, verifier and uninstaller. It checks the machine, creates
  an isolated `.venv/`, installs the dependencies with retries, builds the
  index, verifies the result, and restores the previous environment if any
  step fails. `--offline` installs from a wheelhouse, `--rebuild` recreates the
  environment, `--dry-run` changes nothing. Documented in `docs/INSTALL.md`.
- `scripts/local_pipeline.py`: a fourteen-stage on-device CI/CD pipeline from
  preflight to the Android APK, with flake absorption, per-stage logs,
  machine-readable telemetry, an artifact cache that never caches a gate, a
  `--fast` mode and `--stage`/`--skip`/`--list`/`--clean`/`--telemetry`.
  Documented in `docs/LOCAL-PIPELINE.md`.
- `scripts/install_hooks.py`: installs a `pre-push` hook that runs the pipeline
  and stops a push when a stage fails, so "run it before you push" is enforced
  by git rather than remembered. Installed by `scripts/install.py`; `--status`,
  `--uninstall` and `--force` included.
- `requirements-dev.txt`: the test and lint tools, including `respx` for the
  SDK tests, so a contributor installs one file and every stage can run.
- The interface now ships in **17 languages** (English, Spanish, French,
  German, Portuguese, Hindi, Arabic, Swahili, Chinese, Indonesian, Italian,
  Japanese, Korean, Dutch, Russian, Turkish and Vietnamese), with a per-language
  coverage target enforced by `scripts/validate_i18n.py`.
- `docs/DISCLAIMER.md`: the canonical warning and notice of use — reference
  material only, verify before acting, never a sole source of information, no
  professional advice, no warranty, and a limitation of liability. Linked from
  the README, the contribution guide, the entry templates, the domain index,
  the internationalisation guide and `LICENSE-CONTENT`.
- A reference-material notice in every one of the 207 entries, so a reader who
  opens a single entry still sees the warning.
- `scripts/new_topic.py`: scaffolds a new domain end to end and registers it in
  the sidecar schema, `manifest.toml`, the OpenAPI description, the MCP search
  service, the Android content exporter and the domain index.
- `docs/ENTRIES.md`, `docs/TOPICS.md`, `docs/ARCHITECTURE.md`, `docs/RELEASES.md`
  and `docs/README.md`: the writing reference, the topic process, the system
  architecture, the release process and the documentation index.
- In-app updates for the Android app: **Settings → App updates** checks the
  GitHub Releases API for a newer build, downloads the package with the
  platform download service in the background, and hands it to the system
  installer, which always asks the reader to confirm. A `BroadcastReceiver`
  picks the download up again when the app was closed while it was running.
- GitHub issue templates for proposing a new topic, a new entry and a field
  test, a `.github/ISSUE_TEMPLATE/config.yml` chooser that points at the
  guides, and a rewritten pull request template.
- Native Android app (`android/`): Kotlin + Jetpack Compose reader with the knowledge
  base bundled as offline assets, hybrid BM25 + TF-IDF on-device search, a Markdown
  reader, bookmarks, reading progress, themes and 16 UI translations.
- `android/tools/export_content.py` content export pipeline (entries/domains/meta JSON
  and `values-<lang>` string resources) and `.github/workflows/android.yml` CI.
- Android instrumentation tests (`AppSmokeTest`) plus
  `.github/workflows/android-emulator.yml` running them on an API 26/31/35 emulator matrix.

### Changed
- The README now describes every surface of the project (16 domains, six app
  front-ends, the Android and mobile apps, the three SDKs, the MCP server, the
  offline bundle, federation, the installer, the local pipeline,
  internationalisation, CI and releases) and carries the warning at the top.
- The contribution guide now documents the two intake paths, the entry format,
  the translation workflow, the six front-ends, the checks a change must pass,
  the local pipeline as the pre-push check, and what will not be merged.
- `i18n/README.md` carries the real coverage and target per language, and a
  section on multilingual sources, instead of a fixed launch-language list.
- `scripts/new_entry.py` writes the reference-material notice and points the
  contributor at the writing guide.
- The sidecar schema, `manifest.toml`, the OpenAPI description, the MCP
  search service and the Android content exporter accept the six new domains.
- `manifest.toml` lists all seventeen supported languages rather than fifteen.
- The Rails reader treats `puma` as an optional require and no longer pins the
  `date`/`json` default gems, so its suite runs on a machine whose Ruby has no
  OpenSSL and no precompiled native gems.
- The PowerShell and POSIX readers derive the language list from
  `i18n/strings/` rather than from a hard-coded nine, and the POSIX reader puts
  the directory holding `awk` in front of `PATH` so Windows `sort.exe` and
  `find.exe` cannot shadow the coreutils.
- The pipeline now schedules stages in dependency waves: `tests` waits for
  `index` and `bundle`, so the end-to-end suite no longer races a half-written
  offline bundle. Cacheable stages also declare their outputs, and a cached
  artifact is only reused while those files still exist.
- `scripts/build_bundle.py` delegates to the complete site builder in
  `scripts/build_zim.py` instead of writing a partial HTML tree, and the
  end-to-end fixture rebuilds the bundle when its index files are missing.
- The `markdown`, `sdk` and `android` stages resolve their tools by the name
  Windows can actually execute (`npx.cmd`, the SDK package directory from its
  own working directory, the absolute `gradlew.bat`).
- The pipeline's preflight checks that `pytest`, `ruff` and `respx` are
  importable by the interpreter that will run the stages, and prints the exact
  install command when one is missing, instead of letting `tests`, `lint` and
  `sdk` fail later with an import error.
- An "optional" stage is documented for what it is: a stage that may have
  nothing to do when its toolchain is absent. A stage that runs and fails still
  fails the run, so a red check can never be mistaken for a skip.
- Android release builds are minified, shrink resources, derive their version from
  `manifest.toml`, and are signed via environment/`keystore.properties` credentials
  (tag-driven `.github/workflows/android-release.yml` publishes them to GitHub Releases).
- Exported entry bodies no longer repeat the leading `# Title` and metadata blockquote
  (the reader already renders both), and `meta.json` now carries a `contentHash` that the
  importer uses to pick up content refreshes even when the KB version is unchanged.
- Android app declares a `localeConfig` so the 16 translations are selectable via Android's
  per-app language settings.

## [1.0.0] — 2026-01-01

### Added
- Initial public release of **A Book Of Life To Rebuild The World**.
- 70 seed entries across 8 domains: survival, agriculture, materials,
  energy, construction, health, knowledge, society.
- Hybrid search index (SQLite FTS5 + local embeddings + RRF).
- MCP server with 6 agent tools.
- RAG layer with local LLM (Ollama) and citation enforcement.
- Offline bundle pipeline (static HTML + Kiwix ZIM).
- Docker Compose stack (API, MCP, RAG, Ollama, Kiwix, Kolibri).
- Raspberry Pi bootable image builder.
- Python, TypeScript, and Rust SDKs.
- pnk:// federation protocol v1 with Ed25519 signed manifests.
- Mobile app (React Native + SQLite) with offline search.
- Verification state machine and dashboard.
- Bug bounty program.
- Fiscal sponsorship via Open Collective.
- Governance charter v1.0.0.

### Security
- All federation manifests are signed with Ed25519.
- All content is hashed with SHA-256.
- No code execution in content.

## [0.1.0-alpha] — 2025-12-01

### Added
- Internal alpha. Repository scaffold, schemas, CI.

[Unreleased]: https://github.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World/releases/tag/v1.0.0
[0.1.0-alpha]: https://github.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World/releases/tag/v0.1.0-alpha
