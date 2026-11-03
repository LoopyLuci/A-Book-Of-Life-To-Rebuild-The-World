"""
Markdown chunker: split by heading, with token overlap.
Uses a simple word-count proxy for tokens (1 token ≈ 0.75 words).
"""

from __future__ import annotations

import re
from collections.abc import Iterator

HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$", re.MULTILINE)

MAX_TOKENS = 512
OVERLAP_TOKENS = 64
TOKENS_PER_WORD = 1.33


def _approx_tokens(text: str) -> int:
    return int(len(text.split()) * TOKENS_PER_WORD)


def _split_sections(markdown: str) -> list[tuple[str, str]]:
    matches = list(HEADING_RE.finditer(markdown))
    if not matches:
        return [("", markdown)]

    sections: list[tuple[str, str]] = []
    if matches[0].start() > 0:
        sections.append(("", markdown[: matches[0].start()]))

    for i, m in enumerate(matches):
        heading = m.group(2).strip()
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(markdown)
        sections.append((heading, markdown[start:end].strip()))

    return sections


def _split_long(text: str, heading: str) -> Iterator[tuple[str, str]]:
    words = text.split()
    if _approx_tokens(text) <= MAX_TOKENS:
        yield heading, text
        return

    step = MAX_TOKENS - OVERLAP_TOKENS
    for i in range(0, len(words), step):
        chunk = " ".join(words[i : i + MAX_TOKENS])
        if chunk:
            yield heading, chunk


def chunk_markdown(markdown: str) -> Iterator[tuple[str, str]]:
    for heading, body in _split_sections(markdown):
        if not body.strip():
            continue
        yield from _split_long(body, heading)
