# Architecture

Book of Life is one corpus and many surfaces. A Markdown entry and its
sidecar are the only things a human writes; every index, bundle, app
payload, SDK response and agent tool is generated from them. This document
describes how that works, and where each piece lives.

## Design goals

### Offline-first

Every surface must be useful with no network at all. The Android app ships
the whole corpus inside the APK and searches it on device. The offline
bundle is a static site and a ZIM archive. The API, the MCP server and the
RAG layer are designed to run on a local network with no egress. The
embedding model is local and CPU-only. Nothing in the reading path depends
on a remote service.

### Verifiable

Every entry carries its provenance and an honest verification status in its
sidecar: `draft`, `peer-reviewed`, `field-tested` or `deprecated`. Status
changes are recorded in an append-only ledger at
`governance/verification-ledger.jsonl`. A field test is a report in
`field-tests/`, validated against `schemas/field-test.schema.json`.

### Actionable

An entry is a procedure, not an essay. It has a fixed section order —
Overview, Prerequisites, Materials & Tools, Procedure, Safety Notes,
Verification, Sources — and carries concrete quantities: time to complete,
expected yield, cost tier, hazards, resource budget, service life,
maintenance and limits.

### Agent-readable

Each entry has a stable identifier, a `pnk:` URI, a typed sidecar and
prerequisite and link relations. Search returns ranked entries with
difficulty and safety. The MCP server exposes the corpus to an agent as six
tools.

### Forkable

The knowledge base is a plain directory of text files. A community can fork
it, translate it, merge regional variants, mark entries as verified in its
own region, and publish its own signed manifest. The federation protocol
in `docs/federation/PROTOCOL.md` lets independent nodes link, sync and
resolve each other's entries.

### The corpus is the source of truth

`domains/` and `sidecars/` are hand-written. Everything else is generated:

- `build/index.db` from `scripts/build_index.py`
- `build/offline-bundle/` from `scripts/build_zim.py`
- the Android assets from `android/tools/export_content.py`
- the per-language bundles from `scripts/build_i18n.py`
- the merged regional entries from `scripts/build_variants.py`

If a generated file disagrees with the corpus, the corpus wins and the
generated file is rebuilt. The Android pipeline enforces this in CI by
regenerating the assets and failing if the working tree differs.

### Many readers, one corpus

The six front-ends in `apps/` do not talk to each other or to a server. Each
one locates `manifest.toml`, reads `domains/` and `sidecars/` itself, parses the
sidecars without a YAML library, and searches locally. That keeps the reading
path available on a machine with one runtime and no network, and it means a
sidecar schema change is checked against every reader the machine can build.
The Android and React Native apps use the same corpus through their exported
payloads. [`APPS.md`](APPS.md) is the reference.

## Repository map

| Path | What it holds | Primary reader |
|---|---|---|
| `domains/` | One Markdown file per entry | Humans, indexer, apps |
| `sidecars/` | One `.pnk.yaml` per entry | Indexer, apps, agents |
| `schemas/` | JSON Schema for every artefact | Validators |
| `scripts/` | Build, validation and service code | Contributors, CI |
| `apps/` | Six front-ends over the same corpus: Python, Rust, TypeScript, Rails, PowerShell, POSIX shell | Readers |
| `i18n/` | UI strings and content translations | Exporter, translators |
| `android/` | Native Android app | Android users |
| `mobile/` | React Native app | Mobile users |
| `sdk/` | Python, TypeScript and Rust clients | Integrators |
| `simulators/` | Single-file HTML simulators | Learners |
| `models/` | Parametric OpenSCAD models | Makers |
| `media/` | Video and audio with metadata | Readers, apps |
| `variants/` | Regional overrides of entries | Readers in a climate |
| `field-tests/` | Field-test reports | Verifiers, dashboard |
| `surveys/` | Community survey data | Maintainers |
| `deploy/` | Docker and Raspberry Pi recipes | Operators |
| `docs/` | Disclaimer, protocol, security notes | Everyone |
| `governance/` | Charter, roles, decisions, ledger | Maintainers |
| `api/` | The OpenAPI contract | Integrators |
| `build/` | Generated output, gitignored | Nothing |
| `spec/` | The original project blueprint | Contributors |
| `tests/` | The pytest suite | Contributors |

A few directories deserve a note.

`domains/` holds sixteen domain directories and a `README.md` index in each.
The Markdown files carry the prose; the sidecar carries the metadata.

`sidecars/` mirrors the domain layout exactly, so a sidecar and its entry
are found by the same relative path in both trees. The filename stem is
identical; only the extension differs.

`i18n/` splits in two. `i18n/strings/` holds the user-interface vocabulary,
one YAML file per language. `i18n/translations/` holds translated content:
a Markdown file plus a matching `.pnk.yaml` sidecar per entry.

`variants/` holds regional overrides. A variant carries only the sections
that differ from the canonical entry, plus a sidecar naming the region, the
entry it overrides and the headings it replaces.

`governance/` holds the charter, the role matrix, the decision log, the
deprecation policy, the continuity plan, the fiscal sponsorship terms, the
rotation rules and the roadmap, along with the append-only verification
ledger.

## The entry lifecycle

### 1. Authoring

An entry is two files that must agree:

```text
domains/<domain>/<slug>.md
sidecars/<domain>/<slug>.pnk.yaml
```

The sidecar is the machine-readable half. Its schema is
`schemas/sidecar.schema.json`, a JSON Schema 2020-12 document with
`additionalProperties` set to false, so a typo in a key is an error rather
than a silently ignored field. The required keys are `id`, `title`,
`domain`, `tags`, `difficulty`, `safety`, `sources` and `verification`.

The identifier is a `pnk:` URI built from a Crockford base32 ULID, the
domain and the slug:

```text
pnk:01HZX0K8J9Q7R3VY6T2M4B8N1P/survival/making-fire
```

The ULID carries the creation time, so identifiers sort by age and never
collide across forks.

### 2. Validation

`scripts/validate.py` walks every `*.pnk.yaml` under `sidecars/`, parses
it, checks it against the schema with `jsonschema`, and confirms that the
matching Markdown file exists at the mirrored path. It fails with a
non-zero exit status and lists every error, so it can be used as a gate.

`scripts/validate_field_tests.py` does the same for the YAML reports in
`field-tests/`, against `schemas/field-test.schema.json`.

### 3. Indexing

`scripts/build_index.py` produces `build/index.db`, a SQLite database with
four tables:

| Table | Purpose |
|---|---|
| `entries` | One row per entry, with its metadata and body |
| `entries_fts` | FTS5 virtual table over title, body and tags |
| `chunks` | One row per retrieved chunk: entry, heading, text |
| `chunk_vectors` | The 32-bit float embedding of each chunk |

The `entries` table holds the id, title, domain, tags, difficulty, safety,
verification status, path and body. The FTS table is an external-content
table over `entries`, so the text is stored once, and it tokenises with
the `porter unicode61` tokenizer. Two secondary indexes cover
`entries.domain` and `chunks.entry_id`. The database runs in WAL mode.

The build also writes `build/manifest.json` with the knowledge-base
version, the entry count and the chunk count.

### 4. Chunking and embedding

`scripts/chunker.py` splits a Markdown body by heading, then splits any
section longer than 512 tokens into overlapping windows of 64 tokens. The
heading is kept with every chunk so a retrieved fragment still says where
it came from.

`scripts/embedder.py` embeds each chunk. The production path loads
`all-MiniLM-L6-v2` through ONNX Runtime from
`$BOL_MODEL_DIR` (by default `~/.cache/book-of-life`) and produces 384
dimensions. When the model file is absent — as in a CI runner with no
download — it falls back to a deterministic hash embedding so the build
still succeeds and produces identical output on every run.

`manifest.toml` declares the intended configuration in one place: heading
chunking with a 512-token cap and 64-token overlap, local 384-dimension
embeddings, FTS5 for full text, and reciprocal rank fusion with `k = 60`.
The implementation stores vectors as float blobs and scores them with a
dot product, then collapses the chunk scores to the best chunk per entry.

### 5. Retrieval

`scripts/search.py` runs the hybrid query. It takes BM25 candidates from
the FTS5 table, trying a precise AND query first and relaxing to OR when
that returns nothing. It takes vector candidates from the chunk vectors.
It fuses the two ranked lists with reciprocal rank fusion, scoring each
document as `1 / (k + rank + 1)` in each list and adding the two
contributions.

The result carries the entry id, title, domain, difficulty, safety and a
fused score.

### 6. Bundling

`scripts/build_zim.py` renders the corpus into a static site under
`build/offline-bundle/html/`: an index page, one page per domain and one
page per entry, each with difficulty, safety and verification badges and
the entry identifier in the footer. It writes a client-side search index
as `search-index.json` so the site can be searched with no server.

When `zimwriterfs` is on the path, the script also writes
`build/offline-bundle/a-book-of-life.zim` for Kiwix, and always writes
`build/offline-bundle/bundle-manifest.json`.

`scripts/build_bundle.py` is the simpler variant: static HTML plus a
`bundle-manifest.json`, and an optional `book-of-life.zim`.

### 7. Export to the Android app

`android/tools/export_content.py` reads the corpus, the UI strings and
`manifest.toml`, and writes:

```text
android/app/src/main/assets/content/entries.json
android/app/src/main/assets/content/domains.json
android/app/src/main/assets/content/meta.json
android/core/designsystem/src/main/res/values-<lang>/strings.xml
```

The exporter strips the leading title and metadata blockquote, because the
reader renders both from structured data, and strips the trailing
Verification and Sources sections for the same reason. It normalises the
source list, dropping malformed URLs rather than shipping a broken link,
and prunes prerequisite and link references that do not resolve to an
exported entry.

`meta.json` records the knowledge-base version, the entry and domain
counts and a `contentHash` — the first sixteen hex characters of the
SHA-256 of `entries.json`. The importer re-imports whenever the version,
the entry count or the hash changes, so a content refresh is picked up even
when the version was not bumped.

The generated files are committed, and CI regenerates them and fails if the
working tree differs.

### 8. Consumption

| Consumer | Reads |
|---|---|
| `scripts/serve.py` | `build/index.db` |
| `scripts/mcp_server.py` | `build/index.db`, `sidecars/`, `domains/` |
| `scripts/rag.py` | The search index and the entry bodies |
| `scripts/dashboard.py` | `build/index.db`, `sidecars/`, `field-tests/` |
| `scripts/federation.py` | `sidecars/`, `domains/` |
| The Android app | The exported assets |
| The React Native app | A server, or a preloaded SQLite file |
| The SDKs | The HTTP API |

## Build and release pipeline

Each script produces one artefact and is driven by one workflow.

| Script | Produces | Runs in |
|---|---|---|
| `scripts/validate.py` | Sidecar validation report | `ci.yml` |
| `scripts/validate_field_tests.py` | Field-test validation report | `ci.yml` |
| `scripts/build_index.py` | `build/index.db` | `ci.yml`, `release.yml` |
| `scripts/dashboard.py` | `build/dashboard.html` | `ci.yml` |
| `scripts/build_models.py` | `build/models/*.stl` | `ci.yml` |
| `scripts/build_media.py` | `build/media-index.json` | `ci.yml` |
| `scripts/validate_i18n.py` | Coverage report | `ci.yml` |
| `scripts/build_i18n.py` | `build/i18n/<lang>.json` | `ci.yml` |
| `scripts/build_variants.py` | `build/variants/` | `ci.yml` |
| `scripts/build_zim.py` | `build/offline-bundle/` (HTML, search index, ZIM) | Local pipeline, `release.yml` |
| `scripts/build_bundle.py` | Delegates to `build_zim.py` | Local pipeline (`bundle` stage) |
| `android/tools/export_content.py` | Android assets | `android.yml` |
| `scripts/state_of_the_book.py` | `build/reports/` | `ci.yml` |
| `scripts/archive.py` | `build/archive/` | `archive.yml` |

`scripts/local_pipeline.py` is the same sequence on the machine you are sitting
at: fourteen stages, dependency-aware scheduling, flake absorption, per-stage
logs and telemetry, and a cache that only applies to artifact stages. It is the
gate a contributor runs before a push, and the installer wires it into
`.git/hooks/pre-push` with `scripts/install_hooks.py`. The apps in `apps/` are
tested by its `apps` stage; see [`APPS.md`](APPS.md) and
[`LOCAL-PIPELINE.md`](LOCAL-PIPELINE.md).

`ci.yml` runs on every push and pull request to `main`. It has a
`validate` job that validates the sidecars and the field tests, builds the
index and the dashboard, runs the test suite and uploads the index as an
artefact. Separate jobs cover Markdown linting over `domains/**/*.md`, the
link check, the model build (which needs OpenSCAD), the media build, the
i18n coverage check and build, the variant build, the simulator HTML
well-formedness check, the three SDK builds and test suites, the federation
identity check, the annual state-of-the-book report, and structural checks
for the changelog, the governance files, the funding file and
`CODEOWNERS`.

`android.yml` runs when `android/`, `domains/`, `sidecars/`, `i18n/` or
`manifest.toml` change. It regenerates the content assets, verifies that
they are committed, runs the JVM unit tests and assembles a debug APK.

`android-emulator.yml` runs the Compose instrumentation suite on an
emulator matrix covering API 26, 31 and 35.

`release.yml` and `android-release.yml` both trigger on a `v*` tag and are
described in `docs/RELEASES.md`.

`archive.yml` runs on a schedule and on demand, archiving the corpus to the
Internet Archive, Zenodo and Software Heritage.

## The surfaces

### The Android app

`android/` is a multi-module Gradle project. The modules are declared in
`android/settings.gradle.kts`:

| Module | Responsibility |
|---|---|
| `:app` | Application class, navigation, dependency wiring |
| `:core:common` | Dispatchers, text utilities |
| `:core:model` | Pure-Kotlin domain models |
| `:core:designsystem` | Theme, components, shared UI strings |
| `:core:data` | Room, DataStore, importer, search engine |
| `:feature:home` | Library, domains, continue reading |
| `:feature:search` | Search and filters |
| `:feature:reader` | Markdown reader, bookmarks, share |
| `:feature:bookmarks` | Saved entries |
| `:feature:settings` | Appearance, reading, content, app updates |

Injection is by Hilt. Storage is Room 2.6 with DataStore Preferences for
settings and `kotlinx.serialization` for the wire format. The UI is
Jetpack Compose with Material 3 and Navigation Compose; the Markdown
renderer uses `org.jetbrains:markdown` in GitHub flavour mode. The
toolchain is Kotlin 2.0.21, AGP 8.7.3, JDK 17, `minSdk 26`,
`targetSdk 35` and `compileSdk 35`, on Gradle 8.9.

Search runs entirely on device. `SearchEngine` takes lexical candidates
from a Room FTS4 table using prefix queries, re-scores them with BM25,
adds a second TF-IDF cosine signal, and fuses the two rankings with
reciprocal rank fusion. The in-memory index is built once, cached behind a
mutex, and invalidated when the content is re-imported. Results carry a
snippet with the matched terms highlighted, and can be filtered by domain,
difficulty and safety.

The app is fully usable with no network. The corpus is bundled as assets,
imported into Room on first launch, and every read and every query is
local. The only network call in the app is the optional update check
described in `docs/RELEASES.md`.

Eight UI translations — Arabic, German, Spanish, French, Hindi,
Portuguese, Swahili and Chinese — are generated from `i18n/strings/*.yaml`
into `values-<lang>/strings.xml` inside the design-system module, and are
selectable through Android's per-app language settings.

### The React Native app

`mobile/` is a React Native 0.75 shell for the same content. It uses
`react-native-sqlite-storage` with an FTS4 table for local search,
AsyncStorage for preferences and React Navigation for the stack. It has
two screens, Home and Entry, and a sync module that pages through
`/entries` and `/entries/{id}` on a server and upserts each entry into the
local database. The local SQLite file is a cache; the corpus remains the
source of truth.

## SDKs and the API

### The contract

`api/openapi.yaml` is the public contract. It is an OpenAPI 3.1.0
document describing thirteen endpoints under six tags — search, entries,
verification, governance, federation and system — including the search
filters, the cursor-paginated entry list, the link graph, the verification
record and ledger, and the federation manifest, resolve and peers calls.
It names two server environments: a rate-limited hosted mirror and an
unlimited local deployment.

### The three SDKs

| SDK | Package | Source layout |
|---|---|---|
| Python | `abook-sdk` | `abook/` |
| TypeScript | `@abookoflife/sdk` | `src/` |
| Rust | `abook` | `src/` |

The Python package holds `client.py`, `models.py`, `errors.py` and
`pnk.py`; the TypeScript package holds the same four modules under
`src/`; the Rust crate holds `client.rs`, `models.rs`, `error.rs` and
`pnk.rs`.

The Python SDK is a hatchling package requiring Python 3.10 or newer, with
a synchronous `Client` and an asynchronous `AsyncClient` over `httpx`. The
TypeScript SDK is an ESM package built with `tsc` and tested with
`vitest`. The Rust SDK is a Tokio crate using `reqwest` with rustls. All
three mirror the endpoint set in the OpenAPI document, including the
pagination cursor on the entry list.

### The MCP server

`scripts/mcp_server.py` runs over stdio and exposes six tools to an agent:

| Tool | Returns |
|---|---|
| `abook_search` | Ranked entries with title, domain, difficulty and safety |
| `abook_get` | The full Markdown body and the sidecar for one entry |
| `abook_linked` | Outgoing and incoming links for one entry |
| `abook_verify` | Verification status, reviewers, date and location |
| `abook_list_domains` | Every domain with its entry count and description |
| `abook_stats` | Totals and breakdowns by verification, difficulty, safety |

Search accepts an optional domain filter and a limit between 1 and 50.
`abook_search` and `abook_stats` need the index; `abook_get`,
`abook_linked` and `abook_verify` read the sidecars directly, so they work
even when the index has not been built.

### The local server

`scripts/serve.py` is a FastAPI application for local use. It exposes
`/health`, `/search`, `/entry/{entry_id}`, `/verify/{entry_id}`,
`/field-tests`, `/ledger`, `/stats`, `/dashboard` and a small HTML index.
Its paths are the local development shape and do not match the public
OpenAPI paths one for one; the OpenAPI document is the contract that the
SDKs and the deployed API implement.

### The RAG layer

`scripts/rag.py` retrieves with the hybrid index and generates with a local
Ollama model. Its system prompt constrains the model to answer only from
the retrieved context, to cite every claim with the entry identifier, and
to say so explicitly when the context does not contain the answer.

## Internationalisation

### Two directories, two jobs

`i18n/strings/<lang>.yaml` holds the user-interface vocabulary: the site
name, the search placeholder, the section names, the status labels and the
safety labels. `en.yaml` is the canonical file and defines 21 keys.

`i18n/translations/<lang>/<domain>/<slug>.md` holds translated content,
with a matching `.pnk.yaml` sidecar that names the original entry in
`translation_of`. The exporter and the validator read both.

### Coverage targets

`scripts/validate_i18n.py` carries the target for each language:

| Language | Target |
|---|---|
| `es`, `fr`, `de`, `pt` | 100% |
| `hi`, `ar`, `zh` | 80% |
| `sw` | 60% |

Coverage is the share of canonical entries that have a translation. The
nine languages named in `manifest.toml` are `en`, `es`, `fr`, `de`, `hi`,
`ar`, `sw`, `zh` and `ja`; the translation toolchain currently tracks the
eight languages other than English.

### What the validator enforces

`scripts/validate_i18n.py` fails the build when a language is missing its
UI string file, when that file is missing any key present in `en.yaml`,
when a translation sidecar does not satisfy the sidecar schema, when a
`translation_of` identifier does not exist in the canonical set, or when
the measured coverage is below the target for that language. It prints the
measured coverage for every language before it reports.

`scripts/build_i18n.py` writes `build/i18n/<lang>.json` for each language
with its UI strings and its translated entry list, plus a
`build/i18n/manifest.json` summarising the counts.

## Federation

### Identity

Every node that publishes a federation manifest has a `node_id` — a ULID
generated on first use — and an Ed25519 keypair. `scripts/federation.py`
creates them on demand and stores them in
`governance/federation/identity.json` with restrictive file permissions.
The private key never leaves the node; the public key is published in the
manifest so peers can verify what the node signs.

### Identifiers

Two URI forms are defined. The bare form is stable across every knowledge
base that holds the entry:

```text
pnk:<ulid>/<domain>/<slug>
```

The node-scoped form names the node that authoritatively hosts an entry
that is unique to it:

```text
pnk://<node_id>/<domain>/<slug>
```

A client resolves a URI locally first, then asks each known peer, and
caches the answer.

### Mirroring in practice

Mirroring is a sync, not a copy of the repository.

1. A node publishes a signed sync manifest: every entry with its id,
   title, domain, difficulty, safety, verification status, update date and
   the SHA-256 hash of its body. The signature is Ed25519 over the
   canonical JSON of the entry list.
2. The syncing node fetches the manifest and verifies the signature
   against the peer's published public key. An unsigned manifest is
   rejected.
3. It computes what to fetch: entries it does not have, and entries whose
   remote verification rank is higher than its own. The ranks are
   `field-tested` above `peer-reviewed` above `draft`, with `deprecated`
   lowest.
4. It fetches each entry, checks the body against the manifest hash, and
   merges it into `domains/` and `sidecars/`.
5. It appends a record to the peer ledger.

The command line is `scripts/federation.py`, with the sub-commands
`identity`, `manifest`, `add-peer`, `sync`, `resolve` and `ledger`.
`--dry-run` reports what would change without writing anything.

### Trust

Peers are marked `trusted`, `neutral` or `untrusted`. An untrusted peer is
never contacted. A trusted peer is merged automatically. A neutral peer is
fetched, but its entries are demoted to `draft` on arrival until a local
verifier signs off. Trust is stored locally in
`governance/federation/peers.yaml` and is not transitive.

The protocol never destroys an entry. Where two nodes disagree at the same
verification rank, the conflict is counted and left for a human.

## Extending the system

### Add a domain

```bash
python scripts/new_topic.py ceramics --title "Ceramics & Glass" \
    --description "Clay bodies, glazes, kiln design and testing"
```

The script creates `domains/<slug>/README.md` and `sidecars/<slug>/`, and
registers the domain in `schemas/sidecar.schema.json`, `manifest.toml`,
`api/openapi.yaml`, `scripts/mcp_server.py`,
`android/tools/export_content.py` and `domains/README.md`. It never
overwrites an existing registration and it prints everything it touched.

### Add an entry

```bash
python scripts/new_entry.py chemistry my-experiment "My Experiment"
```

The script writes `domains/<domain>/<slug>.md` with the standard section
order and the reference notice, and `sidecars/<domain>/<slug>.pnk.yaml`
with a fresh identifier and `draft` status. It is a starting point, not a
finished entry. Fill it in, then run `python scripts/validate.py` and
`python scripts/build_index.py`.

### Add a language

1. Add `i18n/strings/<lang>.yaml` with every key present in `en.yaml`.
2. Add the language to `LANGS` and to `COVERAGE_TARGETS` in
   `scripts/validate_i18n.py` and `scripts/build_i18n.py`.
3. Add the language to `supported_languages` in `manifest.toml`.
4. Translate content into `i18n/translations/<lang>/`, with a sidecar
   naming the original in `translation_of`.

The Android exporter picks up the new string file with no further change
and writes `values-<lang>/strings.xml`.

### Add a simulator

A simulator is a single HTML file in `simulators/` with inline CSS and
JavaScript and no network dependency. CI checks that each file has a
doctype and a closing `html` tag. Add a row to the table in
`simulators/README.md` naming the entry it explains.

### Add a 3D model

A model is a parametric OpenSCAD file under `models/<domain>/`.
`scripts/build_models.py` exports every `.scad` file to binary STL under
`build/models/` and writes `build/models-manifest.json`. Without OpenSCAD
on the path the script still writes the manifest and reports that no STL
was produced. Link the model from an entry through the `media` list in its
sidecar.

### Add a field test

A field test is a YAML report in `field-tests/` that satisfies
`schemas/field-test.schema.json`. It records the tester, the date, the
location, the conditions, the deviations from the written procedure, the
results, any measurements, the failure modes and the safety observations.
Validate it with `python scripts/validate_field_tests.py`, then advance
the entry with `scripts/verify.py advance <entry_id> --to field-tested
--actor <you> --field-test-id <id>`. The transition refuses to run
without a matching report, and `scripts/verify.py` appends the event to
the verification ledger.

## Where things live

| Task | File |
|---|---|
| Add an entry | `scripts/new_entry.py` |
| Add a domain | `scripts/new_topic.py` |
| Validate sidecars | `scripts/validate.py` |
| Validate field tests | `scripts/validate_field_tests.py` |
| Build the search index | `scripts/build_index.py` |
| Query the index | `scripts/search.py` |
| Serve the local API | `scripts/serve.py` |
| Expose the book to an agent | `scripts/mcp_server.py` |
| Answer with citations | `scripts/rag.py` |
| Advance verification status | `scripts/verify.py` |
| Build the verification dashboard | `scripts/dashboard.py` |
| Build the offline site and ZIM | `scripts/build_zim.py` |
| Build the simpler offline bundle | `scripts/build_bundle.py` |
| Export the Android content | `android/tools/export_content.py` |
| Build the Android APK | `android/gradlew` |
| Build the 3D models | `scripts/build_models.py` |
| Index the media | `scripts/build_media.py` |
| Merge the regional variants | `scripts/build_variants.py` |
| Check translation coverage | `scripts/validate_i18n.py` |
| Build the language bundles | `scripts/build_i18n.py` |
| Sync with a peer node | `scripts/federation.py` |
| Write the annual report | `scripts/state_of_the_book.py` |
| Bump the version | `scripts/bump_version.py` |
| Archive the corpus | `scripts/archive.py` |
| Publish a release | `.github/workflows/release.yml` |
| Publish the Android release | `.github/workflows/android-release.yml` |
