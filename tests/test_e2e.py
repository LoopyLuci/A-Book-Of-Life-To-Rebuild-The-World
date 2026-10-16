"""
End-to-end test: validate → build index → search → MCP tool call → bundle.
Run after `python scripts/validate.py` and `python scripts/build_index.py`.
"""

import json
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
INDEX = ROOT / "build" / "index.db"
BUNDLE = ROOT / "build" / "offline-bundle"
HTML = BUNDLE / "html"


@pytest.fixture(scope="session", autouse=True)
def _build_everything():
    if not INDEX.exists():
        subprocess.run([sys.executable, "scripts/build_index.py"], check=True, cwd=ROOT)
    if not HTML.exists():
        subprocess.run([sys.executable, "scripts/build_zim.py"], check=True, cwd=ROOT)


def test_index_has_entries():
    assert INDEX.exists()
    import sqlite3
    conn = sqlite3.connect(INDEX)
    try:
        n = conn.execute("SELECT COUNT(*) FROM entries").fetchone()[0]
        chunks = conn.execute("SELECT COUNT(*) FROM chunks").fetchone()[0]
    finally:
        conn.close()
    assert n >= 70, f"Expected >= 70 entries, found {n}"
    assert chunks >= n, "Expected at least one chunk per entry"


def test_search_returns_fire_for_fire_query():
    from scripts.search import search
    hits = search("making fire", limit=5)
    assert any("Fire" in h["title"] for h in hits)


def test_search_returns_water_for_purification():
    from scripts.search import search
    hits = search("purify water", limit=5)
    assert any("Water" in h["title"] for h in hits)


def test_mcp_get_returns_body():
    import asyncio
    from scripts import mcp_server

    hits = mcp_server.hybrid_search("making fire", limit=1)
    assert hits, "Expected at least one hit"
    entry_id = hits[0]["id"]

    out = asyncio.run(mcp_server.call_tool("abook_get", {"entry_id": entry_id}))
    payload = json.loads(out[0].text)
    assert payload["metadata"]["id"] == entry_id
    assert "Making Fire" in payload["body"]


def test_offline_bundle_has_index_html():
    assert (HTML / "index.html").exists()
    assert (HTML / "style.css").exists()
    assert (HTML / "search-index.json").exists()


def test_offline_bundle_has_all_domain_pages():
    for domain in [
        "survival", "agriculture", "materials", "energy",
        "construction", "health", "knowledge", "society",
    ]:
        assert (HTML / domain / "index.html").exists(), f"Missing {domain}/index.html"


def test_offline_bundle_entry_count():
    index_json = json.loads((HTML / "search-index.json").read_text())
    assert len(index_json) >= 70
    for doc in index_json:
        assert (HTML / doc["path"]).exists(), f"Missing page {doc['path']}"
