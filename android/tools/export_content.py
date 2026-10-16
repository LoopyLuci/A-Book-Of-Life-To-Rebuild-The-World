#!/usr/bin/env python3
"""
Export the A Book Of Life knowledge base into Android app assets.

Reads:
  domains/**/*.md            canonical entries (Markdown)
  sidecars/**/*.pnk.yaml     metadata sidecars
  i18n/strings/*.yaml        UI string translations
  manifest.toml              KB version

Writes:
  android/app/src/main/assets/content/entries.json
  android/app/src/main/assets/content/domains.json
  android/app/src/main/assets/content/meta.json
  android/core/designsystem/src/main/res/values-<lang>/strings.xml   (translations)

Translations are emitted next to the design-system module's default English
strings so that lint sees each translation alongside its default-locale
counterpart (otherwise it reports spurious ExtraTranslation errors).
"""

from __future__ import annotations

import hashlib
import json
import re
import shutil
import sys
import tomllib
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
DOMAINS_DIR = ROOT / "domains"
SIDECARS_DIR = ROOT / "sidecars"
I18N_DIR = ROOT / "i18n" / "strings"
MANIFEST = ROOT / "manifest.toml"

ANDROID_DIR = ROOT / "android"
ASSETS_DIR = ANDROID_DIR / "app" / "src" / "main" / "assets" / "content"
RES_DIR = ANDROID_DIR / "app" / "src" / "main" / "res"
DS_RES_DIR = ANDROID_DIR / "core" / "designsystem" / "src" / "main" / "res"

DOMAIN_META = {
    "survival": ("Survival & Immediate Needs", "Water, fire, shelter, first aid", "local_fire_department", "#D84315"),
    "agriculture": ("Agriculture & Food Systems", "Soil, crops, livestock, preservation", "eco", "#2E7D32"),
    "materials": ("Materials & Fabrication", "Metals, glass, chemicals, textiles", "handyman", "#6D4C41"),
    "energy": ("Energy & Power", "Generation, storage, conversion", "bolt", "#F9A825"),
    "construction": ("Construction & Infrastructure", "Shelter, roads, water, sanitation", "architecture", "#455A64"),
    "health": ("Health & Medicine", "Diagnosis, surgery, medicine, care", "medical_services", "#C62828"),
    "knowledge": ("Knowledge & Communication", "Printing, radio, education, records", "menu_book", "#1565C0"),
    "society": ("Society & Governance", "Law, economics, ethics, community", "groups", "#6A1B9A"),
}

VALID_DOMAINS = list(DOMAIN_META.keys())


def kb_version() -> str:
    if MANIFEST.exists():
        with MANIFEST.open("rb") as f:
            data = tomllib.load(f)
        return data.get("project", {}).get("version", "0.0.0")
    return "0.0.0"


def strip_leading_title_block(body: str) -> str:
    """Drop the leading H1 title and metadata blockquote from an entry body.

    The reader already renders the entry title and its metadata, so the
    Markdown body should begin at the first real content heading.
    """
    lines = body.splitlines()
    i = 0
    while i < len(lines) and not lines[i].strip():
        i += 1
    if i < len(lines) and lines[i].startswith("# "):
        i += 1
        while i < len(lines) and not lines[i].strip():
            i += 1
        while i < len(lines) and lines[i].lstrip().startswith(">"):
            i += 1
    return "\n".join(lines[i:]).lstrip("\n")


def load_entries() -> list[dict]:
    entries = []
    for sidecar_path in sorted(SIDECARS_DIR.rglob("*.pnk.yaml")):
        rel = sidecar_path.relative_to(SIDECARS_DIR)
        md_path = DOMAINS_DIR / rel.with_suffix("").with_suffix(".md")
        if not md_path.exists():
            print(f"  skip (no markdown): {sidecar_path}", file=sys.stderr)
            continue
        with sidecar_path.open("r", encoding="utf-8") as f:
            meta = yaml.safe_load(f)
        body = strip_leading_title_block(md_path.read_text(encoding="utf-8"))
        verification = meta.get("verification", {}) or {}
        sources = []
        for s in meta.get("sources", []) or []:
            if isinstance(s, str):
                sources.append({"title": s, "license": "public-domain"})
            else:
                sources.append({
                    "title": s.get("title", ""),
                    "author": s.get("author", ""),
                    "url": s.get("url", ""),
                    "license": s.get("license", ""),
                    "year": s.get("year", 0),
                })
        entries.append({
            "id": meta["id"],
            "slug": md_path.stem,
            "title": meta["title"],
            "domain": meta["domain"],
            "tags": list(meta.get("tags", []) or []),
            "difficulty": meta["difficulty"],
            "safety": meta["safety"],
            "timeToComplete": meta.get("time_to_complete", ""),
            "prerequisites": list(meta.get("prerequisites", []) or []),
            "materialsRequired": list(meta.get("materials_required", []) or []),
            "toolsRequired": list(meta.get("tools_required", []) or []),
            "sources": sources,
            "verification": {
                "status": verification.get("status", "draft"),
                "reviewers": list(verification.get("reviewers", []) or []),
                "testedBy": verification.get("tested_by", "") or "",
                "date": str(verification.get("date", "") or ""),
                "location": verification.get("location", "") or "",
                "notes": verification.get("notes", "") or "",
            },
            "links": list(meta.get("links", []) or []),
            "regions": list(meta.get("geographic_applicability", ["universal"]) or ["universal"]),
            "language": meta.get("language", "en"),
            "body": body,
        })
    return entries


def build_domains(entries: list[dict]) -> list[dict]:
    counts: dict[str, int] = {}
    for e in entries:
        counts[e["domain"]] = counts.get(e["domain"], 0) + 1
    out = []
    for slug, (title, desc, icon, color) in DOMAIN_META.items():
        out.append({
            "slug": slug,
            "title": title,
            "description": desc,
            "icon": icon,
            "color": color,
            "entryCount": counts.get(slug, 0),
        })
    return out


def _android_escape(value: str) -> str:
    value = value.replace("{count}", "%1$d")
    value = value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    value = value.replace("'", "\\'").replace('"', '\\"')
    return value


def write_translations() -> None:
    langs: list[str] = []
    for src in sorted(I18N_DIR.glob("*.yaml")):
        lang = src.stem
        if lang == "en":
            continue
        langs.append(lang)
        with src.open("r", encoding="utf-8") as f:
            strings = yaml.safe_load(f) or {}
        out_dir = DS_RES_DIR / f"values-{lang}"
        out_dir.mkdir(parents=True, exist_ok=True)
        lines = ['<?xml version="1.0" encoding="utf-8"?>', "<resources>"]
        for key, value in strings.items():
            lines.append(f'    <string name="{key}">{_android_escape(str(value))}</string>')
        lines.append("</resources>")
        (out_dir / "strings.xml").write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"  wrote {out_dir.relative_to(ROOT)}/strings.xml ({len(strings)} strings)")

    for lang in langs:
        legacy = RES_DIR / f"values-{lang}"
        if legacy.exists():
            shutil.rmtree(legacy)
            print(f"  removed legacy {legacy.relative_to(ROOT)}")


def main() -> int:
    if not SIDECARS_DIR.exists():
        print("No sidecars found.", file=sys.stderr)
        return 1

    entries = load_entries()
    domains = build_domains(entries)
    version = kb_version()

    ASSETS_DIR.mkdir(parents=True, exist_ok=True)

    entries_json = json.dumps(entries, ensure_ascii=False, separators=(",", ":"))
    (ASSETS_DIR / "entries.json").write_text(entries_json, encoding="utf-8")
    (ASSETS_DIR / "domains.json").write_text(
        json.dumps(domains, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    meta = {
        "kbVersion": version,
        "contentHash": hashlib.sha256(entries_json.encode("utf-8")).hexdigest()[:16],
        "entryCount": len(entries),
        "domainCount": len(domains),
        "defaultLanguage": "en",
        "license": "CC-BY-SA-4.0",
        "generatedBy": "android/tools/export_content.py",
    }
    (ASSETS_DIR / "meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print(f"Exported {len(entries)} entries across {len(domains)} domains (KB {version})")
    for d in domains:
        print(f"  {d['slug']:<13} {d['entryCount']:>3} entries")
    write_translations()

    total_chars = sum(len(e["body"]) for e in entries)
    print(f"Content payload: {total_chars / 1024:.0f} KB of Markdown")
    return 0


if __name__ == "__main__":
    sys.exit(main())
