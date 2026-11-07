#!/usr/bin/env python3
"""Validate field-test reports and their references to canonical entries."""

from __future__ import annotations

import json
import sys
from pathlib import Path, PurePosixPath, PureWindowsPath
from typing import Any

import yaml
from jsonschema import Draft202012Validator, FormatChecker

ROOT = Path(__file__).resolve().parent.parent
SCHEMA_PATH = ROOT / "schemas" / "field-test.schema.json"
FIELD_TESTS_DIR = ROOT / "field-tests"
SIDECARS_DIR = ROOT / "sidecars"


def validate_photo_paths(
    photos: Any,
    repo_root: Path,
    report_label: str,
) -> list[str]:
    """Return errors for report image paths that are missing or unsafe."""
    if not isinstance(photos, list):
        return []

    errors = []
    root = repo_root.resolve()
    for photo in photos:
        if not isinstance(photo, str):
            continue
        relative = PurePosixPath(photo)
        windows_path = PureWindowsPath(photo)
        if (
            not photo
            or "\\" in photo
            or "\0" in photo
            or relative.is_absolute()
            or windows_path.is_absolute()
            or windows_path.drive
            or ".." in relative.parts
        ):
            errors.append(
                f"{report_label}: photo path must be a safe repository-relative path: {photo!r}"
            )
            continue
        image_path = root.joinpath(*relative.parts).resolve()
        if not image_path.is_relative_to(root) or not image_path.is_file():
            errors.append(
                f"{report_label}: photo file does not exist in the repository: {photo}"
            )
    return errors


def validate(
    field_tests_dir: Path = FIELD_TESTS_DIR,
    schema_path: Path = SCHEMA_PATH,
    sidecars_dir: Path = SIDECARS_DIR,
) -> tuple[list[str], int]:
    """Return validation errors and the number of reports checked."""
    with schema_path.open("r", encoding="utf-8") as f:
        schema = json.load(f)
    validator = Draft202012Validator(schema, format_checker=FormatChecker())

    entry_statuses: dict[str, str] = {}
    errors: list[str] = []
    for path in sorted(sidecars_dir.rglob("*.pnk.yaml")):
        try:
            with path.open("r", encoding="utf-8") as f:
                sidecar = yaml.safe_load(f)
        except yaml.YAMLError as exc:
            errors.append(f"{path}: YAML parse error: {exc}")
            continue
        if isinstance(sidecar, dict) and isinstance(sidecar.get("id"), str):
            verification = sidecar.get("verification")
            verification = verification if isinstance(verification, dict) else {}
            entry_statuses[sidecar["id"]] = str(verification.get("status", ""))

    report_ids: set[str] = set()
    reviewed_entry_ids: set[str] = set()
    count = 0
    report_paths = (
        sorted(field_tests_dir.rglob("*.yaml"))
        if field_tests_dir.exists()
        else []
    )
    for path in report_paths:
        count += 1
        try:
            with path.open("r", encoding="utf-8") as f:
                data: Any = yaml.safe_load(f)
        except yaml.YAMLError as exc:
            errors.append(f"{path}: YAML parse error: {exc}")
            continue

        report_errors = list(validator.iter_errors(data))
        for err in report_errors:
            errors.append(f"{path}: {err.json_path}: {err.message}")

        if not isinstance(data, dict):
            continue
        report_is_valid = not report_errors
        report_id = data.get("id")
        if isinstance(report_id, str):
            if report_id in report_ids:
                errors.append(f"{path}: duplicate field-test id: {report_id}")
                report_is_valid = False
            report_ids.add(report_id)
            if path.stem != report_id:
                errors.append(
                    f"{path}: filename must match report id {report_id!r}"
                )
                report_is_valid = False

        entry_id = data.get("entry_id")
        if isinstance(entry_id, str) and entry_id not in entry_statuses:
            errors.append(f"{path}: entry_id does not match a canonical sidecar: {entry_id}")
            report_is_valid = False
        photo_errors = validate_photo_paths(
            data.get("photos", []),
            field_tests_dir.resolve().parent,
            str(path),
        )
        errors.extend(photo_errors)
        if photo_errors:
            report_is_valid = False
        if report_is_valid and data.get("verified") is True:
            reviewed_entry_ids.add(entry_id)

    for entry_id, status in sorted(entry_statuses.items()):
        if status == "field-tested" and entry_id not in reviewed_entry_ids:
            errors.append(
                f"{entry_id}: field-tested status has no valid, reviewed field-test report"
            )

    return errors, count


def main() -> int:
    errors, count = validate()
    if errors:
        print(f"Field-test validation failed with {len(errors)} error(s):", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print(f"Field-test validation passed. {count} report(s) checked.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
