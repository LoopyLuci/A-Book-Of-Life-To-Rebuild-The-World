"""Typed models returned by the SDK."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass(frozen=True)
class Version:
    kb_version: str
    api_version: str
    schema_version: str
    built_at: str


@dataclass(frozen=True)
class SearchResult:
    id: str
    title: str
    domain: str
    difficulty: str
    safety: str
    score: float
    snippet: str | None = None


@dataclass(frozen=True)
class EntrySummary:
    id: str
    title: str
    domain: str
    difficulty: str
    safety: str
    verification_status: str


@dataclass(frozen=True)
class Entry:
    id: str
    title: str
    domain: str
    difficulty: str
    safety: str
    verification_status: str
    tags: list[str] = field(default_factory=list)
    body: str = ""
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class Edge:
    id: str
    relation: str


@dataclass(frozen=True)
class LinkGraph:
    id: str
    outgoing: list[Edge] = field(default_factory=list)
    incoming: list[Edge] = field(default_factory=list)


@dataclass(frozen=True)
class Verification:
    entry_id: str
    status: str
    reviewers: list[str] = field(default_factory=list)
    tested_by: str | None = None
    tested_date: str | None = None
    tested_location: str | None = None
    notes: str = ""


@dataclass(frozen=True)
class VerificationEvent:
    entry_id: str
    from_status: str
    to_status: str
    actor: str
    timestamp: str
    notes: str = ""


@dataclass(frozen=True)
class FieldTest:
    raw: dict[str, Any]


@dataclass(frozen=True)
class Stats:
    total: int
    by_status: dict[str, int]
    by_domain: dict[str, int]
    by_safety: dict[str, int]
    by_difficulty: dict[str, int]


@dataclass(frozen=True)
class Resolution:
    uri: str
    node_id: str
    api_url: str
    entry_id: str
    title: str
