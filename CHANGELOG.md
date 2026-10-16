# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Native Android app (`android/`): Kotlin + Jetpack Compose reader with the knowledge
  base bundled as offline assets, hybrid BM25 + TF-IDF on-device search, a Markdown
  reader, bookmarks, reading progress, themes and 8 UI translations.
- `android/tools/export_content.py` content export pipeline (entries/domains/meta JSON
  and `values-<lang>` string resources) and `.github/workflows/android.yml` CI.

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

[Unreleased]: https://github.com/abookoflife/a-book-of-life-to-rebuild-the-world/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/abookoflife/a-book-of-life-to-rebuild-the-world/releases/tag/v1.0.0
[0.1.0-alpha]: https://github.com/abookoflife/a-book-of-life-to-rebuild-the-world/releases/tag/v0.1.0-alpha
