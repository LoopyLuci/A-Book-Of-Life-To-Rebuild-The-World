import json

import yaml

from scripts import dashboard


def _write_entry(path, entry_id, title, *, safety="green", status="draft"):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        yaml.safe_dump(
            {
                "id": entry_id,
                "title": title,
                "domain": "survival",
                "safety": safety,
                "difficulty": "novice",
                "sources": [
                    {"title": "Source", "language": "fr"},
                    {"title": "Another source", "language": "en"},
                ],
                "verification": {"status": status},
            }
        ),
        encoding="utf-8",
    )


def test_dashboard_reports_coverage_and_escapes_ledger_values(tmp_path, monkeypatch):
    root = tmp_path
    sidecars = root / "sidecars"
    field_tests = root / "field-tests"
    output = root / "build" / "dashboard.html"
    _write_entry(
        sidecars / "survival" / "fire.pnk.yaml",
        "pnk:TEST/survival/fire",
        "Fire",
        safety="red",
    )
    (field_tests / "ft-fire").mkdir(parents=True)
    (field_tests / "ft-fire" / "ft-fire-report.yaml").write_text(
        yaml.safe_dump(
            {
                "id": "ft-fire-report",
                "entry_id": "pnk:TEST/survival/fire",
                "date": "2026-03-15",
                "safety_observed": False,
            }
        ),
        encoding="utf-8",
    )
    translation = root / "i18n" / "translations" / "es" / "survival"
    translation.mkdir(parents=True)
    (translation / "fire.md").write_text("translated", encoding="utf-8")
    (root / "governance").mkdir()
    (root / "governance" / "verification-ledger.jsonl").write_text(
        json.dumps(
            {
                "timestamp": "2026-03-15",
                "entry_id": "pnk:TEST/survival/fire",
                "from_status": "draft",
                "to_status": "peer-reviewed",
                "actor": "<script>alert(1)</script>",
            }
        )
        + "\n",
        encoding="utf-8",
    )

    monkeypatch.setattr(dashboard, "ROOT", root)
    monkeypatch.setattr(dashboard, "SIDECARS_DIR", sidecars)
    monkeypatch.setattr(dashboard, "FIELD_TESTS_DIR", field_tests)
    monkeypatch.setattr(dashboard, "LEDGER_PATH", root / "governance" / "verification-ledger.jsonl")
    monkeypatch.setattr(dashboard, "OUT_PATH", output)

    assert dashboard.build() == 0
    html = output.read_text(encoding="utf-8")

    assert "<h3>Field Reports</h3><div class=\"value\">1</div>" in html
    assert "<h3>Reports Awaiting Review</h3><div class=\"value\">1</div>" in html
    assert "<td>1</td><td>100.0%</td>" in html
    assert "Red Safety, Not Field-Tested" in html
    assert "&lt;script&gt;alert(1)&lt;/script&gt;" in html
    assert "<script>alert(1)</script>" not in html
