#!/usr/bin/env python3
"""
Bump the project version across all manifests.
Usage: python scripts/bump_version.py 1.1.0
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def replace(path: Path, pattern: str, replacement: str) -> bool:
    if not path.exists():
        return False
    text = path.read_text(encoding="utf-8")
    new = re.sub(pattern, replacement, text, count=1)
    if new != text:
        path.write_text(new, encoding="utf-8")
        return True
    return False


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: bump_version.py <version>", file=sys.stderr)
        return 1
    version = sys.argv[1]

    changed = []

    if replace(
        ROOT / "manifest.toml",
        r'version = "[^"]+"',
        f'version = "{version}"',
    ):
        changed.append("manifest.toml")

    if replace(
        ROOT / "pyproject.toml",
        r'version = "[^"]+"',
        f'version = "{version}"',
    ):
        changed.append("pyproject.toml")

    if replace(
        ROOT / "sdk" / "python" / "pyproject.toml",
        r'version = "[^"]+"',
        f'version = "{version}"',
    ):
        changed.append("sdk/python/pyproject.toml")

    if replace(
        ROOT / "sdk" / "typescript" / "package.json",
        r'"version": "[^"]+"',
        f'"version": "{version}"',
    ):
        changed.append("sdk/typescript/package.json")

    if replace(
        ROOT / "sdk" / "rust" / "Cargo.toml",
        r'version = "[^"]+"',
        f'version = "{version}"',
    ):
        changed.append("sdk/rust/Cargo.toml")

    if replace(
        ROOT / "mobile" / "package.json",
        r'"version": "[^"]+"',
        f'"version": "{version}"',
    ):
        changed.append("mobile/package.json")

    print(f"Bumped to {version}:")
    for f in changed:
        print(f"  - {f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
