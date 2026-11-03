# Security Policy

The full security policy, the threat model and the bug bounty are in
[`docs/security/SECURITY.md`](docs/security/SECURITY.md) and
[`docs/security/BUG-BOUNTY.md`](docs/security/BUG-BOUNTY.md).

**In short:**

- Do not report a vulnerability in a public issue, a discussion, or a pull
  request. Use the private reporting channel described in
  [`docs/security/SECURITY.md`](docs/security/SECURITY.md).
- The latest minor release of `main` receives security fixes.
- Federation manifests are signed with Ed25519, content hashes are SHA-256,
  and transport is TLS 1.3. No proprietary cryptography, and no rolling your
  own.

## Verifying what you download

Every release publishes a signed APK and an offline bundle. Check the release
notes and the checksums in the release before installing anything.
