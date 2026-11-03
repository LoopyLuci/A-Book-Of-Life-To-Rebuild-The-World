"""Ranking the corpus against a free-text query.

The search is a BM25-flavoured ranking over three fields -- title, tags and
body -- with the fields weighted so that a title match always outranks a tag
match, and a tag match always outranks a body match.  On top of the token
scoring there is a substring (phrase) bonus, which is what makes "water pur"
find *Water Purification*.

The implementation is deliberately small and dependency free: the corpus has a
few hundred entries, so an in-memory inverted index is both fast enough and
easy to reason about.
"""

from __future__ import annotations

import math
import re
from bisect import bisect_left
from collections.abc import Iterable, Sequence
from dataclasses import dataclass

from .corpus import Corpus, Entry

__all__ = ["SearchEngine", "SearchResult", "tokenize"]

#: Word characters, excluding the underscore, so that ``first-aid`` is two
#: tokens and non-latin scripts keep working.
TOKEN_RE = re.compile(r"[^\W_]+", re.UNICODE)

#: Field weights.  A title hit is worth eight tag hits, a tag hit is worth
#: three body hits.
TITLE_WEIGHT = 8.0
TAG_WEIGHT = 3.0
BODY_WEIGHT = 1.0

#: BM25 parameters.
K1 = 1.2
B = 0.75

#: Bonus added when the whole query appears verbatim in a field.
PHRASE_BONUS_TITLE = 60.0
PHRASE_BONUS_TAGS = 20.0
PHRASE_BONUS_BODY = 4.0

#: Weight of a token that only matches by prefix.
PREFIX_WEIGHT = 0.35

#: How many vocabulary entries a prefix may expand into.
MAX_PREFIX_EXPANSIONS = 12

#: Match tiers, highest first.
TIER_TITLE = 3
TIER_TAGS = 2
TIER_BODY = 1


def tokenize(text: str) -> list[str]:
    """Split *text* into lowercase word tokens.

    Args:
        text: The text to split.

    Returns:
        The list of tokens.
    """
    return TOKEN_RE.findall(text.lower())


def _normalize_phrase(text: str) -> str:
    """Normalise a query or a field for substring comparison."""
    return " ".join(text.lower().split())


@dataclass(frozen=True)
class SearchResult:
    """One ranked entry."""

    entry: Entry
    score: float
    tier: int
    snippet: str = ""

    @property
    def matched_field(self) -> str:
        """Return the name of the field that produced the match."""
        if self.tier == TIER_TITLE:
            return "title"
        if self.tier == TIER_TAGS:
            return "tags"
        return "body"


class SearchEngine:
    """An in-memory index over a :class:`~abook.corpus.Corpus`."""

    def __init__(self, corpus: Corpus) -> None:
        """Index *corpus* so that it can be searched.

        Args:
            corpus: The corpus to index.
        """
        self._corpus = corpus
        self._entries: tuple[Entry, ...] = corpus.entries
        self._title_tokens: list[list[str]] = []
        self._tag_tokens: list[list[str]] = []
        self._body_tokens: list[list[str]] = []
        self._title_postings: dict[str, list[tuple[int, int]]] = {}
        self._tag_postings: dict[str, list[tuple[int, int]]] = {}
        self._body_postings: dict[str, list[tuple[int, int]]] = {}
        self._title_lower: list[str] = []
        self._tags_lower: list[str] = []
        self._body_lower: list[str] = []
        self._build()

    # ------------------------------------------------------------------
    # Index construction
    # ------------------------------------------------------------------
    def _build(self) -> None:
        """Tokenise every entry and build the inverted indexes."""
        for position, entry in enumerate(self._entries):
            title_tokens = tokenize(entry.title)
            tag_tokens = [token for tag in entry.tags for token in tokenize(tag)]
            body_tokens = tokenize(entry.body)
            self._title_tokens.append(title_tokens)
            self._tag_tokens.append(tag_tokens)
            self._body_tokens.append(body_tokens)
            self._title_lower.append(entry.title.lower())
            self._tags_lower.append(" ".join(entry.tags).lower())
            self._body_lower.append(entry.body.lower())
            self._add_postings(self._title_postings, position, title_tokens)
            self._add_postings(self._tag_postings, position, tag_tokens)
            self._add_postings(self._body_postings, position, body_tokens)
        self._vocabulary = sorted(
            set(self._title_postings) | set(self._tag_postings) | set(self._body_postings)
        )

    @staticmethod
    def _add_postings(
        postings: dict[str, list[tuple[int, int]]], position: int, tokens: Sequence[str]
    ) -> None:
        """Record the term frequencies of one document in *postings*."""
        counts: dict[str, int] = {}
        for token in tokens:
            counts[token] = counts.get(token, 0) + 1
        for token, count in counts.items():
            postings.setdefault(token, []).append((position, count))

    # ------------------------------------------------------------------
    # Scoring helpers
    # ------------------------------------------------------------------
    def _average_length(self, tokens: Sequence[Sequence[str]]) -> float:
        """Return the average document length of a field."""
        if not tokens:
            return 0.0
        return sum(len(item) for item in tokens) / len(tokens)

    def _bm25(
        self,
        postings: dict[str, list[tuple[int, int]]],
        lengths: Sequence[Sequence[str]],
        term: str,
        weight: float,
    ) -> dict[int, float]:
        """Return the BM25 contribution of *term* over one field."""
        posting = postings.get(term)
        if not posting:
            return {}
        total = len(self._entries)
        average = self._average_length(lengths) or 1.0
        document_frequency = len(posting)
        idf = math.log(1.0 + (total - document_frequency + 0.5) / (document_frequency + 0.5))
        scores: dict[int, float] = {}
        for position, frequency in posting:
            length = len(lengths[position]) or 1
            denominator = frequency + K1 * (1.0 - B + B * length / average)
            scores[position] = weight * idf * (frequency * (K1 + 1.0)) / denominator
        return scores

    def _prefix_matches(self, term: str) -> list[str]:
        """Return the vocabulary entries that start with *term*."""
        if len(term) < 2:
            return []
        index = bisect_left(self._vocabulary, term)
        matches: list[str] = []
        while index < len(self._vocabulary) and len(matches) < MAX_PREFIX_EXPANSIONS:
            candidate = self._vocabulary[index]
            if not candidate.startswith(term):
                break
            matches.append(candidate)
            index += 1
        return matches

    def _snippet(self, entry: Entry, terms: Iterable[str]) -> str:
        """Return a short excerpt of *entry* around the first matching term."""
        body = entry.body
        if not body:
            return ""
        lowered = body.lower()
        position = -1
        for term in terms:
            found = lowered.find(term)
            if found >= 0 and (position < 0 or found < position):
                position = found
        if position < 0:
            position = 0
        start = max(0, position - 60)
        end = min(len(body), position + 140)
        excerpt = " ".join(body[start:end].split())
        if start > 0:
            excerpt = "…" + excerpt
        if end < len(body):
            excerpt = excerpt + "…"
        return excerpt

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------
    def search(
        self,
        query: str,
        limit: int = 50,
        domain: str | None = None,
        safety: str | None = None,
    ) -> list[SearchResult]:
        """Search the corpus.

        Args:
            query: The free-text query.
            limit: The maximum number of results.
            domain: Restrict the results to a single domain when given.
            safety: Restrict the results to a single safety level when given.

        Returns:
            The ranked results.  Title matches come first, then tag matches,
            then body matches; within a tier the BM25 score decides.
        """
        text = query.strip()
        if not text:
            return []
        terms = tokenize(text)
        if not terms:
            return []

        scores: dict[int, float] = {}
        tiers: dict[int, int] = {}

        def add(field_scores: dict[int, float], tier: int) -> None:
            for position, value in field_scores.items():
                scores[position] = scores.get(position, 0.0) + value
                if tiers.get(position, 0) < tier:
                    tiers[position] = tier

        for term in terms:
            add(self._bm25(self._title_postings, self._title_tokens, term, TITLE_WEIGHT), TIER_TITLE)
            add(self._bm25(self._tag_postings, self._tag_tokens, term, TAG_WEIGHT), TIER_TAGS)
            add(self._bm25(self._body_postings, self._body_tokens, term, BODY_WEIGHT), TIER_BODY)
            if term not in self._title_postings:
                for expansion in self._prefix_matches(term):
                    add(
                        self._bm25(
                            self._title_postings, self._title_tokens, expansion, TITLE_WEIGHT * PREFIX_WEIGHT
                        ),
                        TIER_TITLE,
                    )
            if term not in self._tag_postings:
                for expansion in self._prefix_matches(term):
                    add(
                        self._bm25(
                            self._tag_postings, self._tag_tokens, expansion, TAG_WEIGHT * PREFIX_WEIGHT
                        ),
                        TIER_TAGS,
                    )

        phrase = _normalize_phrase(text)
        if len(phrase) >= 3:
            for position in range(len(self._entries)):
                if phrase in self._title_lower[position]:
                    scores[position] = scores.get(position, 0.0) + PHRASE_BONUS_TITLE
                    tiers[position] = TIER_TITLE
                elif phrase in self._tags_lower[position]:
                    scores[position] = scores.get(position, 0.0) + PHRASE_BONUS_TAGS
                    tiers[position] = max(tiers.get(position, 0), TIER_TAGS)
                elif phrase in self._body_lower[position]:
                    scores[position] = scores.get(position, 0.0) + PHRASE_BONUS_BODY
                    tiers[position] = max(tiers.get(position, 0), TIER_BODY)

        results: list[SearchResult] = []
        for position, tier in tiers.items():
            entry = self._entries[position]
            if domain is not None and entry.domain != domain:
                continue
            if safety is not None and entry.safety != safety:
                continue
            results.append(
                SearchResult(
                    entry=entry,
                    score=scores.get(position, 0.0),
                    tier=tier,
                    snippet=self._snippet(entry, terms),
                )
            )
        results.sort(key=lambda item: (-item.tier, -item.score, item.entry.title.lower()))
        return results[:limit]

    def quick_jump(self, query: str, limit: int = 30) -> list[Entry]:
        """Return the entries that match a short quick-jump query.

        Titles that start with the query come first, then titles that contain
        it, then entries whose slug or tags match.

        Args:
            query: The quick-jump query.
            limit: The maximum number of entries.

        Returns:
            The matching entries, best match first.
        """
        text = query.strip().lower()
        if not text:
            return list(self._entries[:limit])
        starts: list[Entry] = []
        contains: list[Entry] = []
        other: list[Entry] = []
        for entry in self._entries:
            title = entry.title.lower()
            if title.startswith(text):
                starts.append(entry)
            elif text in title:
                contains.append(entry)
            elif text in entry.slug.lower() or any(text in tag.lower() for tag in entry.tags):
                other.append(entry)
        return (starts + contains + other)[:limit]

    def domain_entries(self, domain: str) -> tuple[Entry, ...]:
        """Return every entry of *domain*."""
        return self._corpus.entries_by_domain.get(domain, ())
