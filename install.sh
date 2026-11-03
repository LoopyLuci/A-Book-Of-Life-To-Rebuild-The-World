#!/bin/sh
#
# Installs, updates or verifies Book of Life on Linux and macOS.
#
# A one line installer that does the whole job: it checks the machine,
# creates an isolated environment, installs the dependencies, builds the
# search index, verifies the install, and leaves working launchers behind.
#
# The install is transactional. If anything fails, the previous working
# environment is put back, so an update can never leave the machine worse
# than it found it.
#
# Usage:
#   ./install.sh              install or repair
#   ./install.sh update       update an existing install
#   ./install.sh verify       check an existing install
#   ./install.sh uninstall    remove the installation
#
# Options:
#   --offline   install from vendor/wheels without touching the network
#   --rebuild   recreate the virtual environment from scratch
#   --force     reinstall even when the version has not changed
#
# One line install:
#   curl -fsSL https://raw.githubusercontent.com/LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World/main/install.sh | sh

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ ! -f "$ROOT/manifest.toml" ]; then
    ROOT=$(pwd)
fi

COMMAND=install
OFFLINE=""
REBUILD=""
FORCE=""

for arg in "$@"; do
    case "$arg" in
        install|update|verify|uninstall) COMMAND="$arg" ;;
        --offline) OFFLINE="--offline" ;;
        --rebuild) REBUILD="--rebuild" ;;
        --force)   FORCE="--force" ;;
        -h|--help)
            sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "unknown option: $arg" >&2
            exit 2
            ;;
    esac
done

step() { printf '\033[1;36m==> %s\033[0m\n' "$1"; }
ok()   { printf '\033[1;32m    ok  %s\033[0m\n' "$1"; }
warn() { printf '\033[1;33m    !!  %s\033[0m\n' "$1"; }
fail() { printf '\033[1;31m    xx  %s\033[0m\n' "$1"; }

printf 'Book of Life installer  |  %s\n' "$ROOT"

step "Checking the machine"

PYTHON=""
for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
        if "$candidate" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else 1)' 2>/dev/null; then
            PYTHON="$candidate"
            break
        fi
    fi
done

if [ -z "$PYTHON" ]; then
    fail "Python 3.11 or newer is required and was not found."
    echo "  Install it with your package manager and run this again." >&2
    exit 2
fi
ok "python at $(command -v "$PYTHON")"

if [ ! -f "$ROOT/manifest.toml" ]; then
    fail "manifest.toml was not found, so this is not the project root."
    exit 2
fi

FREE_KB=$(df -Pk "$ROOT" | awk 'NR==2 {print $4}')
FREE_GB=$((FREE_KB / 1024 / 1024))
if [ "$FREE_GB" -lt 2 ]; then
    fail "only ${FREE_GB} GB free; 2 GB is needed"
    exit 2
fi
ok "${FREE_GB} GB free"

set +e
"$PYTHON" "$ROOT/scripts/install.py" "$COMMAND" $OFFLINE $REBUILD $FORCE
CODE=$?
set -e

if [ "$CODE" -ne 0 ]; then
    fail "the '$COMMAND' did not complete (exit $CODE)."
    echo "  The previous working environment was kept." >&2
    exit "$CODE"
fi

ok "the '$COMMAND' completed"
printf '\n'
echo "  start the local server:  .venv/bin/python scripts/serve.py"
echo "  run the pipeline:        .venv/bin/python scripts/local_pipeline.py"
printf '\n'
