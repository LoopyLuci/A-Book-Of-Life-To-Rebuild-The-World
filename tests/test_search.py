from scripts.search import search


def test_search_returns_results():
    results = search("fire", limit=5)
    assert isinstance(results, list)
    if results:
        assert "id" in results[0]
        assert "title" in results[0]
