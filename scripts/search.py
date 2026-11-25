#!/usr/bin/env python3
"""
Hybrid search: BM25 (FTS5) + vector similarity, fused with RRF.
"""

from __future__ import annotations

import argparse
import re
import sqlite3
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
from embedder import embed_texts, semantic_available

ROOT = Path(__file__).resolve().parent.parent
INDEX_PATH = ROOT / "build" / "index.db"
RRF_K = 60

# FTS5 column weights, in the column order of the entries_fts table:
# title, body, tags. A match in the title is worth far more than the same
# word buried in the body, which is what makes "purify water" find
# "Water Purification" rather than a chemistry chapter that mentions water.
FTS_WEIGHTS = (10.0, 1.0, 3.0)


def _run_match(
    conn: sqlite3.Connection,
    match: str,
    limit: int,
    domain: str | None = None,
):
    sql = """
        SELECT e.id, e.title, e.domain, bm25(entries_fts, ?, ?, ?) AS score
        FROM entries_fts
        JOIN entries e ON e.rowid = entries_fts.rowid
        WHERE entries_fts MATCH ?
    """
    params: tuple[object, ...] = (*FTS_WEIGHTS, match)
    if domain is not None:
        sql += " AND e.domain = ?"
        params += (domain,)
    sql += " ORDER BY score LIMIT ?"
    return conn.execute(sql, (*params, limit)).fetchall()


def _prefix_variants(terms: list[str]) -> list[list[str]]:
    """Prefix forms of the terms, from the exact term down to a short stem.

    The porter stemmer shortens "purification" to "purif", so a query for
    "purify" would never match it with an exact token. A prefix of the typed
    word does match the stem, provided the prefix is short enough. The
    cascade below tries the typed word first and then shortens it a letter at
    a time, never below four characters.
    """
    variants: list[list[str]] = [list(terms)]
    for offset in range(1, 4):
        variant = []
        for term in terms:
            length = max(4, len(term) - offset)
            variant.append(f"{term[:length]}*")
        if variant != variants[-1]:
            variants.append(variant)
    return variants


def _query_shapes(terms: list[str]) -> list[str]:
    """The FTS queries to try, from the most precise to the most forgiving."""
    if not terms:
        return []
    shapes: list[str] = []
    for variant in _prefix_variants(terms):
        shapes.append(" AND ".join(variant))
    for variant in _prefix_variants(terms):
        shapes.append(" OR ".join(variant))
    # Keep the order but drop the duplicates.
    seen: set[str] = set()
    ordered: list[str] = []
    for shape in shapes:
        if shape not in seen:
            seen.add(shape)
            ordered.append(shape)
    return ordered


def bm25_search(
    conn: sqlite3.Connection,
    query: str,
    limit: int = 50,
    domain: str | None = None,
):
    terms = re.findall(r"[A-Za-z0-9]+", query)
    if not terms:
        return []

    # Every shape is tried, and the best score each entry achieves is kept.
    # The prefix shapes are a superset of the exact ones, so an entry that
    # matches "purification" scores well even when the reader typed
    # "purify"; the exact shapes still catch a literal match the prefix
    # would have ranked lower.
    best: dict[str, tuple[float, tuple]] = {}
    for shape in _query_shapes(terms):
        for row in _run_match(conn, shape, limit * 2, domain):
            entry_id = row[0]
            score = row[3]
            current = best.get(entry_id)
            if current is None or score < current[0]:
                best[entry_id] = (score, row)

    ranked = sorted(best.values(), key=lambda item: item[0])
    return [row for _score, row in ranked[:limit]]


def vector_search(
    conn: sqlite3.Connection,
    query: str,
    limit: int = 50,
    domain: str | None = None,
):
    qvec = embed_texts([query])[0]
    sql = (
        "SELECT chunk_id, entry_id, vector FROM chunk_vectors "
        "JOIN chunks USING (chunk_id) JOIN entries ON entries.id = chunks.entry_id"
    )
    params: tuple[object, ...] = ()
    if domain is not None:
        sql += " WHERE entries.domain = ?"
        params = (domain,)
    rows = conn.execute(sql, params).fetchall()

    scored: list[tuple[str, float]] = []
    for _chunk_id, entry_id, blob in rows:
        vec = np.frombuffer(blob, dtype=np.float32)
        sim = float(np.dot(qvec, vec))
        scored.append((entry_id, sim))

    # Collapse to best score per entry
    best: dict[str, float] = {}
    for entry_id, sim in scored:
        if entry_id not in best or sim > best[entry_id]:
            best[entry_id] = sim

    ranked = sorted(best.items(), key=lambda x: -x[1])[:limit]
    return [(eid, sim) for eid, sim in ranked]


def rrf_fuse(bm25, vector, k: int = RRF_K):
    scores: dict[str, float] = {}
    for rank, row in enumerate(bm25):
        scores[row[0]] = scores.get(row[0], 0.0) + 1.0 / (k + rank + 1)
    for rank, (eid, _) in enumerate(vector):
        scores[eid] = scores.get(eid, 0.0) + 1.0 / (k + rank + 1)
    return sorted(scores.items(), key=lambda x: -x[1])


def search(query: str, limit: int = 20, domain: str | None = None):
    conn = sqlite3.connect(INDEX_PATH)
    try:
        bm25 = bm25_search(conn, query, domain=domain)
        if semantic_available():
            vec = vector_search(conn, query, domain=domain)
        else:
            # Without the real embedding model the vectors are hashes, and a
            # cosine distance between two hashes means nothing. Ranking on it
            # would shuffle the results at random, so the lexical score is
            # used on its own.
            vec = []
        fused = rrf_fuse(bm25, vec)

        results = []
        for entry_id, score in fused[:limit]:
            row = conn.execute(
                "SELECT id, title, domain, difficulty, safety FROM entries WHERE id = ?",
                (entry_id,),
            ).fetchone()
            if row:
                results.append({
                    "id": row[0],
                    "title": row[1],
                    "domain": row[2],
                    "difficulty": row[3],
                    "safety": row[4],
                    "score": round(score, 6),
                })
        return results
    finally:
        conn.close()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("query")
    parser.add_argument("--limit", type=int, default=10)
    args = parser.parse_args()

    for r in search(args.query, args.limit):
        print(f"[{r['score']:.4f}] {r['title']} ({r['domain']}, {r['difficulty']})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
