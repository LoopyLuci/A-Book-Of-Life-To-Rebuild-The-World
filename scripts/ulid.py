"""
Minimal ULID implementation (no external dependency).
Spec: https://github.com/ulid/spec
"""

from __future__ import annotations

import os
import time

CROCKFORD = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"


def _encode(value: int, length: int) -> str:
    chars = []
    for _ in range(length):
        value, rem = divmod(value, 32)
        chars.append(CROCKFORD[rem])
    return "".join(reversed(chars))


def new_ulid() -> str:
    ts = int(time.time() * 1000)
    rand = int.from_bytes(os.urandom(10), "big")
    return _encode(ts, 10) + _encode(rand, 16)


def new_pnk(domain: str, slug: str) -> str:
    return f"pnk:{new_ulid()}/{domain}/{slug}"
