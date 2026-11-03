"""Tests for the corpus loader, the search ranking, the translations and the version.

The tests run against the real knowledge base of the repository, so they check
the application against the data it actually ships with.
"""

from __future__ import annotations

import tomllib
from pathlib import Path

import pytest

from abook import __version__
from abook.corpus import (
    Corpus,
    Entry,
    find_repo_root,
    load_corpus,
    load_disclaimer,
    load_manifest,
)
from abook.i18n import Translator
from abook.search import TIER_BODY, TIER_TAGS, TIER_TITLE, SearchEngine

APP_ROOT = Path(__file__).resolve().parents[1]
PYPROJECT_PATH = APP_ROOT / "pyproject.toml"


@pytest.fixture(scope="session")
def repo_root() -> Path:
    """Return the repository root of the checkout the tests run in."""
    return find_repo_root(Path(__file__).resolve())


@pytest.fixture(scope="session")
def corpus(repo_root: Path) -> Corpus:
    """Return the knowledge base of the repository."""
    return load_corpus(repo_root)


@pytest.fixture(scope="session")
def engine(corpus: Corpus) -> SearchEngine:
    """Return a search engine over the knowledge base."""
    return SearchEngine(corpus)


# ----------------------------------------------------------------------
# Corpus loading
# ----------------------------------------------------------------------
def test_repo_root_is_discovered(repo_root: Path) -> None:
    """The repository root is found by walking up to the manifest."""
    assert (repo_root / "manifest.toml").is_file()
    assert (repo_root / "sidecars").is_dir()
    assert (repo_root / "domains").is_dir()


def test_corpus_loads_every_sidecar(corpus: Corpus, repo_root: Path) -> None:
    """Every sidecar in the repository becomes an entry."""
    sidecars = sorted((repo_root / "sidecars").rglob("*.pnk.yaml"))
    assert sidecars
    assert len(corpus) == len(sidecars)
    assert len(corpus.entries_by_id) == len(corpus)


def test_corpus_knows_the_sixteen_domains(corpus: Corpus, repo_root: Path) -> None:
    """The domain list comes from the manifest, the counts from the sidecars."""
    manifest = load_manifest(repo_root)
    declared = list(manifest["domains"]["list"])
    assert declared == list(corpus.domains)
    assert len(corpus.domains) == 16
    assert sum(corpus.domain_counts.values()) == len(corpus)
    for domain, count in corpus.domain_counts.items():
        assert count == len(corpus.entries_by_domain[domain])


def test_entries_carry_their_metadata(corpus: Corpus) -> None:
    """Each entry has an id, a title, a domain, a safety level and a body."""
    for entry in corpus.entries:
        assert entry.id
        assert entry.title
        assert entry.domain in corpus.domains
        assert entry.safety in ("green", "yellow", "red")
        assert entry.difficulty
        assert entry.verification.status
        assert entry.body.strip()
        assert entry.path.startswith("domains" + "/")


def test_entries_are_ordered_by_domain_and_title(corpus: Corpus) -> None:
    """The entries are sorted, so the interface is stable between runs."""
    keys = [(entry.domain, entry.title.lower()) for entry in corpus.entries]
    assert keys == sorted(keys)


def test_corpus_falls_back_to_a_direct_scan(corpus: Corpus, repo_root: Path) -> None:
    """The corpus is still complete when the pre-built index is not used."""
    scanned = load_corpus(repo_root, prefer_index=False)
    assert scanned.source == "filesystem"
    assert len(scanned) == len(corpus)
    assert scanned.entries_by_id.keys() == corpus.entries_by_id.keys()


def test_corpus_loads_without_an_index_database(tmp_path: Path, repo_root: Path) -> None:
    """A checkout without ``build/index.db`` loads instead of crashing."""
    manifest = load_manifest(repo_root)
    (tmp_path / "manifest.toml").write_bytes((repo_root / "manifest.toml").read_bytes())
    sidecar = next(iter(sorted((repo_root / "sidecars").rglob("*.pnk.yaml"))))
    domain = sidecar.parent.name
    (tmp_path / "sidecars" / domain).mkdir(parents=True)
    (tmp_path / "sidecars" / domain / sidecar.name).write_text(
        sidecar.read_text(encoding="utf-8"), encoding="utf-8"
    )
    body = repo_root / "domains" / domain / f"{sidecar.name[: -len('.pnk.yaml')]}.md"
    (tmp_path / "domains" / domain).mkdir(parents=True)
    (tmp_path / "domains" / domain / body.name).write_text(
        body.read_text(encoding="utf-8"), encoding="utf-8"
    )

    loaded = load_corpus(tmp_path)
    assert len(loaded) == 1
    assert loaded.source == "filesystem"
    assert loaded.index_path is None
    assert loaded.entries[0].body.strip()
    assert manifest["project"]["version"] == loaded.version


def test_disclaimer_is_quoted_from_the_repository(repo_root: Path) -> None:
    """The disclaimer comes from section 12 of ``docs/DISCLAIMER.md``."""
    disclaimer = load_disclaimer(repo_root)
    assert disclaimer
    assert "sole source of information" in disclaimer
    assert "Local law" in disclaimer


# ----------------------------------------------------------------------
# Search ranking
# ----------------------------------------------------------------------
def test_search_ranks_title_matches_first(engine: SearchEngine) -> None:
    """A title match beats a tag match, and a tag match beats a body match."""
    results = engine.search("water purification")
    assert results
    assert results[0].entry.title == "Water Purification"
    assert results[0].tier == TIER_TITLE
    for result in results:
        assert result.tier in (TIER_TITLE, TIER_TAGS, TIER_BODY)
    tiers = [result.tier for result in results]
    assert tiers == sorted(tiers, reverse=True)


def test_search_finds_tag_matches(engine: SearchEngine) -> None:
    """A tag that appears in no title still produces results."""
    results = engine.search("cpr")
    assert results
    assert any(result.entry.title == "Basic First Aid" for result in results)


def test_search_ranks_titles_above_bodies(engine: SearchEngine) -> None:
    """Entries whose title matches come before entries that only match in the body."""
    results = engine.search("solar")
    assert len(results) > 1
    title_hits = [result for result in results if result.tier == TIER_TITLE]
    body_hits = [result for result in results if result.tier == TIER_BODY]
    assert title_hits
    assert body_hits
    last_title = max(results.index(result) for result in title_hits)
    first_body = min(results.index(result) for result in body_hits)
    assert last_title < first_body


def test_search_matches_substrings(engine: SearchEngine) -> None:
    """A substring of a title still finds the entry."""
    results = engine.search("water purif")
    assert results
    assert results[0].entry.title == "Water Purification"
    assert results[0].tier == TIER_TITLE


def test_search_honours_the_filters(engine: SearchEngine) -> None:
    """The domain and safety filters restrict the results."""
    results = engine.search("water", domain="survival")
    assert results
    assert all(result.entry.domain == "survival" for result in results)
    red = engine.search("water", safety="red")
    assert red
    assert all(result.entry.safety == "red" for result in red)


def test_search_respects_the_limit(engine: SearchEngine) -> None:
    """No more results than asked for are returned."""
    assert len(engine.search("water", limit=5)) <= 5
    assert len(engine.search("", limit=5)) == 0


def test_quick_jump_prefers_title_prefixes(engine: SearchEngine) -> None:
    """The quick jump puts the entries that start with the query first."""
    entries = engine.quick_jump("water")
    assert entries
    assert entries[0].title.lower().startswith("water")


# ----------------------------------------------------------------------
# Language fallback
# ----------------------------------------------------------------------
def test_translator_falls_back_to_english(repo_root: Path, tmp_path: Path) -> None:
    """An unknown language falls back to the English catalogue."""
    translator = Translator(repo_root / "i18n" / "strings", "zz")
    assert translator.language == "en"
    assert translator.t("site_name") == "A Book Of Life To Rebuild The World"


def test_translator_falls_back_when_the_file_is_unreadable(
    repo_root: Path, tmp_path: Path
) -> None:
    """A broken catalogue file falls back to English instead of raising."""
    strings = tmp_path / "strings"
    strings.mkdir()
    (strings / "en.yaml").write_text(
        'site_name: "English name"\n', encoding="utf-8"
    )
    (strings / "fr.yaml").write_text("site_name: [unclosed\n", encoding="utf-8")
    translator = Translator(strings, "fr")
    assert translator.language == "en"
    assert translator.t("site_name") == "English name"


def test_translator_falls_back_for_missing_keys(tmp_path: Path) -> None:
    """A key that no catalogue defines falls back to the built-in English value."""
    strings = tmp_path / "strings"
    strings.mkdir()
    (strings / "en.yaml").write_text('site_name: "English"\n', encoding="utf-8")
    (strings / "fr.yaml").write_text('site_name: "Francais"\n', encoding="utf-8")
    translator = Translator(strings, "fr")
    assert translator.t("site_name") == "Francais"
    assert translator.t("safety_yellow") == "Caution"
    assert translator.t("a_key_nobody_defined") == "a_key_nobody_defined"


def test_translator_falls_back_to_the_english_value(tmp_path: Path) -> None:
    """A key that the language does not define falls back to the English value."""
    strings = tmp_path / "strings"
    strings.mkdir()
    (strings / "en.yaml").write_text(
        'site_name: "English"\ntagline: "English tagline"\n', encoding="utf-8"
    )
    (strings / "fr.yaml").write_text('site_name: "Francais"\n', encoding="utf-8")
    translator = Translator(strings, "fr")
    assert translator.t("site_name") == "Francais"
    assert translator.t("tagline") == "English tagline"


def test_every_language_is_offered(repo_root: Path) -> None:
    """The nine supported languages are all available."""
    translator = Translator(repo_root / "i18n" / "strings", "en")
    offered = translator.available_languages()
    for language in ("en", "es", "fr", "de", "pt", "hi", "ar", "sw", "zh"):
        assert language in offered
        translator.set_language(language)
        assert translator.language == language
        assert translator.t("site_name")


# ----------------------------------------------------------------------
# Version
# ----------------------------------------------------------------------
def test_version_matches_the_manifest(repo_root: Path) -> None:
    """The version in the manifest, in the package and in the pyproject agree."""
    manifest = load_manifest(repo_root)
    manifest_version = manifest["project"]["version"]
    with PYPROJECT_PATH.open("rb") as handle:
        pyproject = tomllib.load(handle)
    assert pyproject["project"]["version"] == manifest_version
    assert __version__ == manifest_version


def test_pyproject_declares_no_runtime_dependencies() -> None:
    """The application installs nothing: it runs on a bare CPython."""
    with PYPROJECT_PATH.open("rb") as handle:
        pyproject = tomllib.load(handle)
    assert pyproject["project"]["dependencies"] == []
    assert pyproject["project"]["requires-python"] == ">=3.11"


# ----------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------
def test_entries_are_immutable() -> None:
    """An entry cannot be changed after it has been loaded."""
    entry = Entry(id="x", title="X", domain="survival", slug="x")
    with pytest.raises(AttributeError):
        entry.title = "Y"  # type: ignore[misc]
