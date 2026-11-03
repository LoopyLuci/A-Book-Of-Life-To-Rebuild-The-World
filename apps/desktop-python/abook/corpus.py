"""Reading the repository corpus: Markdown bodies plus YAML sidecars.

The corpus of *A Book Of Life To Rebuild The World* lives in two places
inside the repository:

``sidecars/<domain>/<slug>.pnk.yaml``
    The metadata of an entry: id, title, domain, tags, difficulty, safety,
    time to complete, prerequisites, sources, verification status and links.

``domains/<domain>/<slug>.md``
    The Markdown body that the reader pane renders.

This module turns those files into :class:`Entry` records and a :class:`Corpus`
index.  Nothing in here touches the network: the only optional external input
is the optional SQLite index in ``build/index.db``, which is only used when it
is present and not older than the corpus itself.

The YAML reader is :mod:`abook.yamlmini`, a dependency-free parser for the
subset of YAML used by this repository.  When PyYAML happens to be installed
it is used instead, because it is the reference implementation.
"""

from __future__ import annotations

import logging
import re
import sqlite3
import tomllib
from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from . import yamlmini

LOGGER = logging.getLogger(__name__)

__all__ = [
    "Corpus",
    "Entry",
    "Source",
    "Verification",
    "find_repo_root",
    "load_corpus",
    "load_disclaimer",
    "load_domain_descriptions",
    "load_manifest",
    "parse_yaml_text",
]

#: The file that marks the root of the repository.
MANIFEST_FILENAME = "manifest.toml"

#: The suffix of an entry metadata sidecar.
SIDECAR_SUFFIX = ".pnk.yaml"

#: The directory that holds the entry metadata.
SIDECARS_DIRNAME = "sidecars"

#: The directory that holds the Markdown bodies.
DOMAINS_DIRNAME = "domains"

#: The optional pre-built search index.
INDEX_RELPATH = "build/index.db"

#: The disclaimer document that the about box quotes.
DISCLAIMER_RELPATH = "docs/DISCLAIMER.md"

#: A short warning used when ``docs/DISCLAIMER.md`` cannot be read.
DISCLAIMER_FALLBACK = (
    "Reference and education only. Double-check everything against primary "
    "sources and qualified professionals. Never use one entry, or this "
    "project, as a sole source of information. Not professional advice of any "
    "kind. Red-level work needs training, supervision and the right "
    "equipment. Provided \"as is\", with no warranty, and with liability "
    "excluded as far as the law allows. Local law, standards and primary "
    "sources always win."
)

#: Callback invoked with ``(done, total)`` while the corpus is loading.
ProgressCallback = Callable[[int, int], None]

try:  # pragma: no cover - depends on the environment
    import yaml as _pyyaml
except ImportError:  # pragma: no cover - the application ships without it
    _pyyaml = None


@dataclass(frozen=True)
class Source:
    """One cited source of an entry."""

    title: str
    license: str = ""

    def __str__(self) -> str:
        """Return the source as ``Title (license)``."""
        return f"{self.title} ({self.license})" if self.license else self.title


@dataclass(frozen=True)
class Verification:
    """The verification state of an entry."""

    status: str = "draft"
    date: str = ""
    reviewers: tuple[str, ...] = ()
    tested_by: str = ""
    location: str = ""


@dataclass(frozen=True)
class Entry:
    """One knowledge base entry: its metadata and its Markdown body."""

    id: str
    title: str
    domain: str
    slug: str
    path: str = ""
    tags: tuple[str, ...] = ()
    difficulty: str = ""
    safety: str = ""
    time_to_complete: str = ""
    prerequisites: tuple[str, ...] = ()
    materials: tuple[str, ...] = ()
    tools: tuple[str, ...] = ()
    sources: tuple[Source, ...] = ()
    verification: Verification = field(default_factory=Verification)
    links: tuple[str, ...] = ()
    body: str = ""

    @property
    def search_text(self) -> str:
        """Return the text that is searched for this entry."""
        return "\n".join((self.title, " ".join(self.tags), self.body))


@dataclass(frozen=True)
class Corpus:
    """The loaded knowledge base."""

    root: Path
    version: str
    entries: tuple[Entry, ...] = ()
    domains: tuple[str, ...] = ()
    domain_counts: Mapping[str, int] = field(default_factory=dict)
    safety_counts: Mapping[str, int] = field(default_factory=dict)
    entries_by_id: Mapping[str, Entry] = field(default_factory=dict)
    entries_by_domain: Mapping[str, tuple[Entry, ...]] = field(default_factory=dict)
    index_path: Path | None = None
    source: str = "filesystem"
    warnings: tuple[str, ...] = ()

    def __len__(self) -> int:
        """Return the number of entries in the corpus."""
        return len(self.entries)

    def get(self, entry_id: str) -> Entry | None:
        """Return the entry with *entry_id*, or ``None`` when it is unknown."""
        return self.entries_by_id.get(entry_id)


def parse_yaml_text(text: str) -> Any:
    """Parse YAML text with PyYAML when it is installed.

    PyYAML is the reference implementation for this repository, but the desktop
    application must not depend on it, so the bundled :mod:`abook.yamlmini`
    parser is used as a fallback.

    Args:
        text: The document text.

    Returns:
        The parsed value.
    """
    if _pyyaml is not None:
        return _pyyaml.safe_load(text)
    return yamlmini.parse_yaml(text)


def _load_yaml_file(path: Path) -> Any:
    """Parse the YAML document stored at *path*."""
    return parse_yaml_text(path.read_text(encoding="utf-8"))


def find_repo_root(start: Path | None = None) -> Path:
    """Locate the repository root by walking up until ``manifest.toml`` is found.

    Args:
        start: The file or directory to start from.  Defaults to this module.

    Returns:
        The directory that holds ``manifest.toml``.

    Raises:
        FileNotFoundError: When no manifest was found.
    """
    candidates: list[Path] = []
    if start is not None:
        candidates.append(Path(start).resolve())
    candidates.append(Path(__file__).resolve())
    candidates.append(Path.cwd().resolve())
    for candidate in candidates:
        base = candidate if candidate.is_dir() else candidate.parent
        for directory in (base, *base.parents):
            if (directory / MANIFEST_FILENAME).is_file():
                return directory
    raise FileNotFoundError(
        f"could not find {MANIFEST_FILENAME}; the application must run inside "
        "the repository checkout"
    )


def load_manifest(root: Path) -> dict[str, Any]:
    """Read ``manifest.toml`` from the repository root.

    Args:
        root: The repository root.

    Returns:
        The parsed manifest, or an empty mapping when it cannot be read.
    """
    manifest_path = root / MANIFEST_FILENAME
    try:
        with manifest_path.open("rb") as handle:
            return tomllib.load(handle)
    except (OSError, tomllib.TOMLDecodeError):  # pragma: no cover - defensive
        LOGGER.warning("could not read %s", manifest_path)
        return {}


def _as_text(value: Any) -> str:
    """Coerce a YAML value into a plain string."""
    if value is None:
        return ""
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


def _as_tuple(value: Any) -> tuple[str, ...]:
    """Coerce a YAML value into a tuple of strings."""
    if value is None:
        return ()
    if isinstance(value, str):
        return (value,) if value else ()
    if isinstance(value, Mapping):
        return tuple(_as_text(item) for item in value.values())
    if isinstance(value, Sequence):
        return tuple(_as_text(item) for item in value)
    return (_as_text(value),)


def _build_sources(value: Any) -> tuple[Source, ...]:
    """Coerce the ``sources`` list of a sidecar into :class:`Source` objects."""
    sources: list[Source] = []
    if not isinstance(value, Sequence) or isinstance(value, (str, bytes)):
        return ()
    for item in value:
        if isinstance(item, Mapping):
            sources.append(
                Source(
                    title=_as_text(item.get("title")),
                    license=_as_text(item.get("license")),
                )
            )
        else:
            sources.append(Source(title=_as_text(item)))
    return tuple(sources)


def _build_verification(value: Any) -> Verification:
    """Coerce the ``verification`` mapping of a sidecar."""
    if not isinstance(value, Mapping):
        return Verification(status=_as_text(value))
    return Verification(
        status=_as_text(value.get("status")) or "draft",
        date=_as_text(value.get("date")),
        reviewers=_as_tuple(value.get("reviewers")),
        tested_by=_as_text(value.get("tested_by")),
        location=_as_text(value.get("location")),
    )


def _index_is_fresh(index_path: Path, sidecars: Sequence[Path]) -> bool:
    """Return ``True`` when the SQLite index is not older than the sidecars."""
    try:
        built_at = index_path.stat().st_mtime
    except OSError:  # pragma: no cover - defensive
        return False
    for sidecar in sidecars:
        try:
            if sidecar.stat().st_mtime > built_at:
                return False
        except OSError:  # pragma: no cover - defensive
            continue
    return True


def _load_bodies_from_index(index_path: Path) -> dict[str, str]:
    """Read the entry bodies from the pre-built SQLite index.

    Args:
        index_path: The path of ``build/index.db``.

    Returns:
        A mapping of entry id to Markdown body.  The mapping is empty when the
        index is missing, unreadable or does not have the expected schema.
    """
    if not index_path.is_file():
        return {}
    try:
        uri = f"{index_path.resolve().as_uri()}?mode=ro"
        connection = sqlite3.connect(uri, uri=True)
    except (OSError, sqlite3.Error):
        LOGGER.warning("could not open the search index at %s", index_path)
        return {}
    try:
        rows = connection.execute("SELECT id, body FROM entries").fetchall()
    except sqlite3.Error:
        LOGGER.warning("the search index at %s has an unexpected schema", index_path)
        return {}
    finally:
        connection.close()
    return {str(row[0]): str(row[1]) for row in rows}


def _read_body(path: Path) -> str:
    """Read a Markdown body, returning an empty string when it is missing."""
    try:
        return path.read_text(encoding="utf-8")
    except OSError:
        LOGGER.warning("missing body %s", path)
        return ""


def load_corpus(
    root: Path | None = None,
    *,
    prefer_index: bool = True,
    progress: ProgressCallback | None = None,
) -> Corpus:
    """Load the knowledge base from the repository.

    Args:
        root: The repository root.  Discovered automatically when omitted.
        prefer_index: When ``True`` the pre-built SQLite index is used for the
            entry bodies when it is present and not older than the sidecars.
        progress: Optional callback invoked with ``(done, total)`` after every
            entry, used to drive the progress bar of the user interface.

    Returns:
        The loaded corpus.
    """
    repo = Path(root).resolve() if root is not None else find_repo_root()
    manifest = load_manifest(repo)
    version = _as_text(manifest.get("project", {}).get("version"))
    warnings: list[str] = []

    sidecars_dir = repo / SIDECARS_DIRNAME
    sidecars = sorted(sidecars_dir.rglob(f"*{SIDECAR_SUFFIX}")) if sidecars_dir.is_dir() else []
    if not sidecars:
        warnings.append(f"no sidecars found under {sidecars_dir}")

    index_path = repo / INDEX_RELPATH
    bodies: dict[str, str] = {}
    source = "filesystem"
    if prefer_index and _index_is_fresh(index_path, sidecars):
        bodies = _load_bodies_from_index(index_path)
        if bodies:
            source = "index-db"
    elif prefer_index and index_path.is_file():
        LOGGER.info("the search index is older than the corpus, scanning files")

    entries: list[Entry] = []
    total = len(sidecars)
    for position, sidecar_path in enumerate(sidecars, start=1):
        try:
            meta = _load_yaml_file(sidecar_path)
        except (OSError, ValueError) as error:
            warnings.append(f"{sidecar_path.name}: {error}")
            LOGGER.warning("could not read %s: %s", sidecar_path, error)
            continue
        if not isinstance(meta, Mapping):
            warnings.append(f"{sidecar_path.name}: not a mapping")
            continue
        entry = _build_entry(repo, sidecar_path, meta, bodies)
        if entry is not None:
            entries.append(entry)
        if progress is not None:
            progress(position, total)

    entries.sort(key=lambda item: (item.domain, item.title.lower(), item.id))

    declared = manifest.get("domains", {}).get("list", [])
    declared_domains = [_as_text(name) for name in declared] if isinstance(declared, list) else []
    found_domains = sorted({entry.domain for entry in entries})
    domains = list(declared_domains)
    domains.extend(name for name in found_domains if name not in domains)

    domain_counts: dict[str, int] = {name: 0 for name in domains}
    safety_counts: dict[str, int] = {}
    entries_by_domain: dict[str, list[Entry]] = {name: [] for name in domains}
    for entry in entries:
        domain_counts[entry.domain] = domain_counts.get(entry.domain, 0) + 1
        safety_counts[entry.safety] = safety_counts.get(entry.safety, 0) + 1
        entries_by_domain.setdefault(entry.domain, []).append(entry)

    return Corpus(
        root=repo,
        version=version,
        entries=tuple(entries),
        domains=tuple(domains),
        domain_counts=domain_counts,
        safety_counts=safety_counts,
        entries_by_id={entry.id: entry for entry in entries},
        entries_by_domain={name: tuple(items) for name, items in entries_by_domain.items()},
        index_path=index_path if index_path.is_file() else None,
        source=source,
        warnings=tuple(warnings),
    )


def _build_entry(
    repo: Path,
    sidecar_path: Path,
    meta: Mapping[str, Any],
    bodies: Mapping[str, str],
) -> Entry | None:
    """Build an :class:`Entry` from a sidecar and the matching Markdown body."""
    sidecars_dir = repo / SIDECARS_DIRNAME
    relative = sidecar_path.relative_to(sidecars_dir)
    slug = relative.name[: -len(SIDECAR_SUFFIX)] if relative.name.endswith(SIDECAR_SUFFIX) else relative.stem
    body_path = repo / DOMAINS_DIRNAME / relative.parent / f"{slug}.md"
    try:
        relative_body = str(body_path.relative_to(repo))
    except ValueError:  # pragma: no cover - defensive
        relative_body = str(body_path)
    relative_body = relative_body.replace("\\", "/")

    entry_id = _as_text(meta.get("id"))
    if not entry_id:
        LOGGER.warning("sidecar %s has no id", sidecar_path)
        return None

    body = bodies.get(entry_id)
    if body is None:
        body = _read_body(body_path)

    materials = _as_tuple(meta.get("materials_required"))
    tools = _as_tuple(meta.get("tools_required"))
    return Entry(
        id=entry_id,
        title=_as_text(meta.get("title")) or slug,
        domain=_as_text(meta.get("domain")) or relative.parent.name,
        slug=slug,
        path=relative_body,
        tags=_as_tuple(meta.get("tags")),
        difficulty=_as_text(meta.get("difficulty")),
        safety=_as_text(meta.get("safety")),
        time_to_complete=_as_text(meta.get("time_to_complete")),
        prerequisites=_as_tuple(meta.get("prerequisites")),
        materials=materials,
        tools=tools,
        sources=_build_sources(meta.get("sources")),
        verification=_build_verification(meta.get("verification")),
        links=_as_tuple(meta.get("links")),
        body=body,
    )


def load_disclaimer(root: Path) -> str:
    """Return the summary section of ``docs/DISCLAIMER.md``, quoted verbatim.

    Args:
        root: The repository root.

    Returns:
        The bullet list of section 12, or :data:`DISCLAIMER_FALLBACK` when the
        document cannot be read.
    """
    path = root / DISCLAIMER_RELPATH
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        LOGGER.warning("could not read %s", path)
        return DISCLAIMER_FALLBACK
    summary = _extract_section(text, "12")
    return summary or DISCLAIMER_FALLBACK


def _extract_section(text: str, number: str) -> str:
    """Extract the body of the ``## <number>.`` section of a Markdown document."""
    lines = text.splitlines()
    collected: list[str] = []
    inside = False
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("## "):
            heading = stripped[3:].strip()
            if inside:
                break
            inside = heading.split(".")[0].strip() == number
            continue
        if inside:
            collected.append(line.rstrip())
    while collected and not collected[0].strip():
        collected.pop(0)
    while collected and not collected[-1].strip():
        collected.pop()
    return "\n".join(collected).strip()


def load_domain_descriptions(root: Path) -> dict[str, str]:
    """Read the one-line description of every domain from ``domains/README.md``.

    Args:
        root: The repository root.

    Returns:
        A mapping of domain slug to description.  Empty when the file is
        missing or has no table.
    """
    path = root / DOMAINS_DIRNAME / "README.md"
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return {}
    descriptions: dict[str, str] = {}
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue
        cells = [cell.strip() for cell in stripped.strip("|").split("|")]
        if len(cells) < 2:
            continue
        match = re.match(r"\[([^\]]+)\]", cells[0])
        name = (match.group(1) if match else cells[0]).strip()
        if not name or name.startswith("http"):
            continue
        description = cells[1]
        if not description or set(description) <= set("-: "):
            continue
        descriptions[name] = description
    return descriptions
