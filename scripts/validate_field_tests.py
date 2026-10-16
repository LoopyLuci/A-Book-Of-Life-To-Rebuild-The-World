#!/usr/bin/env python3
"""Validate all field-test reports against the schema."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parent.parent
SCHEMA_PATH = ROOT / "schemas" / "field-test.schema.json"
FIELD_TESTS_DIR = ROOT / "field-tests"


def main() -> int:
    with SCHEMA_PATH.open("r", encoding="utf-8") as f:
        schema = json.load(f)
    validator = Draft202012Validator(schema)

    if not FIELD_TESTS_DIR.exists():
        print("No field-tests directory; nothing to validate.")
        return 0

    errors = []
    count = 0
    for path in sorted(FIELD_TESTS_DIR.glob("*.yaml")):
        count += 1
        with path.open("r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
        for err in validator.iter_errors(data):
            errors.append(f"{path}: {err.json_path}: {err.message}")

    if errors:
        print(f"Field-test validation failed with {len(errors)} error(s):", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1

    print(f"Field-test validation passed. {count} report(s) checked.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
