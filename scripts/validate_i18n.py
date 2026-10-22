#!/usr/bin/env python3
"""
Validate translation coverage and translation sidecars.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parent.parent
I18N_DIR = ROOT / "i18n"
STRINGS_DIR = I18N_DIR / "strings"
TRANSLATIONS_DIR = I18N_DIR / "translations"
SCHEMA_PATH = ROOT / "schemas" / "sidecar.schema.json"

LANGS = ["es", "fr", "de", "pt", "hi", "ar", "sw", "zh", "nl", "ru", "it", "ja"]
COVERAGE_TARGETS = {
    "es": 1.0, "fr": 1.0, "de": 1.0, "pt": 1.0,
    "hi": 0.8, "ar": 0.8, "sw": 0.6, "zh": 0.8, "ru": 0.4, "nl": 0.3, "it": 0.3,
    "ja": 0.4,
}


def _load_canonical_ids() -> set[str]:
    ids: set[str] = set()
    for path in (ROOT / "sidecars").rglob("*.pnk.yaml"):
        with path.open("r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
        ids.add(data["id"])
    return ids


def main() -> int:
    canonical = _load_canonical_ids()
    if not canonical:
        print("No canonical entries found.")
        return 1

    with SCHEMA_PATH.open("r", encoding="utf-8") as f:
        schema = json.load(f)
    validator = Draft202012Validator(schema)

    errors: list[str] = []
    coverage: dict[str, float] = {}

    for lang in LANGS:
        # UI strings
        strings_path = STRINGS_DIR / f"{lang}.yaml"
        if not strings_path.exists():
            errors.append(f"Missing UI strings: {strings_path}")
            continue

        with strings_path.open("r", encoding="utf-8") as f:
            strings = yaml.safe_load(f)
        canonical_strings_path = STRINGS_DIR / "en.yaml"
        with canonical_strings_path.open("r", encoding="utf-8") as f:
            canonical_strings = yaml.safe_load(f)
        missing_keys = set(canonical_strings) - set(strings)
        if missing_keys:
            errors.append(f"{lang}: UI strings missing keys: {sorted(missing_keys)}")

        # Content translations
        lang_dir = TRANSLATIONS_DIR / lang
        if not lang_dir.exists():
            coverage[lang] = 0.0
            if COVERAGE_TARGETS[lang] > 0:
                errors.append(f"{lang}: no translations found (target {COVERAGE_TARGETS[lang]:.0%})")
            continue

        translated_ids: set[str] = set()
        for sidecar_path in lang_dir.rglob("*.pnk.yaml"):
            with sidecar_path.open("r", encoding="utf-8") as f:
                data = yaml.safe_load(f)
            for err in validator.iter_errors(data):
                errors.append(f"{sidecar_path}: {err.json_path}: {err.message}")
            tid = data.get("translation_of") or data.get("id")
            if tid in canonical:
                translated_ids.add(tid)
            else:
                errors.append(f"{sidecar_path}: translation_of {tid} not found in canonical set")

        coverage[lang] = len(translated_ids) / len(canonical)
        if coverage[lang] < COVERAGE_TARGETS[lang]:
            errors.append(
                f"{lang}: coverage {coverage[lang]:.1%} below target {COVERAGE_TARGETS[lang]:.0%}"
            )

    print("Translation coverage:")
    for lang, pct in sorted(coverage.items()):
        print(f"  {lang}: {pct:5.1%} (target {COVERAGE_TARGETS[lang]:.0%})")

    if errors:
        print(f"\ni18n validation failed with {len(errors)} error(s):", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1

    print("\ni18n validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
