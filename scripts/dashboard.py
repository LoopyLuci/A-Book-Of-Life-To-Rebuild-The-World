#!/usr/bin/env python3
"""
Generate a static verification dashboard as a self-contained HTML file.
"""

from __future__ import annotations

import json
import sqlite3
from datetime import datetime
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
INDEX_PATH = ROOT / "build" / "index.db"
SIDECARS_DIR = ROOT / "sidecars"
FIELD_TESTS_DIR = ROOT / "field-tests"
LEDGER_PATH = ROOT / "governance" / "verification-ledger.jsonl"
OUT_PATH = ROOT / "build" / "dashboard.html"

TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Verification Dashboard — A Book Of Life To Rebuild The World</title>
<style>
:root {
  --fg:#1a1a1a; --bg:#fafaf7; --accent:#8b5a2b; --muted:#666;
  --green:#2e7d32; --yellow:#b28900; --red:#c62828; --blue:#1565c0;
}
* { box-sizing: border-box; }
body {
  font-family: -apple-system, system-ui, sans-serif;
  max-width: 72rem; margin: 0 auto; padding: 2rem;
  color: var(--fg); background: var(--bg);
}
h1 { border-bottom: 2px solid var(--accent); padding-bottom: .5rem; }
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 1rem; }
.card { background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 1rem; }
.card h3 { margin: 0 0 .5rem; font-size: .85rem; text-transform: uppercase; color: var(--muted); }
.card .value { font-size: 2rem; font-weight: 600; }
.bar { height: 12px; border-radius: 6px; background: #eee; overflow: hidden; margin-top: .5rem; }
.bar > span { display: block; height: 100%; }
table { border-collapse: collapse; width: 100%; margin-top: 1.5rem; }
th, td { border: 1px solid #ddd; padding: .45rem .6rem; text-align: left; font-size: .9rem; }
th { background: #f0ece4; }
.status-draft { color: var(--muted); }
.status-peer-reviewed { color: var(--blue); }
.status-field-tested { color: var(--green); font-weight: 600; }
.status-deprecated { color: var(--red); }
.badge { display: inline-block; padding: .1rem .5rem; border-radius: 3px; font-size: .75rem; }
.badge.green { background: #d4edda; color: #155724; }
.badge.yellow { background: #fff3cd; color: #856404; }
.badge.red { background: #f8d7da; color: #721c24; }
footer { margin-top: 2rem; color: var(--muted); font-size: .8rem; }
</style>
</head>
<body>
<h1>Verification Dashboard</h1>
<p>Generated {generated_at}</p>

<div class="grid">
  <div class="card"><h3>Total Entries</h3><div class="value">{total}</div></div>
  <div class="card"><h3>Field-Tested</h3><div class="value" style="color:var(--green)">{field_tested}</div>
    <div class="bar"><span style="width:{pct_field}%; background:var(--green)"></span></div>
    <small>{pct_field}% verified in the field</small>
  </div>
  <div class="card"><h3>Peer-Reviewed</h3><div class="value" style="color:var(--blue)">{peer_reviewed}</div></div>
  <div class="card"><h3>Draft</h3><div class="value" style="color:var(--muted)">{draft}</div></div>
</div>

<h2>Domain Breakdown</h2>
<table>
<thead><tr><th>Domain</th><th>Total</th><th>Draft</th><th>Peer-Reviewed</th><th>Field-Tested</th><th>Deprecated</th><th>% Field-Tested</th></tr></thead>
<tbody>
{domain_rows}
</tbody>
</table>

<h2>Safety Distribution</h2>
<table>
<thead><tr><th>Level</th><th>Count</th></tr></thead>
<tbody>
{safety_rows}
</tbody>
</table>

<h2>Difficulty Distribution</h2>
<table>
<thead><tr><th>Level</th><th>Count</th></tr></thead>
<tbody>
{difficulty_rows}
</tbody>
</table>

<h2>Recent Verification Events</h2>
<table>
<thead><tr><th>Date</th><th>Entry</th><th>From</th><th>To</th><th>Actor</th></tr></thead>
<tbody>
{recent_rows}
</tbody>
</table>

<footer>
  <p>A Book Of Life To Rebuild The World — verification dashboard.</p>
</footer>
</body>
</html>
"""


def _load_entries():
    """Yield (sidecar, domain)."""
    for path in sorted(SIDECARS_DIR.rglob("*.pnk.yaml")):
        with path.open("r", encoding="utf-8") as f:
            yield yaml.safe_load(f)


def _load_ledger():
    if not LEDGER_PATH.exists():
        return []
    events = []
    for line in LEDGER_PATH.read_text(encoding="utf-8").splitlines():
        if line.strip():
            events.append(json.loads(line))
    return events


def build() -> int:
    entries = list(_load_entries())
    total = len(entries)

    by_domain: dict[str, dict[str, int]] = {}
    safety_counts: dict[str, int] = {}
    difficulty_counts: dict[str, int] = {}
    status_counts = {"draft": 0, "peer-reviewed": 0, "field-tested": 0, "deprecated": 0}

    for e in entries:
        domain = e["domain"]
        status = e["verification"]["status"]
        by_domain.setdefault(
            domain,
            {"total": 0, "draft": 0, "peer-reviewed": 0, "field-tested": 0, "deprecated": 0},
        )
        by_domain[domain]["total"] += 1
        by_domain[domain][status] = by_domain[domain].get(status, 0) + 1
        status_counts[status] = status_counts.get(status, 0) + 1
        safety_counts[e["safety"]] = safety_counts.get(e["safety"], 0) + 1
        difficulty_counts[e["difficulty"]] = difficulty_counts.get(e["difficulty"], 0) + 1

    pct_field = round(100 * status_counts["field-tested"] / total, 1) if total else 0

    domain_rows = ""
    for d, c in sorted(by_domain.items()):
        pct = round(100 * c["field-tested"] / c["total"], 1) if c["total"] else 0
        domain_rows += (
            f"<tr><td>{d}</td><td>{c['total']}</td>"
            f"<td>{c.get('draft',0)}</td>"
            f"<td>{c.get('peer-reviewed',0)}</td>"
            f"<td>{c.get('field-tested',0)}</td>"
            f"<td>{c.get('deprecated',0)}</td>"
            f"<td>{pct}%</td></tr>\n"
        )

    safety_rows = "\n".join(
        f"<tr><td><span class='badge {k}'>{k}</span></td><td>{v}</td></tr>"
        for k, v in sorted(safety_counts.items())
    )
    difficulty_rows = "\n".join(
        f"<tr><td>{k}</td><td>{v}</td></tr>"
        for k, v in sorted(difficulty_counts.items())
    )

    events = sorted(_load_ledger(), key=lambda x: x["timestamp"], reverse=True)[:25]
    recent_rows = "\n".join(
        f"<tr><td>{e['timestamp']}</td><td>{e['entry_id']}</td>"
        f"<td class='status-{e['from_status']}'>{e['from_status']}</td>"
        f"<td class='status-{e['to_status']}'>{e['to_status']}</td>"
        f"<td>{e['actor']}</td></tr>"
        for e in events
    )

    replacements = {
        "generated_at": datetime.utcnow().isoformat(timespec="seconds") + "Z",
        "total": total,
        "field_tested": status_counts["field-tested"],
        "peer_reviewed": status_counts["peer-reviewed"],
        "draft": status_counts["draft"],
        "pct_field": pct_field,
        "domain_rows": domain_rows,
        "safety_rows": safety_rows,
        "difficulty_rows": difficulty_rows,
        "recent_rows": recent_rows,
    }
    html = TEMPLATE
    for key, value in replacements.items():
        html = html.replace("{" + key + "}", str(value))

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(html, encoding="utf-8")
    print(f"Dashboard written: {OUT_PATH}")
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(build())
