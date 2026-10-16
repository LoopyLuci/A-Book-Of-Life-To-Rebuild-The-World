#!/usr/bin/env python3
"""
Verify that a backup can be restored from the archive manifest.

Downloads the most recent Internet Archive item and checks the SHA-256
against the manifest. Does not overwrite the local repository.
"""

from __future__ import annotations

import hashlib
import json
import sys
import tempfile
from pathlib import Path

import httpx

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "build" / "archive" / "archive-manifest.json"


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    if not MANIFEST.exists():
        print("No archive manifest found.", file=sys.stderr)
        return 1

    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    ia = data.get("internet_archive", {})
    if ia.get("status") != "uploaded":
        print("No Internet Archive upload recorded.", file=sys.stderr)
        return 1

    identifier = ia["identifier"]
    expected = data["sha256"]

    # List files in the IA item
    with httpx.Client(timeout=60.0) as client:
        r = client.get(f"https://archive.org/metadata/{identifier}")
        r.raise_for_status()
        meta = r.json()

    files = [f["name"] for f in meta.get("files", []) if f["name"].endswith(".tar.gz")]
    if not files:
        print("No tarball found in IA item.", file=sys.stderr)
        return 1

    target = files[0]
    url = f"https://archive.org/download/{identifier}/{target}"

    print(f"Downloading {url}...")
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / target
        with httpx.stream("GET", url, timeout=600.0, follow_redirects=True) as resp:
            resp.raise_for_status()
            with out.open("wb") as f:
                for chunk in resp.iter_bytes(chunk_size=1 << 20):
                    f.write(chunk)

        actual = _sha256(out)
        if actual != expected:
            print(f"Checksum mismatch: expected {expected}, got {actual}", file=sys.stderr)
            return 1

    print("Backup verified.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
