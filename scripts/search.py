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
from embedder import embed_texts  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
INDEX_PATH = ROOT / "build" / "index.db"
RRF_K = 60


def _run_match(conn: sqlite3.Connection, match: str, limit: int):
    return conn.execute(
        """
        SELECT e.id, e.title, e.domain, bm25(entries_fts) AS score
        FROM entries_fts
        JOIN entries e ON e.rowid = entries_fts.rowid
        WHERE entries_fts MATCH ?
        ORDER BY score
        LIMIT ?
        """,
        (match, limit),
    ).fetchall()


def bm25_search(conn: sqlite3.Connection, query: str, limit: int = 50):
    terms = re.findall(r"[A-Za-z0-9]+", query)
    if not terms:
        return []
    # Try the precise AND query first, then relax to OR so partial matches
    # (e.g. "purify water" vs "water purification") still return results.
    rows = _run_match(conn, " AND ".join(terms), limit)
    if not rows and len(terms) > 1:
        rows = _run_match(conn, " OR ".join(terms), limit)
    return rows


def vector_search(conn: sqlite3.Connection, query: str, limit: int = 50):
    qvec = embed_texts([query])[0]
    rows = conn.execute(
        "SELECT chunk_id, entry_id, vector FROM chunk_vectors JOIN chunks USING (chunk_id)"
    ).fetchall()

    scored: list[tuple[str, float]] = []
    for chunk_id, entry_id, blob in rows:
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


def search(query: str, limit: int = 20):
    conn = sqlite3.connect(INDEX_PATH)
    try:
        bm25 = bm25_search(conn, query)
        vec = vector_search(conn, query)
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
