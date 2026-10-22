#!/usr/bin/env python3
"""
Build per-language indexes for the offline bundle.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
I18N_DIR = ROOT / "i18n"
TRANSLATIONS_DIR = I18N_DIR / "translations"
STRINGS_DIR = I18N_DIR / "strings"
BUILD_DIR = ROOT / "build" / "i18n"

LANGS = ["es", "fr", "de", "pt", "hi", "ar", "sw", "zh", "nl", "ru", "it", "ja"]


def build() -> int:
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    manifest: dict[str, dict] = {}

    for lang in LANGS:
        strings_path = STRINGS_DIR / f"{lang}.yaml"
        if not strings_path.exists():
            continue
        with strings_path.open("r", encoding="utf-8") as f:
            strings = yaml.safe_load(f)

        lang_dir = TRANSLATIONS_DIR / lang
        translated: list[dict] = []
        if lang_dir.exists():
            for sidecar_path in sorted(lang_dir.rglob("*.pnk.yaml")):
                with sidecar_path.open("r", encoding="utf-8") as f:
                    meta = yaml.safe_load(f)
                md_path = sidecar_path.with_suffix("").with_suffix(".md")
                translated.append(
                    {
                        "id": meta.get("id"),
                        "translation_of": meta.get("translation_of"),
                        "title": meta["title"],
                        "domain": meta["domain"],
                        "path": str(md_path.relative_to(ROOT)),
                    }
                )

        out = {
            "language": lang,
            "strings": strings,
            "translated_count": len(translated),
            "entries": translated,
        }
        out_path = BUILD_DIR / f"{lang}.json"
        out_path.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")
        manifest[lang] = {
            "translated_count": len(translated),
            "strings_complete": True,
        }
        print(f"  {lang}: {len(translated)} translation(s)")

    (BUILD_DIR / "manifest.json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8"
    )
    print(f"i18n build complete: {BUILD_DIR}")
    return 0


if __name__ == "__main__":
    sys.exit(build())
