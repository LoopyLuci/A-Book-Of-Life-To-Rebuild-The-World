"""Tests for the MCP server tool handlers."""

import asyncio
import json

import pytest

from scripts import mcp_server


@pytest.fixture(autouse=True)
def _stub_search(monkeypatch):
    def fake_search(query, limit=10, domain=None):
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


def test_v2_registered_schemas_expose_tool_arguments():
    if mcp_server.MCP_V1:
        pytest.skip("The v1 server registers its schemas through list_tools.")

    tools = asyncio.run(mcp_server.app.list_tools())
    schemas = {tool.name: tool.input_schema for tool in tools}
    search_schema = schemas["abook_search"]

    assert "query" in search_schema["properties"]
    assert "domain" in search_schema["properties"]
    assert "limit" in search_schema["properties"]
    assert search_schema["required"] == ["query"]
    assert schemas["abook_get"]["required"] == ["entry_id"]
    assert schemas["abook_stats"]["properties"] == {}


def test_v2_registered_tool_dispatches_search_arguments():
    if mcp_server.MCP_V1:
        pytest.skip("The v1 server dispatches through the call_tool decorator.")

    result = asyncio.run(
        mcp_server.app.call_tool(
            "abook_search",
            {"query": "fire", "domain": "survival", "limit": 5},
        )
    )
    payload = json.loads(result.content[0].text)

    assert payload["results"][0]["title"] == "Making Fire"


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


def test_search_tool_passes_domain_to_search(monkeypatch):
    calls = []

    def fake_search(query, limit=10, domain=None):
        calls.append((query, limit, domain))
        return []

    monkeypatch.setattr(mcp_server, "hybrid_search", fake_search)

    asyncio.run(
        mcp_server.call_tool(
            "abook_search",
            {"query": "fire", "domain": "survival", "limit": 4},
        )
    )

    assert calls == [("fire", 4, "survival")]


def test_unknown_tool_returns_error():
    out = asyncio.run(mcp_server.call_tool("nonexistent", {}))
    payload = json.loads(out[0].text)
    assert "error" in payload
