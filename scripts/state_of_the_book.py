#!/usr/bin/env python3
"""
Generate the annual State of the Book report.

Outputs:
- build/reports/state-of-the-book-<year>.md
- build/reports/state-of-the-book-<year>.html
- build/reports/state-of-the-book-<year>.json
"""

from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
INDEX_PATH = ROOT / "build" / "index.db"
SIDECARS_DIR = ROOT / "sidecars"
FIELD_TESTS_DIR = ROOT / "field-tests"
LEDGER_PATH = ROOT / "governance" / "verification-ledger.jsonl"
REPORTS_DIR = ROOT / "build" / "reports"

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>State of the Book {year} — A Book Of Life To Rebuild The World</title>
<style>
body {{ font-family: Georgia, serif; max-width: 60rem; margin: 2rem auto;
        padding: 0 1rem; line-height: 1.65; color: #1a1a1a; background: #fafaf7; }}
h1 {{ border-bottom: 3px solid #8b5a2b; padding-bottom: .5rem; }}
h2 {{ border-bottom: 1px solid #ddd; padding-bottom: .3rem; margin-top: 2.5rem; }}
table {{ border-collapse: collapse; width: 100%; margin: 1rem 0; }}
th, td {{ border: 1px solid #ddd; padding: .4rem .6rem; text-align: left; }}
th {{ background: #f0ece4; }}
.big {{ font-size: 2.5rem; font-weight: 700; }}
.grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 1rem; }}
.card {{ background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 1rem; }}
.card h3 {{ margin: 0 0 .3rem; font-size: .8rem; color: #666; text-transform: uppercase; }}
footer {{ margin-top: 3rem; border-top: 1px solid #ddd; padding-top: 1rem; font-size: .8rem; color: #666; }}
</style>
</head>
<body>
<h1>State of the Book — {year}</h1>
<p>Generated {generated_at}.</p>

<div class="grid">
  <div class="card"><h3>Total Entries</h3><div class="big">{total}</div></div>
  <div class="card"><h3>Field-Tested</h3><div class="big">{field_tested}</div></div>
  <div class="card"><h3>Peer-Reviewed</h3><div class="big">{peer_reviewed}</div></div>
  <div class="card"><h3>Draft</h3><div class="big">{draft}</div></div>
</div>

<h2>Growth</h2>
<table>
<thead><tr><th>Metric</th><th>Value</th></tr></thead>
<tbody>
<tr><td>New entries this year</td><td>{new_entries}</td></tr>
<tr><td>New field tests</td><td>{new_field_tests}</td></tr>
<tr><td>Verification events</td><td>{verification_events}</td></tr>
<tr><td>Languages</td><td>{languages}</td></tr>
</tbody>
</table>

<h2>By Domain</h2>
<table>
<thead><tr><th>Domain</th><th>Total</th><th>Field-Tested</th><th>Peer-Reviewed</th><th>Draft</th></tr></thead>
<tbody>
{domain_rows}
</tbody>
</table>

<h2>By Safety</h2>
<table>
<thead><tr><th>Level</th><th>Count</th></tr></thead>
<tbody>
{safety_rows}
</tbody>
</table>

<h2>By Difficulty</h2>
<table>
<thead><tr><th>Level</th><th>Count</th></tr></thead>
<tbody>
{difficulty_rows}
</tbody>
</table>

<h2>Notable Field Tests</h2>
<ul>
{field_test_items}
</ul>

<h2>Governance</h2>
<p>
This year the project operated under <a href="../../governance/CHARTER.md">Charter v1.0.0</a>.
All verification transitions were logged in the append-only ledger and
audited by independent maintainers.
</p>

<footer>
  <p>A Book Of Life To Rebuild The World — State of the Book {year}.</p>
  <p>Content CC BY-SA 4.0. Code MIT.</p>
</footer>
</body>
</html>
"""


def _entries():
    for path in sorted(SIDECARS_DIR.rglob("*.pnk.yaml")):
        with path.open("r", encoding="utf-8") as f:
            yield yaml.safe_load(f)


def _load_ledger():
    if not LEDGER_PATH.exists():
        return []
    out = []
    for line in LEDGER_PATH.read_text(encoding="utf-8").splitlines():
        if line.strip():
            out.append(json.loads(line))
    return out


def _field_tests():
    if not FIELD_TESTS_DIR.exists():
        return []
    out = []
    for path in sorted(FIELD_TESTS_DIR.glob("*.yaml")):
        with path.open("r", encoding="utf-8") as f:
            out.append(yaml.safe_load(f))
    return out


def build(year: int, dry_run: bool = False) -> int:
    entries = list(_entries())
    ledger = _load_ledger()
    field_tests = _field_tests()

    status_counts = Counter(e["verification"]["status"] for e in entries)
    domain_status: dict[str, Counter] = defaultdict(Counter)
    safety_counts: Counter = Counter()
    difficulty_counts: Counter = Counter()
    languages = set()

    for e in entries:
        domain_status[e["domain"]][e["verification"]["status"]] += 1
        safety_counts[e["safety"]] += 1
        difficulty_counts[e["difficulty"]] += 1
        languages.add(e.get("language", "en"))

    new_entries = sum(
        1 for e in entries
        if e["verification"].get("date", "").startswith(str(year))
    )
    new_field_tests = sum(
        1 for ft in field_tests if ft.get("date", "").startswith(str(year))
    )
    verification_events = sum(
        1 for ev in ledger if ev.get("timestamp", "").startswith(str(year))
    )

    total = len(entries)
    field_tested = status_counts.get("field-tested", 0)
    peer_reviewed = status_counts.get("peer-reviewed", 0)
    draft = status_counts.get("draft", 0)

    domain_rows = "\n".join(
        f"<tr><td>{d}</td><td>{sum(c.values())}</td>"
        f"<td>{c.get('field-tested',0)}</td>"
        f"<td>{c.get('peer-reviewed',0)}</td>"
        f"<td>{c.get('draft',0)}</td></tr>"
        for d, c in sorted(domain_status.items())
    )
    safety_rows = "\n".join(
        f"<tr><td>{k}</td><td>{v}</td></tr>" for k, v in sorted(safety_counts.items())
    )
    difficulty_rows = "\n".join(
        f"<tr><td>{k}</td><td>{v}</td></tr>" for k, v in sorted(difficulty_counts.items())
    )
    field_test_items = "\n".join(
        f"<li><strong>{ft['entry_id']}</strong> — tested by {ft['tester']} "
        f"at {ft['location']} on {ft['date']}</li>"
        for ft in field_tests
        if ft.get("date", "").startswith(str(year))
    ) or "<li>No field tests recorded this year.</li>"

    context = {
        "year": year,
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "total": total,
        "field_tested": field_tested,
        "peer_reviewed": peer_reviewed,
        "draft": draft,
        "new_entries": new_entries,
        "new_field_tests": new_field_tests,
        "verification_events": verification_events,
        "languages": len(languages),
        "domain_rows": domain_rows,
        "safety_rows": safety_rows,
        "difficulty_rows": difficulty_rows,
        "field_test_items": field_test_items,
    }

    if dry_run:
        print(json.dumps(context, indent=2))
        return 0

    REPORTS_DIR.mkdir(parents=True, exist_ok=True)

    html = HTML_TEMPLATE.format(**context)
    (REPORTS_DIR / f"state-of-the-book-{year}.html").write_text(html, encoding="utf-8")

    md = f"""# State of the Book — {year}

Generated {context['generated_at']}.

## Headline numbers

- Total entries: **{total}**
- Field-tested: **{field_tested}**
- Peer-reviewed: **{peer_reviewed}**
- Draft: **{draft}**

## Growth

- New entries: **{new_entries}**
- New field tests: **{new_field_tests}**
- Verification events: **{verification_events}**
- Languages: **{len(languages)}**

## By domain

| Domain | Total | Field-Tested | Peer-Reviewed | Draft |
|--------|------:|-------------:|--------------:|------:|
""" + "\n".join(
        f"| {d} | {sum(c.values())} | {c.get('field-tested',0)} | "
        f"{c.get('peer-reviewed',0)} | {c.get('draft',0)} |"
        for d, c in sorted(domain_status.items())
    ) + "\n\n## By safety\n\n| Level | Count |\n|-------|------:|\n" + "\n".join(
        f"| {k} | {v} |" for k, v in sorted(safety_counts.items())
    ) + "\n\n## By difficulty\n\n| Level | Count |\n|-------|------:|\n" + "\n".join(
        f"| {k} | {v} |" for k, v in sorted(difficulty_counts.items())
    ) + "\n"

    (REPORTS_DIR / f"state-of-the-book-{year}.md").write_text(md, encoding="utf-8")
    (REPORTS_DIR / f"state-of-the-book-{year}.json").write_text(
        json.dumps(context, indent=2), encoding="utf-8"
    )

    print(f"Reports written to {REPORTS_DIR}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(prog="abook-state")
    parser.add_argument("--year", type=int, default=datetime.now().year)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    return build(args.year, dry_run=args.dry_run)


if __name__ == "__main__":
    sys.exit(main())
