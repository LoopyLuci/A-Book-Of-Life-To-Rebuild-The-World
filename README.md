# Book of Life – Rebuild the World

> A living, decentralized, offline-first knowledge engine for rebuilding civilization from first principles.

[![CI](https://github.com/book-of-life/book-of-life/actions/workflows/ci.yml/badge.svg)](https://github.com/book-of-life/book-of-life/actions/workflows/ci.yml)
[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## What is this?

**Book of Life** is an open-source, forkable, field-ready knowledge base covering every domain required to rebuild civilization: survival, water, agriculture, materials, energy, construction, transport, health, knowledge, and society.

Every entry is:
- **Offline-first** — works with zero internet connectivity
- **Verifiable** — sourced and field-tested with provenance tracking
- **Actionable** — step-by-step procedures, schematics, and measurements
- **Agent-readable** — structured for both humans and AI retrieval

## Quick Start

```bash
# Clone the repository
git clone https://github.com/book-of-life/book-of-life.git
cd book-of-life

# Install dependencies
pip install -r requirements.txt

# Validate all sidecars
python scripts/validate.py

# Build the search index
python scripts/build_index.py

# Run the local server
python scripts/serve.py
```

## Offline Deployment

```bash
# Full offline bundle (Kiwix + Ollama + maps + Kolibri)
cd deploy/docker
docker compose up -d
```

## Repository Structure

```
book-of-life/
├── domains/          # Source of truth (Markdown + assets)
├── sidecars/         # Metadata sidecars (.pnk.yaml)
├── android/          # Native Android app (Kotlin + Jetpack Compose)
├── mobile/           # React Native mobile app
├── scripts/          # Build, index, validation
├── build/            # Generated artifacts (gitignored)
├── deploy/           # Deployment recipes
└── .github/          # CI/CD workflows
```

## Native Android App

A fully offline, native reader lives in [`android/`](android/) — Kotlin, Jetpack Compose
and Material 3, with a bundled copy of the knowledge base and hybrid (BM25 + TF-IDF)
on-device search. See [`android/README.md`](android/README.md) for build instructions.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). All contributions are governed by our [Code of Conduct](CODE_OF_CONDUCT.md).

## License

Content: [CC BY-SA 4.0](LICENSE-CONTENT)  
Code: [MIT](LICENSE-CODE)
