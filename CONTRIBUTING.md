# Contributing to Book of Life

Thank you for helping rebuild civilization. This document explains how to contribute.

## Contribution Tiers

| Tier | Role | Permissions |
|------|------|-------------|
| Reader | Browse, search, download | Public |
| Contributor | Submit PRs for content, translations | Signed CLA |
| Verifier | Field-test entries, mark verification status | Nominated by maintainers |
| Domain Maintainer | Review PRs for a domain | Elected per domain |
| Core Maintainer | Release management, architecture | Consensus of maintainers |

## Getting Started

1. Fork the repository.
2. Create a branch: `git checkout -b feat/your-topic`.
3. Add or edit content in `domains/<domain>/`.
4. Add or update the sidecar in `sidecars/<domain>/`.
5. Run validation: `python scripts/validate.py`.
6. Run the index build: `python scripts/build_index.py`.
7. Submit a pull request.

## Content Guidelines

- Every entry MUST have a sidecar YAML.
- Every claim MUST have a source (public domain, CC-BY-SA, or original).
- Procedures MUST be step-by-step and reproducible.
- Safety hazards MUST be marked `safety: red` or `safety: yellow`.
- Use inclusive, jargon-free language.

## Sidecar Schema

See `schemas/sidecar.schema.json` for the full schema.

## Verification Lifecycle

1. **Draft** — unverified
2. **Peer-Reviewed** — two contributors review for accuracy
3. **Field-Tested** — at least one verifier reproduces the procedure and documents results
4. **Deprecated** — superseded by a better method

## Code of Conduct

All contributors must follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## License

By contributing, you agree your content is licensed under CC BY-SA 4.0 and
your code under MIT.
