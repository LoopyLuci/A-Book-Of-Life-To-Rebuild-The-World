#!/usr/bin/env python3
"""
Retrieval-Augmented Generation over A Book Of Life To Rebuild The World.
Uses the hybrid index for retrieval and a local LLM (Ollama) for generation.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

import httpx

sys.path.insert(0, str(Path(__file__).parent))
from search import search as hybrid_search  # noqa: E402
from mcp_server import _read_body, _load_sidecar  # noqa: E402

OLLAMA_URL = "http://localhost:11434"
DEFAULT_MODEL = "abook-rag"
FALLBACK_MODEL = "llama3.1:8b"

SYSTEM_PROMPT = """You are the assistant for A Book Of Life To Rebuild The World,
an offline-first knowledge base for rebuilding civilization.

Rules:
- Answer ONLY from the provided context.
- Cite every claim with the entry id in square brackets, e.g. [pnk:.../survival/making-fire].
- If the context does not contain the answer, say so explicitly.
- Prefer concrete, step-by-step guidance over theory.
- Never invent facts, measurements, or sources.
"""


def retrieve(query: str, k: int = 5) -> list[dict[str, Any]]:
    """Return top-k entries with their bodies."""
    hits = hybrid_search(query, limit=k)
    docs = []
    for hit in hits:
        body = _read_body(hit["id"])
        sidecar = _load_sidecar(hit["id"])
        if body and sidecar:
            docs.append(
                {
                    "id": hit["id"],
                    "title": hit["title"],
                    "domain": hit["domain"],
                    "body": body,
                    "score": hit["score"],
                }
            )
    return docs


def format_context(docs: list[dict[str, Any]]) -> str:
    blocks = []
    for i, doc in enumerate(docs, 1):
        blocks.append(
            f"--- Context {i} ---\n"
            f"id: {doc['id']}\n"
            f"title: {doc['title']}\n"
            f"domain: {doc['domain']}\n\n"
            f"{doc['body']}\n"
        )
    return "\n".join(blocks)


def ask(query: str, model: str = DEFAULT_MODEL, k: int = 5) -> dict[str, Any]:
    docs = retrieve(query, k=k)
    if not docs:
        return {
            "answer": "No relevant entries found in A Book Of Life To Rebuild The World.",
            "sources": [],
        }

    context = format_context(docs)
    user_prompt = f"Context:\n{context}\n\nQuestion: {query}\n\nAnswer with citations:"

    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_prompt},
        ],
        "stream": False,
        "options": {"temperature": 0.2, "num_ctx": 8192},
    }

    try:
        with httpx.Client(timeout=120.0) as client:
            resp = client.post(f"{OLLAMA_URL}/api/chat", json=payload)
            resp.raise_for_status()
            data = resp.json()
            answer = data["message"]["content"]
    except httpx.HTTPError:
        # Fall back to a smaller model if the tuned model is missing
        payload["model"] = FALLBACK_MODEL
        with httpx.Client(timeout=120.0) as client:
            resp = client.post(f"{OLLAMA_URL}/api/chat", json=payload)
            resp.raise_for_status()
            data = resp.json()
            answer = data["message"]["content"]

    return {
        "answer": answer,
        "sources": [{"id": d["id"], "title": d["title"], "score": d["score"]} for d in docs],
        "model": payload["model"],
    }


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser(description="Ask A Book Of Life To Rebuild The World.")
    parser.add_argument("query")
    parser.add_argument("--k", type=int, default=5)
    parser.add_argument("--model", default=DEFAULT_MODEL)
    args = parser.parse_args()

    result = ask(args.query, model=args.model, k=args.k)
    print(result["answer"])
    print("\n--- Sources ---")
    for s in result["sources"]:
        print(f"  [{s['score']:.4f}] {s['title']} ({s['id']})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
