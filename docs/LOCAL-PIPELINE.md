# The local pipeline

`scripts/local_pipeline.py` is the on-device delivery pipeline. It runs every
check this repository has, on the machine you are sitting at, with no CI
service and no network. It exists so that a contributor with no account
anywhere can prove a change is good, and so that the same sequence runs before
a push that publishes.

It is deliberately not a wrapper around `pytest`: a green `pytest` says the
Python tests pass, and says nothing about whether the sidecars validate, the
translations are complete, the Markdown renders, the bundle assembles, the SDKs
build, the six front-ends still work, or the APK still compiles.

## Running it

```bash
python scripts/local_pipeline.py              # everything
python scripts/local_pipeline.py --fast       # skip the slow stages
python scripts/local_pipeline.py --list       # show the stages and exit
python scripts/local_pipeline.py --stage apps # one stage
python scripts/local_pipeline.py --skip bundle --skip android
python scripts/local_pipeline.py --clean      # discard the cache and logs first
python scripts/local_pipeline.py --telemetry  # print the last report as JSON
python scripts/local_pipeline.py --quiet
```

The exit status is `0` only when no stage failed. A stage marked *optional* is
one whose toolchain may be absent (Node for the web readers, Ruby for Rails,
Gradle for the APK): when the toolchain is missing the stage runs no command and
reports a pass, and when it is present the stage really runs and a failure is a
failure. Optional never means "a red stage is forgiven".

## The stages

| Stage | Required | Slow | What it does |
|-------|----------|------|--------------|
| `preflight` | yes | | Checks Python ≥ 3.11, `manifest.toml`, `git`, free disk, the optional toolchains and PyYAML before anything else runs. |
| `validate` | yes | | `scripts/validate.py` and `scripts/validate_field_tests.py`: every sidecar against `schemas/`, every field test against its schema. |
| `lint` | no | | `ruff check .` over the Python and the apps. |
| `markdown` | no | | `markdownlint-cli2` over `domains/**/*.md`. |
| `i18n` | yes | | `scripts/validate_i18n.py` for coverage, then `scripts/build_i18n.py` to rebuild the language indexes. |
| `tests` | yes | | The Python test suite: `pytest -q`. Waits for `index` and `bundle`, because the end-to-end tests read both. |
| `index` | yes | | Rebuilds the SQLite search index and the dashboard data. |
| `media` | no | | `scripts/build_media.py`: validates and derives the media assets. |
| `models` | no | yes | Builds the printable models. |
| `variants` | no | | Builds the regional variants (arctic, arid, tropical). |
| `bundle` | yes | yes | Assembles the offline bundle: static HTML, the client-side search index, domain index pages, the bundle manifest and, when `zimwriterfs` is present, the ZIM archive. |
| `sdk` | no | | Builds and tests the Python, TypeScript and Rust SDKs whose toolchain is present. |
| `apps` | no | yes | Runs the test suite of every app front-end the machine can build. |
| `android` | no | yes | Exports the content into the app and runs `gradlew test :app:assembleDebug`. |

Optional stages are optional because their toolchain is optional. A machine
without Node does not fail the `apps` stage for the web readers; the stage runs
the apps it can build. A required stage that fails stops the run; an optional
stage that fails does not, but the run still exits non-zero, because a red check
is information the push must not ignore. `--list` prints the same table as a
single screen.

### Dependencies between stages

Most stages are independent and run in parallel. A few declare `requires`, and
the runner schedules them in waves so a dependency finishes first:

- `tests` requires `index` and `bundle`, because the end-to-end tests read the
  search index and the offline HTML. Without the dependency the suite raced the
  bundle and failed on a half-written `build/offline-bundle/`.
- A dependency that is not selected is not waited for. `--stage tests` alone
  runs immediately, and the test fixture builds whatever it needs.
- If a dependency cycle ever appears, the remaining stages run instead of
  hanging; the stage table is the place to fix it.

`ABP_PIPELINE_PARALLEL=0` keeps the same order but runs every stage serially.

## What it does when something fails

A failure is treated as one of two things, and the pipeline decides rather than
the contributor:

- **A real failure.** Every attempt failed. The stage is reported as `FAIL`,
  the path to its log is printed, and the run stops with a non-zero status.
- **A flake.** A stage that failed under load passed when re-run serially after
  the machine settled. It is reported as `FLAKY`, with the number of attempts,
  and the run continues — but the flake is never hidden: it appears in the
  summary, in the telemetry file and in `logs/local_pipeline/summary.txt`.

This matters because the pipeline runs stages in parallel on purpose. A test
that is timing-sensitive, or that assumes no other build is running, fails
under that load and passes alone. The retry is serially executed, after
`ABP_PIPELINE_SETTLE_S` seconds, so the second attempt runs in the conditions it
was written for.

**Never weaken an assertion to get a green run.** If a stage fails every
attempt, the code or the environment is wrong. An environment-coupled test —
one that assumes a port is free, a server is off, or a tool is absent — should
be made backend-agnostic instead.

## Caching

The cache is per-stage and keyed by a fingerprint of the stage's declared
inputs (paths, and the modification time of the files under them). It is only
applied to stages that *write an artifact from their inputs*: `index`, `media`,
`models`, `variants` and `bundle`. Those are marked `cacheable` in
`build_stages()`, and each declares the `outputs` it writes.

A cached result is only reused while every declared output still exists. Delete
`build/` and the next run rebuilds instead of reporting a green artifact that is
no longer on disk. The fingerprint covers the inputs (paths and modification
times); the existence check covers the outputs.

A gate is never cached — not `validate`, not `lint`, not `markdown`, not
`i18n`, not `tests`, not `apps`, not `sdk`, not `android`. A green run has to
mean the check ran against this tree, not against one from an hour ago. If you
want a guaranteed cold run, `--clean` deletes the cache and the logs first.

`ABP_PIPELINE_CACHE=0` disables the cache entirely for one invocation.

## Which interpreter runs it

Every stage runs with the interpreter that started the pipeline, so a tool that
is installed for a *different* Python is, for the pipeline, not installed at
all. The preflight therefore checks for `pytest`, `ruff` and `respx` in that
interpreter and stops with the install command when one is missing:

```bash
python -m pip install -r requirements.txt -r requirements-dev.txt
```

`python scripts/install.py install` does the same thing into the isolated
`.venv/`, and repairs an environment created before `requirements-dev.txt`
existed. The `pre-push` hook prefers `.venv/`, so a hook run is only as complete
as that environment: repair it with `scripts/install.py install` when the
preflight says an extra is missing.

## Environment

| Variable | Default | Effect |
|----------|---------|--------|
| `ABP_PIPELINE_FLAKY_ATTEMPTS` | `3` | How many times a failing stage is retried before it counts as a failure. |
| `ABP_PIPELINE_SETTLE_S` | `3` | Seconds to wait between attempts, so the machine can settle. |
| `ABP_PIPELINE_TIMEOUT_S` | `3600` | Per-command timeout. A hung build fails instead of hanging the run. |
| `ABP_PIPELINE_CACHE` | `1` | Set to `0` to disable the artifact cache. |
| `ABP_PIPELINE_PARALLEL` | `1` | Set to `0` to run every stage serially. |
| `NO_COLOR` | unset | Disables colour, for a log that is read by a machine. |

### The project environment file

Build caches, temporary directories and toolchain paths belong on one drive and
in one place, and they differ per machine. `scripts/env.ps1` (Windows) and
`scripts/env.sh` (POSIX) hold them and are **not tracked**; source one of them
in your shell if you want the same values the pipeline uses.

The pipeline reads the file for the current platform itself and applies its
values to every command it runs, so a build started from a bare shell behaves
the same as one started from a shell where the file was sourced. The parser
understands the two forms the files use — `$Env:NAME = "value"` and
`export NAME="value"` — and treats a `PATH` assignment as a prefix operation,
so the inherited `PATH` is kept.

## Diagnostics

Everything lands in `logs/local_pipeline/`:

| File | What it holds |
|------|---------------|
| `<stage>.log` | The full output of every command of that stage, including the command line, for the latest run. |
| `summary.txt` | One line per stage: status, name, duration, detail. |
| `telemetry.json` | A machine-readable report: platform, Python, CPU count, per-stage status, attempts, duration, command and log path, plus the settings the run used. |
| `cache.json` | The input fingerprints of the last successful artifact stages. |

`--telemetry` prints `telemetry.json` to standard output so a script can read
it without knowing the layout.

The telemetry file is what makes a failure diagnosable after the fact: it
records *which* command failed, how many attempts it took, and how long it ran,
alongside the platform it ran on. When a stage fails on one machine and not
another, that is the first file to look at.

## Before a push

`push == publish`. Run the pipeline first, then push:

```bash
python scripts/local_pipeline.py
git push
```

The installer wires that rule into git: `python scripts/install_hooks.py` writes
`.git/hooks/pre-push`, which runs the pipeline and stops the push when a stage
fails. The hook prefers the project's `.venv`, so it sees the same dependencies
the pipeline does. It is local to a checkout, and `--status`, `--uninstall` and
`--force` are available; the installer runs it for you.

```bash
python scripts/install_hooks.py --status      # is the hook installed?
python scripts/install_hooks.py --uninstall   # remove it
```

Do not bypass the hook with `--no-verify`. A red stage is the hook doing its
job; fix the stage.

A pipeline that passes does not prove a change is correct — it proves that the
checks this project knows how to make have been made. Review the diff as well.
