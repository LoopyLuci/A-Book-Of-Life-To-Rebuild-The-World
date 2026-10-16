#!/usr/bin/env python3
"""
Build a fully offline browsable static site and ZIM archive for
A Book Of Life To Rebuild The World.
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

SITE_NAME = "A Book Of Life To Rebuild The World"
SITE_SLUG = "a-book-of-life"
ZIM_LANGUAGE = "eng"

STYLE_CSS = """
:root { --fg:#1a1a1a; --bg:#fafaf7; --accent:#8b5a2b; --muted:#666; }
* { box-sizing: border-box; }
body {
  font-family: Georgia, 'Iowan Old Style', serif;
  max-width: 52rem; margin: 0 auto; padding: 1.5rem; line-height: 1.65;
  color: var(--fg); background: var(--bg);
}
header.site { border-bottom: 2px solid var(--accent); padding-bottom: .75rem; margin-bottom: 1.5rem; }
header.site h1 { margin: 0; font-size: 1.5rem; }
header.site a { color: var(--accent); text-decoration: none; }
nav.crumbs { font-size: .85rem; color: var(--muted); margin-bottom: 1rem; }
article h1 { border-bottom: 1px solid #ddd; padding-bottom: .5rem; }
blockquote {
  color: var(--muted); border-left: 3px solid var(--accent);
  padding-left: 1rem; margin-left: 0; background: #f3efe8;
}
table { border-collapse: collapse; margin: 1rem 0; width: 100%; }
th, td { border: 1px solid #ccc; padding: .4rem .6rem; text-align: left; }
th { background: #f0ece4; }
code { background: #efe9e0; padding: .1rem .3rem; border-radius: 3px; }
pre { background: #efe9e0; padding: 1rem; overflow-x: auto; border-radius: 6px; }
.badges { margin: .5rem 0 1.5rem; font-size: .8rem; }
.badge { display: inline-block; padding: .15rem .5rem; margin-right: .35rem; border-radius: 3px; background: #e0d8c8; }
.badge.red { background: #e8b4b4; }
.badge.yellow { background: #e8dcb4; }
.badge.green { background: #b4e8c0; }
footer { border-top: 1px solid #ddd; margin-top: 3rem; padding-top: 1rem; font-size: .8rem; color: var(--muted); }
input[type=search] { width: 100%; padding: .5rem; font-size: 1rem; margin: .5rem 0; }
#results li { margin: .5rem 0; }
"""

INDEX_HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>{site_name}</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
<header class="site">
  <h1><a href="index.html">{site_name}</a></h1>
</header>
<main>
  <p>A living, offline-first knowledge base for rebuilding civilization from first principles.</p>
  <input type="search" id="q" placeholder="Search {entry_count} entries...">
  <ul id="results"></ul>

  <h2>Domains</h2>
  <ul>
    {domain_list}
  </ul>
</main>
<footer>
  <p>Content licensed CC BY-SA 4.0. Code licensed MIT.</p>
</footer>
<script>
const INDEX_URL = 'search-index.json';
let docs = [];
fetch(INDEX_URL).then(r => r.json()).then(d => { docs = d; });

function score(doc, q) {
  const t = (doc.title + ' ' + doc.body).toLowerCase();
  const terms = q.toLowerCase().split(/\\s+/).filter(Boolean);
  let s = 0;
  for (const term of terms) {
    const idx = t.indexOf(term);
    if (idx >= 0) s += 1 + Math.max(0, 1 - idx / 5000);
  }
  return s;
}

document.getElementById('q').addEventListener('input', (e) => {
  const q = e.target.value.trim();
  const ul = document.getElementById('results');
  if (!q) { ul.innerHTML = ''; return; }
  const hits = docs
    .map(d => ({ d, s: score(d, q) }))
    .filter(x => x.s > 0)
    .sort((a, b) => b.s - a.s)
    .slice(0, 30);
  ul.innerHTML = hits.map(({d}) =>
    `<li><a href="${d.path}">${d.title}</a> <small>(${d.domain})</small></li>`
  ).join('');
});
</script>
</body>
</html>
"""

ENTRY_TEMPLATE = """<!DOCTYPE html>
<html lang="{lang}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>{title} — {site_name}</title>
  <link rel="stylesheet" href="{rel_root}style.css">
</head>
<body>
<header class="site">
  <h1><a href="{rel_root}index.html">{site_name}</a></h1>
</header>
<nav class="crumbs">
  <a href="{rel_root}index.html">Home</a> ›
  <a href="{rel_root}{domain}/index.html">{domain_title}</a> ›
  {title}
</nav>
<div class="badges">
  <span class="badge">{domain}</span>
  <span class="badge">{difficulty}</span>
  <span class="badge {safety}">{safety}</span>
  <span class="badge">{verification}</span>
</div>
<article>
{body_html}
</article>
<footer>
  <p>ID: <code>{entry_id}</code></p>
  <p>Content licensed CC BY-SA 4.0. Code licensed MIT.</p>
</footer>
</body>
</html>
"""


def _domain_title(name: str) -> str:
    return name.replace("-", " ").title()


def _reset_bundle() -> None:
    if BUNDLE_DIR.exists():
        shutil.rmtree(BUNDLE_DIR)
    HTML_DIR.mkdir(parents=True)


def _write_css() -> None:
    (HTML_DIR / "style.css").write_text(STYLE_CSS, encoding="utf-8")


def _load_all():
    entries = []
    for sidecar_path in sorted(SIDECARS_DIR.rglob("*.pnk.yaml")):
        rel = sidecar_path.relative_to(SIDECARS_DIR)
        md_path = DOMAINS_DIR / rel.with_suffix("").with_suffix(".md")
        if not md_path.exists():
            continue
        with sidecar_path.open("r", encoding="utf-8") as f:
            meta = yaml.safe_load(f)
        entries.append((meta, md_path))
    return entries


def _render_entry(meta: dict, md_path: Path) -> str:
    body_md = md_path.read_text(encoding="utf-8")
    body_html = markdown.markdown(
        body_md,
        extensions=["tables", "fenced_code", "toc", "sane_lists"],
    )
    rel_root = "../../"
    return ENTRY_TEMPLATE.format(
        lang=meta.get("language", "en"),
        title=meta["title"],
        site_name=SITE_NAME,
        rel_root=rel_root,
        domain=meta["domain"],
        domain_title=_domain_title(meta["domain"]),
        difficulty=meta["difficulty"],
        safety=meta["safety"],
        verification=meta["verification"]["status"],
        body_html=body_html,
        entry_id=meta["id"],
    )


def _render_domain_index(domain: str, entries: list[tuple[dict, Path]]) -> str:
    items = "\n".join(
        f'    <li><a href="../{domain}/{md.stem}.html">{meta["title"]}</a> '
        f'<small>({meta["difficulty"]}, {meta["safety"]})</small></li>'
        for meta, md in entries
    )
    return f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<title>{_domain_title(domain)} — {SITE_NAME}</title>
<link rel="stylesheet" href="../style.css"></head>
<body>
<header class="site"><h1><a href="../index.html">{SITE_NAME}</a></h1></header>
<nav class="crumbs"><a href="../index.html">Home</a> › {_domain_title(domain)}</nav>
<h2>{_domain_title(domain)}</h2>
<ul>
{items}
</ul>
<footer><p>Content licensed CC BY-SA 4.0.</p></footer>
</body></html>
"""


def _render_root_index(by_domain: dict[str, int], entry_count: int) -> str:
    domain_list = "\n".join(
        f'    <li><a href="{d}/index.html">{_domain_title(d)}</a> — {n} entries</li>'
        for d, n in sorted(by_domain.items())
    )
    return (
        INDEX_HTML_TEMPLATE.replace("{site_name}", SITE_NAME)
        .replace("{entry_count}", str(entry_count))
        .replace("{domain_list}", domain_list)
    )


def _write_search_index(entries: list[tuple[dict, Path]]) -> None:
    docs = []
    for meta, md in entries:
        docs.append(
            {
                "id": meta["id"],
                "title": meta["title"],
                "domain": meta["domain"],
                "path": f"{meta['domain']}/{md.stem}.html",
                "body": md.read_text(encoding="utf-8"),
            }
        )
    (HTML_DIR / "search-index.json").write_text(
        json.dumps(docs), encoding="utf-8"
    )


def _build_zim() -> Path | None:
    zim_out = BUNDLE_DIR / f"{SITE_SLUG}.zim"
    if not shutil.which("zimwriterfs"):
        print("zimwriterfs not found; skipping ZIM. Install kiwix-tools to build.")
        return None

    # Minimal ZIM metadata files expected by zimwriterfs
    (HTML_DIR / "favicon.png").write_bytes(b"")  # placeholder
    (HTML_DIR / "Description").write_text(
        "A living, offline-first knowledge base for rebuilding civilization.",
        encoding="utf-8",
    )

    cmd = [
        "zimwriterfs",
        "--welcome", "index.html",
        "--favicon", "favicon.png",
        "--language", ZIM_LANGUAGE,
        "--title", SITE_NAME,
        "--description", "Rebuild the world from first principles.",
        "--creator", "A Book Of Life Contributors",
        "--publisher", "A Book Of Life",
        str(HTML_DIR),
        str(zim_out),
    ]
    subprocess.run(cmd, check=True)
    return zim_out


def build() -> int:
    _reset_bundle()
    _write_css()

    entries = _load_all()
    if not entries:
        print("No entries found. Aborting.", file=sys.stderr)
        return 1

    by_domain: dict[str, list[tuple[dict, Path]]] = {}
    for meta, md in entries:
        by_domain.setdefault(meta["domain"], []).append((meta, md))

    # Entry pages
    for meta, md in entries:
        out_dir = HTML_DIR / meta["domain"]
        out_dir.mkdir(parents=True, exist_ok=True)
        (out_dir / f"{md.stem}.html").write_text(
            _render_entry(meta, md), encoding="utf-8"
        )

    # Domain indexes
    for domain, dom_entries in by_domain.items():
        out_dir = HTML_DIR / domain
        out_dir.mkdir(parents=True, exist_ok=True)
        (out_dir / "index.html").write_text(
            _render_domain_index(domain, dom_entries), encoding="utf-8"
        )

    # Root index
    (HTML_DIR / "index.html").write_text(
        _render_root_index({d: len(v) for d, v in by_domain.items()}, len(entries)),
        encoding="utf-8",
    )

    # Client-side search index
    _write_search_index(entries)

    # ZIM
    zim_path = _build_zim()

    manifest = {
        "site_name": SITE_NAME,
        "site_slug": SITE_SLUG,
        "entry_count": len(entries),
        "domain_count": len(by_domain),
        "html_dir": str(HTML_DIR.relative_to(ROOT)),
        "zim": str(zim_path.relative_to(ROOT)) if zim_path else None,
    }
    (BUNDLE_DIR / "bundle-manifest.json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8"
    )

    print(f"Offline bundle built at {HTML_DIR}")
    if zim_path:
        print(f"ZIM archive: {zim_path}")
    return 0


if __name__ == "__main__":
    sys.exit(build())
