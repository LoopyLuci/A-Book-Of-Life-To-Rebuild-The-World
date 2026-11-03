"""The pre-push hook installer, tested on a throwaway hook path."""

from __future__ import annotations

from scripts import install_hooks


def test_install_writes_a_marked_hook(tmp_path):
    hook = tmp_path / "pre-push"

    assert install_hooks.install(hook, force=False) == 0

    text = hook.read_text(encoding="utf-8")
    assert install_hooks.MARKER in text
    assert "scripts/local_pipeline.py" in text
    assert install_hooks.show_status(hook) == 0


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
