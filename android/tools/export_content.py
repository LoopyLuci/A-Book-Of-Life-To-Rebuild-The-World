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
    "water": ("Water & Sanitation", "Harvesting, storage, springs, reuse", "water_drop", "#0277BD"),
    "agriculture": ("Agriculture & Food Systems", "Soil, crops, livestock, preservation", "eco", "#2E7D32"),
    "materials": ("Materials & Fabrication", "Metals, glass, chemicals, textiles", "handyman", "#6D4C41"),
    "energy": ("Energy & Power", "Generation, storage, conversion", "bolt", "#F9A825"),
    "construction": ("Construction & Infrastructure", "Shelter, roads, water, sanitation", "architecture", "#455A64"),
    "transport": ("Transport & Logistics", "Carts, pack animals, ferries, bicycles", "local_shipping", "#EF6C00"),
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


def strip_trailing_meta_sections(body: str) -> str:
    """Drop the trailing Verification/Sources sections.

    The app renders both from structured sidecar data (with clickable source
    rows and verification badges), so leaving the Markdown copies in the body
    would duplicate them and, worse, repeat unverified prose such as
    "Tested by: -".
    """
    lines = body.splitlines()
    for index, line in enumerate(lines):
        if re.match(r"^##\s+(verification|sources)\s*$", line.strip(), re.IGNORECASE):
            lines = lines[:index]
            break
    return "\n".join(lines).rstrip() + "\n"


def section_bullets(body: str, heading: str) -> list[str]:
    """Extract bullet items from a level-2 Markdown section."""
    lines = body.splitlines()
    start = None
    for index, line in enumerate(lines):
        if re.match(rf"^##\s+{re.escape(heading)}\s*$", line.strip(), re.IGNORECASE):
            start = index + 1
            break
    if start is None:
        return []
    items: list[str] = []
    for line in lines[start:]:
        if line.startswith("## "):
            break
        match = re.match(r"^\s*[-*]\s+(.+?)\s*$", line)
        if match:
            text = re.sub(r"\*\*(.+?)\*\*", r"\1", match.group(1)).strip()
            if text:
                items.append(text)
    return items


VALID_URL = re.compile(r"^https?://\S+$")


def normalize_sources(raw_sources: list) -> list[dict]:
    """Convert sidecar sources into clean, de-duplicated citation records.

    String sources keep only their title: earlier versions silently stamped
    every one of them as "public-domain", which was not verifiable and often
    wrong. Missing urls are left blank so the UI can offer a search instead of
    presenting an invented link.
    """
    normalized: list[dict] = []
    seen: set[tuple[str, str]] = set()
    for source in raw_sources or []:
        if isinstance(source, str):
            title, author, url, license_name, year = source.strip(), "", "", "", 0
        elif isinstance(source, dict):
            title = str(source.get("title", "") or "").strip()
            author = str(source.get("author", "") or "").strip()
            url = str(source.get("url", "") or "").strip()
            license_name = str(source.get("license", "") or "").strip()
            raw_year = source.get("year", 0) or 0
            try:
                year = int(raw_year)
            except (TypeError, ValueError):
                year = 0
        else:
            continue
        if not title:
            continue
        if url and not VALID_URL.match(url):
            print(f"  warn: dropping invalid source url for {title!r}: {url}", file=sys.stderr)
            url = ""
        key = (title.casefold(), url)
        if key in seen:
            continue
        seen.add(key)
        normalized.append({
            "title": title,
            "author": author,
            "url": url,
            "license": license_name,
            "year": year,
        })
    return normalized


def prune_dangling_references(entries: list[dict]) -> None:
    """Remove prerequisite/link ids that do not resolve to an exported entry."""
    known_ids = {entry["id"] for entry in entries}
    for entry in entries:
        for field in ("prerequisites", "links"):
            kept = []
            dropped = []
            for ref in entry.get(field, []):
                (kept if ref in known_ids else dropped).append(ref)
            if dropped:
                print(
                    f"  warn: {entry['slug']} dropped dangling {field}: {dropped}",
                    file=sys.stderr,
                )
            entry[field] = kept


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
        body = strip_trailing_meta_sections(
            strip_leading_title_block(md_path.read_text(encoding="utf-8"))
        )
        verification = meta.get("verification", {}) or {}
        sources = normalize_sources(meta.get("sources", []))
        materials = list(meta.get("materials_required", []) or [])
        tools = list(meta.get("tools_required", []) or [])
        if not materials and not tools:
            materials = section_bullets(body, "Materials & Tools")
        entries.append({
            "id": meta["id"],
            "slug": md_path.stem,
            "title": meta["title"],
            "domain": meta["domain"],
            "tags": list(meta.get("tags", []) or []),
            "difficulty": meta["difficulty"],
            "safety": meta["safety"],
            "timeToComplete": meta.get("time_to_complete", ""),
            "yield": meta.get("yield", "") or "",
            "season": meta.get("season", "") or "",
            "storage": meta.get("storage", "") or "",
            "cost": meta.get("cost", "unknown") or "unknown",
            "hazards": list(meta.get("hazards", []) or []),
            "prerequisites": list(meta.get("prerequisites", []) or []),
            "materialsRequired": materials,
            "toolsRequired": tools,
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
    prune_dangling_references(entries)
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
    source_total = sum(len(e["sources"]) for e in entries)
    source_linked = sum(1 for e in entries for s in e["sources"] if s["url"])
    print(
        f"Sources: {source_total} total "
        f"({source_linked} with links, {source_total - source_linked} searchable)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
