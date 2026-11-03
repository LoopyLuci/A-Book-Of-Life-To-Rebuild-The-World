#!/usr/bin/env python3
"""
Assemble the offline bundle: static HTML, client-side search index and ZIM.

This is the stable entry point the pipeline and the documentation call. The
work itself lives in `build_zim.py`; this module keeps the older name working
and never produces a partial site, which is what a second builder would do.
"""

from __future__ import annotations

import sys

import build_zim


def build() -> int:
    return build_zim.build()


if __name__ == "__main__":
    sys.exit(build())
