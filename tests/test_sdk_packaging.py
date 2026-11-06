"""The Python SDK's build configuration, and the trap it has to avoid.

Hatchling looks for a ``.gitignore`` above a project and applies its patterns
with the project directory as the anchor. The repository ignores ``/abook`` at
its root — that is the generated launcher — which, seen from ``sdk/python``,
reads as "exclude ``abook/``", so the SDK used to build a wheel with no code in
it. Whether the bug appeared depended on the absolute path of the checkout,
because hatchling drops the ignore rules when the project directory itself
looks ignored; a build under ``/tmp`` passed while a build under
``/home/runner/...`` shipped an empty package.

``ignore-vcs`` in the SDK's ``pyproject.toml`` is what keeps the wheel whole.
These tests fail if it is removed, or if the ignore rule it works around goes
away without the reason being revisited.
"""

from __future__ import annotations

import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SDK = ROOT / "sdk" / "python"
PYPROJECT = SDK / "pyproject.toml"


def _config() -> dict:
    return tomllib.loads(PYPROJECT.read_text(encoding="utf-8"))


def test_the_sdk_does_not_let_vcs_rules_drop_its_package() -> None:
    build = _config()["tool"]["hatch"]["build"]

    assert build["ignore-vcs"] is True


def test_the_sdk_ships_the_abook_package() -> None:
    wheel = _config()["tool"]["hatch"]["build"]["targets"]["wheel"]

    assert wheel["packages"] == ["abook"]
    assert (SDK / "abook" / "__init__.py").is_file()


def test_the_ignore_rule_this_works_around_is_still_there() -> None:
    # If /abook stops being ignored at the root, someone may delete the
    # ignore-vcs workaround without realising it was the thing keeping the
    # wheel whole. This keeps the two facts tied together.
    ignored = {
        line.strip()
        for line in (ROOT / ".gitignore").read_text(encoding="utf-8").splitlines()
    }

    assert "/abook" in ignored
    assert "/abook.cmd" in ignored
