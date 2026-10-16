# Continuity Plan

What happens if the project's maintainers disappear? This document is the
answer.

## Principle

**No single point of failure.** The project must survive the loss of any
individual, any mirror, any hosting provider, or any legal entity.

## Redundancies

| Asset | Primary | Backup 1 | Backup 2 |
|-------|---------|----------|----------|
| Code | GitHub | GitLab mirror | Software Heritage |
| Content | GitHub | Internet Archive | Zenodo |
| Domain | Registrar A | Registrar B (escrow) | — |
| DNS | Provider A | Provider B | — |
| Keys | Core Maintainer A | Core Maintainer B | Hardware token in safe |
| Funding | Open Collective | Direct bank | — |

## Bus factor mitigations

- At least 3 Core Maintainers with full access to all assets.
- Every secret is shared between at least 2 Core Maintainers.
- Onboarding docs are maintained in `docs/operations/`.
- Quarterly drills: restore from Internet Archive, rotate keys, verify
  that mirrors are healthy.

## Abandonment protocol

If no Core Maintainer is active for 90 consecutive days:

1. The Domain Maintainers convene to elect an interim Core Maintainer.
2. If they cannot, the fiscal sponsor appoints a steward.
3. If the fiscal sponsor is unavailable, the repository is archived
   read-only on GitHub and all content remains under its open license.
4. Mirrors remain independent and may fork.

## Successor designation

Each Core Maintainer designates a successor in `governance/successors.yaml`.

```yaml
successors:
  - maintainer: "@maintainer-a"
    successor: "@maintainer-b"
    effective: 2026-01-01
  - maintainer: "@maintainer-b"
    successor: "@maintainer-c"
    effective: 2026-01-01
```

## Legal continuity

- The project's trademark (if any) is held by the fiscal sponsor.
- Content licenses (CC BY-SA 4.0) are irrevocable.
- Code licenses (MIT) are irrevocable.
- No contributor agreement grants anyone the right to relicense closed.

## Data preservation

- All content is mirrored to at least 3 independent locations monthly.
- Mirrors are listed at `https://abookoflife.org/mirrors`.
- Any mirror may be promoted to primary by consensus of active
  maintainers.

## Emergency contacts

| Role | Contact | Backup |
|------|---------|--------|
| Fiscal sponsor | sponsor@opencollective.com | — |
| Legal counsel | legal@abookoflife.org | — |
| Domain registrar | (in vault) | — |
| Security | security@abookoflife.org | — |
