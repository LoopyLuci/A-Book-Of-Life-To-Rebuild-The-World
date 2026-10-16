#!/usr/bin/env python3
"""
Dependency audit: report known vulnerabilities and outdated pins.

Runs `pip-audit`, `npm audit`, and `cargo audit` if available.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def run(cmd: list[str], cwd: Path) -> tuple[int, str]:
    if not shutil.which(cmd[0]):
        return 127, f"{cmd[0]} not installed"
    try:
        out = subprocess.run(
            cmd, cwd=cwd, capture_output=True, text=True, check=False
        )
        return out.returncode, out.stdout + out.stderr
    except Exception as exc:  # noqa: BLE001
        return 1, str(exc)


def main() -> int:
    failures = 0

    print("=== Python (pip-audit) ===")
    code, out = run(["pip-audit", "-r", "requirements.txt"], ROOT)
    print(out.strip())
    if code not in (0, 127):
        failures += 1

    print("\n=== TypeScript (npm audit) ===")
    sdk_ts = ROOT / "sdk" / "typescript"
    if sdk_ts.exists():
        code, out = run(["npm", "audit", "--audit-level=high"], sdk_ts)
        print(out.strip())
        if code not in (0, 127):
            failures += 1

    print("\n=== Rust (cargo audit) ===")
    sdk_rust = ROOT / "sdk" / "rust"
    if sdk_rust.exists():
        code, out = run(["cargo", "audit"], sdk_rust)
        print(out.strip())
        if code not in (0, 127):
            failures += 1

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
