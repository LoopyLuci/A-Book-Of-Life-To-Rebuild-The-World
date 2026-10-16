# Bug Bounty Program

A Book Of Life To Rebuild The World runs a public bug bounty for security,
correctness, and safety-critical issues.

## Scope

### In scope

- The API server (`scripts/serve.py`, `deploy/docker/`).
- The MCP server (`scripts/mcp_server.py`).
- The RAG layer (`scripts/rag.py`).
- The federation protocol (`scripts/federation.py`).
- The mobile app (`mobile/`).
- The build pipelines (`.github/workflows/`).
- Content that is **factually dangerous** (e.g., a procedure that causes
  injury if followed exactly).

### Out of scope

- Third-party dependencies (report upstream).
- Social engineering.
- Denial of service via resource exhaustion on the hosted mirror.
- Vulnerabilities in forks.

## Reward tiers

| Severity | Examples | Reward |
|----------|----------|--------|
| **Critical** | Remote code execution, signature forgery, mass data loss | $2000 + advisory credit |
| **High** | Auth bypass, arbitrary file write, dangerous content bypass | $1000 |
| **Medium** | XSS, CSRF, info disclosure, content-hash bypass | $500 |
| **Low** | Rate-limit bypass, minor info leak | $100 |
| **Content** | A procedure that endangers life if followed | $250 |

Rewards are paid in USD via Open Collective or crypto. Credit is given in
the advisory unless you prefer to remain anonymous.

## How to report

1. **Do not open a public issue.**
2. Email `security@abookoflife.org` with:
   - A clear description.
   - Reproduction steps.
   - Impact assessment.
   - Your PGP key if you want encrypted replies.
3. We acknowledge within 72 hours.
4. We triage within 7 days.
5. We fix within 30 days for critical issues.
6. We publish a public advisory after the fix.

## Safe harbor

Good-faith research is authorized. We will not pursue legal action against
researchers who:

- Follow this policy.
- Do not access or modify other users' data.
- Do not disrupt service.
- Report promptly.

## Hall of fame

Contributors who report valid issues are listed at
`https://abookoflife.org/security/hall-of-fame`.
