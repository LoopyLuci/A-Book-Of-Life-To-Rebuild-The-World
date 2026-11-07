# Field testing

Field reports are evidence about one attempt in one setting. They are not
proof that a procedure is safe, correct everywhere, or appropriate for a
reader. Read the [disclaimer](DISCLAIMER.md) before testing or relying on any
entry.

## Before a test

1. Read the entry and its primary sources. Check applicable training,
   supervision, permissions, equipment, local rules, and site hazards.
2. Do not attempt a procedure that is beyond your training or equipment.
   Stop if conditions differ in a way that could increase risk.
3. Decide what outcome and measurements would count as success, and what
   conditions require stopping. Do not improvise around a failed safety
   control.
4. Record the entry ID and the version or revision tested. Note substitutions
   and deviations rather than presenting them as the documented procedure.

Field testing is not a request to perform dangerous, regulated, medical, or
otherwise unsuitable work. A report that a procedure was not attempted because
of a safety concern is useful feedback.

## Public-report privacy

Reports are public repository content. Include only information you are
comfortable publishing:

- Use a team name or pseudonym; do not include personal email addresses,
  phone numbers, or other identifying details.
- Give a broad location such as a region or climate, not precise coordinates
  or a location that identifies a person, home, or sensitive site.
- Share photos only with the consent of identifiable people and the rights
  holder. Remove embedded location metadata before submission.
- Do not include private third-party information. Contact maintainers through
  the project's public contribution channels instead of placing contact
  details in a report.

## Submit and review

1. Open a pull request with a YAML report based on
   [`schemas/field-test-template.yaml`](../schemas/field-test-template.yaml),
   or use the [Field Test issue template](../.github/ISSUE_TEMPLATE/field-test.md)
   to propose a report.
2. Include the canonical `entry_id`, date, broad location, conditions,
   procedure followed, deviations, results, safety observations, failures,
   and actionable recommendations. Measurements should include units.
3. Run `python scripts/validate_field_tests.py`. CI also checks the report
   schema, date, filename, unique report ID, and that the entry exists.
4. Maintainers review the report for completeness, privacy, and consistency
   with the entry. If accepted, record a public reviewer name/team or
   pseudonym and review date, then set `verified: true`. This records review
   for publication; it does not certify the procedure or the tester.
5. A report does not automatically change an entry's verification status.
   Only the project's verification workflow may promote an entry, and the
   report must be linked to the exact entry. Failures and safety concerns
   should be investigated and recorded before any promotion.

Never edit a report to make an outcome look successful. Preserve negative
results and limitations; corrections should be made transparently in a new
revision or follow-up report.
