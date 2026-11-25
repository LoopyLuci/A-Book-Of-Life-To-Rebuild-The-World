# Long-Term Roadmap

This is a 10-year outlook, revised annually.

## Immediate priorities — next 90 days

This short-cycle plan starts from the repository snapshot reviewed on
2026-11-06. The baseline is **207 entries across 16 domains, 938 recorded
sources, 33 peer-reviewed entries, no entries currently marked field-tested,
1 field-test report pending review, and 43 red-safety entries not marked
field-tested**. Two previous field-tested statuses were reset to draft because
their matching reports were not present in the repository. These figures are
not quality scores; the generated verification dashboard is the current view
of the corpus.

| Priority | Work | Acceptance criteria |
|----------|------|---------------------|
| Safety-led evidence | Triage red-safety and peer-reviewed entries against their primary sources. Invite field reports only for work that testers are qualified and equipped to perform safely. | No red-safety procedure is tested to meet a quota. Every submitted report validates, names the exact entry, records deviations and negative outcomes, and receives privacy review before publication. |
| Evidence workflow | Make report review and verification promotion distinct, auditable steps. | A report cannot promote an entry unless it passes the report schema and a maintainer has marked it reviewed; transitions remain recorded in the append-only ledger. |
| Trust dashboard | Publish a generated view of entry status, field reports, sources, language coverage, and the red-safety review queue. | Dashboard numbers are generated from the current corpus and validated reports; privacy-sensitive tester details are not displayed. |
| Reader consistency | Preserve safety and verification labels, source links, and reference-only warnings across supported readers. | Run the `apps` stage of `scripts/local_pipeline.py` after shared corpus/schema changes and record which toolchains were actually exercised. Missing toolchains are reported rather than presented as tested. |
| Community feedback | Give contributors one clear route for reporting a failed procedure, near miss, or correction. | Field-report guidance explains safety boundaries, public-data privacy, review criteria, and how reports affect verification status. |

### Checkpoints

- **By day 30:** maintainers review the red-safety queue and prioritize source
  and wording audits. No one is asked to attempt a procedure as a project
  target.
- **By day 60:** review submitted field reports and record whether each is
  accepted, needs clarification, or is declined, with a reason where
  appropriate. Preserve failures and safety concerns.
- **By day 90:** publish the generated dashboard with a short review of
  remaining evidence gaps. Set the next targets from observed reviewer and
  volunteer capacity, not from pressure to increase field-test counts.

If a suitable, informed, and properly equipped tester is unavailable, the
correct outcome is an explicit evidence gap—not an unsafe test or an inflated
verification status.

## 2026 — Foundation
- [x] Repository scaffold and 207-entry corpus
- [x] Search, MCP, RAG, and SDKs (Python, TS, Rust)
- [x] Federation protocol v1 and fiscal sponsorship
- [x] Validated field-report workflow, privacy guidance, and generated trust dashboard
- [ ] Mobile app v1

Corpus and field-test volume are not release gates. Future growth depends on
source quality, reviewer capacity, and appropriate safety conditions.

## 2027 — Expansion
- 2,000 entries
- 5 languages at 100%
- Safety-led review and field reports, only where suitable testers and
  conditions are available
- Regional variants for 4 climates
- Kiwix ZIM distributed on physical media
- 10 federated KB nodes
- First external security audit

## 2028 — Ecosystem
- Third-party apps (courses, games, curricula)
- Integration with Kolibri, Khan Academy
- 10,000 entries
- Evidence coverage expanded without field-test quotas
- 10 languages
- Federation protocol v2 (Merkle sync)

## 2029 — Standardization
- PNK URI registered with IANA
- Federation spec submitted to a standards body
- SDKs published to PyPI, npm, crates.io
- Annual conference

## 2030 — Resilience
- Physical distribution: printed volumes, SD cards, solar-powered readers
- 20 federated KB nodes across all continents
- 50,000 entries

## 2031 — Independence
- Project fully self-funded from a small endowment
- Core Maintainers on rotation, not full-time
- Governance fully decentralized

## 2032–2036 — Durability
- Maintain evidence-backed, safely reviewed content; do not use test counts as
  a target for hazardous procedures
- Support 20+ languages
- Continuously audit for correctness and safety
- Stay free, open, and offline-first

## Amendments

This roadmap is revised each January. Historical versions are archived in
`governance/roadmap-archive/`.
