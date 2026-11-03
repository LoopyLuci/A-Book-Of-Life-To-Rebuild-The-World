#!/usr/bin/env python3
"""
Scaffold a new knowledge entry (Markdown + sidecar).

Usage: python scripts/new_entry.py <domain> <slug> "<Title>"

The generated files are a starting point, not a finished entry. Read
docs/ENTRIES.md before filling them in, and docs/DISCLAIMER.md before writing
anything that could be followed as a procedure.
"""

from __future__ import annotations

import sys
from pathlib import Path

import yaml
from ulid import new_pnk

ROOT = Path(__file__).resolve().parent.parent
DOMAINS_DIR = ROOT / "domains"
SIDECARS_DIR = ROOT / "sidecars"

VALID_DOMAINS = {
    "survival", "water", "agriculture", "materials", "energy",
    "construction", "transport", "health", "knowledge", "society",
    "chemistry", "biology", "silicon", "ship", "computers", "quantum",
}

NOTICE = (
    "*Reference material only. Verify this information against primary sources\n"
    "and qualified professionals before acting on it. This entry is not a sole\n"
    "source of information.*"
)

TEMPLATE_MD = """# {title}

> **Domain:** {domain} | **Difficulty:** novice | **Safety:** green

{notice}

## Overview

_Describe what this entry enables and why it matters. State the key principle
in one or two sentences and say what the reader will be able to do afterwards._

## Prerequisites

- None

## Materials & Tools

- TBD

## Procedure

1. Step one.
2. Step two.

## Safety Notes

- TBD
- State the real hazard here, and the training, equipment and supervision the
  work needs.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- TBD
"""


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: new_entry.py <domain> <slug> \"<Title>\"", file=sys.stderr)
        return 1

    domain, slug, title = sys.argv[1], sys.argv[2], sys.argv[3]

    if domain not in VALID_DOMAINS:
        print(f"Invalid domain. Choose one of: {sorted(VALID_DOMAINS)}", file=sys.stderr)
        return 1

    pnk = new_pnk(domain, slug)

    md_path = DOMAINS_DIR / domain / f"{slug}.md"
    sidecar_path = SIDECARS_DIR / domain / f"{slug}.pnk.yaml"

    md_path.parent.mkdir(parents=True, exist_ok=True)
    sidecar_path.parent.mkdir(parents=True, exist_ok=True)

    if md_path.exists() or sidecar_path.exists():
        print("Entry already exists.", file=sys.stderr)
        return 1

    md_path.write_text(
        TEMPLATE_MD.format(title=title, domain=domain, notice=NOTICE),
        encoding="utf-8",
    )

    sidecar = {
        "id": pnk,
        "title": title,
        "domain": domain,
        "tags": [slug],
        "difficulty": "novice",
        "safety": "green",
        "time_to_complete": "hours",
        "yield": "",
        "season": "",
        "storage": "",
        "cost": "low",
        "hazards": [],
        "resource_budget": {
            "batch": "",
            "labor_hours": 0,
            "energy_kwh": 0,
            "water_liters": 0,
        },
        "lifespan": "",
        "maintenance": "",
        "limits": [],
        "prerequisites": [],
        "materials_required": [],
        "tools_required": [],
        "sources": [{"title": "Original", "license": "original"}],
        "verification": {"status": "draft"},
        "links": [],
        "geographic_applicability": ["universal"],
        "language": "en",
        "media": [],
    }

    with sidecar_path.open("w", encoding="utf-8") as f:
        yaml.safe_dump(sidecar, f, sort_keys=False, allow_unicode=True)

    print(f"Created:\n  {md_path}\n  {sidecar_path}")
    print("\nNext: read docs/ENTRIES.md, then fill in the entry and its sidecar,")
    print("and run: python scripts/validate.py")
    return 0


if __name__ == "__main__":
    sys.exit(main())
