# Contributing to Book of Life

Thank you for helping rebuild civilization. This guide explains how to
contribute, from a one-line typo fix to a whole new domain.

> [!IMPORTANT]
> Everything you contribute is published. Read
> [docs/DISCLAIMER.md](docs/DISCLAIMER.md) first: your contribution will carry
> the same reference-only, verify-before-use, no-warranty terms as the rest of
> the book, and it must not give medical, legal, engineering or safety advice.

## Ways to contribute

| I want to… | Do this |
|-------------|---------|
| Fix a typo or a wrong number | Open a pull request against the Markdown file. |
| Report something dangerous or wrong | Open an issue and say so in the title. |
| Propose a new **entry** | Use the [New Entry issue template](.github/ISSUE_TEMPLATE/new-entry.md). |
| Propose a new **topic** (a whole subject area) | Use the [New Topic issue template](.github/ISSUE_TEMPLATE/new-topic.md). |
| Translate an entry | Follow the workflow in [`i18n/README.md`](i18n/README.md) and open a pull request. |
| Report that you tried a procedure | Use the [Field Test template](.github/ISSUE_TEMPLATE/field-test.md). |
| Contribute code | Open a pull request. See [Code](#code) below. |

Nothing here needs an invitation. The most useful contribution is usually a
correction backed by a source, and the second most useful is a report that a
procedure did not work as written.

## Contribution tiers

| Tier | Role | Permissions |
|------|------|-------------|
| Reader | Browse, search, download | Public |
| Contributor | Submit pull requests for content and translations | Signed CLA |
| Verifier | Field-test entries, move them to `field-tested` | Nominated by maintainers |
| Domain Maintainer | Review pull requests for a domain | Elected per domain |
| Core Maintainer | Release management, architecture | Consensus of maintainers |

The CLA is in [`governance/CLA.md`](governance/CLA.md). It is a short
copyright-and-licence statement; by opening a pull request you confirm that
you have the right to license what you send, and that your contribution is
published under CC BY-SA 4.0 (content) or MIT (code).

The CLA bot comments on your first pull request and records your confirmation
in [`governance/cla-signatures.json`](governance/cla-signatures.json).

## Proposing a new entry

1. Check that the subject is not already covered. Search the domain index in
   `domains/<domain>/README.md`, then search the whole book.
2. Open an issue with the [New Entry template](.github/ISSUE_TEMPLATE/new-entry.md).
   Give the domain, the title, one paragraph on what the entry enables, the
   sources you would use, and the safety level you think it deserves.
3. A domain maintainer or a core maintainer responds, usually within a week.
   They may ask for a different domain, a narrower scope, a different safety
   level, or a source that is easier to check.
4. If the proposal is accepted, open a pull request with the entry and its
   sidecar.

### Scaffolding

```bash
# Creates domains/<domain>/<slug>.md and sidecars/<domain>/<slug>.pnk.yaml
python scripts/new_entry.py chemistry my-experiment "My Experiment"

# Creates a new domain: directory, README index, schema and manifest entries
python scripts/new_topic.py ceramics --title "Ceramics & Glass" \
    --description "Clay bodies, glazes, kiln design and testing"
```

Both scripts print the files they created. Nothing else in the repository
needs to change by hand.

## Proposing a new topic

A **topic** is a subject area that deserves its own domain: a field with its
own vocabulary, its own sources and its own safety profile. `chemistry`,
`silicon`, `ship` and `quantum` were all added this way.

Read [docs/TOPICS.md](docs/TOPICS.md) for the criteria a topic must meet and
the process it goes through. In short:

1. Open an issue with the [New Topic template](.github/ISSUE_TEMPLATE/new-topic.md).
2. Describe the subject, who needs it, what a reader should be able to do
   after reading it, and which sources would back it.
3. The maintainers accept or decline the topic, and agree which domain it
   belongs to — new domain or existing one.
4. Accepted topics are scaffolded with `scripts/new_topic.py`, which adds the
   domain to the schema, the manifest, the search service and the app.
5. The first entries are written, reviewed and merged.

## Writing an entry

The full reference is in [docs/ENTRIES.md](docs/ENTRIES.md). The short
version:

- Every entry needs a Markdown file and a sidecar. The sidecar is the
  machine-readable half; the Markdown is the human-readable half. They must
  agree.
- Every entry uses the same section order: Overview, Prerequisites, Materials
  & Tools, Procedure, Safety Notes, Verification, Sources.
- Every claim needs a source you have actually read. Record the licence.
- Safety is graded `green`, `yellow` or `red`. Grade it honestly and, for
  `red`, state what training, supervision, equipment and authorisation the
  work needs.
- Difficulty is graded `novice`, `apprentice`, `journeyman` or `master`.
- Write plainly. Short sentences. Concrete nouns. Numbers with units. No
  marketing tone, no filler, no "it is important to note that".
- Never give medical, legal, financial or engineering advice. Describe the
  procedure and the hazard, and point to the qualified person who decides.
- Do not invent citations, URLs, measurements or standards. If you do not
  know, say so in the entry and mark it `draft`.

## Translation

The interface ships in 17 languages and the entries are translated into 16 of
them, each with a coverage target. UI strings live in
`i18n/strings/<lang>.yaml`; content translations live in
`i18n/translations/<lang>/<domain>/<slug>.md` with a matching
`.pnk.yaml` sidecar.

- Keep the section order and the heading levels of the English original.
- Keep numbers, units, standard numbers and safety levels exactly as they
  are. Translate the words around them, never the values.
- Keep the em dashes and the "—" placeholders in the Verification block.
- A translation may be shorter than the original if the language is more
  compact, but it must not omit a step or a hazard.
- Coverage is checked by `python scripts/validate_i18n.py`, which fails when a
  language drops below its target. The targets and the current coverage are in
  [`i18n/README.md`](i18n/README.md).

Sources do not have to wait for a translation. Every entry cites sources in
several languages and records the language of each one, so a reader of an
untranslated entry can still follow the trail. Adding a source in a new
language is a useful contribution on its own; see the sources section of
[docs/ENTRIES.md](docs/ENTRIES.md).

## Code

- The Python code targets 3.11 and is checked with `ruff`.
- The Android code targets Kotlin 2.0, Compose BOM 2024.10, JDK 17, and is
  checked with `gradlew test` and `gradlew assembleDebug`.
- The SDKs are generated from the OpenAPI description in `api/openapi.yaml`.
  Do not hand-edit generated code.
- Keep the project offline-first. A change that makes the app require a
  network connection to read the book is a change that will be asked about.

### The six front-ends

`apps/` holds six independent readers of the same corpus, in six toolchains:
Python/`tkinter`, Rust/`egui`, TypeScript, Rails, PowerShell and POSIX `sh`.
They exist so that no single dependency can lock a reader out of the book, so a
change to the corpus or to the sidecar schema may need a matching change in
several of them.

- [docs/APPS.md](docs/APPS.md) explains what each app guarantees, how to run it
  and how to add a seventh.
- Each app has its own test suite. A new app is welcome if it reads the corpus
  from disk, parses the sidecars without guessing, honours `language` with an
  English fallback, shows the safety level and the reference-material notice,
  and can be tested with one command from the repository root.
- A shared rule is tested six times on purpose: if you change how a sidecar is
  read, expect the same change in every app that reads it.

### Checks your change must pass

```bash
python scripts/validate.py            # sidecars against the schema
python scripts/build_index.py         # the search index builds
python scripts/validate_i18n.py       # translation coverage
python -m pytest -q                   # the test suite
python -m ruff check .                # lint
npx markdownlint-cli2 "domains/**/*.md"
```

That is the list by hand. The same checks, plus the app suites and the Android
build, run as one command:

```bash
python scripts/local_pipeline.py          # every stage
python scripts/local_pipeline.py --fast   # skip the slow stages
python scripts/local_pipeline.py --stage apps
```

Run it before you push. **A push publishes**: the `pre-push` hook runs the same
pipeline, and only a green run is deployed. A stage that fails under load and
passes when re-run serially is reported as a flake, never hidden; a real
failure stops the run and names its log in `logs/local_pipeline/`. See
[docs/LOCAL-PIPELINE.md](docs/LOCAL-PIPELINE.md).

If you have not set up a checkout yet, [docs/INSTALL.md](docs/INSTALL.md) has
the one-command installer, the update path and the offline wheelhouse.

## Documentation map

| Document | What is in it |
|----------|---------------|
| [docs/DISCLAIMER.md](docs/DISCLAIMER.md) | Warnings and limits of liability. Read it first. |
| [docs/INSTALL.md](docs/INSTALL.md) | Install, update, verify, uninstall. |
| [docs/APPS.md](docs/APPS.md) | The six front-ends. |
| [docs/LOCAL-PIPELINE.md](docs/LOCAL-PIPELINE.md) | The on-device pipeline. |
| [docs/ENTRIES.md](docs/ENTRIES.md) | How to write an entry. |
| [docs/TOPICS.md](docs/TOPICS.md) | How to propose a topic. |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | How the repository fits together. |
| [docs/RELEASES.md](docs/RELEASES.md) | How a release is cut. |

## Verification lifecycle

1. **Draft** — unverified. What most entries are.
2. **Peer-Reviewed** — two contributors have read the entry for accuracy
   against its sources. This is a reading, not a test.
3. **Field-Tested** — at least one verifier carried out the procedure and
   filed a report in `field-tests/`.
4. **Deprecated** — superseded by a better method. The entry stays, with a
   pointer to its replacement.

Verification status is a statement about the review, never a warranty. See
[docs/DISCLAIMER.md](docs/DISCLAIMER.md) section 6.

## Code of conduct

All contributors must follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## Licence of contributions

By contributing you agree that your content is licensed under CC BY-SA 4.0
(see [LICENSE-CONTENT](LICENSE-CONTENT)) and your code under MIT (see
[LICENSE-CODE](LICENSE-CODE)). You keep your copyright. You confirm that you
have the right to license what you send, and that it does not infringe
anyone else's rights.

## What we will not merge

- Entries that give medical, legal, financial or engineering advice.
- Entries with a safety level that is too low for the work described.
- Uncited claims presented as fact, or citations the contributor has not read.
- Copied text from a source whose licence does not allow it.
- Procedural instructions for work that is illegal in most places, or that
  the contributor cannot describe responsibly.
- Generated bulk content that no person has read.
