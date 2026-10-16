#!/usr/bin/env python3
"""
Scan media/ for videos and audio, validate metadata, and emit an index
for inclusion in the offline bundle.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parent.parent
MEDIA_DIR = ROOT / "media"
SCHEMA_PATH = ROOT / "schemas" / "media.schema.json"
BUILD_DIR = ROOT / "build"


def _validate(meta: dict, validator: Draft202012Validator, path: Path) -> list[str]:
    errors = []
    for err in validator.iter_errors(meta):
        errors.append(f"{path}: {err.json_path}: {err.message}")
    return errors


def main() -> int:
    if not MEDIA_DIR.exists():
        print("No media directory found.")
        return 0

    with SCHEMA_PATH.open("r", encoding="utf-8") as f:
        schema = json.load(f)
    validator = Draft202012Validator(schema)

    index = []
    errors: list[str] = []
    count = 0

    for meta_path in sorted(MEDIA_DIR.rglob("metadata.yaml")):
        count += 1
        with meta_path.open("r", encoding="utf-8") as f:
            meta = yaml.safe_load(f)
        errors.extend(_validate(meta, validator, meta_path))

        media_path = ROOT / meta["path"]
        if not media_path.exists():
            errors.append(f"{meta_path}: media file not found: {meta['path']}")
            continue

        if meta.get("transcript"):
            tpath = ROOT / meta["transcript"]
            if not tpath.exists():
                errors.append(f"{meta_path}: transcript not found: {meta['transcript']}")

        index.append(
            {
                "entry_id": meta["entry_id"],
                "type": meta["type"],
                "path": meta["path"],
                "transcript": meta.get("transcript"),
                "language": meta.get("language", "en"),
                "duration_seconds": meta.get("duration_seconds"),
                "caption": meta.get("caption", ""),
            }
        )

    if errors:
        print(f"Media validation failed with {len(errors)} error(s):", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1

    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    (BUILD_DIR / "media-index.json").write_text(
        json.dumps({"count": count, "items": index}, indent=2), encoding="utf-8"
    )
    print(f"Media index built: {count} item(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
