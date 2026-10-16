# Deprecation Policy

Content and APIs may become obsolete. This policy ensures nothing breaks
without notice.

## Content deprecation

An entry may be deprecated when:

1. A safer or more accurate method supersedes it.
2. Its sources are retracted.
3. Its procedure is found to cause harm.
4. It is superseded by a regional variant.

### Process

1. Any contributor opens a "Deprecate" issue using the template.
2. Domain Maintainer reviews within 14 days.
3. If approved, the entry is marked `verification.status: deprecated`.
4. The entry's body is prefixed with a deprecation banner.
5. The replacement entry (if any) is linked in the `links:` field.
6. A verification ledger event is appended.
7. The entry remains published for 12 months before archival.

### Banner format

```markdown
> ⚠️ **Deprecated.** This entry has been superseded by
> [New Entry Title](link). It is retained for historical reference only.
```

## API deprecation

- Public endpoints follow semver.
- Any endpoint may be deprecated with a 12-month notice.
- Deprecated endpoints return `Sunset` and `Deprecation` headers.
- After sunset, the endpoint returns `410 Gone` with a link to the
  replacement.

### Response headers

```
Deprecation: true
Sunset: Sat, 01 Jan 2027 00:00:00 GMT
Link: <https://api.abookoflife.org/v2/replacement>; rel="successor-version"
```

## SDK deprecation

- Major versions supported for 24 months after the next major release.
- Security fixes applied to the two most recent major versions.
- Deprecation notices posted in the SDK's README and CHANGELOG.

## Federation protocol deprecation

- Protocol versions are negotiated via `protocol_version` in the manifest.
- Peers on older versions receive a warning but continue to function for
  6 months.
- After 6 months, sync is refused until the peer upgrades.

## Breaking change policy

- Breaking changes require a major version bump.
- Breaking changes must be listed in `CHANGELOG.md` under "Breaking".
- Breaking changes must include a migration guide in `docs/migrations/`.
