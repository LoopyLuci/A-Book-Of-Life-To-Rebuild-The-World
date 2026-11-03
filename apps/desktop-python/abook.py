#!/usr/bin/env python3
"""Entry point of the *A Book Of Life* desktop reader.

Run the application with::

    python apps/desktop-python/abook.py

The reader opens the knowledge base of the repository it lives in, works
completely offline and needs nothing but CPython 3.11 with ``tkinter``.

The ``--selftest`` flag loads the corpus, runs a few searches, checks the
translation fallback and the version, then exits without opening a window.  It
is the way the application is verified on a machine without a display::

    python apps/desktop-python/abook.py --selftest

The implementation lives in the ``abook`` package next to this file; this
script only adds it to the import path and hands over to :func:`abook.cli.main`.
"""

from __future__ import annotations

import sys
from pathlib import Path

APP_DIR = Path(__file__).resolve().parent
if str(APP_DIR) not in sys.path:
    sys.path.insert(0, str(APP_DIR))

from abook.cli import main  # noqa: E402

if __name__ == "__main__":
    sys.exit(main())
