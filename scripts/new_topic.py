#!/usr/bin/env python3
"""
Scaffold a new domain (topic) in the knowledge base.

Usage:
  python scripts/new_topic.py <slug> --title "Title" --description "One line"

The script creates the domain directories, writes the domain README index,
and registers the domain everywhere it is listed: the sidecar schema, the
project manifest, the OpenAPI description, the search service and the Android
content exporter. It never overwrites an existing registration.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

DOMAINS_DIR = ROOT / "domains"
SIDECARS_DIR = ROOT / "sidecars"
SCHEMA_PATH = ROOT / "schemas" / "sidecar.schema.json"
MANIFEST_PATH = ROOT / "manifest.toml"
OPENAPI_PATH = ROOT / "api" / "openapi.yaml"
MCP_PATH = ROOT / "scripts" / "mcp_server.py"
EXPORT_PATH = ROOT / "android" / "tools" / "export_content.py"
DOMAINS_README = ROOT / "domains" / "README.md"

README_TEMPLATE = """# {title}

{description}

## Entries

| Entry | Difficulty | Safety | Time |
|-------|------------|--------|------|
"""

DOMAIN_ROW = (
    "| [{slug}]({slug}/README.md) | {description} | TBD |\n"
)

SCHEMA_ENUM_MARKER = '"enum": ['
MCP_ENUM_BLOCK = """                        "enum": [
                            "survival", "agriculture", "materials", "energy",
                            "construction", "health", "knowledge", "society",
                            "water", "transport", "chemistry", "biology",
                            "silicon", "ship", "computers", "quantum",
                        ],"""


def add_to_schema(slug: str) -> bool:
    text = SCHEMA_PATH.read_text(encoding="utf-8")
    if f'"{slug}"' in text:
        return False
    updated = re.sub(
        r'("enum": \[)([^\]]*)(\])',
        lambda m: m.group(1) + m.group(2).rstrip() + f', "{slug}"' + m.group(3),
        text,
        count=1,
    )
    SCHEMA_PATH.write_text(updated, encoding="utf-8")
    return True


def add_to_manifest(slug: str) -> bool:
    text = MANIFEST_PATH.read_text(encoding="utf-8")
    if f'  "{slug}",\n' in text:
        return False
    updated = text.replace(
        '  "society",\n]',
        f'  "society",\n  "{slug}",\n]',
        1,
    )
    if updated == text:
        raise SystemExit("Could not find the domain list in manifest.toml")
    MANIFEST_PATH.write_text(updated, encoding="utf-8")
    return True


def add_to_openapi(slug: str) -> bool:
    text = OPENAPI_PATH.read_text(encoding="utf-8")
    if f", {slug}]" in text:
        return False
    updated = text.replace(
        "society]",
        f"society, {slug}]",
        1,
    )
    OPENAPI_PATH.write_text(updated, encoding="utf-8")
    return True


def add_to_mcp(slug: str) -> bool:
    text = MCP_PATH.read_text(encoding="utf-8")
    if f'"{slug}",' in text:
        return False
    updated = text.replace(
        MCP_ENUM_BLOCK,
        MCP_ENUM_BLOCK.replace(
            '"quantum",',
            f'"quantum",\n                            "{slug}",',
        ),
        1,
    )
    if updated == text:
        raise SystemExit("Could not find the domain enum in scripts/mcp_server.py")
    MCP_PATH.write_text(updated, encoding="utf-8")
    return True


def add_to_android_exporter(slug: str, title: str, description: str) -> bool:
    text = EXPORT_PATH.read_text(encoding="utf-8")
    if f'"{slug}": (' in text:
        return False
    line = (
        f'    "{slug}": ("{title}", "{description}", "menu_book", "#546E7A"),\n'
    )
    updated = text.replace(
        '    "quantum": ("Quantum Computing", "Qubits, control, error correction, algorithms", "hub", "#D81B60"),\n',
        '    "quantum": ("Quantum Computing", "Qubits, control, error correction, algorithms", "hub", "#D81B60"),\n' + line,
        1,
    )
    if updated == text:
        raise SystemExit("Could not find DOMAIN_META in android/tools/export_content.py")
    EXPORT_PATH.write_text(updated, encoding="utf-8")
    return True


def add_to_domains_readme(slug: str, description: str) -> bool:
    text = DOMAINS_README.read_text(encoding="utf-8")
    if f"[{slug}]({slug}/README.md)" in text:
        return False
    row = DOMAIN_ROW.format(slug=slug, description=description)
    marker = "| [quantum](quantum/README.md) |"
    index = text.find(marker)
    if index == -1:
        raise SystemExit("Could not find the domain table in domains/README.md")
    end = text.find("\n", index) + 1
    updated = text[:end] + row + text[end:]
    DOMAINS_README.write_text(updated, encoding="utf-8")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("slug", help="Domain slug, for example ceramics")
    parser.add_argument("--title", required=True, help="Human readable domain title")
    parser.add_argument("--description", required=True, help="One line description")
    args = parser.parse_args()

    slug = args.slug.strip().lower()
    if not re.fullmatch(r"[a-z0-9-]+", slug):
        print("Domain slug must be lowercase letters, digits and hyphens.", file=sys.stderr)
        return 1

    domain_dir = DOMAINS_DIR / slug
    if domain_dir.exists():
        print(f"Domain directory already exists: {domain_dir}", file=sys.stderr)
        return 1

    domain_dir.mkdir(parents=True)
    (SIDECARS_DIR / slug).mkdir(parents=True)
    (domain_dir / "README.md").write_text(
        README_TEMPLATE.format(title=args.title, description=args.description),
        encoding="utf-8",
    )

    registered = []
    if add_to_schema(slug):
        registered.append("schemas/sidecar.schema.json")
    if add_to_manifest(slug):
        registered.append("manifest.toml")
    if add_to_openapi(slug):
        registered.append("api/openapi.yaml")
    if add_to_mcp(slug):
        registered.append("scripts/mcp_server.py")
    if add_to_android_exporter(slug, args.title, args.description):
        registered.append("android/tools/export_content.py")
    if add_to_domains_readme(slug, args.description):
        registered.append("domains/README.md")

    print(f"Created domain '{slug}':")
    print(f"  {domain_dir / 'README.md'}")
    print(f"  {SIDECARS_DIR / slug}")
    print("Registered in:")
    for path in registered:
        print(f"  {path}")
    if not registered:
        print("  (already registered)")
    print("\nNext: write the first entry with")
    print(f"  python scripts/new_entry.py {slug} <slug> \"<Title>\"")
    return 0


if __name__ == "__main__":
    sys.exit(main())
