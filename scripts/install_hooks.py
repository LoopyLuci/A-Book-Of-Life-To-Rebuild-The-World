#!/usr/bin/env python3
"""
Install the pre-push hook that runs the local pipeline.

A push publishes, so the pipeline is the one check that must happen before a
commit leaves the machine. This script writes `pre-push` into the hooks
directory that git reads for this repository. Linked worktrees share that
directory with their main checkout, so one install covers all of them. Git
hooks are local: they are never committed, and every clone has to opt in once.

    python scripts/install_hooks.py            # install or refresh the hook
    python scripts/install_hooks.py --status   # report whether it is installed
    python scripts/install_hooks.py --uninstall

The hook runs `local_pipeline.py` from the repository root and stops the push
when the pipeline fails. The interpreter that installed the hook runs the
pipeline first, so the push uses the packages that were installed for it. The
hook never adds `--no-verify`: a green run is what makes the push safe, not a
bypass of it.
"""

from __future__ import annotations

import argparse
import shlex
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HOOK_NAME = "pre-push"
MARKER = "# installed by scripts/install_hooks.py"


def hook_script(python: str) -> str:
    """The hook body. `python` is the interpreter that runs the pipeline first."""
    preferred = shlex.quote(python)
    return f"""#!/bin/sh
{MARKER} -- see docs/LOCAL-PIPELINE.md
#
# A push publishes. Run the whole pipeline first, and stop the push when it
# fails. Do not remove this hook to get past a red stage: fix the stage.
set -u

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
if [ -z "$repo_root" ] || [ ! -d "$repo_root" ]; then
    echo "pre-push: cannot locate the repository root" >&2
    exit 1
fi
cd "$repo_root" || exit 1

if [ ! -f scripts/local_pipeline.py ]; then
    echo "pre-push: scripts/local_pipeline.py is missing; the push is allowed" >&2
    exit 0
fi

# The interpreter that installed this hook comes first, then the project's
# .venv, then whatever python3 or python is on PATH.
if [ -f {preferred} ]; then
    py={preferred}
elif [ -x .venv/bin/python ]; then
    py=.venv/bin/python
elif [ -x .venv/Scripts/python.exe ]; then
    py=.venv/Scripts/python.exe
elif command -v python3 >/dev/null 2>&1; then
    py=python3
elif command -v python >/dev/null 2>&1; then
    py=python
else
    echo "pre-push: no Python interpreter found; the pipeline did not run" >&2
    echo "pre-push: install Python 3.11+ and run scripts/install.py, then push again" >&2
    exit 0
fi

echo "pre-push: running the local pipeline with $py (this can take several minutes)"
if "$py" scripts/local_pipeline.py; then
    exit 0
fi

echo "" >&2
echo "pre-push: the pipeline failed, so the push was stopped." >&2
echo "pre-push: read logs/local_pipeline/summary.txt, fix the failing stage," >&2
echo "pre-push: and push again. Do not bypass this hook with --no-verify." >&2
exit 1
"""


def git_hooks_dir(root: Path = ROOT) -> Path | None:
    """The hooks directory git reads for the checkout at `root`, or None outside git.

    A linked worktree has a git directory of its own (`.git/worktrees/<name>`),
    but git reads hooks only from the common directory shared with the main
    checkout. Asking for `--git-common-dir` puts the hook where git looks.
    """
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--git-common-dir"],
            cwd=str(root),
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=False,
        )
    except OSError:
        return None
    if result.returncode != 0:
        return None
    common_dir = Path(result.stdout.strip())
    if not common_dir.is_absolute():
        common_dir = root / common_dir
    return (common_dir / "hooks").resolve()


def show_status(hook: Path) -> int:
    if not hook.exists():
        print(f"pre-push hook: not installed ({hook})")
        return 1
    text = hook.read_text(encoding="utf-8", errors="replace")
    if MARKER not in text:
        print(f"pre-push hook: a different hook is installed ({hook})")
        return 1
    print(f"pre-push hook: installed ({hook})")
    return 0


def install(hook: Path, force: bool, python: str = sys.executable) -> int:
    if hook.exists() and MARKER not in hook.read_text(encoding="utf-8", errors="replace"):
        if not force:
            print(
                f"refusing to overwrite an existing pre-push hook that this project "
                f"did not write: {hook}\nRe-run with --force to replace it.",
                file=sys.stderr,
            )
            return 1
    interpreter = Path(python).as_posix()
    hook.parent.mkdir(parents=True, exist_ok=True)
    hook.write_text(hook_script(interpreter), encoding="utf-8", newline="\n")
    try:
        hook.chmod(0o755)
    except OSError:
        # Windows has no execute bit; git runs the hook through its own shell.
        pass
    print(f"pre-push hook installed: {hook}")
    print(f"It runs scripts/local_pipeline.py with {interpreter} before every push.")
    return 0


def uninstall(hook: Path) -> int:
    if not hook.exists():
        print("pre-push hook: nothing to remove")
        return 0
    if MARKER not in hook.read_text(encoding="utf-8", errors="replace"):
        print(f"refusing to remove a hook this project did not write: {hook}", file=sys.stderr)
        return 1
    hook.unlink()
    print(f"pre-push hook removed: {hook}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Install, inspect or remove the pre-push hook of this checkout."
    )
    parser.add_argument("--status", action="store_true",
                        help="report whether the hook is installed")
    parser.add_argument("--uninstall", action="store_true",
                        help="remove the hook")
    parser.add_argument("--force", action="store_true",
                        help="replace a pre-push hook this project did not write")
    args = parser.parse_args(argv)

    hooks = git_hooks_dir()
    if hooks is None:
        print("not a git checkout; there is no hooks directory to write to", file=sys.stderr)
        return 1
    hook = hooks / HOOK_NAME

    if args.status:
        return show_status(hook)
    if args.uninstall:
        return uninstall(hook)
    return install(hook, force=args.force)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\ninterrupted", file=sys.stderr)
        sys.exit(130)
