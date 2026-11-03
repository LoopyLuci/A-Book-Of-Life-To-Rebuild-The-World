# Releases

A release is a tag and the artefacts published from it. This document
covers what a release is, how versions work, what the release workflows
produce, how a reader updates, how to check a release before it goes out,
and what to do when one goes out wrong.

## What a release is

A release is a git tag on `main` plus the artefacts published from that
tag. The tag is both the trigger and the approval: pushing a tag that
matches `v*` starts the release workflows, and nothing is published from
a branch, a pull request or a schedule.

What the tag publishes is real, immediately usable software:

- A signed Android APK that anyone can download and install.
- A ZIM archive that Kiwix can open.
- The hybrid search index as a SQLite database.
- A bootable Raspberry Pi image.
- Three container images for the API, the MCP server and the RAG service.

Because a tag reaches users, it is pushed only with the owner's
agreement. Under the governance charter, cutting a release is a Core
Maintainer responsibility, decided by rough consensus after a seven-day
comment period, and Core Maintainers are between three and nine in number.
The role matrix in `governance/ROLES.md` reserves the right to cut a
release to that role alone.

The corpus is forkable, and so is the release. A fork may tag and publish
under its own name. `manifest.toml` carries the project version, the
Android exporter writes it into `meta.json`, and the reader shows it under
Settings, so a reader can always tell which knowledge-base snapshot a
build was made from.

## The version scheme

### Where the version lives

`manifest.toml` holds the project version under `[project] version`. It is
currently `0.1.0-alpha`. The knowledge-base schema version is separate:
`[knowledge_base] schema_version` is `1.2.0`, and it versions the
sidecar schema rather than the content.

`scripts/bump_version.py` writes the version into every manifest that
carries one:

```text
manifest.toml
pyproject.toml
sdk/python/pyproject.toml
sdk/typescript/package.json
sdk/rust/Cargo.toml
mobile/package.json
```

Run it as `python scripts/bump_version.py 1.1.0`, or as
`make bump-version VERSION=1.1.0`.

### How the Android version is derived

`android/app/build.gradle.kts` reads the version out of the root
`manifest.toml` with a regular expression and uses it twice.

`versionName` is the version string verbatim, including any pre-release
suffix, so the reader sees `0.1.0-alpha` in Settings.

`versionCode` is computed from the numeric part before the suffix:

```text
versionCode = major * 10000 + minor * 100 + patch
```

So `1.2.3` becomes `10203`, and `0.1.0` becomes `100`. The suffix is
stripped before the arithmetic, so `1.2.3-alpha` and `1.2.3` share the
code `10203`. Play requires `versionCode` to rise for every upload, so
the patch number is the counter that has to move.

### Tag names

Releases are tagged `v*`, for example `v1.0.0`. The tag name is used
verbatim in the APK asset name and as the container image tag, so it is
worth keeping it identical to the version in `manifest.toml`.

## The release workflows

Two workflows trigger on a `v*` tag. Both run at the same time and both
attach their artefacts to the release for that tag.

### The Android release

`.github/workflows/android-release.yml` runs on a pushed `v*` tag with
`contents: write` permission. It:

1. Checks out the repository, sets up JDK 17 and Python 3.11, and
   installs `PyYAML`.
2. Regenerates the app content assets with
   `android/tools/export_content.py`, so the APK is built from the tagged
   corpus and not from a stale export.
3. Decodes the release keystore: it reads the base64-encoded keystore
   from the `ABOOK_RELEASE_KEYSTORE_BASE64` secret and writes it to a
   temporary `release.jks`. If the secret is not set, the step fails with
   an explicit error rather than silently building an unsigned package.
4. Runs the JVM unit tests with `./gradlew test`.
5. Assembles the release APK with `./gradlew assembleRelease`, passing the
   keystore location and the three credentials.
6. Stages the artefact as `abook-of-life-<tag>.apk`.
7. Creates the GitHub release with `gh release create`, attaching that
   APK and generating the release notes.

The repository secrets it needs are:

| Secret | Purpose |
|---|---|
| `ABOOK_RELEASE_KEYSTORE_BASE64` | The base64-encoded release keystore |
| `ABOOK_RELEASE_STORE_PASSWORD` | The keystore password |
| `ABOOK_RELEASE_KEY_ALIAS` | The key alias |
| `ABOOK_RELEASE_KEY_PASSWORD` | The key password |

The release build is minified with R8 and shrinks resources. If no release
keystore is configured, the Gradle build falls back to the debug signing
key, which is useful for local verification and is never valid for
distribution.

### The offline release

`.github/workflows/release.yml` runs on a pushed `v*` tag with
`contents: write` and `packages: write`. It has five jobs.

| Job | Does | Produces |
|---|---|---|
| `build-index` | Validates and builds the index | `index.db` |
| `build-offline-bundle` | Builds the ZIM bundle | the ZIM, the manifest |
| `build-images` | Pushes the container images | `api`, `mcp`, `rag` |
| `build-pi-image` | Builds the Pi image | `a-book-of-life.img.xz` |
| `publish-release` | Attaches the artefacts | the release page |

The bundle job installs `zim-tools` and runs `scripts/build_zim.py`. That
script skips the ZIM when `zimwriterfs` is not on the path, so the
absence of the ZIM asset on the release page means the tool was missing
in the runner, not that the build failed.

The images job pushes three tags each, the release tag and `latest`:

```text
ghcr.io/<repository>/api:<tag>
ghcr.io/<repository>/mcp:<tag>
ghcr.io/<repository>/rag:<tag>
```

The publish job downloads the artefacts and attaches them with the
release action, generating the notes. The exact asset names on the
release page are:

| Asset | What it is |
|---|---|
| `index.db` | The hybrid search index, SQLite FTS5 plus vectors |
| `a-book-of-life.zim` | The offline browsable archive for Kiwix |
| `bundle-manifest.json` | The manifest for the offline bundle |
| `a-book-of-life.img.xz` | The bootable Raspberry Pi image |
| `abook-of-life-v<tag>.apk` | The signed Android package |

The `index.db`, the ZIM and the bundle manifest come from the Release
workflow; the APK comes from the Android release workflow.

## Updating an app that was installed by hand

The app can fetch and install a newer build, but only when the reader
asks it to. Nothing happens in the background and nothing is installed
without a confirmation.

### The steps in the app

1. The reader opens Settings, then App updates, and taps "Check for
   updates".
2. The app asks the GitHub Releases API for the latest published release
   of the project repository. The owner and repository names are string
   resources, so a fork can point the check at its own repository. The
   request uses a 15-second connect timeout and a 20-second read timeout.
3. A draft release is refused. The app looks for the first asset whose
   name ends in `.apk` and that has a download URL; if the release has no
   package, the check fails with a plain message.
4. The release tag is compared with the installed `versionName`. The
   comparison strips a leading `v` and any pre-release suffix, and a
   build with no suffix sorts as newer than one with a suffix. If the tag
   is not newer, the app reports that it is up to date and names the
   newest release it found.
5. If a newer build exists, the reader taps "Download update". The
   transfer is handed to the platform download service, so it continues
   after the app is closed and the platform reports it in the notification
   shade. The file is stored as `abook-of-life-<tag without the leading
   v>.apk` in the app's own downloads directory.
6. The download identifier and the release tag are persisted, so a
   download started before a restart is picked up again rather than
   restarted.
7. When the package is on disk, the state becomes "Update downloaded" and
   the reader taps "Install update".

### What the reader has to consent to

Two separate consents stand between the download and the installed build.

The app needs permission to install packages at all. Before the installer
can be opened, the app checks whether the platform will let it request
package installation. If the permission has not been granted, the app
sends the reader to the system "install unknown apps" screen for this app,
and the reader has to grant it there. Android may also ask the reader
whether this application is allowed to install packages.

The platform installer always appears. The app hands the downloaded
package to the system installer with a view intent and a provider URI.
The system installer displays it, and the reader confirms. Android never
allows an application to install another package silently, and this app
does not attempt it.

So the sequence of consents is: ask the reader to check, ask the reader to
download, ask the reader to allow package installation, and ask the reader
to confirm in the system installer. Every one of them is a deliberate act
by a person.

A reader who prefers to install by hand can use "Save APK to Downloads"
or "Share app" under Settings to pass the package to another device
instead.

## The release checklist

### 1. Bump the version

```bash
python scripts/bump_version.py 1.1.0
```

Commit the result. The Android `versionCode` follows from it, and the
container images are tagged with the tag name.

### 2. Write the changelog entry

Add the entry under the `## [Unreleased]` heading in `CHANGELOG.md`. The
CI workflow greps for that heading, so the section must exist. When the
tag is cut, move the entry into a `## [1.1.0] - <date>` section.

### 3. Regenerate the Android assets

```bash
python android/tools/export_content.py
```

Commit the regenerated files. The Android workflow regenerates them
again and fails if the working tree differs, so a stale export fails the
build rather than shipping an old corpus.

### 4. Run the full local test run

The one command that runs every check is the local pipeline; the list below is
what it runs, for when you need to re-run one piece by hand.

```bash
python scripts/local_pipeline.py     # preflight, validate, lint, markdown,
                                     # i18n, tests, index, media, models,
                                     # variants, bundle, sdk, apps, android
```

```bash
python scripts/validate.py
python scripts/validate_field_tests.py
python scripts/build_index.py
python scripts/validate_i18n.py
python scripts/build_i18n.py
python scripts/build_variants.py
python scripts/build_media.py
python scripts/build_models.py
python -m pytest -q
python -m ruff check .
npx markdownlint-cli2 "domains/**/*.md"
```

Every one of these has to pass. The build models step needs OpenSCAD on
the path to produce STL files; without it the step reports the sources it
found and writes the manifest, which is not a failure.

### 5. Wait for the pipeline to go green

The CI workflow must be green on the commit you are about to tag. The
Android workflow only runs when `android/`, `domains/`, `sidecars/`,
`i18n/` or `manifest.toml` change, so check that it ran for this commit
and not only for the last one that touched those paths.

### 6. Tag and push

```bash
git tag v1.1.0
git push origin v1.1.0
```

This is the moment the release reaches users. Do it only with the owner's
agreement.

### 7. Verify the release

- The release page carries all five assets: `index.db`,
  `a-book-of-life.zim`, `bundle-manifest.json`,
  `a-book-of-life.img.xz` and `abook-of-life-v1.1.0.apk`. The two
  workflows run in parallel, so check that neither was left out; the
  Android workflow's release creation step fails if a release for the tag
  already exists, and the bundle job can publish without the ZIM when
  `zimwriterfs` is missing from the runner.
- The three container images exist for the tag and for `latest`.
- Install the APK on a device, open it, and check that the knowledge-base
  version under Settings matches the tag and that the entry count is the
  one you expect.
- Turn the network off on that device and search for something. The book
  must still work.
- The entry count in `bundle-manifest.json` matches the corpus.

## Rolling back a bad release

### A rollback is a new release

A published release is already in people's hands. A tag is immutable, and
both release workflows key off the tag name, so the same tag cannot be
re-cut. Rolling back means shipping a correction.

### The procedure

1. Assess it. If the release introduced a dangerous instruction, a wrong
   safety level or a broken procedure, treat it as a safety issue before
   anything else.
2. Correct the corpus. Edit the Markdown and the sidecar. If the entry is
   no longer safe to follow, mark it `deprecated` in the sidecar and
   prefix the body with the deprecation banner. The deprecation policy in
   `governance/DEPRECATION.md` sets out the whole process: a deprecate
   issue, review by a Domain Maintainer within fourteen days, the status
   change, the banner, a link to the replacement, an event in the
   verification ledger, and the entry stays published for twelve months
   before archival.
3. Republish. Cut a patch release with the correction, even if other work
   is still in flight.
4. Withdraw the artefact if it is actively harmful. Removing the GitHub
   release, or the individual asset, stops the in-app update check from
   offering it, because the check reads the latest published release.
   Readers who already installed the bad build keep it, which is why step
   three is not optional.
5. Record it. Append the event to the verification ledger and note the
   decision in the decision log.

### Why a bad release is still a bad release

- The whole purpose of the book is that a reader in a village with no
  grid can trust a procedure well enough to act on it. A release that
  ships a wrong number, a wrong safety level or a missing hazard breaks
  that promise, and the reader has no way to know it has been broken.
- Verification status is a statement about the review, not a warranty,
  and the disclaimer says so plainly. That covers an honest mistake. It
  does not cover a release that could have been held back.
- The offline-first design makes it worse, not better. The APK, the ZIM
  archive and the Pi image are copied around and installed with no
  central ability to revoke them. A reader may hold the bad build for
  months, and a ZIM file copied onto a school server cannot be recalled
  at all.
- The project does not retract. The deprecation policy deliberately keeps
  a deprecated entry published for twelve months with a visible banner.
  Correction with a marker is the model, not removal.
- The bar for shipping is therefore the full pipeline, every time, not
  the pipeline for an ordinary change.

### Safety-level and hazard corrections are expedited

A correction to a safety level, a hazard list, a dose, a tolerance or a
step that can injure somebody does not wait for a release train.

1. Open an issue and say so in the title, as the contribution guide asks
   for anything dangerous or wrong.
2. Make the correction and get a second reviewer on it. The
   verification state machine requires two reviewers before an entry can
   move to `peer-reviewed`, and the same discipline applies to a safety
   correction.
3. Cut a patch release as soon as the correction is reviewed, even if
   other work is still in flight. Tag it so that the in-app update check
   offers it to everyone.
4. If the entry is unsafe as written, deprecate it in the same change
   rather than leaving the corrected text in place without a marker.
5. Tell the mirrors. A federation sync pushes the correction to the
   nodes that trust this one, and the peer ledger records the sync.

The in-app update path is what makes an expedited release useful: a
reader who already has the app can pick up the fixed build from Settings
without hunting for a download page.

## How the artefacts are consumed

| Artefact | For | How it is used |
|---|---|---|
| `abook-of-life-v<tag>.apk` | A phone or a tablet | Install and read offline |
| `a-book-of-life.zim` | Kiwix | Open the archive and search it |
| `build/offline-bundle/` | A school or a site | Serve the static HTML |
| `a-book-of-life.img.xz` | A Raspberry Pi | Flash it and boot |
| `index.db` | A service | Point the API or the SDKs at it |
| `ghcr.io/.../api` | A server | Run the HTTP API |
| `ghcr.io/.../mcp` | An agent | Run the MCP server |
| `ghcr.io/.../rag` | A local LLM | Answer with citations |

### The offline bundle for a Raspberry Pi or a school

The Pi image is the one-command route.
`deploy/raspberry-pi/build-image.sh` takes a Raspberry Pi OS Lite image,
expands the root partition, enables SSH and writes a first-boot
provisioning script. That script clones the repository, installs the
Python dependencies, validates the sidecars, builds the index and the ZIM,
brings up the Docker stack and installs a systemd unit for the API, and
advertises it on the local network over Avahi. The image is compressed
with xz and is flashed with:

```bash
xz -dc a-book-of-life.img.xz | \
  sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
```

For a school that already has a Linux machine, the static HTML under
`build/offline-bundle/html/` is enough on its own. The Compose stack in
`deploy/docker/docker-compose.yml` adds the API on 8080, the MCP server
on 8083, the RAG service on 8084, Kiwix on 8081, Kolibri on 8082 and
Ollama on 11434, all sharing the built corpus.

### The ZIM file for Kiwix

`a-book-of-life.zim` opens in Kiwix on a phone, a laptop or a Kiwix
server. It gives full-text search over the whole book, with no network
and no account. The Compose stack serves the same archive.

### The SDKs

The Python, TypeScript and Rust packages give typed access to the search
API, the entry list, the link graph, the verification record and the
federation endpoints. The contract is `api/openapi.yaml`. Each package
publishes its own version, which `scripts/bump_version.py` keeps in step
with the project version.

### The Android APK

`abook-of-life-v<tag>.apk` is a self-contained reader. The whole corpus
is inside the package, the search index is built on the device at first
launch, and no network is needed to read, search or bookmark. It is the
one artefact a reader can carry with them.

### The long-term archive

`scripts/archive.py` deposits a tarball of the corpus with the Internet
Archive, Zenodo and Software Heritage, and the annual archive workflow
runs it on a schedule. A release therefore survives the platform that
hosted it, which is the point of publishing several artefacts in the
first place.
