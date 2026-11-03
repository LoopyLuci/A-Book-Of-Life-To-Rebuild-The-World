# Book of Life — Rebuild the World

> A living, decentralized, offline-first knowledge engine for rebuilding
> civilization from first principles.

[![CI](https://github.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World/actions/workflows/ci.yml/badge.svg)](https://github.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World/actions/workflows/ci.yml)
[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Languages](https://img.shields.io/badge/languages-17-blue.svg)](i18n/README.md)

> [!WARNING]
> **This project is reference material, not professional advice.**
> Every procedure, figure and instruction must be independently checked
> against primary sources and qualified professionals before you rely on it.
> No single entry is a complete or sole source of information, and no entry may
> be used *solely* as a single source. Nothing here is medical, legal,
> engineering or safety advice, and it is provided "as is" without warranty of
> any kind, express or implied.
> Read **[docs/DISCLAIMER.md](docs/DISCLAIMER.md)** before you use anything
> here.

## What this is

**Book of Life** is an open-source, forkable, field-ready knowledge base
covering the domains required to rebuild civilization — from finding water and
lighting a fire, through farming, materials, construction and transport, to
chemistry, biology, semiconductors, shipbuilding, computers and quantum
computing.

Every entry is:

- **Offline-first** — works with zero internet connectivity, on a phone, a
  laptop, or a Raspberry Pi in a village with no grid.
- **Verifiable** — sourced, with a recorded licence and language for every
  source, and marked with an honest verification status.
- **Actionable** — step-by-step procedures, materials, measurements, hazards
  and limitations.
- **Agent-readable** — structured for humans, for search, and for AI
  retrieval, with a stable identifier and a machine-readable sidecar.
- **Multilingual** — the interface in 17 languages, the entries translated
  into 16, and every entry carrying sources in more than one language so a
  reader can follow the trail without translating first.

## Install

The project installs itself, transactionally: a failed step restores the
previous working environment.

Windows:

```powershell
irm https://raw.githubusercontent.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World/main/install.ps1 | iex
```

Linux and macOS:

```sh
curl -fsSL https://raw.githubusercontent.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World/main/install.sh | sh
```

Or from a checkout:

```bash
python scripts/install.py install     # install or repair
python scripts/install.py update      # update an existing install
python scripts/install.py verify      # check an existing install
python scripts/install.py uninstall   # remove the installation
```

The installer checks the machine, creates an isolated `.venv/`, installs the
dependencies with retries, builds the search index, verifies the result and
leaves a launcher behind. It needs Python 3.11 or newer and about 2 GB of free
space, and it can install with no network at all from a wheelhouse. The full
reference is in [`docs/INSTALL.md`](docs/INSTALL.md).

## The knowledge base

**16 domains**, **207 entries**, **938 recorded sources** (a mean of 4.5 per
entry, every one with a licence and a language), growing every week.

| Domain | Covers |
|--------|--------|
| [survival](domains/survival/README.md) | Water, fire, shelter, first aid, signalling, foraging. |
| [water](domains/water/README.md) | Harvesting, springs, storage, treatment, reuse, sanitation. |
| [agriculture](domains/agriculture/README.md) | Soil, crops, irrigation, livestock, seed saving, preservation. |
| [materials](domains/materials/README.md) | Metals, glass, ceramics, textiles, paper, adhesives, leather. |
| [energy](domains/energy/README.md) | Fire, solar, wind, hydro, biogas, batteries, microgrids, wiring. |
| [construction](domains/construction/README.md) | Shelter, masonry, timber framing, roads, wells, latrines, seismic bracing. |
| [transport](domains/transport/README.md) | Carts, pack animals, bicycles, ferries, cargo, route planning. |
| [health](domains/health/README.md) | Diagnosis, surgery, wound care, dentistry, mental health, triage. |
| [knowledge](domains/knowledge/README.md) | Printing, radio, cryptography, measurement, education, music, maps. |
| [society](domains/society/README.md) | Governance, law, economics, ethics, conflict resolution, community. |
| [chemistry](domains/chemistry/README.md) | Stoichiometry, equilibria, electrochemistry, separation, analysis, lab safety. |
| [biology](domains/biology/README.md) | Cells, genetics, microbiology, ecology, fermentation, field medicine. |
| [silicon](domains/silicon/README.md) | Silicon purification, crystal growth, wafers, fabrication, devices. |
| [ship](domains/ship/README.md) | Hull design, shipyards, welding, propulsion, navigation, safety. |
| [computers](domains/computers/README.md) | Circuits, PCBs, firmware, operating systems, networks, data, testing. |
| [quantum](domains/quantum/README.md) | Qubits, cryogenics, control electronics, error correction, algorithms. |

Every entry is a Markdown file in `domains/<domain>/` with a matching
`.pnk.yaml` sidecar in `sidecars/<domain>/`. The sidecar carries the stable
identifier, domain, tags, difficulty, safety level, sources, verification
status and links — it is what the index, the apps, the SDKs and the agents
read.

## The six front-ends

Six independent readers, in six toolchains, over one corpus. They exist so that
no single dependency can lock a reader out of the book.

| App | Toolchain | Interface |
|-----|-----------|-----------|
| [`apps/desktop-python`](apps/desktop-python) | CPython 3.11+, `tkinter`, no third-party packages | Native desktop window |
| [`apps/desktop-rust`](apps/desktop-rust) | Rust + `egui`/`eframe` | Native desktop window, no web view |
| [`apps/web-ts`](apps/web-ts) | Node 20+, TypeScript, no framework | Browser, one static bundle |
| [`apps/web-rails`](apps/web-rails) | Ruby 3.2+, Rails 8 | Server-rendered pages, no JavaScript required |
| [`apps/powershell`](apps/powershell) | PowerShell 7+ | Terminal |
| [`apps/shell`](apps/shell) | `sh`, `awk`, `find`, `sort` | Terminal |

```bash
python apps/desktop-python/abook.py                                   # Python desktop
cargo run --manifest-path apps/desktop-rust/Cargo.toml --release      # Rust desktop
npm --prefix apps/web-ts install && npm --prefix apps/web-ts run build # TypeScript web
cd apps/web-rails && bundle install && bin/rails server               # Rails web
pwsh -NoProfile -File apps/powershell/abook.ps1                       # PowerShell terminal
sh apps/shell/abook.sh                                                # POSIX terminal
```

Every one of them finds the corpus from any working directory, parses the
sidecars itself, searches offline with a title-first ranking, switches language
at runtime, shows the safety level and verification status before the
instructions, and keeps the reader's bookmarks and history out of the checkout.
See [`docs/APPS.md`](docs/APPS.md).

### Device apps

- [`android/`](android/) — Kotlin + Jetpack Compose. The whole corpus ships
  inside the APK and is searched on device. **Settings → App updates** downloads
  the latest GitHub release and installs it in the background.
- [`mobile/`](mobile/) — React Native shell for the same content.

## The other surfaces

| Surface | What it is |
|---------|------------|
| `domains/` + `sidecars/` | The corpus itself: Markdown entries with machine-readable metadata. |
| Python / TypeScript / Rust SDKs (`sdk/`) | Typed clients for the index, the search API and the bundle. |
| MCP server (`scripts/mcp_server.py`) | Model Context Protocol server so an agent can search the book. |
| Offline bundle | ZIM archive, index database, media, models and UI strings in one downloadable package. |
| Federation | A manifest and identity scheme for mirroring the book across nodes. |

## Languages

The interface ships in **17 languages** — English, Spanish, French, German,
Portuguese, Hindi, Arabic, Swahili, Chinese, Indonesian, Italian, Japanese,
Korean, Dutch, Russian, Turkish and Vietnamese — and the entries are translated
into **16** of them, with a coverage target per language that is enforced by
the pipeline:

| Coverage | Languages |
|----------|-----------|
| 100 % | Spanish, French, German, Portuguese |
| 80 % | Arabic, Hindi, Chinese |
| 60 % | Swahili |
| 40 % | Japanese, Russian |
| 25–30 % | Indonesian, Italian, Korean, Dutch, Turkish, Vietnamese |

Translations live in `i18n/strings/` and `i18n/translations/`, and
`scripts/validate_i18n.py` fails the build when a language drops below its
target. Every entry also cites sources in several languages, so the trail is
readable even where the entry itself is not yet translated. See
[`i18n/README.md`](i18n/README.md) and [`docs/ENTRIES.md`](docs/ENTRIES.md).

## The local pipeline

`scripts/local_pipeline.py` is the on-device delivery pipeline: no CI service,
no network, fourteen stages from preflight to the Android APK.

```bash
python scripts/local_pipeline.py              # everything
python scripts/local_pipeline.py --fast       # skip the slow stages
python scripts/local_pipeline.py --list       # show the stages
python scripts/local_pipeline.py --stage apps # one stage
python scripts/local_pipeline.py --telemetry  # the last run as JSON
```

It checks the toolchain and the disk before anything runs, validates every
sidecar, lints, builds the index, checks the translation coverage, runs the test
suites of the backend and of all six front-ends, assembles the bundle and
compiles the APK. A stage that fails under load and passes when re-run serially
is reported as a **flake** rather than hidden; a real failure stops the run and
names its log. Every run leaves `logs/local_pipeline/` with per-stage logs, a
summary and a machine-readable telemetry file. See
[`docs/LOCAL-PIPELINE.md`](docs/LOCAL-PIPELINE.md).

Run it before every push. **A push publishes.**

## Quick start from a checkout

```bash
git clone https://github.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World.git
cd A-Book-Of-Life-To-Rebuild-The-World

python scripts/install.py install   # environment, dependencies, index, verify
python scripts/serve.py             # local API and dashboard

python scripts/validate.py          # every sidecar against the schema
python scripts/build_index.py       # rebuild the search index
python scripts/new_entry.py chemistry my-experiment "My Experiment"
python scripts/new_topic.py "Textiles" --summary "Spinning, weaving and dyeing."
```

## Contributing

New entries and new topics are welcome, and there is a low-friction path for
both:

- **Propose an entry** with the [New Entry issue template](.github/ISSUE_TEMPLATE/new-entry.md).
- **Propose a topic or domain** with the [New Topic issue template](.github/ISSUE_TEMPLATE/new-topic.md).
- **Report a field test** with the [Field Test template](.github/ISSUE_TEMPLATE/field-test.md).
- **Send a pull request** directly. The [contribution guide](CONTRIBUTING.md)
  has the entry format, the sidecar schema, the writing rules and the checks
  your change must pass.

A contribution is expected to be accurate, sourced, and honest about what has
not been verified: `status: draft` is a respectable state, and a fabricated
source is not. The writing reference is [docs/ENTRIES.md](docs/ENTRIES.md); the
structure is [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Documentation

| Document | What is in it |
|----------|---------------|
| [docs/DISCLAIMER.md](docs/DISCLAIMER.md) | Warnings, limits of liability, and how to use the book safely. **Read this first.** |
| [docs/INSTALL.md](docs/INSTALL.md) | Install, update, verify, uninstall; the offline wheelhouse; troubleshooting. |
| [docs/APPS.md](docs/APPS.md) | The six front-ends, what each guarantees, how to run and test them. |
| [docs/LOCAL-PIPELINE.md](docs/LOCAL-PIPELINE.md) | The on-device CI/CD pipeline: stages, flags, flakes, cache, telemetry. |
| [docs/ENTRIES.md](docs/ENTRIES.md) | How to write an entry: structure, safety levels, difficulty, sources, verification. |
| [docs/TOPICS.md](docs/TOPICS.md) | How to propose a new domain, and how topics become entries. |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Repository layout, data flow, index, apps, SDKs, federation. |
| [docs/RELEASES.md](docs/RELEASES.md) | Release process, tags, the APK, the offline bundle, signing. |
| [docs/security/SECURITY.md](docs/security/SECURITY.md) | Reporting a security problem. |
| [docs/federation/PROTOCOL.md](docs/federation/PROTOCOL.md) | Mirroring the book across nodes. |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute, tier by tier. |
| [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | How we treat each other. |
| [governance/](governance/CHARTER.md) | Charter, roles, decision log, roadmap, continuity. |

## Repository structure

```
A-Book-Of-Life-To-Rebuild-The-World/
├── domains/          # Source of truth: one Markdown file per entry
├── sidecars/         # Machine-readable metadata, one .pnk.yaml per entry
├── schemas/          # JSON Schema for sidecars, field tests, manifests, media
├── scripts/          # Installer, pipeline, validation, indexing, SDK, MCP server
├── apps/             # Six front-ends: Python, Rust, TypeScript, Rails, pwsh, sh
├── i18n/             # UI strings in 17 languages and 16 translated corpora
├── android/          # Native Android app (Kotlin + Jetpack Compose)
├── mobile/           # React Native app
├── sdk/              # Python, TypeScript and Rust SDKs
├── simulators/       # Small offline interactive simulators
├── models/           # Printable 3D models
├── media/            # Image, audio and video assets
├── variants/         # Regional adaptations (arctic, arid, tropical)
├── field-tests/      # Field test reports
├── surveys/          # Community surveys
├── deploy/           # Docker and Raspberry Pi deployment recipes
├── docs/             # Documentation, including the disclaimer
├── governance/       # Charter, roles, decision log, continuity
└── .github/          # CI/CD, issue and pull request templates
```

## Offline deployment

```bash
# Full offline bundle (Kiwix + Ollama + maps + Kolibri)
cd deploy/docker
docker compose up -d
```

`scripts/build_bundle.py` assembles the offline bundle, `scripts/build_zim.py`
writes the ZIM archive, and `scripts/build_index.py` produces the SQLite index
with full-text and optional vector search.

## CI and releases

Every push runs validation, the Markdown and link checks, the SDK builds and
tests, the model and media builds, the i18n coverage check, the app suites and
the Android build — the same stages as the local pipeline. Releases are cut from
`v*` tags and publish the offline bundle, the ZIM archive, and a signed Android
APK. See [docs/RELEASES.md](docs/RELEASES.md).

## License

Content is licensed under [CC BY-SA 4.0](LICENSE-CONTENT) and code under
[MIT](LICENSE-CODE). Third-party sources named by an entry stay under their own
licences, which every sidecar records.

Contributions are accepted under the terms in [CONTRIBUTING.md](CONTRIBUTING.md)
and the [CLA](governance/CLA.md). Everyone who participates is expected to
follow the [Code of Conduct](CODE_OF_CONDUCT.md).
