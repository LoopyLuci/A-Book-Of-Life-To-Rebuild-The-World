#!/usr/bin/env python3
"""
Build all OpenSCAD models into STL/STEP artifacts.
Requires `openscad` on PATH for STL export.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODELS_DIR = ROOT / "models"
BUILD_DIR = ROOT / "build" / "models"


def find_openscad() -> str | None:
    for name in ("openscad", "openscad-nightly"):
        if shutil.which(name):
            return name
    return None


def build_model(scad: Path, openscad: str) -> Path:
    rel = scad.relative_to(MODELS_DIR)
    out = BUILD_DIR / rel.with_suffix(".stl")
    out.parent.mkdir(parents=True, exist_ok=True)

    cmd = [
        openscad,
        "-o", str(out),
        "--export-format", "binstl",
        str(scad),
    ]
    subprocess.run(cmd, check=True, capture_output=True)
    return out


def main() -> int:
    models = sorted(MODELS_DIR.rglob("*.scad"))
    if not models:
        print("No .scad models found.")
        return 0

    openscad = find_openscad()
    if not openscad:
        print("openscad not found on PATH; skipping STL export.")
        print(f"Found {len(models)} .scad source file(s).")
        # Still emit a manifest of source files
        manifest = {
            "source_count": len(models),
            "sources": [str(m.relative_to(ROOT)) for m in models],
            "stl_generated": False,
        }
        (ROOT / "build").mkdir(exist_ok=True)
        (ROOT / "build" / "models-manifest.json").write_text(
            json.dumps(manifest, indent=2), encoding="utf-8"
        )
        return 0

    if BUILD_DIR.exists():
        shutil.rmtree(BUILD_DIR)
    BUILD_DIR.mkdir(parents=True)

    built = []
    for m in models:
        out = build_model(m, openscad)
        built.append(str(out.relative_to(ROOT)))
        print(f"  {m.relative_to(MODELS_DIR)} -> {out.relative_to(ROOT)}")

    manifest = {
        "source_count": len(models),
        "built_count": len(built),
        "stl_generated": True,
        "artifacts": built,
    }
    (ROOT / "build" / "models-manifest.json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8"
    )
    print(f"Built {len(built)} model(s) into {BUILD_DIR}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
