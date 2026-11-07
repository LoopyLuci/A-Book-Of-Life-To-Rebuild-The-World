import json

import pytest
import yaml

from scripts import verify


def _sidecar(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        yaml.safe_dump(
            {
                "id": "pnk:TEST/survival/fire",
                "verification": {"status": "peer-reviewed"},
            }
        ),
        encoding="utf-8",
    )


def _report(path, *, verified=True):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        yaml.safe_dump(
            {
                "id": path.stem,
                "entry_id": "pnk:TEST/survival/fire",
                "tester": "Test team",
                "date": "2026-03-15",
                "location": "Test region",
                "conditions": {"weather": "clear"},
                "results": "Procedure completed with recorded measurements.",
                "safety_observed": True,
                "verified": verified,
                **(
                    {"reviewed_by": "Maintainer Team", "reviewed_at": "2026-03-16"}
                    if verified
                    else {}
                ),
            }
        ),
        encoding="utf-8",
    )


def _configure_paths(tmp_path, monkeypatch, *, verified=True):
    root = tmp_path
    sidecars = root / "sidecars"
    reports = root / "field-tests"
    _sidecar(sidecars / "survival" / "fire.pnk.yaml")
    _report(reports / "ft-fire-test.yaml", verified=verified)
    (root / "governance").mkdir()
    monkeypatch.setattr(verify, "SIDECARS_DIR", sidecars)
    monkeypatch.setattr(verify, "FIELD_TESTS_DIR", reports)
    monkeypatch.setattr(verify, "GOVERNANCE_DIR", root / "governance")


def test_field_test_promotion_requires_review(tmp_path, monkeypatch):
    _configure_paths(tmp_path, monkeypatch, verified=False)

    with pytest.raises(ValueError, match="reviewed and set verified"):
        verify.transition(
            "pnk:TEST/survival/fire",
            verify.Status.FIELD_TESTED,
            "maintainer",
            field_test_id="ft-fire-test",
        )

    assert verify.load_record("pnk:TEST/survival/fire").status is verify.Status.PEER_REVIEWED
    assert not (tmp_path / "governance" / "verification-ledger.jsonl").exists()


def test_field_test_promotion_requires_valid_report(tmp_path, monkeypatch):
    _configure_paths(tmp_path, monkeypatch)
    report_path = tmp_path / "field-tests" / "ft-fire-test.yaml"
    report = yaml.safe_load(report_path.read_text(encoding="utf-8"))
    report["date"] = "not-a-date"
    report_path.write_text(yaml.safe_dump(report), encoding="utf-8")

    with pytest.raises(ValueError, match="Invalid field-test report"):
        verify.transition(
            "pnk:TEST/survival/fire",
            verify.Status.FIELD_TESTED,
            "maintainer",
            field_test_id="ft-fire-test",
        )


def test_field_test_promotion_rejects_missing_photo(tmp_path, monkeypatch):
    _configure_paths(tmp_path, monkeypatch)
    report_path = tmp_path / "field-tests" / "ft-fire-test.yaml"
    report = yaml.safe_load(report_path.read_text(encoding="utf-8"))
    report["photos"] = ["field-tests/missing.jpg"]
    report_path.write_text(yaml.safe_dump(report), encoding="utf-8")

    with pytest.raises(ValueError, match="photo file does not exist"):
        verify.transition(
            "pnk:TEST/survival/fire",
            verify.Status.FIELD_TESTED,
            "maintainer",
            field_test_id="ft-fire-test",
        )


def test_field_test_promotion_accepts_reviewed_report(tmp_path, monkeypatch):
    _configure_paths(tmp_path, monkeypatch)

    record = verify.transition(
        "pnk:TEST/survival/fire",
        verify.Status.FIELD_TESTED,
        "maintainer",
        field_test_id="ft-fire-test",
    )

    assert record.status is verify.Status.FIELD_TESTED
    assert record.tested_by == "Test team"
    event = json.loads((tmp_path / "governance" / "verification-ledger.jsonl").read_text())
    assert event["field_test_id"] == "ft-fire-test"


def test_reset_to_draft_clears_obsolete_review_and_test_metadata(tmp_path, monkeypatch):
    root = tmp_path
    sidecar_path = root / "sidecars" / "survival" / "fire.pnk.yaml"
    sidecar_path.parent.mkdir(parents=True)
    sidecar_path.write_text(
        yaml.safe_dump(
            {
                "id": "pnk:TEST/survival/fire",
                "verification": {
                    "status": "field-tested",
                    "reviewers": ["reviewer-one", "reviewer-two"],
                    "tested_by": "Test team",
                    "date": "2026-03-15",
                    "location": "Test region",
                },
            }
        ),
        encoding="utf-8",
    )
    (root / "governance").mkdir()
    monkeypatch.setattr(verify, "SIDECARS_DIR", root / "sidecars")
    monkeypatch.setattr(verify, "GOVERNANCE_DIR", root / "governance")

    record = verify.transition(
        "pnk:TEST/survival/fire",
        verify.Status.DRAFT,
        "maintainer",
        notes="Major rewrite invalidated prior review.",
    )

    assert record.reviewers == []
    assert record.tested_by is None
    assert record.tested_date is None
    saved = yaml.safe_load(sidecar_path.read_text(encoding="utf-8"))
    assert saved["verification"] == {
        "status": "draft",
        "notes": "Major rewrite invalidated prior review.",
    }
