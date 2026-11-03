#!/usr/bin/env python3
"""
Federation engine for A Book Of Life To Rebuild The World.

Implements:
- Node identity (ULID + Ed25519 keypair)
- Signed sync manifests
- Peer sync with verification precedence
- Conflict detection
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import sys
import time
from dataclasses import asdict, dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import httpx
import yaml

ROOT = Path(__file__).resolve().parent.parent
SIDECARS_DIR = ROOT / "sidecars"
FEDERATION_DIR = ROOT / "governance" / "federation"
PEER_LEDGER = FEDERATION_DIR / "peer-ledger.jsonl"
PEERS_FILE = FEDERATION_DIR / "peers.yaml"
IDENTITY_FILE = FEDERATION_DIR / "identity.json"

PROTOCOL_VERSION = "1.0"

VERIFICATION_RANK = {
    "draft": 1,
    "peer-reviewed": 2,
    "field-tested": 3,
    "deprecated": 0,
}


# ---------------------------------------------------------------------------
# Identity
# ---------------------------------------------------------------------------

def _new_ulid() -> str:
    CROCKFORD = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
    ts = int(time.time() * 1000)

    def enc(v: int, n: int) -> str:
        out = []
        for _ in range(n):
            v, r = divmod(v, 32)
            out.append(CROCKFORD[r])
        return "".join(reversed(out))

    import os as _os
    rand = int.from_bytes(_os.urandom(10), "big")
    return enc(ts, 10) + enc(rand, 16)


def load_or_create_identity() -> dict[str, Any]:
    FEDERATION_DIR.mkdir(parents=True, exist_ok=True)
    if IDENTITY_FILE.exists():
        return json.loads(IDENTITY_FILE.read_text(encoding="utf-8"))

    try:
        from cryptography.hazmat.primitives import serialization
        from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
    except ImportError as exc:
        raise SystemExit(
            "cryptography is required for federation. Install: pip install cryptography"
        ) from exc

    priv = Ed25519PrivateKey.generate()
    pub = priv.public_key()

    priv_pem = priv.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    ).decode()
    pub_pem = pub.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    ).decode()

    identity = {
        "node_id": _new_ulid(),
        "private_key_pem": priv_pem,
        "public_key_pem": pub_pem,
        "created_at": datetime.now(UTC).isoformat(),
    }
    IDENTITY_FILE.write_text(json.dumps(identity, indent=2), encoding="utf-8")
    IDENTITY_FILE.chmod(0o600)
    return identity


# ---------------------------------------------------------------------------
# Sync manifest
# ---------------------------------------------------------------------------

def _sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _canonical_json(obj: Any) -> bytes:
    return json.dumps(obj, sort_keys=True, separators=(",", ":")).encode("utf-8")


def _sidecar_to_entry(sidecar: dict, body: str) -> dict[str, Any]:
    return {
        "id": sidecar["id"],
        "title": sidecar["title"],
        "domain": sidecar["domain"],
        "difficulty": sidecar["difficulty"],
        "safety": sidecar["safety"],
        "verification": sidecar["verification"]["status"],
        "verification_date": sidecar["verification"].get("date"),
        "updated_at": sidecar["verification"].get("date")
        or datetime.now(UTC).date().isoformat(),
        "content_hash": "sha256:" + _sha256_hex(body.encode("utf-8")),
    }


def build_sync_manifest(identity: dict) -> dict[str, Any]:
    entries = []
    for path in sorted(SIDECARS_DIR.rglob("*.pnk.yaml")):
        rel = path.relative_to(SIDECARS_DIR)
        md_path = ROOT / "domains" / rel.with_suffix("").with_suffix(".md")
        if not md_path.exists():
            continue
        with path.open("r", encoding="utf-8") as f:
            sidecar = yaml.safe_load(f)
        entries.append(_sidecar_to_entry(sidecar, md_path.read_text(encoding="utf-8")))

    entries.sort(key=lambda x: x["id"])
    payload = {
        "node_id": identity["node_id"],
        "protocol_version": PROTOCOL_VERSION,
        "generated_at": datetime.now(UTC).isoformat(),
        "entries": entries,
    }

    signature = _sign(identity["private_key_pem"], _canonical_json(payload["entries"]))
    payload["signature"] = signature
    return payload


def _sign(private_pem: str, data: bytes) -> str:
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

    priv = serialization.load_pem_private_key(private_pem.encode(), password=None)
    assert isinstance(priv, Ed25519PrivateKey)
    return base64.b64encode(priv.sign(data)).decode()


def verify_signature(public_pem: str, data: bytes, signature_b64: str) -> bool:
    from cryptography.exceptions import InvalidSignature
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey

    pub = serialization.load_pem_public_key(public_pem.encode())
    assert isinstance(pub, Ed25519PublicKey)
    try:
        pub.verify(base64.b64decode(signature_b64), data)
        return True
    except InvalidSignature:
        return False


# ---------------------------------------------------------------------------
# Peers
# ---------------------------------------------------------------------------

@dataclass
class Peer:
    node_id: str
    api_url: str
    public_key_pem: str
    trust: str = "neutral"  # trusted | neutral | untrusted
    last_sync: str | None = None


def load_peers() -> dict[str, Peer]:
    if not PEERS_FILE.exists():
        return {}
    with PEERS_FILE.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f) or {}
    return {p["node_id"]: Peer(**p) for p in raw.get("peers", [])}


def save_peers(peers: dict[str, Peer]) -> None:
    FEDERATION_DIR.mkdir(parents=True, exist_ok=True)
    data = {"peers": [asdict(p) for p in peers.values()]}
    with PEERS_FILE.open("w", encoding="utf-8") as f:
        yaml.safe_dump(data, f, sort_keys=False, allow_unicode=True)


def add_peer(api_url: str, trust: str = "neutral") -> Peer:
    with httpx.Client(timeout=30.0) as client:
        r = client.get(f"{api_url.rstrip('/')}/federation/manifest")
        r.raise_for_status()
        manifest = r.json()

    peer = Peer(
        node_id=manifest["node_id"],
        api_url=api_url.rstrip("/"),
        public_key_pem=manifest["public_key"],
        trust=trust,
    )
    peers = load_peers()
    peers[peer.node_id] = peer
    save_peers(peers)
    return peer


# ---------------------------------------------------------------------------
# Sync
# ---------------------------------------------------------------------------

@dataclass
class SyncResult:
    peer_node_id: str
    entries_fetched: int = 0
    entries_merged: int = 0
    entries_conflicted: int = 0
    signature_verified: bool = False
    conflicts: list[str] = field(default_factory=list)


def _local_entries() -> dict[str, dict[str, Any]]:
    out = {}
    for path in sorted(SIDECARS_DIR.rglob("*.pnk.yaml")):
        rel = path.relative_to(SIDECARS_DIR)
        md_path = ROOT / "domains" / rel.with_suffix("").with_suffix(".md")
        if not md_path.exists():
            continue
        with path.open("r", encoding="utf-8") as f:
            sidecar = yaml.safe_load(f)
        out[sidecar["id"]] = {
            "sidecar": sidecar,
            "body": md_path.read_text(encoding="utf-8"),
            "path": path,
            "md_path": md_path,
        }
    return out


def sync_peer(peer: Peer, *, dry_run: bool = False) -> SyncResult:
    result = SyncResult(peer_node_id=peer.node_id)

    if peer.trust == "untrusted":
        return result

    with httpx.Client(timeout=60.0) as client:
        # 1. Fetch remote sync manifest
        r = client.get(f"{peer.api_url}/federation/sync-manifest")
        r.raise_for_status()
        manifest = r.json()

        # 2. Verify signature
        signature = manifest.get("signature", "")
        canonical = _canonical_json(manifest["entries"])
        if not verify_signature(peer.public_key_pem, canonical, signature):
            raise ValueError(f"Signature verification failed for peer {peer.node_id}")
        result.signature_verified = True

        local = _local_entries()

        # 3. Compute entries to fetch
        to_fetch = []
        for remote_entry in manifest["entries"]:
            eid = remote_entry["id"]
            if eid not in local:
                to_fetch.append(remote_entry)
                continue
            local_hash = "sha256:" + _sha256_hex(local[eid]["body"].encode("utf-8"))
            if local_hash == remote_entry["content_hash"]:
                continue
            local_rank = VERIFICATION_RANK[local[eid]["sidecar"]["verification"]["status"]]
            remote_rank = VERIFICATION_RANK[remote_entry["verification"]]
            if remote_rank > local_rank:
                to_fetch.append(remote_entry)
            elif remote_rank == local_rank:
                result.entries_conflicted += 1
                result.conflicts.append(eid)

        result.entries_fetched = len(to_fetch)

        if dry_run:
            return result

        # 4. Fetch and merge
        for remote_entry in to_fetch:
            eid = remote_entry["id"]
            rr = client.get(f"{peer.api_url}/federation/entry/{eid}")
            if rr.status_code != 200:
                continue
            payload = rr.json()
            if payload["content_hash"] != remote_entry["content_hash"]:
                result.entries_conflicted += 1
                result.conflicts.append(eid)
                continue
            if peer.trust == "neutral":
                payload["sidecar"]["verification"]["status"] = "draft"
            _write_entry(payload)
            result.entries_merged += 1

    _append_peer_ledger(result)
    return result


def _write_entry(payload: dict) -> None:
    sidecar = payload["sidecar"]
    domain = sidecar["domain"]
    slug = sidecar["id"].rsplit("/", 1)[-1]

    md_path = ROOT / "domains" / domain / f"{slug}.md"
    sc_path = SIDECARS_DIR / domain / f"{slug}.pnk.yaml"
    md_path.parent.mkdir(parents=True, exist_ok=True)
    sc_path.parent.mkdir(parents=True, exist_ok=True)

    md_path.write_text(payload["body"], encoding="utf-8")
    with sc_path.open("w", encoding="utf-8") as f:
        yaml.safe_dump(sidecar, f, sort_keys=False, allow_unicode=True)


def _append_peer_ledger(result: SyncResult) -> None:
    FEDERATION_DIR.mkdir(parents=True, exist_ok=True)
    record = {
        "timestamp": datetime.now(UTC).isoformat(),
        "peer_node_id": result.peer_node_id,
        "entries_fetched": result.entries_fetched,
        "entries_merged": result.entries_merged,
        "entries_conflicted": result.entries_conflicted,
        "signature_verified": result.signature_verified,
        "conflicts": result.conflicts,
    }
    with PEER_LEDGER.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record) + "\n")


# ---------------------------------------------------------------------------
# Resolution
# ---------------------------------------------------------------------------

def resolve_uri(uri: str) -> dict[str, Any] | None:
    """Resolve a pnk URI locally, then across trusted peers."""
    # 1. Local
    local = _local_entries()
    if uri in local:
        sidecar = local[uri]["sidecar"]
        return {
            "uri": uri,
            "node_id": "local",
            "api_url": "http://localhost:8080/v1",
            "entry_id": uri,
            "title": sidecar["title"],
        }

    # 2. Peers
    peers = load_peers()
    with httpx.Client(timeout=15.0) as client:
        for peer in peers.values():
            if peer.trust == "untrusted":
                continue
            try:
                r = client.get(f"{peer.api_url}/federation/resolve", params={"uri": uri})
                if r.status_code == 200:
                    return r.json()
            except httpx.HTTPError:
                continue
    return None


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(prog="abook-federation")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("identity", help="Show or create node identity")
    sub.add_parser("manifest", help="Print signed sync manifest")

    p_add = sub.add_parser("add-peer", help="Register a peer KB node")
    p_add.add_argument("api_url")
    p_add.add_argument("--trust", choices=["trusted", "neutral", "untrusted"], default="neutral")

    p_sync = sub.add_parser("sync", help="Sync with one or more peers")
    p_sync.add_argument("--peer", help="Peer node_id (default: all trusted/neutral)")
    p_sync.add_argument("--dry-run", action="store_true")

    p_res = sub.add_parser("resolve", help="Resolve a pnk:// URI")
    p_res.add_argument("uri")

    p_led = sub.add_parser("ledger", help="Print peer ledger")
    p_led.add_argument("--limit", type=int, default=50)

    args = parser.parse_args()

    if args.cmd == "identity":
        identity = load_or_create_identity()
        print(json.dumps({
            "node_id": identity["node_id"],
            "created_at": identity["created_at"],
            "public_key_pem": identity["public_key_pem"].strip(),
        }, indent=2))
        return 0

    if args.cmd == "manifest":
        identity = load_or_create_identity()
        manifest = build_sync_manifest(identity)
        print(json.dumps(manifest, indent=2))
        return 0

    if args.cmd == "add-peer":
        peer = add_peer(args.api_url, trust=args.trust)
        print(f"Added peer: {peer.node_id} ({peer.api_url}) trust={peer.trust}")
        return 0

    if args.cmd == "sync":
        peers = load_peers()
        if args.peer:
            peers = {args.peer: peers[args.peer]}
        for peer in peers.values():
            result = sync_peer(peer, dry_run=args.dry_run)
            print(
                f"[{peer.node_id}] fetched={result.entries_fetched} "
                f"merged={result.entries_merged} "
                f"conflicts={result.entries_conflicted} "
                f"sig_ok={result.signature_verified}"
            )
        return 0

    if args.cmd == "resolve":
        res = resolve_uri(args.uri)
        if res is None:
            print("Not found", file=sys.stderr)
            return 1
        print(json.dumps(res, indent=2))
        return 0

    if args.cmd == "ledger":
        if not PEER_LEDGER.exists():
            print("No peer ledger.")
            return 0
        lines = PEER_LEDGER.read_text(encoding="utf-8").splitlines()
        for line in lines[-args.limit:]:
            if line.strip():
                print(line)
        return 0

    return 1


if __name__ == "__main__":
    sys.exit(main())
