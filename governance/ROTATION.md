# Maintenance Rotation

To prevent burnout, every routine duty rotates weekly or monthly among
Core Maintainers and Domain Maintainers.

## Weekly duties

| Week | On-call | Backup |
|------|---------|--------|
| W1 2026 | @maintainer-a | @maintainer-b |
| W2 2026 | @maintainer-b | @maintainer-c |
| W3 2026 | @maintainer-c | @maintainer-a |
| W4 2026 | @maintainer-a | @maintainer-b |

## On-call responsibilities

- Triage new issues within 48 hours.
- Acknowledge new PRs within 72 hours.
- Merge field-tested PRs.
- Respond to security reports within 24 hours.
- Publish a weekly status note in `governance/WEEKLY.md`.

## Monthly duties

- **Release manager:** cut the monthly release, verify artifacts.
- **Dependency steward:** review and merge Renovate/Dependabot PRs.
- **Ledger auditor:** verify the verification ledger append-only invariant.
- **Community steward:** run the monthly community call.

## Quarterly duties

- **Financial report** published to `governance/finance/`.
- **Roadmap review** in a public document.
- **Trust audit:** verify peer signatures, rotate keys if needed.
- **Backup verification:** restore from Internet Archive / Zenodo.

## Annual duties

- **State of the Book** report.
- **Election** of new Domain Maintainers.
- **Charter review** (amendments if needed).
- **Security audit** (external if budget allows).

## Rotation rules

- No person serves on-call two consecutive weeks.
- Any maintainer may swap with another with 24-hour notice.
- If a maintainer misses two consecutive on-call weeks, the backup takes
  over and a rotation review is triggered.
