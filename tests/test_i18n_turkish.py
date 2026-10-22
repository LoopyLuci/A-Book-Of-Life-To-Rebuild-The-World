"""Integrity checks for the Turkish localisation of the knowledge base.

Every Turkish entry must ship a translated Markdown body next to a sidecar
that declares ``language: tr``, the sidecar tags must stay ASCII, and every
relative link must point back into the canonical English tree so that it
still resolves from ``i18n/translations/tr/<domain>/``.
"""

from __future__ import annotations

import re
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
TRANSLATIONS = ROOT / "i18n" / "translations" / "tr"
STRINGS = ROOT / "i18n" / "strings"
SIDECARS = ROOT / "sidecars"

TAG_PATTERN = re.compile(r"^[a-z0-9-]+$")
LINK_PATTERN = re.compile(r"\]\(([^)\s]+)\)")
LINK_PREFIX = "../../../../domains/"

TURKISH_ENTRIES = (
    "agriculture/beekeeping",
    "agriculture/composting",
    "agriculture/crop-rotation",
    "agriculture/food-preservation",
    "biology/animal-husbandry-breeding",
    "biology/aseptic-culture",
    "biology/cell-biology-microscopy",
    "biology/ecosystem-monitoring",
    "chemistry/acid-base-equilibria",
    "chemistry/analytical-standards-weighing",
    "chemistry/catalysis-and-kinetics",
    "chemistry/chromatography-separation",
    "computers/ac-circuit-analysis",
    "computers/assembly-language",
    "computers/bus-standards-interfaces",
    "computers/compilers-linkers",
    "construction/bridges",
    "construction/composting-toilet",
    "construction/latrines-sanitation",
    "construction/masonry",
    "energy/battery-basics",
    "energy/biogas-digester",
    "energy/dc-microgrids",
    "energy/efficient-lighting",
    "health/anatomy-basics",
    "health/antibiotics",
    "health/childbirth",
    "health/dental-care",
    "knowledge/bookbinding",
    "knowledge/cryptography",
    "knowledge/education",
    "knowledge/library-organization",
    "materials/adhesives",
    "materials/blacksmithing",
    "materials/brick-making",
    "materials/ceramics",
    "quantum/circuit-construction",
    "quantum/cryogenics-dilution",
    "quantum/error-correction-codes",
    "quantum/microwave-control",
    "ship/boat-repair-maintenance",
    "ship/cargo-stowage",
    "ship/coastal-navigation",
    "ship/hull-design-principles",
    "silicon/cleanroom-protocols",
    "silicon/dopant-diffusion",
    "silicon/etching-patterning",
    "silicon/ic-design-flow",
    "society/community-food-security",
    "society/community-organizing",
    "society/conflict-resolution",
    "society/consensus-decision-making",
    "survival/basic-first-aid",
    "survival/cold-exposure",
    "survival/edible-plants",
    "survival/emergency-shelter",
    "transport/bicycle-maintenance",
    "transport/cargo-lashing",
    "transport/handcarts",
    "transport/pack-animals",
    "water/greywater-reuse",
    "water/rainwater-harvesting",
    "water/spring-development",
)


def _sidecars() -> list[Path]:
    return sorted(TRANSLATIONS.rglob("*.pnk.yaml"))


def test_every_entry_has_a_body_and_a_sidecar() -> None:
    """Each Turkish entry has both a .md body and a .pnk.yaml sidecar."""
    for entry in TURKISH_ENTRIES:
        domain, slug = entry.split("/", 1)
        body = TRANSLATIONS / domain / f"{slug}.md"
        sidecar = TRANSLATIONS / domain / f"{slug}.pnk.yaml"
        assert body.exists(), f"missing translated body: {body}"
        assert sidecar.exists(), f"missing translation sidecar: {sidecar}"


def test_translated_entries_are_not_missing() -> None:
    """Every entry translated on disk is one of the delivered entries."""
    on_disk = {
        f"{path.parent.name}/{path.name.removesuffix('.pnk.yaml')}"
        for path in _sidecars()
    }
    assert on_disk == set(TURKISH_ENTRIES)


def test_every_sidecar_declares_turkish() -> None:
    """Every Turkish sidecar carries the language key with the value 'tr'."""
    for path in _sidecars():
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
        assert data.get("language") == "tr", f"{path} does not declare language: tr"


def test_every_tag_is_ascii() -> None:
    """Tags match the schema pattern: lowercase letters, digits and hyphens."""
    for path in _sidecars():
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
        for tag in data.get("tags", []):
            assert TAG_PATTERN.match(tag), f"{path} has a non-ASCII tag: {tag}"


def test_relative_links_point_at_the_canonical_tree() -> None:
    """No translated body links outside ../../../../domains/."""
    for path in sorted(TRANSLATIONS.rglob("*.md")):
        text = path.read_text(encoding="utf-8")
        for target in LINK_PATTERN.findall(text):
            if target.startswith(("http://", "https://", "#")):
                continue
            assert target.startswith(LINK_PREFIX), f"{path} links to {target}"


def test_every_translation_points_at_a_canonical_entry() -> None:
    """Each sidecar names an existing English entry as its source."""
    canonical = {
        yaml.safe_load(path.read_text(encoding="utf-8"))["id"]
        for path in SIDECARS.rglob("*.pnk.yaml")
    }
    for path in _sidecars():
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
        assert data.get("translation_of") in canonical, f"{path} has no canonical source"


def test_ui_strings_cover_every_english_key() -> None:
    """The Turkish interface file carries every key of the English one."""
    english = yaml.safe_load((STRINGS / "en.yaml").read_text(encoding="utf-8"))
    turkish = yaml.safe_load((STRINGS / "tr.yaml").read_text(encoding="utf-8"))
    assert set(english) == set(turkish)
    assert list(english) == list(turkish), "the key order must match en.yaml"


def test_ui_strings_keep_their_placeholders() -> None:
    """Every {placeholder} of the English string survives the translation."""
    placeholder = re.compile(r"\{[a-z_]+\}")
    english = yaml.safe_load((STRINGS / "en.yaml").read_text(encoding="utf-8"))
    turkish = yaml.safe_load((STRINGS / "tr.yaml").read_text(encoding="utf-8"))
    for key, value in english.items():
        assert set(placeholder.findall(str(value))) == set(
            placeholder.findall(str(turkish[key]))
        ), f"placeholder mismatch on {key}"


def test_turkish_entries_are_unique() -> None:
    """The delivered entry list has no duplicates and covers 63 entries."""
    assert len(set(TURKISH_ENTRIES)) == len(TURKISH_ENTRIES)
    assert len(TURKISH_ENTRIES) == 63
