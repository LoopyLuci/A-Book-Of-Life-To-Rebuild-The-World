#!/usr/bin/env python3
"""
Archive the knowledge base to:
- Internet Archive (Wayback Machine + item upload)
- Zenodo (DOI registration)
- Software Heritage (code)

Requires credentials in environment:
- IA_ACCESS_KEY, IA_SECRET_KEY
- ZENODO_TOKEN
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import tarfile
from datetime import UTC, datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILD_DIR = ROOT / "build"
ARCHIVE_DIR = BUILD_DIR / "archive"


def _bundle() -> Path:
    """Create a tarball of the entire repository (excluding build/)."""
    ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(UTC).strftime("%Y%m%dT%H%M%SZ")
    out = ARCHIVE_DIR / f"a-book-of-life-{stamp}.tar.gz"

    def _exclude(tarinfo: tarfile.TarInfo) -> tarfile.TarInfo | None:
        p = tarinfo.name
        if "/build/" in p or p.startswith("build/"):
            return None
        if "/.git/" in p or p.startswith(".git/"):
            return None
        if "/__pycache__/" in p:
            return None
        if p.endswith(".pyc"):
            return None
        return tarinfo

    with tarfile.open(out, "w:gz") as tar:
        tar.add(ROOT, arcname="a-book-of-life", filter=_exclude)

    return out


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def archive_internet_archive(bundle: Path, dry_run: bool = False) -> dict:
    """Upload to the Internet Archive as a new item."""
    access = os.environ.get("IA_ACCESS_KEY")
    secret = os.environ.get("IA_SECRET_KEY")

    identifier = f"a-book-of-life-{datetime.now(UTC).strftime('%Y%m%d')}"
    metadata = {
        "identifier": identifier,
        "title": f"A Book Of Life To Rebuild The World — snapshot {identifier}",
        "creator": "A Book Of Life Contributors",
        "mediatype": "texts",
        "collection": "opensource",
        "licenseurl": "https://creativecommons.org/licenses/by-sa/4.0/",
        "subject": "civilization;knowledge;offline;survival;open-source",
    }

    if dry_run or not (access and secret):
        return {
            "status": "skipped",
            "reason": "missing credentials or dry-run",
            "identifier": identifier,
            "bundle": str(bundle),
        }

    try:
        from internetarchive import upload  # type: ignore
    except ImportError:
        return {"status": "skipped", "reason": "internetarchive package not installed"}

    responses = upload(
        identifier,
        files=[str(bundle)],
        metadata=metadata,
        access_key=access,
        secret_key=secret,
    )
    return {
        "status": "uploaded",
        "identifier": identifier,
        "url": f"https://archive.org/details/{identifier}",
        "responses": [r.status_code for r in responses],
    }


def archive_zenodo(bundle: Path, dry_run: bool = False) -> dict:
    """Create a Zenodo deposition and register a DOI."""
    token = os.environ.get("ZENODO_TOKEN")

    if dry_run or not token:
        return {"status": "skipped", "reason": "missing token or dry-run"}

    try:
        import requests  # type: ignore
    except ImportError:
        return {"status": "skipped", "reason": "requests package not installed"}

    headers = {"Authorization": f"Bearer {token}"}
    base = "https://zenodo.org/api"

    # 1. Create deposition
    r = requests.post(
        f"{base}/deposit/depositions",
        headers=headers,
        json={},
        timeout=60,
    )
    r.raise_for_status()
    dep = r.json()
    bucket = dep["links"]["bucket"]
    dep_id = dep["id"]

    # 2. Upload file
    with bundle.open("rb") as f:
        r = requests.put(
            f"{bucket}/{bundle.name}",
            data=f,
            headers={"Content-Type": "application/octet-stream"},
            timeout=300,
        )
    r.raise_for_status()

    # 3. Set metadata
    metadata = {
        "metadata": {
            "title": "A Book Of Life To Rebuild The World",
            "upload_type": "dataset",
            "description": (
                "An offline-first, open-source knowledge base for rebuilding "
                "civilization from first principles."
            ),
            "creators": [{"name": "A Book Of Life Contributors"}],
            "license": "CC-BY-SA-4.0",
            "keywords": ["civilization", "knowledge", "survival", "open-source"],
        }
    }
    r = requests.put(
        f"{base}/deposit/depositions/{dep_id}",
        headers=headers,
        json=metadata,
        timeout=60,
    )
    r.raise_for_status()

    # 4. Publish
    r = requests.post(
        f"{base}/deposit/depositions/{dep_id}/actions/publish",
        headers=headers,
        timeout=60,
    )
    r.raise_for_status()

    return {
        "status": "published",
        "doi": r.json().get("doi"),
        "url": r.json().get("links", {}).get("html"),
        "deposition_id": dep_id,
    }


def main() -> int:
    parser = argparse.ArgumentParser(prog="abook-archive")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--target", choices=["ia", "zenodo", "all"], default="all")
    args = parser.parse_args()

    bundle = _bundle()
    digest = _sha256(bundle)
    print(f"Bundle: {bundle}")
    print(f"SHA-256: {digest}")

    results: dict = {
        "bundle": str(bundle.relative_to(ROOT)),
        "sha256": digest,
        "generated_at": datetime.now(UTC).isoformat(),
    }

    if args.target in ("ia", "all"):
        results["internet_archive"] = archive_internet_archive(bundle, args.dry_run)
        print(f"  IA: {results['internet_archive']['status']}")

    if args.target in ("zenodo", "all"):
        results["zenodo"] = archive_zenodo(bundle, args.dry_run)
        print(f"  Zenodo: {results['zenodo']['status']}")

    out = ARCHIVE_DIR / "archive-manifest.json"
    out.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(f"Manifest: {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
