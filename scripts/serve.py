#!/usr/bin/env python3
"""FastAPI server exposing search, retrieval, and verification."""

from __future__ import annotations

import sqlite3
from pathlib import Path

from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import FileResponse, HTMLResponse
from pydantic import BaseModel

import sys

sys.path.insert(0, str(Path(__file__).parent))
from search import search as hybrid_search  # noqa: E402
from verify import (  # noqa: E402
    Status,
    list_field_tests,
    load_ledger,
    load_record,
)
from dashboard import OUT_PATH as DASHBOARD_PATH  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
INDEX_PATH = ROOT / "build" / "index.db"

app = FastAPI(title="A Book Of Life To Rebuild The World API", version="1.0.0")


class SearchResult(BaseModel):
    id: str
    title: str
    domain: str
    difficulty: str
    safety: str
    score: float


class Entry(BaseModel):
    id: str
    title: str
    domain: str
    tags: str
    difficulty: str
    safety: str
    verification_status: str
    body: str


class VerificationResponse(BaseModel):
    entry_id: str
    status: str
    reviewers: list[str]
    tested_by: str | None
    tested_date: str | None
    tested_location: str | None
    notes: str


@app.get("/health")
def health():
    return {"status": "ok", "index_exists": INDEX_PATH.exists()}


@app.get("/search", response_model=list[SearchResult])
def search_endpoint(
    q: str = Query(..., min_length=1),
    limit: int = Query(20, ge=1, le=100),
):
    return hybrid_search(q, limit)


@app.get("/entry/{entry_id:path}", response_model=Entry)
def get_entry(entry_id: str):
    conn = sqlite3.connect(INDEX_PATH)
    try:
        row = conn.execute(
            """
            SELECT id, title, domain, tags, difficulty, safety,
                   verification_status, body
            FROM entries WHERE id = ?
            """,
            (entry_id,),
        ).fetchone()
    finally:
        conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Entry not found")
    return Entry(
        id=row[0], title=row[1], domain=row[2], tags=row[3],
        difficulty=row[4], safety=row[5], verification_status=row[6], body=row[7],
    )


@app.get("/verify/{entry_id:path}", response_model=VerificationResponse)
def get_verification(entry_id: str):
    try:
        rec = load_record(entry_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    return VerificationResponse(
        entry_id=rec.entry_id,
        status=rec.status.value,
        reviewers=rec.reviewers,
        tested_by=rec.tested_by,
        tested_date=rec.tested_date,
        tested_location=rec.tested_location,
        notes=rec.notes,
    )


@app.get("/field-tests")
def get_field_tests():
    return list_field_tests()


@app.get("/ledger")
def get_ledger():
    return load_ledger()


@app.get("/stats")
def get_stats():
    conn = sqlite3.connect(INDEX_PATH)
    try:
        total = conn.execute("SELECT COUNT(*) FROM entries").fetchone()[0]
        by_status = dict(
            conn.execute(
                "SELECT verification_status, COUNT(*) FROM entries GROUP BY verification_status"
            ).fetchall()
        )
        by_domain = dict(
            conn.execute("SELECT domain, COUNT(*) FROM entries GROUP BY domain").fetchall()
        )
    finally:
        conn.close()
    return {
        "total": total,
        "by_status": by_status,
        "by_domain": by_domain,
    }


@app.get("/dashboard", response_class=HTMLResponse)
def dashboard():
    if DASHBOARD_PATH.exists():
        return DASHBOARD_PATH.read_text(encoding="utf-8")
    raise HTTPException(
        status_code=404,
        detail="Dashboard not built. Run: python scripts/dashboard.py",
    )


@app.get("/", response_class=HTMLResponse)
def index():
    return """
    <!DOCTYPE html>
    <html><head><title>A Book Of Life To Rebuild The World</title></head>
    <body>
      <h1>A Book Of Life To Rebuild The World — API</h1>
      <ul>
        <li><a href="/docs">/docs</a> — OpenAPI spec</li>
        <li><a href="/dashboard">/dashboard</a> — verification dashboard</li>
        <li><a href="/stats">/stats</a> — knowledge base stats</li>
      </ul>
    </body></html>
    """


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8080)
