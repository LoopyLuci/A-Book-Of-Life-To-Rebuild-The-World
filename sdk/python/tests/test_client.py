import pytest
import respx
import httpx

from abook import Client, NotFoundError
from abook.pnk import parse, build, slug_from_title


@respx.mock
def test_search_returns_results():
    respx.get("http://localhost:8080/v1/search").mock(
        return_value=httpx.Response(
            200,
            json={"query": "fire", "results": [
                {"id": "pnk:TEST/survival/making-fire", "title": "Making Fire",
                 "domain": "survival", "difficulty": "novice",
                 "safety": "yellow", "score": 0.9}
            ]},
        )
    )
    with Client() as c:
        results = c.search("fire")
    assert len(results) == 1
    assert results[0].title == "Making Fire"


@respx.mock
def test_get_entry_404():
    respx.get("http://localhost:8080/v1/entries/pnk:X/missing/slug").mock(
        return_value=httpx.Response(404, json={"detail": "Entry not found"})
    )
    with Client() as c:
        with pytest.raises(NotFoundError):
            c.get_entry("pnk:X/missing/slug")


def test_pnk_parse_entry_form():
    uri = parse("pnk:01HZX0/survival/making-fire")
    assert uri.domain == "survival"
    assert uri.slug == "making-fire"
    assert uri.entry_ulid == "01HZX0"


def test_pnk_parse_node_form():
    uri = parse("pnk://node-abc/survival/making-fire")
    assert uri.node_id == "node-abc"
    assert uri.domain == "survival"


def test_pnk_build_roundtrip():
    s = build("node-abc", "survival", "making-fire")
    parsed = parse(s)
    assert parsed.node_id == "node-abc"
    assert parsed.domain == "survival"
    assert parsed.slug == "making-fire"


def test_slugify():
    assert slug_from_title("Making Fire!") == "making-fire"
    assert slug_from_title("  Water   Purification ") == "water-purification"
