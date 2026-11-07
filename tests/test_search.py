from scripts.search import search


def test_search_returns_results():
    results = search("fire", limit=5)
    assert isinstance(results, list)
    if results:
        assert "id" in results[0]
        assert "title" in results[0]


def test_search_domain_filter_returns_only_matching_entries():
    results = search("fire", limit=20, domain="survival")

    assert results
    assert all(result["domain"] == "survival" for result in results)
