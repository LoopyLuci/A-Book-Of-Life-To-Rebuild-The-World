"""
Local embedding generator using ONNX Runtime.
Falls back to a deterministic hash-based embedding if the model
is not available (useful for CI without downloads).
"""

from __future__ import annotations

import hashlib
import os
from pathlib import Path

import numpy as np

MODEL_DIR = Path(os.environ.get("BOL_MODEL_DIR", Path.home() / ".cache" / "book-of-life"))
MODEL_PATH = MODEL_DIR / "all-MiniLM-L6-v2.onnx"
DIM = 384
_USE_ONNX = MODEL_PATH.exists()


def semantic_available() -> bool:
    """Whether the real embedding model is installed.

    The hash fallback produces stable but meaningless vectors. Callers that
    rank by similarity must check this first: a cosine distance between two
    hashes carries no information about the two texts.
    """
    return _USE_ONNX


def _hash_embed(text: str) -> np.ndarray:
    """Deterministic fallback embedding (not semantic, but stable)."""
    h = hashlib.sha256(text.encode("utf-8")).digest()
    rng = np.random.default_rng(int.from_bytes(h[:8], "big"))
    vec = rng.standard_normal(DIM).astype(np.float32)
    norm = np.linalg.norm(vec)
    return vec / norm if norm > 0 else vec


def _onnx_embed(texts: list[str]) -> np.ndarray:
    import onnxruntime as ort
    from transformers import AutoTokenizer

    tokenizer = AutoTokenizer.from_pretrained("sentence-transformers/all-MiniLM-L6-v2")
    session = ort.InferenceSession(str(MODEL_PATH), providers=["CPUExecutionProvider"])

    inputs = tokenizer(
        texts,
        padding=True,
        truncation=True,
        max_length=256,
        return_tensors="np",
    )

    feed = {
        "input_ids": inputs["input_ids"].astype(np.int64),
        "attention_mask": inputs["attention_mask"].astype(np.int64),
    }
    if "token_type_ids" in inputs:
        feed["token_type_ids"] = inputs["token_type_ids"].astype(np.int64)

    outputs = session.run(None, feed)[0]  # (batch, seq, hidden)
    mask = inputs["attention_mask"][..., None].astype(np.float32)
    summed = (outputs * mask).sum(axis=1)
    counts = mask.sum(axis=1)
    mean = summed / np.clip(counts, 1e-9, None)
    norms = np.linalg.norm(mean, axis=1, keepdims=True)
    return (mean / np.clip(norms, 1e-9, None)).astype(np.float32)


def embed_texts(texts: list[str]) -> np.ndarray:
    if not texts:
        return np.zeros((0, DIM), dtype=np.float32)
    if _USE_ONNX:
        return _onnx_embed(texts)
    return np.stack([_hash_embed(t) for t in texts])
