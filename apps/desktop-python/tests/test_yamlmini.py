"""Tests for the dependency-free YAML reader.

The reader has to agree with PyYAML on the files of the repository, so the
two are compared whenever PyYAML is installed.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from abook import yamlmini
from abook.corpus import find_repo_root


def test_reads_a_mapping() -> None:
    assert yamlmini.parse_yaml("a: 1\nb: two\n") == {"a": 1, "b": "two"}


def test_reads_a_nested_mapping() -> None:
    document = """
verification:
  status: peer-reviewed
  date: "2026-02-20"
"""
    assert yamlmini.parse_yaml(document) == {
        "verification": {"status": "peer-reviewed", "date": "2026-02-20"}
    }


def test_reads_flow_and_block_sequences() -> None:
    assert yamlmini.parse_yaml("tags: [a, b, c]\n") == {"tags": ["a", "b", "c"]}
    assert yamlmini.parse_yaml("tags: []\n") == {"tags": []}
    assert yamlmini.parse_yaml("tags:\n  - a\n  - b\n") == {"tags": ["a", "b"]}
    assert yamlmini.parse_yaml("tags:\n- a\n- b\n") == {"tags": ["a", "b"]}


def test_reads_a_sequence_of_mappings() -> None:
    document = """
sources:
  - title: WHO Basic Emergency Care
    license: public domain
  - title: Another source
"""
    assert yamlmini.parse_yaml(document) == {
        "sources": [
            {"title": "WHO Basic Emergency Care", "license": "public domain"},
            {"title": "Another source"},
        ]
    }


def test_keeps_identifiers_with_colons_intact() -> None:
    """A colon that is not followed by a space is part of the value."""
    document = "links:\n  - pnk:01M52TVK0262WR91WPZ1FVPE6X/health/wound-care\n"
    assert yamlmini.parse_yaml(document) == {
        "links": ["pnk:01M52TVK0262WR91WPZ1FVPE6X/health/wound-care"]
    }


def test_ignores_comments() -> None:
    document = "# a comment\nsite_name: \"Name\"  # trailing comment\n"
    assert yamlmini.parse_yaml(document) == {"site_name": "Name"}


def test_reads_scalars() -> None:
    document = "a: null\nb: true\nc: false\nd: 1.5\ne: 'single'\nf: \"double\\n\"\n"
    assert yamlmini.parse_yaml(document) == {
        "a": None,
        "b": True,
        "c": False,
        "d": 1.5,
        "e": "single",
        "f": "double\n",
    }


def test_rejects_unsupported_constructs() -> None:
    with pytest.raises(yamlmini.YamlParseError):
        yamlmini.parse_yaml("a: |\n  block\n")
    with pytest.raises(yamlmini.YamlParseError):
        yamlmini.parse_yaml("a: [1, 2\n")


def test_agrees_with_pyyaml_on_the_repository() -> None:
    """The bundled reader parses every catalogue of the repository like PyYAML."""
    yaml = pytest.importorskip("yaml")
    root = find_repo_root(Path(__file__).resolve())
    files = sorted((root / "sidecars").rglob("*.pnk.yaml"))
    files += sorted((root / "i18n" / "strings").glob("*.yaml"))
    assert files
    for path in files:
        text = path.read_text(encoding="utf-8")
        assert yamlmini.parse_yaml(text) == yaml.safe_load(text), path
