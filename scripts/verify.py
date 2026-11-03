#!/usr/bin/env python3
"""
Verification state machine for A Book Of Life To Rebuild The World.

Lifecycle:  draft -> peer-reviewed -> field-tested -> deprecated
Backwards:  any -> draft (on major rewrite)
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from datetime import UTC, datetime
from enum import Enum
from pathlib import Path
from typing import Any

import yaml

ROOT = Path(__file__).resolve().parent.parent
SIDECARS_DIR = ROOT / "sidecars"
FIELD_TESTS_DIR = ROOT / "field-tests"
GOVERNANCE_DIR = ROOT / "governance"


class Status(str, Enum):  # noqa: UP042 - the string mixin is part of the API
    DRAFT = "draft"
    PEER_REVIEWED = "peer-reviewed"
    FIELD_TESTED = "field-tested"
    DEPRECATED = "deprecated"


VALID_TRANSITIONS = {
    Status.DRAFT: {Status.PEER_REVIEWED, Status.DEPRECATED},
    Status.PEER_REVIEWED: {Status.FIELD_TESTED, Status.DRAFT, Status.DEPRECATED},
    Status.FIELD_TESTED: {Status.DEPRECATED, Status.DRAFT},
    Status.DEPRECATED: {Status.DRAFT},
}

REQUIRED_REVIEWERS = 2


@dataclass
class VerificationEvent:
    entry_id: str
    from_status: Status
    to_status: Status
    actor: str
    timestamp: str
    notes: str = ""
    reviewers: list[str] = field(default_factory=list)
    field_test_id: str | None = None


@dataclass
class VerificationRecord:
    entry_id: str
    status: Status
    reviewers: list[str] = field(default_factory=list)
    tested_by: str | None = None
    tested_date: str | None = None
    tested_location: str | None = None
    notes: str = ""
    history: list[VerificationEvent] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Sidecar I/O
# ---------------------------------------------------------------------------

def _sidecar_path(entry_id: str) -> Path | None:
    for path in SIDECARS_DIR.rglob("*.pnk.yaml"):
        with path.open("r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
        if data.get("id") == entry_id:
            return path
    return None


def load_record(entry_id: str) -> VerificationRecord:
    path = _sidecar_path(entry_id)
    if path is None:
        raise ValueError(f"Entry not found: {entry_id}")

    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    v = data.get("verification", {})
    return VerificationRecord(
        entry_id=entry_id,
        status=Status(v.get("status", "draft")),
        reviewers=v.get("reviewers", []),
        tested_by=v.get("tested_by"),
        tested_date=v.get("date"),
        tested_location=v.get("location"),
        notes=v.get("notes", ""),
    )


def save_record(record: VerificationRecord) -> None:
    path = _sidecar_path(record.entry_id)
    if path is None:
        raise ValueError(f"Entry not found: {record.entry_id}")

    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    payload: dict[str, Any] = {"status": record.status.value}
    if record.reviewers:
        payload["reviewers"] = record.reviewers
    if record.tested_by:
        payload["tested_by"] = record.tested_by
    if record.tested_date:
        payload["date"] = record.tested_date
    if record.tested_location:
        payload["location"] = record.tested_location
    if record.notes:
        payload["notes"] = record.notes

    data["verification"] = payload

    with path.open("w", encoding="utf-8") as f:
        yaml.safe_dump(data, f, sort_keys=False, allow_unicode=True)


# ---------------------------------------------------------------------------
# Transition enforcement
# ---------------------------------------------------------------------------

def can_transition(current: Status, target: Status) -> bool:
    return target in VALID_TRANSITIONS.get(current, set())


def transition(
    entry_id: str,
    target: Status,
    actor: str,
    *,
    reviewers: list[str] | None = None,
    field_test_id: str | None = None,
    notes: str = "",
    force: bool = False,
) -> VerificationRecord:
    record = load_record(entry_id)

    if not force and not can_transition(record.status, target):
        raise ValueError(
            f"Invalid transition: {record.status.value} -> {target.value}. "
            f"Allowed: {sorted(s.value for s in VALID_TRANSITIONS[record.status])}"
        )

    # Peer-reviewed requires the mandated number of reviewers
    if target is Status.PEER_REVIEWED:
        merged = sorted(set(record.reviewers) | set(reviewers or []))
        if len(merged) < REQUIRED_REVIEWERS:
            raise ValueError(
                f"Peer review requires {REQUIRED_REVIEWERS} reviewers; "
                f"got {len(merged)}."
            )
        record.reviewers = merged

    # Field-tested requires a valid field-test report
    if target is Status.FIELD_TESTED:
        if not field_test_id:
            raise ValueError("Field-test transition requires --field-test-id.")
        report = load_field_test(field_test_id)
        if report["entry_id"] != entry_id:
            raise ValueError("Field test entry_id does not match target entry.")
        record.tested_by = report["tester"]
        record.tested_date = report["date"]
        record.tested_location = report["location"]

    event = VerificationEvent(
        entry_id=entry_id,
        from_status=record.status,
        to_status=target,
        actor=actor,
        timestamp=datetime.now(UTC).date().isoformat(),
        notes=notes,
        reviewers=reviewers or [],
        field_test_id=field_test_id,
    )
    record.history.append(event)
    record.status = target
    if notes:
        record.notes = notes

    save_record(record)
    _append_ledger(event)
    return record


# ---------------------------------------------------------------------------
# Ledger (append-only audit log)
# ---------------------------------------------------------------------------

def _append_ledger(event: VerificationEvent) -> None:
    GOVERNANCE_DIR.mkdir(parents=True, exist_ok=True)
    ledger = GOVERNANCE_DIR / "verification-ledger.jsonl"
    with ledger.open("a", encoding="utf-8") as f:
        f.write(json.dumps(event.__dict__, default=str) + "\n")


def load_ledger() -> list[dict[str, Any]]:
    ledger = GOVERNANCE_DIR / "verification-ledger.jsonl"
    if not ledger.exists():
        return []
    out = []
    for line in ledger.read_text(encoding="utf-8").splitlines():
        if line.strip():
            out.append(json.loads(line))
    return out


# ---------------------------------------------------------------------------
# Field tests
# ---------------------------------------------------------------------------

def load_field_test(field_test_id: str) -> dict[str, Any]:
    path = FIELD_TESTS_DIR / f"{field_test_id}.yaml"
    if not path.exists():
        raise ValueError(f"Field test not found: {field_test_id}")
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def list_field_tests() -> list[dict[str, Any]]:
    if not FIELD_TESTS_DIR.exists():
        return []
    out = []
    for path in sorted(FIELD_TESTS_DIR.glob("*.yaml")):
        with path.open("r", encoding="utf-8") as f:
            out.append(yaml.safe_load(f))
    return out


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _print_record(r: VerificationRecord) -> None:
    print(f"Entry:    {r.entry_id}")
    print(f"Status:   {r.status.value}")
    if r.reviewers:
        print(f"Reviewers: {', '.join(r.reviewers)}")
    if r.tested_by:
        print(f"Tested:   {r.tested_by} at {r.tested_location} on {r.tested_date}")
    if r.notes:
        print(f"Notes:    {r.notes}")


def main() -> int:
    parser = argparse.ArgumentParser(prog="abook-verify")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_show = sub.add_parser("show", help="Show verification record.")
    p_show.add_argument("entry_id")

    p_adv = sub.add_parser("advance", help="Advance state.")
    p_adv.add_argument("entry_id")
    p_adv.add_argument("--to", required=True, choices=[s.value for s in Status])
    p_adv.add_argument("--actor", required=True)
    p_adv.add_argument("--reviewer", action="append", default=[])
    p_adv.add_argument("--field-test-id")
    p_adv.add_argument("--notes", default="")
    p_adv.add_argument("--force", action="store_true")

    p_led = sub.add_parser("ledger", help="Print verification ledger.")
    p_led.add_argument("--json", action="store_true")

    p_ftl = sub.add_parser("field-tests", help="List field tests.")
    p_ftl.add_argument("--json", action="store_true")

    args = parser.parse_args()

    if args.cmd == "show":
        _print_record(load_record(args.entry_id))
        return 0

    if args.cmd == "advance":
        rec = transition(
            args.entry_id,
            Status(args.to),
            args.actor,
            reviewers=args.reviewer,
            field_test_id=args.field_test_id,
            notes=args.notes,
            force=args.force,
        )
        _print_record(rec)
        return 0

    if args.cmd == "ledger":
        events = load_ledger()
        if args.json:
            print(json.dumps(events, indent=2))
        else:
            for e in events:
                print(
                    f"{e['timestamp']} {e['entry_id']}: "
                    f"{e['from_status']} -> {e['to_status']} by {e['actor']}"
                )
        return 0

    if args.cmd == "field-tests":
        tests = list_field_tests()
        if args.json:
            print(json.dumps(tests, indent=2))
        else:
            for t in tests:
                print(f"{t['id']}: {t['entry_id']} by {t['tester']} on {t['date']}")
        return 0

    return 1


if __name__ == "__main__":
    sys.exit(main())
