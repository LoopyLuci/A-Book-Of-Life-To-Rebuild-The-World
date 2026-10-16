# The pnk:// Federation Protocol

Version 1.0 — draft.

## 1. Motivation

A Book Of Life To Rebuild The World is designed to be **forkable**. Any
community may run its own knowledge base, add local entries, translate
existing ones, and mark entries as verified in their region. The federation
protocol allows independent KB nodes to:

1. Reference each other's entries via stable `pnk://` URIs.
2. Synchronize entries they trust.
3. Publish signed manifests of their local state.
4. Resolve entries that do not exist locally.

## 2. Node identity

Every KB node has:

- A `node_id` — a ULID generated at first boot.
- An Ed25519 keypair.
- A public API URL.

The **federation manifest** is published at `/federation/manifest`:

```json
{
  "node_id": "01HZX0K8J9Q7R3VY6T2M4B8N00",
  "kb_version": "1.0.0",
  "api_url": "https://kb.example.org/v1",
  "public_key": "MCowBQYDK2VwAyEA...",
  "domains": ["survival", "agriculture", "..."],
  "languages": ["en", "es", "fr"],
  "entry_count": 70,
  "created_at": "2026-01-15T12:00:00Z"
}
```

## 3. pnk:// URI schemes

### 3.1 Entry URI (bare)

```
pnk:<ulid>/<domain>/<slug>
```

- `<ulid>` is the 26-character Crockford base32 ULID assigned at creation.
- This form is **stable across all KBs**. Two nodes with the same entry
  produce the same bare URI.

### 3.2 Node-scoped URI

```
pnk://<node_id>/<domain>/<slug>
```

- `<node_id>` is the ULID of the KB node that authoritatively hosts the entry.
- Used when an entry is unique to one node.

### 3.3 Resolution order

When a client encounters a `pnk:` URI:

1. Try local resolution (grep the local sidecars).
2. If not found, query each known peer's `/federation/resolve?uri=...`.
3. Cache the resolution result for the TTL specified in the response.

## 4. Sync protocol

### 4.1 Sync manifest

Each node publishes a **signed sync manifest** at:

```
GET /federation/sync-manifest
```

Response:

```json
{
  "node_id": "01HZX0K8J9Q7R3VY6T2M4B8N00",
  "generated_at": "2026-07-15T12:00:00Z",
  "entries": [
    {
      "id": "pnk:01HZX0K8J9Q7R3VY6T2M4B8N1P/survival/making-fire",
      "updated_at": "2026-06-01T08:00:00Z",
      "content_hash": "sha256:...",
      "verification": "field-tested"
    }
  ],
  "signature": "base64(Ed25519(sha256(canonical_json(entries))))"
}
```

### 4.2 Sync algorithm

Two nodes A and B synchronize as follows:

1. A fetches B's sync manifest.
2. A verifies B's signature against B's published public key.
3. A computes the set of entries in B that A does not have, or that A has
   with an older `updated_at`.
4. A fetches those entries via `GET /federation/entry/{entry_id}`.
5. A verifies the content hash against the manifest.
6. A merges each entry, respecting **verification precedence**:
   - `field-tested` > `peer-reviewed` > `draft`.
   - If both nodes have `field-tested`, the more recent one wins.
7. A records the sync in its peer ledger.

### 4.3 Conflict resolution

Conflicts are resolved by these rules, in order:

1. **Verification status:** higher status wins.
2. **Verification date:** more recent wins.
3. **Manual review:** if both are `field-tested` on the same date, mark
   both as `deprecated` and file a review request.

Sideload conflicts (both entries exist but with different bodies) always
trigger manual review. The federation protocol never destroys entries.

## 5. Trust model

Nodes may declare other nodes as **trusted**, **neutral**, or **untrusted**:

- **Trusted:** automatic merge on sync.
- **Neutral:** fetch entries, but mark them as `unverified` until a local
  verifier signs off.
- **Untrusted:** never fetch, never merge.

Trust relationships are stored locally and are **not** transitive.

## 6. Peer ledger

Every node maintains a `peer-ledger.jsonl` with one record per sync:

```json
{
  "timestamp": "2026-07-15T12:05:00Z",
  "peer_node_id": "01HZX0K8J9Q7R3VY6T2M4B8N01",
  "peer_api_url": "https://kb2.example.org/v1",
  "entries_fetched": 12,
  "entries_merged": 10,
  "entries_conflicted": 2,
  "signature_verified": true
}
```

## 7. Security considerations

- **Signatures are mandatory.** Unsigned manifests are rejected.
- **HTTPS is required** for production nodes.
- **Rate limits** apply to federation endpoints to prevent abuse.
- **No transitive trust.** A trusted by B, B trusted by C, does not imply A
  trusted by C.
- **Content hash verification** prevents tampering in transit.
- **DoS mitigation:** sync manifests are cached for 5 minutes.

## 8. Version negotiation

`GET /federation/manifest` returns a `protocol_version` field. Peers refuse
to sync if the major version differs. The current protocol version is `1.0`.

## 9. Reference implementation

See `scripts/federation.py` in the main repository.

## 10. Test vectors

Test vectors are published at `docs/federation/test-vectors.json`.
