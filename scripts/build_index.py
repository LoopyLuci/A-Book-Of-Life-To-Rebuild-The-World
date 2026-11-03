#!/usr/bin/env python3
"""
Build the hybrid search index: SQLite FTS5 (BM25) + local vector embeddings.
"""

from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
DOMAINS_DIR = ROOT / "domains"
SIDECARS_DIR = ROOT / "sidecars"
BUILD_DIR = ROOT / "build"
INDEX_PATH = BUILD_DIR / "index.db"

sys.path.insert(0, str(Path(__file__).parent))
from chunker import chunk_markdown  # noqa: E402
from embedder import embed_texts  # noqa: E402


def load_entries():
    for sidecar_path in sorted(SIDECARS_DIR.rglob("*.pnk.yaml")):
        rel = sidecar_path.relative_to(SIDECARS_DIR)
        md_path = DOMAINS_DIR / rel.with_suffix("").with_suffix(".md")
        if not md_path.exists():
            continue
        with sidecar_path.open("r", encoding="utf-8") as f:
            meta = yaml.safe_load(f)
        text = md_path.read_text(encoding="utf-8")
        yield meta, text, md_path


def init_db(conn: sqlite3.Connection) -> None:
    conn.executescript(
        """
        PRAGMA journal_mode = WAL;
        PRAGMA synchronous = NORMAL;

        CREATE TABLE IF NOT EXISTS entries (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            domain TEXT NOT NULL,
            tags TEXT NOT NULL,
            difficulty TEXT NOT NULL,
            safety TEXT NOT NULL,
            verification_status TEXT NOT NULL,
            path TEXT NOT NULL,
            body TEXT NOT NULL
        );

        CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts USING fts5(
            title, body, tags,
            content='entries',
            content_rowid='rowid',
            tokenize='porter unicode61'
        );

        CREATE TABLE IF NOT EXISTS chunks (
            chunk_id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_id TEXT NOT NULL,
            heading TEXT,
            ordinal INTEGER NOT NULL,
            text TEXT NOT NULL,
            FOREIGN KEY (entry_id) REFERENCES entries(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS chunk_vectors (
            chunk_id INTEGER PRIMARY KEY,
            vector BLOB NOT NULL,
            FOREIGN KEY (chunk_id) REFERENCES chunks(chunk_id) ON DELETE CASCADE
        );

        CREATE INDEX IF NOT EXISTS idx_entries_domain ON entries(domain);
        CREATE INDEX IF NOT EXISTS idx_chunks_entry ON chunks(entry_id);
        """
    )


def build() -> int:
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    if INDEX_PATH.exists():
        INDEX_PATH.unlink()

    conn = sqlite3.connect(INDEX_PATH)
    try:
        init_db(conn)

        entries = list(load_entries())
        print(f"Loaded {len(entries)} entries.")

        all_chunks: list[tuple[str, str, int, str]] = []

        for meta, body, path in entries:
            conn.execute(
                """
                INSERT INTO entries (id, title, domain, tags, difficulty, safety,
                                     verification_status, path, body)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    meta["id"],
                    meta["title"],
                    meta["domain"],
                    ",".join(meta.get("tags", [])),
                    meta["difficulty"],
                    meta["safety"],
                    meta["verification"]["status"],
                    str(path.relative_to(ROOT)),
                    body,
                ),
            )

            for ordinal, (heading, chunk_text) in enumerate(chunk_markdown(body)):
                all_chunks.append((meta["id"], heading, ordinal, chunk_text))

        conn.execute(
            "INSERT INTO entries_fts(rowid, title, body, tags) "
            "SELECT rowid, title, body, tags FROM entries"
        )

        print(f"Embedding {len(all_chunks)} chunks...")
        texts = [c[3] for c in all_chunks]
        vectors = embed_texts(texts)

        for (entry_id, heading, ordinal, chunk_text), vec in zip(
            all_chunks, vectors, strict=False
        ):
            cur = conn.execute(
                "INSERT INTO chunks (entry_id, heading, ordinal, text) VALUES (?, ?, ?, ?)",
                (entry_id, heading, ordinal, chunk_text),
            )
            conn.execute(
                "INSERT INTO chunk_vectors (chunk_id, vector) VALUES (?, ?)",
                (cur.lastrowid, vec.tobytes()),
            )

        conn.commit()

        manifest = {
            "kb_version": "0.1.0-alpha",
            "entry_count": len(entries),
            "chunk_count": len(all_chunks),
            "index_path": str(INDEX_PATH.relative_to(ROOT)),
        }
        (BUILD_DIR / "manifest.json").write_text(
            json.dumps(manifest, indent=2), encoding="utf-8"
        )

        print(f"Index built: {INDEX_PATH}")
        print(f"  Entries: {len(entries)}")
        print(f"  Chunks:  {len(all_chunks)}")
        return 0
    finally:
        conn.close()


if __name__ == "__main__":
    sys.exit(build())
