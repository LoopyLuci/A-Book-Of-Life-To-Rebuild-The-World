#!/usr/bin/env python3
"""
Check a translation folder: file pairs, sidecar language tag, tag syntax
and rewritten relative links.

Usage:
    python scripts/check_i18n_translations.py [--lang ru] [--entries FILE]

The optional ``--entries`` file is the JSON work list that holds the
``domain``/``slug`` pairs to check; when it is omitted every entry found
under ``i18n/translations/<lang>`` is checked.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
TRANSLATIONS_DIR = ROOT / "i18n" / "translations"
DOMAINS_DIR = ROOT / "domains"

TAG_PATTERN = re.compile(r"^[a-z0-9-]+$")
LINK_PATTERN = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
EXPECTED_LINK_PREFIX = "../../../../domains/"


def check_sidecar(path: Path, lang: str, errors: list[str]) -> None:
    """Check one ``.pnk.yaml`` sidecar."""
    try:
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
    except yaml.YAMLError as exc:
        errors.append(f"{path}: YAML parse error: {exc}")
        return
    if not isinstance(data, dict):
        errors.append(f"{path}: the sidecar is not a mapping")
        return

    if data.get("language") != lang:
        errors.append(f"{path}: language is {data.get('language')!r}, expected {lang!r}")

    tags = data.get("tags")
    if not isinstance(tags, list) or not tags:
        errors.append(f"{path}: tags must be a non-empty list")
    else:
        for tag in tags:
            if not isinstance(tag, str) or not TAG_PATTERN.match(tag):
                errors.append(f"{path}: tag {tag!r} does not match {TAG_PATTERN.pattern}")

    if not data.get("translation_of"):
        errors.append(f"{path}: translation_of is missing")


def check_markdown(path: Path, errors: list[str]) -> None:
    """Check the relative links of one translated Markdown file."""
    text = path.read_text(encoding="utf-8")
    for target in LINK_PATTERN.findall(text):
        if target.startswith(("http://", "https://", "#", "mailto:")):
            continue
        if not target.startswith(EXPECTED_LINK_PREFIX):
            errors.append(f"{path}: relative link {target!r} does not start with {EXPECTED_LINK_PREFIX}")
            continue
        target_path = (path.parent / target).resolve()
        if not target_path.exists():
            errors.append(f"{path}: link {target!r} does not resolve to an existing file")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lang", default="ru", help="language code to check")
    parser.add_argument("--entries", type=Path, default=None, help="JSON work list")
    args = parser.parse_args()

    lang_dir = TRANSLATIONS_DIR / args.lang
    if not lang_dir.exists():
        print(f"No translations found for {args.lang}.", file=sys.stderr)
        return 1

    if args.entries:
        work = json.loads(args.entries.read_text(encoding="utf-8"))
        items = work[args.lang] if isinstance(work, dict) else work
        pairs = [(item["domain"], item["slug"]) for item in items]
    else:
        pairs = []
        for sidecar in sorted(lang_dir.rglob("*.pnk.yaml")):
            relative = sidecar.relative_to(lang_dir)
            pairs.append((relative.parts[0], sidecar.name[: -len(".pnk.yaml")]))

    errors: list[str] = []
    checked = 0
    for domain, slug in pairs:
        md_path = lang_dir / domain / f"{slug}.md"
        sidecar_path = lang_dir / domain / f"{slug}.pnk.yaml"
        if not md_path.exists():
            errors.append(f"{domain}/{slug}: missing Markdown file {md_path}")
        if not sidecar_path.exists():
            errors.append(f"{domain}/{slug}: missing sidecar {sidecar_path}")
        if not md_path.exists() or not sidecar_path.exists():
            continue
        checked += 1
        check_sidecar(sidecar_path, args.lang, errors)
        check_markdown(md_path, errors)

    print(f"checked {checked} entry/entries for {args.lang}")
    if errors:
        print(f"{len(errors)} problem(s) found:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1
    print(f"all {checked} entry/entries for {args.lang} passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
