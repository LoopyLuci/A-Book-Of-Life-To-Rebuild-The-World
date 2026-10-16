"""Tests for the MCP server tool handlers."""

import asyncio
import json
from unittest.mock import patch

import pytest

from scripts import mcp_server


@pytest.fixture(autouse=True)
def _stub_search(monkeypatch):
    def fake_search(query, limit=10):
        return [
            {
                "id": "pnk:TEST/survival/making-fire",
                "title": "Making Fire",
                "domain": "survival",
                "difficulty": "novice",
                "safety": "yellow",
                "score": 0.99,
            }
        ]

    monkeypatch.setattr(mcp_server, "hybrid_search", fake_search)


def test_list_tools_registers_all():
    tools = asyncio.run(mcp_server.list_tools())
    names = {t.name for t in tools}
    assert {
        "abook_search",
        "abook_get",
        "abook_linked",
        "abook_verify",
        "abook_list_domains",
        "abook_stats",
    }.issubset(names)


def test_search_tool_returns_json():
    out = asyncio.run(
        mcp_server.call_tool("abook_search", {"query": "fire", "limit": 5})
    )
    payload = json.loads(out[0].text)
    assert payload["results"][0]["title"] == "Making Fire"


def test_search_tool_domain_filter():
    out = asyncio.run(
        mcp_server.call_tool(
            "abook_search", {"query": "fire", "domain": "agriculture"}
        )
    )
    payload = json.loads(out[0].text)
    assert payload["results"] == []


def test_unknown_tool_returns_error():
    out = asyncio.run(mcp_server.call_tool("nonexistent", {}))
    payload = json.loads(out[0].text)
    assert "error" in payload
