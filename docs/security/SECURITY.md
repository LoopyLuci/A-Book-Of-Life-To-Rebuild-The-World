# Security Policy

## Supported versions

The latest minor release of `main` receives security fixes.

## Reporting a vulnerability

See `BUG-BOUNTY.md`.

## Cryptographic details

- Federation manifests are signed with Ed25519.
- Content hashes are SHA-256.
- Transport is TLS 1.3.
- No proprietary crypto. No rolling your own.

## Threat model

| Threat | Mitigation |
|--------|------------|
| Malicious sync peer | Signature verification + trust levels |
| Tampered content | SHA-256 content hash |
| Forged verification | Ledger signatures + reviewer identity |
| RCE via content | No code execution in content; sandboxed simulators |
| DoS on federation | Rate limits + caching |
| Data loss on mobile | Local SQLite is a cache; server is source of truth |
