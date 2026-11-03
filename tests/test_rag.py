"""Tests for the RAG layer (no live LLM required)."""


from scripts import rag


def _fake_retrieve(query, k=5):
    return [
        {
            "id": "pnk:TEST/survival/making-fire",
            "title": "Making Fire",
            "domain": "survival",
            "body": "# Making Fire\n\nUse a ferro rod...",
            "score": 0.99,
        }
    ]


def test_format_context_contains_id():
    docs = _fake_retrieve("fire")
    ctx = rag.format_context(docs)
    assert "pnk:TEST/survival/making-fire" in ctx
    assert "Making Fire" in ctx


def test_ask_returns_sources(monkeypatch):
    monkeypatch.setattr(rag, "retrieve", _fake_retrieve)

    class FakeResp:
        def raise_for_status(self): pass
        def json(self):
            return {"message": {"content": "Use a ferro rod [pnk:TEST/survival/making-fire]."}}

    class FakeClient:
        def __enter__(self): return self
        def __exit__(self, *a): return False
        def post(self, *a, **kw): return FakeResp()

    monkeypatch.setattr(rag.httpx, "Client", lambda **kw: FakeClient())

    result = rag.ask("How do I start a fire?")
    assert "ferro rod" in result["answer"]
    assert result["sources"][0]["id"] == "pnk:TEST/survival/making-fire"


def test_ask_returns_no_results(monkeypatch):
    monkeypatch.setattr(rag, "retrieve", lambda q, k=5: [])
    result = rag.ask("unrelated query")
    assert "No relevant entries" in result["answer"]
    assert result["sources"] == []
