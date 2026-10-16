#!/usr/bin/env python3
"""
Model Context Protocol (MCP) server exposing A Book Of Life To Rebuild The World
to AI agents. Runs over stdio (default) or SSE.
"""

from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path
from typing import Any

import yaml
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import TextContent, Tool

ROOT = Path(__file__).resolve().parent.parent
INDEX_PATH = ROOT / "build" / "index.db"
SIDECARS_DIR = ROOT / "sidecars"
DOMAINS_DIR = ROOT / "domains"

sys.path.insert(0, str(Path(__file__).parent))
from search import search as hybrid_search  # noqa: E402

SERVER_NAME = "a-book-of-life"
SERVER_VERSION = "1.0.0"

app = Server(SERVER_NAME)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _conn() -> sqlite3.Connection:
    if not INDEX_PATH.exists():
        raise RuntimeError(
            f"Index not found at {INDEX_PATH}. Run: python scripts/build_index.py"
        )
    return sqlite3.connect(INDEX_PATH)


def _load_sidecar(entry_id: str) -> dict[str, Any] | None:
    for path in SIDECARS_DIR.rglob("*.pnk.yaml"):
        with path.open("r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
        if data.get("id") == entry_id:
            return data
    return None


def _read_body(entry_id: str) -> str | None:
    sidecar = _load_sidecar(entry_id)
    if not sidecar:
        return None
    rel = Path(sidecar["domain"]) / f"{entry_id.rsplit('/', 1)[-1]}.md"
    md = DOMAINS_DIR / rel
    if not md.exists():
        return None
    return md.read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# Tool registry
# ---------------------------------------------------------------------------

@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="abook_search",
            description=(
                "Hybrid BM25 + semantic search across A Book Of Life To Rebuild "
                "The World. Returns ranked entries with title, domain, "
                "difficulty, safety, and relevance score."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Search query."},
                    "domain": {
                        "type": "string",
                        "description": "Optional domain filter.",
                        "enum": [
                            "survival", "agriculture", "materials", "energy",
                            "construction", "health", "knowledge", "society",
                        ],
                    },
                    "limit": {"type": "integer", "default": 10, "minimum": 1, "maximum": 50},
                },
                "required": ["query"],
            },
        ),
        Tool(
            name="abook_get",
            description="Retrieve the full Markdown body and sidecar metadata for a single entry by its PNK id.",
            inputSchema={
                "type": "object",
                "properties": {"entry_id": {"type": "string"}},
                "required": ["entry_id"],
            },
        ),
        Tool(
            name="abook_linked",
            description="Return all entries linked from or to the given entry (prerequisites, materials, cross-domain links).",
            inputSchema={
                "type": "object",
                "properties": {"entry_id": {"type": "string"}},
                "required": ["entry_id"],
            },
        ),
        Tool(
            name="abook_verify",
            description="Return the verification status, reviewers, field-test date and location for an entry.",
            inputSchema={
                "type": "object",
                "properties": {"entry_id": {"type": "string"}},
                "required": ["entry_id"],
            },
        ),
        Tool(
            name="abook_list_domains",
            description="List all domains with entry counts and descriptions.",
            inputSchema={"type": "object", "properties": {}},
        ),
        Tool(
            name="abook_stats",
            description="Return knowledge-base statistics: total entries, chunks, verification breakdown.",
            inputSchema={"type": "object", "properties": {}},
        ),
    ]


# ---------------------------------------------------------------------------
# Tool handlers
# ---------------------------------------------------------------------------

@app.call_tool()
async def call_tool(name: str, arguments: dict[str, Any]) -> list[TextContent]:
    try:
        if name == "abook_search":
            return _tool_search(arguments)
        if name == "abook_get":
            return _tool_get(arguments)
        if name == "abook_linked":
            return _tool_linked(arguments)
        if name == "abook_verify":
            return _tool_verify(arguments)
        if name == "abook_list_domains":
            return _tool_list_domains()
        if name == "abook_stats":
            return _tool_stats()
        return [TextContent(type="text", text=json.dumps({"error": f"Unknown tool: {name}"}))]
    except Exception as exc:  # noqa: BLE001
        return [TextContent(type="text", text=json.dumps({"error": str(exc)}))]


def _tool_search(args: dict[str, Any]) -> list[TextContent]:
    results = hybrid_search(args["query"], limit=args.get("limit", 10))
    domain = args.get("domain")
    if domain:
        results = [r for r in results if r["domain"] == domain]
    return [TextContent(type="text", text=json.dumps({"results": results}, indent=2))]


def _tool_get(args: dict[str, Any]) -> list[TextContent]:
    entry_id = args["entry_id"]
    body = _read_body(entry_id)
    sidecar = _load_sidecar(entry_id)
    if body is None or sidecar is None:
        return [TextContent(type="text", text=json.dumps({"error": "Entry not found"}))]
    return [
        TextContent(
            type="text",
            text=json.dumps({"metadata": sidecar, "body": body}, indent=2),
        )
    ]


def _tool_linked(args: dict[str, Any]) -> list[TextContent]:
    entry_id = args["entry_id"]
    sidecar = _load_sidecar(entry_id)
    if not sidecar:
        return [TextContent(type="text", text=json.dumps({"error": "Entry not found"}))]

    outgoing = sidecar.get("links", []) + sidecar.get("prerequisites", [])
    incoming: list[str] = []
    for path in SIDECARS_DIR.rglob("*.pnk.yaml"):
        with path.open("r", encoding="utf-8") as f:
            other = yaml.safe_load(f)
        refs = other.get("links", []) + other.get("prerequisites", [])
        if entry_id in refs:
            incoming.append(other["id"])

    return [
        TextContent(
            type="text",
            text=json.dumps({"outgoing": outgoing, "incoming": incoming}, indent=2),
        )
    ]


def _tool_verify(args: dict[str, Any]) -> list[TextContent]:
    sidecar = _load_sidecar(args["entry_id"])
    if not sidecar:
        return [TextContent(type="text", text=json.dumps({"error": "Entry not found"}))]
    return [
        TextContent(
            type="text",
            text=json.dumps(sidecar.get("verification", {}), indent=2),
        )
    ]


def _tool_list_domains() -> list[TextContent]:
    conn = _conn()
    try:
        rows = conn.execute(
            "SELECT domain, COUNT(*) FROM entries GROUP BY domain ORDER BY domain"
        ).fetchall()
    finally:
        conn.close()
    domains = [
        {
            "name": d,
            "count": c,
            "description": {
                "survival": "Immediate needs: water, fire, shelter, first aid",
                "agriculture": "Food production, soil, livestock, preservation",
                "materials": "Metals, glass, textiles, chemicals, adhesives",
                "energy": "Generation, storage, distribution, conversion",
                "construction": "Shelter, infrastructure, water systems, sanitation",
                "health": "Medicine, surgery, pharmacology, mental health",
                "knowledge": "Communication, printing, education, art, music",
                "society": "Governance, economics, conflict resolution, culture",
            }.get(d, ""),
        }
        for d, c in rows
    ]
    return [TextContent(type="text", text=json.dumps({"domains": domains}, indent=2))]


def _tool_stats() -> list[TextContent]:
    conn = _conn()
    try:
        total = conn.execute("SELECT COUNT(*) FROM entries").fetchone()[0]
        chunks = conn.execute("SELECT COUNT(*) FROM chunks").fetchone()[0]
        by_status = dict(
            conn.execute(
                "SELECT verification_status, COUNT(*) FROM entries GROUP BY verification_status"
            ).fetchall()
        )
        by_difficulty = dict(
            conn.execute(
                "SELECT difficulty, COUNT(*) FROM entries GROUP BY difficulty"
            ).fetchall()
        )
        by_safety = dict(
            conn.execute("SELECT safety, COUNT(*) FROM entries GROUP BY safety").fetchall()
        )
    finally:
        conn.close()

    return [
        TextContent(
            type="text",
            text=json.dumps(
                {
                    "total_entries": total,
                    "total_chunks": chunks,
                    "by_verification": by_status,
                    "by_difficulty": by_difficulty,
                    "by_safety": by_safety,
                    "server": f"{SERVER_NAME} v{SERVER_VERSION}",
                },
                indent=2,
            ),
        )
    ]


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

async def main() -> None:
    async with stdio_server() as (read, write):
        await app.run(read, write, app.create_initialization_options())


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())
