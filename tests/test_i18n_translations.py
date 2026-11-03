"""Checks for every translation: coverage, sidecar shape, tags and link rewrite.

One generic test for every language, so a new language is covered the moment
it is registered in `scripts/validate_i18n.py`.
"""

import re
from pathlib import Path

import pytest
import yaml

from scripts.validate_i18n import COVERAGE_TARGETS, LANGS

ROOT = Path(__file__).resolve().parent.parent
TRANSLATIONS_DIR = ROOT / "i18n" / "translations"
STRINGS_DIR = ROOT / "i18n" / "strings"
TAG_RE = re.compile(r"^[a-z0-9-]+$")
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
LINK_PREFIX = "../../../../domains/"


def _canonical_ids() -> set[str]:
    ids: set[str] = set()
    for path in (ROOT / "sidecars").rglob("*.pnk.yaml"):
        with path.open("r", encoding="utf-8") as handle:
            ids.add(yaml.safe_load(handle)["id"])
    return ids


CANONICAL_IDS = _canonical_ids()


@pytest.mark.parametrize("language", LANGS)
def test_ui_strings_cover_every_key(language):
    with (STRINGS_DIR / "en.yaml").open("r", encoding="utf-8") as handle:
        english = yaml.safe_load(handle)
    with (STRINGS_DIR / f"{language}.yaml").open("r", encoding="utf-8") as handle:
        translated = yaml.safe_load(handle)
    assert set(english) == set(translated), f"{language} is missing or adds keys"
    for key, value in english.items():
        assert sorted(re.findall(r"{(\w+)}", str(value))) == sorted(
            re.findall(r"{(\w+)}", str(translated[key]))
        ), f"{language}: placeholder mismatch for {key}"


@pytest.mark.parametrize("language", LANGS)
def test_entries_have_a_body_and_a_sidecar(language):
    bodies = sorted((TRANSLATIONS_DIR / language).rglob("*.md"))
    assert bodies, f"{language} has no translated entries"
    for body in bodies:
        sidecar = body.with_suffix("").with_suffix(".pnk.yaml")
        assert sidecar.exists(), f"missing sidecar for {body}"
        with sidecar.open("r", encoding="utf-8") as handle:
            meta = yaml.safe_load(handle)
        assert meta["language"] == language, f"wrong language in {sidecar}"
        assert meta["id"] == meta["translation_of"]
        assert meta["id"] in CANONICAL_IDS, f"{sidecar} points at an unknown entry"
        assert meta["tags"], f"no tags in {sidecar}"


@pytest.mark.parametrize("language", LANGS)
def test_tags_are_ascii(language):
    for sidecar in (TRANSLATIONS_DIR / language).rglob("*.pnk.yaml"):
        with sidecar.open("r", encoding="utf-8") as handle:
            meta = yaml.safe_load(handle)
        for tag in meta["tags"]:
            assert TAG_RE.match(tag), f"{sidecar}: tag {tag!r} is not ascii"


@pytest.mark.parametrize("language", LANGS)
def test_relative_links_are_rewritten_and_resolve(language):
    for body in (TRANSLATIONS_DIR / language).rglob("*.md"):
        text = body.read_text(encoding="utf-8")
        for target in LINK_RE.findall(text):
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            assert target.startswith(LINK_PREFIX), (
                f"{body}: link {target} was not rewritten for the translation tree"
            )
            resolved = (body.parent / target).resolve()
            assert resolved.exists(), f"{body}: link {target} does not resolve"


@pytest.mark.parametrize("language", LANGS)
def test_coverage_meets_the_target(language):
    translated = set()
    for sidecar in (TRANSLATIONS_DIR / language).rglob("*.pnk.yaml"):
        with sidecar.open("r", encoding="utf-8") as handle:
            meta = yaml.safe_load(handle)
        translated.add(meta.get("translation_of") or meta.get("id"))
    coverage = len(translated & CANONICAL_IDS) / len(CANONICAL_IDS)
    assert coverage >= COVERAGE_TARGETS[language], (
        f"{language}: coverage {coverage:.1%} is below the "
        f"{COVERAGE_TARGETS[language]:.0%} target"
    )
