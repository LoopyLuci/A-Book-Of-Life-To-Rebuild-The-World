#!/usr/bin/env python3
"""
Merge regional variants into the canonical entries.
Output: build/variants/<region>/<domain>/<slug>.md
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
VARIANTS_DIR = ROOT / "variants"
DOMAINS_DIR = ROOT / "domains"
BUILD_DIR = ROOT / "build" / "variants"

HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$", re.MULTILINE)


def _split_sections(markdown: str) -> list[tuple[str, str]]:
    matches = list(HEADING_RE.finditer(markdown))
    if not matches:
        return [("", markdown)]

    sections: list[tuple[str, str]] = []
    if matches[0].start() > 0:
        sections.append(("", markdown[: matches[0].start()]))
    for i, m in enumerate(matches):
        heading = m.group(2).strip()
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(markdown)
        sections.append((heading, markdown[start:end]))
    return sections


def _merge(canonical: str, variant: str, override_headings: list[str]) -> str:
    canon_sections = _split_sections(canonical)
    var_sections = dict(_split_sections(variant))

    out = []
    for heading, body in canon_sections:
        if heading in override_headings and heading in var_sections:
            out.append(f"## {heading}{var_sections[heading]}")
        else:
            out.append(f"## {heading}{body}" if heading else body)
    return "".join(out)


def build() -> int:
    if not VARIANTS_DIR.exists():
        print("No variants directory.")
        return 0

    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    count = 0

    for sidecar_path in sorted(VARIANTS_DIR.rglob("*.pnk.yaml")):
        with sidecar_path.open("r", encoding="utf-8") as f:
            meta = yaml.safe_load(f)

        region = meta["region"]
        rel = sidecar_path.relative_to(VARIANTS_DIR / region)
        slug = rel.name[: -len(".pnk.yaml")]
        md_path = VARIANTS_DIR / region / rel.parent / f"{slug}.md"
        if not md_path.exists():
            print(f"  skip (no markdown): {md_path}")
            continue

        canonical = DOMAINS_DIR / rel.parent / f"{slug}.md"
        if not canonical.exists():
            print(f"  skip (no canonical): {canonical}")
            continue

        merged = _merge(
            canonical.read_text(encoding="utf-8"),
            md_path.read_text(encoding="utf-8"),
            meta.get("overrides", []),
        )

        out_dir = BUILD_DIR / region / rel.parent
        out_dir.mkdir(parents=True, exist_ok=True)
        (out_dir / f"{slug}.md").write_text(merged, encoding="utf-8")
        count += 1
        print(f"  {region}/{rel.parent}: {meta['variant_of']}")

    print(f"Built {count} variant(s) into {BUILD_DIR}")
    return 0


if __name__ == "__main__":
    sys.exit(build())
