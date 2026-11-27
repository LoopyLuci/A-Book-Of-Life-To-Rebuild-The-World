"""The pre-push hook installer, tested on a throwaway hook path."""

from __future__ import annotations

import shlex
import subprocess
import sys
from pathlib import Path

from scripts import install_hooks


def _git(cwd: Path, *args: str) -> None:
    subprocess.run(
        ["git", *args],
        cwd=cwd,
        check=True,
        capture_output=True,
        text=True,
    )


def test_install_writes_a_marked_hook(tmp_path):
    hook = tmp_path / "pre-push"

    assert install_hooks.install(hook, force=False) == 0

    text = hook.read_text(encoding="utf-8")
    assert install_hooks.MARKER in text
    assert "scripts/local_pipeline.py" in text
    assert install_hooks.show_status(hook) == 0


def test_install_runs_the_interpreter_that_installed_it_first(tmp_path):
    hook = tmp_path / "pre-push"
    python = "C:/Program Files/Python311/python.exe"

    assert install_hooks.install(hook, force=False, python=python) == 0

    text = hook.read_text(encoding="utf-8")
    preferred = f"py={shlex.quote(python)}"
    assert preferred in text
    assert text.index(preferred) < text.index("py=.venv/bin/python")
    assert text.index(preferred) < text.index("py=python3")


def test_install_defaults_to_the_running_interpreter(tmp_path):
    hook = tmp_path / "pre-push"

    assert install_hooks.install(hook, force=False) == 0

    text = hook.read_text(encoding="utf-8")
    assert f"py={shlex.quote(Path(sys.executable).as_posix())}" in text


def test_hooks_dir_is_shared_by_a_linked_worktree(tmp_path):
    repo = tmp_path / "repo"
    repo.mkdir()
    _git(repo, "init", "-q")
    _git(
        repo,
        "-c", "user.name=test",
        "-c", "user.email=test@example.invalid",
        "commit", "--allow-empty", "-q", "-m", "init",
    )
    worktree = tmp_path / "wt"
    _git(repo, "worktree", "add", "-q", "-b", "wt-check", str(worktree))

    shared = (repo / ".git" / "hooks").resolve()
    assert install_hooks.git_hooks_dir(repo) == shared
    assert install_hooks.git_hooks_dir(worktree) == shared


def test_status_reports_a_missing_hook(tmp_path):
    assert install_hooks.show_status(tmp_path / "pre-push") == 1


def test_install_refuses_to_overwrite_a_foreign_hook(tmp_path):
    hook = tmp_path / "pre-push"
    hook.write_text("#!/bin/sh\necho mine\n", encoding="utf-8")

    assert install_hooks.install(hook, force=False) == 1
    assert "echo mine" in hook.read_text(encoding="utf-8")


def test_force_replaces_a_foreign_hook(tmp_path):
    hook = tmp_path / "pre-push"
    hook.write_text("#!/bin/sh\necho mine\n", encoding="utf-8")

    assert install_hooks.install(hook, force=True) == 0
    assert install_hooks.MARKER in hook.read_text(encoding="utf-8")


def test_uninstall_removes_only_its_own_hook(tmp_path):
    hook = tmp_path / "pre-push"
    hook.write_text("#!/bin/sh\necho mine\n", encoding="utf-8")

    assert install_hooks.uninstall(hook) == 1
    assert hook.exists()

    assert install_hooks.install(hook, force=True) == 0
    assert install_hooks.uninstall(hook) == 0
    assert not hook.exists()


def test_uninstall_is_idempotent(tmp_path):
    assert install_hooks.uninstall(tmp_path / "pre-push") == 0
