# Install, update, verify, remove

The project installs itself. One command checks the machine, creates an
isolated environment, installs the dependencies, builds the search index,
verifies the result, and leaves a working launcher behind. An install is
transactional: if any step fails, the previous working environment is put back,
so an update can never leave the machine worse than it found it.

Nothing is installed outside the checkout except the Python packages, and those
go into `.venv/` inside the checkout.

## Requirements

| Requirement | Why |
|-------------|-----|
| Python 3.11 or newer, with `venv` | The backend, the scripts and the desktop reader. |
| About 2 GB of free disk | The model cache, the index and the bundle. |
| `git` | Recommended; the updater uses it to fetch a newer revision. |
| A network connection | Unless you install `--offline` from `vendor/wheels`. |

Everything else is optional. Node, Rust, Ruby, PowerShell and the JDK are only
needed for the front-ends or the Android build, and the pipeline reports which
surfaces it covered.

## Install

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World/main/install.ps1 | iex
```

Linux and macOS:

```sh
curl -fsSL https://raw.githubusercontent.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World/main/install.sh | sh
```

From a checkout you already have:

```bash
python scripts/install.py install
```

## The four commands

```bash
python scripts/install.py install     # install or repair
python scripts/install.py update      # update an existing install
python scripts/install.py verify      # check an existing install
python scripts/install.py uninstall   # remove the installation
```

### `install`

1. Checks the environment: Python ≥ 3.11, free disk, the repository files, and
   whether the network will be used.
2. Creates `.venv/` (or reuses it). With `--rebuild` the old environment is
   moved aside to `.venv.previous` rather than deleted, so it can be restored.
3. Installs `requirements.txt`, retrying a failed download three times with a
   backoff, then installs `requirements-dev.txt` if it is present. A failure of
   the developer extras is reported but never fails the install.
4. Verifies the installation: the core dependencies import, every sidecar
   validates, the search index builds, and a smoke test reads a real sidecar.
5. Creates the launcher (`abook.cmd` on Windows, `abook` elsewhere) and
   installs the pre-push hook that runs the local pipeline before every push.
   A checkout with a pre-push hook this project did not write is left alone.
6. Writes `.abook/install-state.json` with the version, the revision, the
   Python version, the platform and the environment path.

If step 3 or 4 fails, the previous environment is restored automatically.

### The pre-push hook

Git hooks are local, so the installer has to write one for the checkout it runs
in. It installs `.git/hooks/pre-push`, which runs the local pipeline and stops a
push when a stage fails. The hook prefers the `.venv/` interpreter, so it runs
with the same dependencies the install just verified.

```bash
python scripts/install_hooks.py --status      # report whether it is installed
python scripts/install_hooks.py --uninstall   # remove it
python scripts/install_hooks.py --force       # replace a hook it did not write
```

The install treats the hook as a convenience, not a requirement: a tree without
a `.git` directory (a release tarball, for example) still installs and runs. See
[`LOCAL-PIPELINE.md`](LOCAL-PIPELINE.md) for what the hook runs.

### `update`

1. Reads the installed version from `.abook/install-state.json`.
2. Runs `git fetch --all --tags` and `git pull --ff-only`, unless `--offline`
   or `--dry-run` was given.
3. Compares the version in `manifest.toml` with the installed one. If they
   match, it stops — `--force` reinstalls anyway.
4. Runs the install again. If that fails, the previous environment is restored.

An update therefore never touches your corpus, your bookmarks or your
preferences; those live in the checkout and in the state directory, and only
`.venv/` is replaced.

### `verify`

Runs the same verification as `install` without changing anything: the imports,
`scripts/validate.py`, `scripts/build_index.py` and the smoke test. Exit status
`0` means the installation is healthy.

### `uninstall`

Removes `.venv/`, the `.abook/` state directory and the launcher. `--dry-run`
prints what would be removed. Your checkout, the corpus and any build output
are left alone.

## Options

| Option | Applies to | Effect |
|--------|-----------|--------|
| `--rebuild` | `install` | Recreate the virtual environment from scratch. |
| `--offline` | `install`, `update` | Install from `vendor/wheels` without touching the network. Fails clearly if the wheelhouse is missing. |
| `--force` | `update` | Reinstall even when the version has not changed. |
| `--dry-run` | `install`, `update`, `uninstall` | Print the commands and change nothing. |

## The offline wheelhouse

To install on a machine with no network, build a wheelhouse on a machine that
has one:

```bash
python -m pip download -r requirements.txt -r requirements-dev.txt -d vendor/wheels
```

Copy the checkout to the offline machine, then:

```bash
python scripts/install.py install --offline
```

`vendor/wheels` is not tracked; it is built per platform, because a wheel for
one interpreter and OS does not install on another.

## After installing

```bash
# Start the local API and dashboard
.venv/bin/python scripts/serve.py        # .venv\Scripts\python on Windows

# Run the test suite
.venv/bin/python -m pytest -q

# Run the whole local pipeline
.venv/bin/python scripts/local_pipeline.py

# Open a desktop reader
.venv/bin/python apps/desktop-python/abook.py
```

The installer prints the two commands that matter for the platform it ran on.
See [`LOCAL-PIPELINE.md`](LOCAL-PIPELINE.md) for the pipeline and
[`APPS.md`](APPS.md) for the six front-ends.

## If something goes wrong

| Symptom | Cause and fix |
|---------|---------------|
| `Python 3.11 or newer is required` | An older interpreter is first on `PATH`. Install 3.11+ and make it first, or run the installer with the full path to it. |
| `only … GB free` | The model cache needs about 2 GB. Free space, or move the checkout to a larger drive. |
| `no vendor/wheels directory` | `--offline` was given without a wheelhouse. Build one first, or drop the flag. |
| The install fails and the environment is restored | Read the reported step. The previous environment is back in place and working; nothing is lost. |
| `verify` fails | The environment is inconsistent. `python scripts/install.py install --rebuild` rebuilds it from scratch. |
