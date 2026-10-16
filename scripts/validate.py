#!/usr/bin/env python3
"""
Validate all sidecars against the JSON schema and cross-check
that each sidecar has a corresponding Markdown file.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parent.parent
SCHEMA_PATH = ROOT / "schemas" / "sidecar.schema.json"
DOMAINS_DIR = ROOT / "domains"
SIDECARS_DIR = ROOT / "sidecars"


def load_schema() -> Draft202012Validator:
    with SCHEMA_PATH.open("r", encoding="utf-8") as f:
        schema = json.load(f)
    return Draft202012Validator(schema)


def iter_sidecars():
    for path in sorted(SIDECARS_DIR.rglob("*.pnk.yaml")):
        yield path


def markdown_path_for(sidecar_path: Path) -> Path:
    rel = sidecar_path.relative_to(SIDECARS_DIR)
    return DOMAINS_DIR / rel.with_suffix("").with_suffix(".md")


def validate() -> int:
    validator = load_schema()
    errors: list[str] = []
    count = 0

    for sidecar_path in iter_sidecars():
        count += 1
        try:
            with sidecar_path.open("r", encoding="utf-8") as f:
                data = yaml.safe_load(f)
        except yaml.YAMLError as exc:
            errors.append(f"{sidecar_path}: YAML parse error: {exc}")
            continue

        for err in validator.iter_errors(data):
            errors.append(f"{sidecar_path}: {err.json_path}: {err.message}")

        md_path = markdown_path_for(sidecar_path)
        if not md_path.exists():
            errors.append(f"{sidecar_path}: missing Markdown file at {md_path}")

    if errors:
        print(f"Validation failed with {len(errors)} error(s):", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        return 1

    print(f"Validation passed. {count} sidecar(s) checked.")
    return 0


if __name__ == "__main__":
    sys.exit(validate())
