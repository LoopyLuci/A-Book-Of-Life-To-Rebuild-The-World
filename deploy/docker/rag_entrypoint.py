"""HTTP wrapper around scripts/rag.py for the Docker stack."""

from fastapi import FastAPI
from pydantic import BaseModel

import sys
sys.path.insert(0, "scripts")
from rag import ask  # noqa: E402

app = FastAPI(title="A Book Of Life — RAG", version="1.0.0")


class Query(BaseModel):
    query: str
    k: int = 5


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/ask")
def ask_endpoint(q: Query):
    return ask(q.query, k=q.k)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8084)
