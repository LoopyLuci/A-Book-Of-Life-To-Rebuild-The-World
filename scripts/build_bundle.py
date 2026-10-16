#!/usr/bin/env python3
"""
Build offline bundle: static HTML + ZIM file.
Requires `zimwriterfs` or `kiwix-tools` for ZIM generation.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

import markdown
import yaml

ROOT = Path(__file__).resolve().parent.parent
DOMAINS_DIR = ROOT / "domains"
SIDECARS_DIR = ROOT / "sidecars"
BUILD_DIR = ROOT / "build"
BUNDLE_DIR = BUILD_DIR / "offline-bundle"
HTML_DIR = BUNDLE_DIR / "html"


def render_entry(md_path: Path, meta: dict) -> str:
    body = md_path.read_text(encoding="utf-8")
    html_body = markdown.markdown(body, extensions=["tables", "fenced_code", "toc"])
    return f"""<!DOCTYPE html>
<html lang="{meta.get('language', 'en')}">
<head>
  <meta charset="utf-8">
  <title>{meta['title']}</title>
  <meta name="domain" content="{meta['domain']}">
  <meta name="difficulty" content="{meta['difficulty']}">
  <meta name="safety" content="{meta['safety']}">
  <link rel="stylesheet" href="/style.css">
</head>
<body>
<article>
{html_body}
</article>
</body>
</html>"""


def build() -> int:
    if BUNDLE_DIR.exists():
        shutil.rmtree(BUNDLE_DIR)
    HTML_DIR.mkdir(parents=True)

    css = "body{font-family:system-ui,sans-serif;max-width:48rem;margin:2rem auto;padding:0 1rem;line-height:1.6}article h1{border-bottom:1px solid #ccc;padding-bottom:.5rem}blockquote{color:#555;border-left:3px solid #ccc;padding-left:1rem}"
    (HTML_DIR / "style.css").write_text(css, encoding="utf-8")

    for sidecar_path in sorted(SIDECARS_DIR.rglob("*.pnk.yaml")):
        rel = sidecar_path.relative_to(SIDECARS_DIR)
        md_path = DOMAINS_DIR / rel.with_suffix("").with_suffix(".md")
        if not md_path.exists():
            continue
        with sidecar_path.open("r", encoding="utf-8") as f:
            meta = yaml.safe_load(f)

        out_dir = HTML_DIR / meta["domain"]
        out_dir.mkdir(parents=True, exist_ok=True)
        out_file = out_dir / f"{md_path.stem}.html"
        out_file.write_text(render_entry(md_path, meta), encoding="utf-8")

    print(f"Static HTML built at {HTML_DIR}")

    # Optional: build ZIM if zimwriterfs is available
    if shutil.which("zimwriterfs"):
        zim_out = BUNDLE_DIR / "book-of-life.zim"
        subprocess.run(
            [
                "zimwriterfs",
                "--welcome", "index.html",
                "--language", "eng",
                "--title", "Book of Life",
                "--description", "Rebuild the World",
                "--creator", "Book of Life Contributors",
                "--publisher", "Book of Life",
                str(HTML_DIR),
                str(zim_out),
            ],
            check=True,
        )
        print(f"ZIM built: {zim_out}")
    else:
        print("zimwriterfs not found; skipping ZIM generation.")

    manifest = {
        "kb_version": "0.1.0-alpha",
        "html_dir": str(HTML_DIR.relative_to(ROOT)),
    }
    (BUNDLE_DIR / "bundle-manifest.json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8"
    )
    return 0


if __name__ == "__main__":
    sys.exit(build())
