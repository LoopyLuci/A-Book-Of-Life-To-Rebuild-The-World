import yaml

from scripts import validate_field_tests


def _write_schema(path):
    path.write_text(
        validate_field_tests.SCHEMA_PATH.read_text(encoding="utf-8"),
        encoding="utf-8",
    )


def _write_sidecar(path, entry_id="pnk:TEST/survival/fire"):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(yaml.safe_dump({"id": entry_id}), encoding="utf-8")


def _write_report(path, **updates):
    report = {
        "id": path.stem,
        "entry_id": "pnk:TEST/survival/fire",
        "tester": "Test contributor",
        "date": "2026-03-15",
        "location": "Outdoor test area",
        "conditions": {},
        "results": "Test completed with observations recorded.",
        "safety_observed": True,
        "verified": False,
    }
    report.update(updates)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(yaml.safe_dump(report), encoding="utf-8")


def test_valid_report_references_existing_entry(tmp_path):
    reports = tmp_path / "field-tests"
    sidecars = tmp_path / "sidecars"
    schema = tmp_path / "schema.json"
    _write_schema(schema)
    _write_sidecar(sidecars / "survival" / "fire.pnk.yaml")
    (reports / "photo.jpg").parent.mkdir(parents=True, exist_ok=True)
    (reports / "photo.jpg").write_bytes(b"test")
    _write_report(
        reports / "ft-fire-test.yaml",
        photos=["field-tests/photo.jpg"],
    )

    errors, count = validate_field_tests.validate(reports, schema, sidecars)

    assert errors == []
    assert count == 1


def test_report_rejects_bad_date_unknown_entry_and_filename_mismatch(tmp_path):
    reports = tmp_path / "field-tests"
    sidecars = tmp_path / "sidecars"
    schema = tmp_path / "schema.json"
    _write_schema(schema)
    _write_sidecar(sidecars / "survival" / "fire.pnk.yaml")
    _write_report(
        reports / "different-name.yaml",
        id="ft-another-test",
        entry_id="pnk:UNKNOWN/survival/missing",
        date="not-a-date",
    )

    errors, _ = validate_field_tests.validate(reports, schema, sidecars)
    joined = "\n".join(errors)

    assert "'not-a-date' is not a 'date'" in joined
    assert "filename must match report id" in joined
    assert "entry_id does not match a canonical sidecar" in joined


def test_report_cannot_claim_review_without_reviewer_and_date(tmp_path):
    reports = tmp_path / "field-tests"
    sidecars = tmp_path / "sidecars"
    schema = tmp_path / "schema.json"
    _write_schema(schema)
    _write_sidecar(sidecars / "survival" / "fire.pnk.yaml")
    _write_report(reports / "ft-fire-test.yaml", verified=True)

    errors, _ = validate_field_tests.validate(reports, schema, sidecars)

    assert any("reviewed_by" in error for error in errors)
    assert any("reviewed_at" in error for error in errors)


def test_report_yaml_parse_errors_are_reported(tmp_path):
    reports = tmp_path / "field-tests"
    schema = tmp_path / "schema.json"
    _write_schema(schema)
    reports.mkdir()
    (reports / "broken.yaml").write_text("id: [unterminated", encoding="utf-8")

    errors, count = validate_field_tests.validate(reports, schema, tmp_path / "sidecars")

    assert count == 1
    assert errors[0].startswith(f"{reports / 'broken.yaml'}: YAML parse error:")


def test_report_rejects_missing_or_escaping_photo_paths(tmp_path):
    reports = tmp_path / "field-tests"
    sidecars = tmp_path / "sidecars"
    schema = tmp_path / "schema.json"
    _write_schema(schema)
    _write_sidecar(sidecars / "survival" / "fire.pnk.yaml")
    _write_report(
        reports / "ft-fire-test.yaml",
        photos=["field-tests/missing.jpg", "../outside.jpg"],
    )

    errors, _ = validate_field_tests.validate(reports, schema, sidecars)
    joined = "\n".join(errors)

    assert "photo file does not exist in the repository" in joined
    assert "photo path must be a safe repository-relative path" in joined


def test_field_tested_entry_requires_reviewed_report(tmp_path):
    reports = tmp_path / "field-tests"
    sidecars = tmp_path / "sidecars"
    schema = tmp_path / "schema.json"
    _write_schema(schema)
    _write_sidecar(sidecars / "survival" / "fire.pnk.yaml")
    sidecar_path = sidecars / "survival" / "fire.pnk.yaml"
    sidecar_path.write_text(
        yaml.safe_dump(
            {
                "id": "pnk:TEST/survival/fire",
                "verification": {"status": "field-tested"},
            }
        ),
        encoding="utf-8",
    )
    _write_report(reports / "ft-fire-test.yaml", verified=False)

    errors, _ = validate_field_tests.validate(reports, schema, sidecars)

    assert any("no valid, reviewed field-test report" in error for error in errors)


def test_missing_reports_directory_does_not_hide_field_tested_status(tmp_path):
    sidecars = tmp_path / "sidecars"
    schema = tmp_path / "schema.json"
    _write_schema(schema)
    sidecar_path = sidecars / "survival" / "fire.pnk.yaml"
    sidecar_path.parent.mkdir(parents=True)
    sidecar_path.write_text(
        yaml.safe_dump(
            {
                "id": "pnk:TEST/survival/fire",
                "verification": {"status": "field-tested"},
            }
        ),
        encoding="utf-8",
    )

    errors, count = validate_field_tests.validate(
        tmp_path / "field-tests",
        schema,
        sidecars,
    )

    assert count == 0
    assert any("no valid, reviewed field-test report" in error for error in errors)
