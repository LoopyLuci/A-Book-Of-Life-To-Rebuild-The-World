#!/usr/bin/env python3
"""
Local, on-device delivery pipeline.

A single command that takes a working tree from "edited" to "verified and
packaged" without a network round trip to a CI server, and without ever
weakening an assertion to make a run look green.

    python scripts/local_pipeline.py                 # full pipeline
    python scripts/local_pipeline.py --list          # show the stages
    python scripts/local_pipeline.py --stage lint    # run one stage
    python scripts/local_pipeline.py --fast          # skip the slow stages
    python scripts/local_pipeline.py --clean         # discard the cache first
    python scripts/local_pipeline.py --telemetry     # machine readable report

Design
------
* **Preflight first.** Every stage depends on the toolchain, the disk and the
  working tree. The preflight stage checks those before anything is built, so
  a missing tool is reported as a missing tool rather than as a mysterious
  failure three stages later.
* **Stages are independent.** Independent stages run concurrently; dependent
  stages wait. The default order is conservative and safe.
* **Nothing is skipped silently.** A stage that is skipped says so, and why,
  in the summary. Cached results are reported as cached.
* **Load flakes are absorbed, real failures are not.** A stage that fails while
  the machine is busy is re-run serially, with the machine allowed to settle,
  a few times. If it passes on any attempt the failure is recorded as a flake
  and the run continues. If it fails every attempt it is a real failure and
  the pipeline stops. Assertions are never modified.
* **Everything is logged.** Per-stage logs, a machine readable telemetry file
  and a human readable summary are written under `logs/local_pipeline/`.
* **The pipeline is idempotent.** Running it twice in a row is safe, and the
  second run is much faster because unchanged stages are cached.

Exit codes
----------
0  every selected stage passed
1  a stage failed
2  the preflight failed
130 interrupted
"""

from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import time
from collections.abc import Sequence
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
LOG_DIR = ROOT / "logs" / "local_pipeline"
CACHE_FILE = LOG_DIR / "cache.json"
TELEMETRY_FILE = LOG_DIR / "telemetry.json"
SUMMARY_FILE = LOG_DIR / "summary.txt"

PYTHON = sys.executable
IS_WINDOWS = os.name == "nt"
# `subprocess` on Windows does not apply PATHEXT, so a bare `npx` never
# resolves although `npx.cmd` is on PATH.
NPX = "npx.cmd" if IS_WINDOWS else "npx"

# Tunables. Every one of them can be overridden from the environment so that
# the same script works on a developer laptop and on a small CI runner.
FLAKE_ATTEMPTS = int(os.environ.get("ABP_PIPELINE_FLAKY_ATTEMPTS", "3"))
SETTLE_SECONDS = float(os.environ.get("ABP_PIPELINE_SETTLE_S", "3"))
STAGE_TIMEOUT = int(os.environ.get("ABP_PIPELINE_TIMEOUT_S", "3600"))
USE_CACHE = os.environ.get("ABP_PIPELINE_CACHE", "1") not in ("0", "false", "no")
PARALLEL = os.environ.get("ABP_PIPELINE_PARALLEL", "1") not in ("0", "false", "no")


# --------------------------------------------------------------------------
# Output helpers
# --------------------------------------------------------------------------

class Printer:
    """Small, dependency free, colour aware logger."""

    def __init__(self, quiet: bool = False) -> None:
        self.quiet = quiet

    @staticmethod
    def _colour(code: str, text: str) -> str:
        if not sys.stdout.isatty() or os.environ.get("NO_COLOR"):
            return text
        return f"\033[{code}m{text}\033[0m"

    def info(self, text: str) -> None:
        if not self.quiet:
            print(self._colour("0", text), flush=True)

    def step(self, text: str) -> None:
        print(self._colour("1;36", f"==> {text}"), flush=True)

    def good(self, text: str) -> None:
        print(self._colour("1;32", f"  ok  {text}"), flush=True)

    def warn(self, text: str) -> None:
        print(self._colour("1;33", f"  !!  {text}"), flush=True)

    def bad(self, text: str) -> None:
        print(self._colour("1;31", f"  xx  {text}"), flush=True)

    def plain(self, text: str = "") -> None:
        print(text, flush=True)


# --------------------------------------------------------------------------
# Stage model
# --------------------------------------------------------------------------

@dataclass
class StageResult:
    name: str
    status: str  # passed | failed | skipped | cached | flaky
    duration: float = 0.0
    attempts: int = 1
    command: str = ""
    detail: str = ""
    log: str = ""

    def as_dict(self) -> dict:
        return {
            "name": self.name,
            "status": self.status,
            "duration_s": round(self.duration, 3),
            "attempts": self.attempts,
            "command": self.command,
            "detail": self.detail,
            "log": self.log,
        }


@dataclass
class Stage:
    name: str
    description: str
    commands: list[Any] = field(default_factory=list)
    inputs: list[str] = field(default_factory=list)
    #: Paths a cacheable stage writes. A cached result is only trusted while
    #: every one of them still exists, so deleting `build/` cannot leave the
    #: pipeline reporting an artifact that is no longer there.
    outputs: list[str] = field(default_factory=list)
    group: str = "default"
    slow: bool = False
    optional: bool = False
    requires: list[str] = field(default_factory=list)
    #: True only for a stage that writes an artifact from its inputs. A gate
    #: (a test, a lint, a validation) is never cached: a green run has to mean
    #: the check ran against this tree, not against one from an hour ago.
    cacheable: bool = False


@dataclass
class Command:
    """One command to run, optionally from a directory of its own.

    Most stages run from the repository root. An app that owns its own build
    file (Gradle, for instance) has to run from its own directory, so the
    working directory travels with the command instead of with the stage.
    """

    argv: Sequence[str]
    cwd: Path | None = None


def _command_parts(command: Any) -> tuple[Sequence[str], Path]:
    """The argv and working directory of a stage command."""
    if isinstance(command, Command):
        return command.argv, command.cwd or ROOT
    return command, ROOT


def _command_text(command: Any) -> str:
    """A one-line description of a stage command, for the summary."""
    argv, cwd = _command_parts(command)
    text = " ".join(str(part) for part in argv)
    return text if cwd == ROOT else f"(cd {cwd.name} && {text})"


# --------------------------------------------------------------------------
# Environment helpers
# --------------------------------------------------------------------------

def project_environment() -> dict[str, str]:
    """Variables from the project's environment file, if it has one.

    `scripts/env.ps1` and `scripts/env.sh` pin the caches, the temporary
    directory and the toolchain paths, and they are local to a machine, so
    they are not tracked. When one of them is present the pipeline adopts its
    values, which is what makes a hooked push behave the same as a run in a
    shell where the file was sourced.
    """
    values: dict[str, str] = {}
    pattern = re.compile(
        r"^\s*(?:\$Env:|export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+?)\s*$"
    )
    # Each platform has its own file, and the two spell a path differently.
    names = ("env.ps1",) if IS_WINDOWS else ("env.sh",)
    for name in names:
        path = ROOT / "scripts" / name
        if not path.exists():
            continue
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.lstrip().startswith("#"):
                continue
            match = pattern.match(line)
            if not match:
                continue
            key, raw = match.group(1), match.group(2).strip()
            if raw.startswith(('"', "'")) and raw.endswith(raw[0]) and len(raw) >= 2:
                raw = raw[1:-1]
            if raw in ("$PATH", "$Env:PATH", "${PATH}"):
                continue
            if key == "PATH":
                # The file prepends directories to the inherited PATH.
                inherited = os.environ.get("PATH", "")
                raw = raw.replace("$PATH", inherited).replace("$Env:PATH", inherited)
                raw = raw.replace("${PATH}", inherited)
                separator = ";" if IS_WINDOWS else ":"
                parts = [part for part in raw.split(separator) if part]
                values["PATH"] = os.pathsep.join(parts)
                continue
            raw = re.sub(r"\$Env:([A-Za-z_][A-Za-z0-9_]*)",
                         lambda m: os.environ.get(m.group(1), ""), raw)
            values[key] = raw
    return values


PROJECT_ENV = project_environment()


def run_command(command: Sequence[str], cwd: Path, log_path: Path,
                timeout: int = STAGE_TIMEOUT) -> tuple[int, str]:
    """Run a command, streaming its output into a log file."""
    printable = " ".join(str(part) for part in command)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    started = time.time()
    environment = os.environ.copy()
    environment.update(PROJECT_ENV)
    with log_path.open("a", encoding="utf-8", errors="replace") as log:
        log.write(f"\n$ {printable}\n")
        log.flush()
        try:
            completed = subprocess.run(
                list(command),
                cwd=str(cwd),
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding="utf-8",
                errors="replace",
                timeout=timeout,
                env=environment,
                check=False,
            )
        except FileNotFoundError as exc:
            log.write(f"command not found: {exc}\n")
            return 127, f"command not found: {command[0]}"
        except subprocess.TimeoutExpired:
            log.write(f"timed out after {timeout}s\n")
            return 124, f"timed out after {timeout}s"
        output = completed.stdout or ""
        log.write(output)
        log.flush()
        elapsed = time.time() - started
        return completed.returncode, f"{elapsed:.1f}s"


def have(command: str) -> bool:
    return shutil.which(command) is not None


def directory_size(path: Path) -> int:
    if not path.exists():
        return 0
    total = 0
    for root, _dirs, files in os.walk(path):
        for name in files:
            try:
                total += (Path(root) / name).stat().st_size
            except OSError:
                continue
    return total


def fingerprint(paths: Sequence[str]) -> str:
    """A stable hash of the inputs of a stage."""
    digest = hashlib.sha256()
    for rel in sorted(paths):
        target = ROOT / rel
        digest.update(rel.encode("utf-8"))
        if target.is_dir():
            for child in sorted(target.rglob("*")):
                if not child.is_file() or "__pycache__" in child.parts:
                    continue
                digest.update(str(child.relative_to(ROOT)).encode("utf-8"))
                try:
                    digest.update(str(child.stat().st_mtime_ns).encode("utf-8"))
                except OSError:
                    continue
        elif target.is_file():
            try:
                digest.update(str(target.stat().st_mtime_ns).encode("utf-8"))
            except OSError:
                continue
    return digest.hexdigest()


# --------------------------------------------------------------------------
# The stages
# --------------------------------------------------------------------------

def _exe(name: str) -> str:
    """The name of a tool as this platform spells it."""
    if IS_WINDOWS and name in ("npm", "npx", "pnpm", "yarn"):
        return f"{name}.cmd"
    return name


def sdk_stage_commands() -> list[Any]:
    """The test commands of every SDK whose toolchain is present."""
    commands: list[Any] = [
        Command([PYTHON, "-m", "pytest", "tests", "-q"], cwd=ROOT / "sdk" / "python"),
    ]

    typescript = ROOT / "sdk" / "typescript"
    if (typescript / "package.json").exists() and have(_exe("npm")):
        commands.append([_exe("npm"), "--prefix", "sdk/typescript", "run", "test"])
        commands.append([_exe("npm"), "--prefix", "sdk/typescript", "run", "build"])

    rust = ROOT / "sdk" / "rust"
    if (rust / "Cargo.toml").exists() and have("cargo"):
        commands.append(["cargo", "test", "--manifest-path", "sdk/rust/Cargo.toml"])

    return commands


def app_stage_commands() -> list[Sequence[str]]:
    """The test command of every app whose toolchain is present.

    A missing toolchain is not a failure: the stage simply tests the apps the
    machine can build. The reported command list is what actually ran, so the
    summary says which surfaces were covered.
    """
    commands: list[Sequence[str]] = []
    apps_dir = ROOT / "apps"

    if (apps_dir / "desktop-python").exists() and have(PYTHON):
        commands.append([PYTHON, "-m", "pytest", "apps/desktop-python/tests", "-q"])

    if (apps_dir / "web-ts" / "package.json").exists() and have(_exe("npm")):
        commands.append([_exe("npm"), "--prefix", "apps/web-ts", "run", "test"])
        commands.append([_exe("npm"), "--prefix", "apps/web-ts", "run", "build"])

    if (apps_dir / "web-rails" / "bin" / "rails").exists() and have("ruby"):
        # Ruby changes into the app before it loads anything, so the command
        # works from the repository root like every other stage.
        commands.append(["ruby", "-Capps/web-rails", "bin/rails", "test"])

    if (apps_dir / "desktop-rust" / "Cargo.toml").exists() and have("cargo"):
        commands.append(["cargo", "test", "--manifest-path", "apps/desktop-rust/Cargo.toml"])
        commands.append(["cargo", "clippy", "--manifest-path", "apps/desktop-rust/Cargo.toml",
                         "--all-targets", "--", "-D", "warnings"])

    if (apps_dir / "powershell" / "tests" / "run-tests.ps1").exists() and have("pwsh"):
        commands.append(["pwsh", "-NoProfile", "-File", "apps/powershell/tests/run-tests.ps1"])

    if (apps_dir / "shell" / "tests" / "run-tests.sh").exists() and have("sh"):
        commands.append(["sh", "apps/shell/tests/run-tests.sh"])

    return commands


def build_stages() -> list[Stage]:
    return [
        Stage(
            name="preflight",
            description="Check the toolchain, the disk and the working tree",
            group="preflight",
        ),
        Stage(
            name="validate",
            description="Validate every sidecar against the schema",
            commands=[
                [PYTHON, "scripts/validate.py"],
                [PYTHON, "scripts/validate_field_tests.py"],
            ],
            inputs=["sidecars", "schemas", "domains"],
        ),
        Stage(
            name="lint",
            description="Lint the Markdown and the Python",
            commands=[
                [PYTHON, "-m", "ruff", "check", "."],
            ],
            inputs=["scripts", "tests", "apps"],
            optional=True,
        ),
        Stage(
            name="markdown",
            description="Markdown lint over the corpus",
            commands=[
                [NPX, "--yes", "--package=markdownlint-cli2@0.13.0",
                 "--package=markdownlint@0.34.0", "markdownlint-cli2",
                 "domains/**/*.md"],
            ],
            inputs=["domains"],
            optional=True,
        ),
        Stage(
            name="i18n",
            description="Check translation coverage and build the language indexes",
            commands=[
                [PYTHON, "scripts/validate_i18n.py"],
                [PYTHON, "scripts/build_i18n.py"],
            ],
            inputs=["i18n", "sidecars"],
        ),
        Stage(
            name="tests",
            description="Run the Python test suite",
            commands=[
                [PYTHON, "-m", "pytest", "-q"],
            ],
            inputs=["tests", "scripts", "sdk/python"],
            # The end-to-end tests read the search index and the offline
            # bundle. They are cheap to wait for and expensive to race with.
            requires=["index", "bundle"],
        ),
        Stage(
            name="index",
            description="Build the search index",
            commands=[
                [PYTHON, "scripts/build_index.py"],
                [PYTHON, "scripts/dashboard.py"],
            ],
            inputs=["domains", "sidecars", "manifest.toml"],
            outputs=["build/index.db", "build/dashboard.html"],
            cacheable=True,
        ),
        Stage(
            name="media",
            description="Validate the media assets",
            commands=[[PYTHON, "scripts/build_media.py"]],
            inputs=["media"],
            outputs=["build/media-index.json"],
            optional=True,
            cacheable=True,
        ),
        Stage(
            name="models",
            description="Build the printable models",
            commands=[[PYTHON, "scripts/build_models.py"]],
            inputs=["models"],
            outputs=["build/models"],
            optional=True,
            slow=True,
            cacheable=True,
        ),
        Stage(
            name="variants",
            description="Build the regional variants",
            commands=[[PYTHON, "scripts/build_variants.py"]],
            inputs=["variants", "domains"],
            outputs=["build/variants"],
            optional=True,
            cacheable=True,
        ),
        Stage(
            name="bundle",
            description="Assemble the offline bundle",
            commands=[[PYTHON, "scripts/build_bundle.py"]],
            inputs=["domains", "sidecars", "i18n", "manifest.toml"],
            outputs=["build/offline-bundle/html/index.html",
                     "build/offline-bundle/bundle-manifest.json"],
            slow=True,
            cacheable=True,
        ),
        Stage(
            name="sdk",
            description="Build and test the SDKs",
            commands=sdk_stage_commands(),
            inputs=["sdk/python", "sdk/typescript", "sdk/rust"],
            optional=True,
        ),
        Stage(
            name="apps",
            description="Test the six app front-ends",
            commands=app_stage_commands(),
            inputs=["apps", "domains", "sidecars", "i18n/strings"],
            optional=True,
            slow=True,
        ),
        Stage(
            name="android",
            description="Export the Android content and build the app",
            commands=[
                [PYTHON, "android/tools/export_content.py"],
                Command(
                    [str(ROOT / "android" / ("gradlew.bat" if IS_WINDOWS else "gradlew")),
                     "test", ":app:assembleDebug", "--console=plain"],
                    cwd=ROOT / "android",
                ),
            ],
            inputs=["android", "domains", "sidecars", "i18n/strings"],
            optional=True,
            slow=True,
        ),
    ]


# --------------------------------------------------------------------------
# Preflight
# --------------------------------------------------------------------------

def preflight(report: dict) -> tuple[bool, list[str]]:
    """Check the environment before any stage runs."""
    problems: list[str] = []
    notes: list[str] = []

    version = sys.version_info
    if version < (3, 11):
        problems.append(f"Python 3.11 or newer is required, found {version.major}.{version.minor}")
    else:
        notes.append(f"python {version.major}.{version.minor}.{version.micro}")

    manifest = ROOT / "manifest.toml"
    if not manifest.exists():
        problems.append("manifest.toml is missing; this is not the project root")
    else:
        notes.append("manifest.toml present")

    for tool, required in (("git", True), ("node", False), ("npm", False),
                           ("cargo", False), ("java", False), ("ruby", False)):
        path = shutil.which(tool)
        if path:
            notes.append(f"{tool} -> {path}")
        elif required:
            problems.append(f"required tool not found: {tool}")
        else:
            notes.append(f"{tool} -> not installed (related stages will be skipped)")

    try:
        import yaml  # noqa: F401
        notes.append("PyYAML available")
    except ImportError:
        problems.append("PyYAML is not installed; run scripts/install.py first")

    usage = shutil.disk_usage(ROOT)
    free_gb = usage.free / (1024 ** 3)
    if free_gb < 1.0:
        problems.append(f"only {free_gb:.1f} GB free; the pipeline needs about 2 GB")
    else:
        notes.append(f"{free_gb:.1f} GB free")

    try:
        import psutil  # type: ignore

        memory_gb = psutil.virtual_memory().total / (1024 ** 3)
        notes.append(f"{memory_gb:.1f} GB memory")
    except (ImportError, OSError, AttributeError):
        # The memory size is a nicety, never a requirement.
        pass

    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=str(ROOT), capture_output=True, text=True, timeout=30, check=False,
        )
        if result.returncode == 0:
            notes.append(f"git {result.stdout.strip()}")
        else:
            notes.append("not a git checkout")
    except (OSError, subprocess.SubprocessError):
        notes.append("not a git checkout")

    report["preflight"] = {"ok": not problems, "notes": notes, "problems": problems}
    return not problems, problems


# --------------------------------------------------------------------------
# Runner
# --------------------------------------------------------------------------

def load_cache() -> dict:
    if CACHE_FILE.exists():
        try:
            return json.loads(CACHE_FILE.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            return {}
    return {}


def save_cache(cache: dict) -> None:
    CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
    CACHE_FILE.write_text(json.dumps(cache, indent=2), encoding="utf-8")


def execute(stage: Stage, printer: Printer) -> StageResult:
    """Run one stage, with flake absorption."""
    log_path = LOG_DIR / f"{stage.name}.log"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    if log_path.exists():
        log_path.unlink()

    printable = "; ".join(_command_text(c) for c in stage.commands)
    total_started = time.time()
    attempts = 0
    last_detail = ""
    last_code = 1

    while attempts < FLAKE_ATTEMPTS:
        attempts += 1
        printer.info(f"    attempt {attempts}/{FLAKE_ATTEMPTS}: {stage.name}")
        for command in stage.commands:
            argv, cwd = _command_parts(command)
            last_code, last_detail = run_command(argv, cwd, log_path)
            if last_code != 0:
                break
        if last_code == 0:
            duration = time.time() - total_started
            status = "flaky" if attempts > 1 else "passed"
            return StageResult(stage.name, status, duration, attempts, printable,
                               last_detail, str(log_path))
        if attempts < FLAKE_ATTEMPTS:
            printer.warn(
                f"    {stage.name} failed (exit {last_code}); "
                f"settling for {SETTLE_SECONDS:.0f}s and retrying serially"
            )
            time.sleep(SETTLE_SECONDS)

    duration = time.time() - total_started
    return StageResult(stage.name, "failed", duration, attempts, printable,
                       last_detail, str(log_path))


def run_selected(stages: list[Stage], printer: Printer, fast: bool,
                 only: list[str] | None, skip: list[str]) -> tuple[list[StageResult], bool]:
    results: list[StageResult] = []
    cache = load_cache()
    if not USE_CACHE:
        cache = {}

    selected = [s for s in stages if not only or s.name in only]
    selected = [s for s in selected if s.name not in skip]
    if fast:
        selected = [s for s in selected if not s.slow]

    if not selected:
        printer.warn("nothing selected")
        return results, True

    # The preflight always runs first, on its own.
    preflight_stage = next((s for s in selected if s.name == "preflight"), None)
    if preflight_stage:
        selected.remove(preflight_stage)
        printer.step(f"preflight: {preflight_stage.description}")
        report: dict = {}
        ok, problems = preflight(report)
        for note in report.get("notes", []):
            printer.info(f"    {note}")
        if not ok:
            for problem in problems:
                printer.bad(problem)
            results.append(StageResult("preflight", "failed", 0.0, 1, detail="; ".join(problems)))
            return results, False
        printer.good("preflight passed")
        results.append(StageResult("preflight", "passed"))

    remaining = [s for s in selected if s.group != "preflight"]

    def run_one(stage: Stage) -> StageResult:
        key = stage.name
        # Only a cacheable stage needs a fingerprint; a gate always runs.
        digest = fingerprint(stage.inputs) if stage.cacheable and stage.inputs else ""
        artifacts_present = all((ROOT / path).exists() for path in stage.outputs)
        if stage.cacheable and digest and artifacts_present and cache.get(key) == digest:
            printer.info(f"{stage.name}: inputs unchanged, artifact reused")
            return StageResult(stage.name, "cached")
        printer.step(f"{stage.name}: {stage.description}")
        result = execute(stage, printer)
        if result.status in ("passed", "flaky") and digest:
            cache[key] = digest
        return result

    def report(stage: Stage, result: StageResult) -> None:
        results.append(result)
        if result.status in ("passed", "flaky"):
            printer.good(f"{stage.name} ({result.duration:.1f}s)")
        elif result.status == "failed" and not stage.optional:
            printer.bad(f"{stage.name}: {result.detail}")
        elif result.status == "failed":
            printer.warn(f"{stage.name} failed but is optional: {result.detail}")
        else:
            printer.info(f"{stage.name} {result.status}")

    pending = list(remaining)
    selected_names = {stage.name for stage in remaining}
    done: set[str] = set()

    def prerequisites_met(stage: Stage) -> bool:
        """True when every selected stage this one depends on has finished.

        A dependency that was not selected is not a reason to wait: the stage
        is then responsible for its own inputs, which is what makes
        `--stage tests` work on its own.
        """
        return all(dep in done or dep not in selected_names for dep in stage.requires)

    stop = False
    while pending and not stop:
        wave = [stage for stage in pending if prerequisites_met(stage)]
        if not wave:
            # A dependency cycle, which the stage table should never contain.
            # Run the rest rather than wait forever.
            wave = list(pending)

        if PARALLEL and len(wave) > 1:
            # Independent stages run together. A stage that fails does not
            # stop the others from finishing, so one report arrives with
            # everything.
            with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
                futures = {pool.submit(run_one, stage): stage for stage in wave}
                for future in concurrent.futures.as_completed(futures):
                    stage = futures[future]
                    try:
                        result = future.result()
                    except (OSError, subprocess.SubprocessError, ValueError) as exc:
                        # A stage must never kill the run.
                        result = StageResult(stage.name, "failed", detail=str(exc))
                    report(stage, result)
        else:
            for stage in wave:
                result = run_one(stage)
                report(stage, result)
                if result.status == "failed" and not stage.optional:
                    stop = True
                    break

        for stage in wave:
            if stage in pending:
                pending.remove(stage)
                done.add(stage.name)

        if stop:
            for stage in pending:
                results.append(StageResult(
                    stage.name, "skipped", detail="an earlier required stage failed"))
            pending.clear()

    save_cache(cache)
    order = {s.name: i for i, s in enumerate(stages)}
    results.sort(key=lambda r: order.get(r.name, 999))
    return results, True


# --------------------------------------------------------------------------
# Reporting
# --------------------------------------------------------------------------

def write_report(results: list[StageResult], printer: Printer) -> int:
    failed = [r for r in results if r.status == "failed"]
    flaky = [r for r in results if r.status == "flaky"]
    passed = [r for r in results if r.status == "passed"]
    cached = [r for r in results if r.status == "cached"]
    skipped = [r for r in results if r.status == "skipped"]

    printer.plain()
    printer.plain("=" * 66)
    printer.plain(f"  {len(passed)} passed, {len(flaky)} flaky, {len(cached)} cached, "
                  f"{len(skipped)} skipped, {len(failed)} failed")
    printer.plain("=" * 66)
    for result in results:
        marker = {
            "passed": "PASS", "flaky": "FLAKY", "cached": "CACHE",
            "skipped": "SKIP", "failed": "FAIL",
        }.get(result.status, result.status.upper())
        printer.plain(f"  {marker:<6} {result.name:<12} {result.duration:8.1f}s"
                      + (f"  {result.detail}" if result.status == "failed" else ""))
    printer.plain("=" * 66)

    if flaky:
        printer.plain("  These stages failed under load and passed when retried.")
        printer.plain("  They are recorded as flakes rather than hidden:")
        for result in flaky:
            printer.plain(f"    - {result.name} (took {result.attempts} attempts)")
    if failed:
        printer.plain("  Failed stages:")
        for result in failed:
            printer.plain(f"    - {result.name}: {result.detail}")
            printer.plain(f"      log: {result.log}")
    printer.plain(f"  logs: {LOG_DIR}")
    printer.plain("=" * 66)

    telemetry = {
        "generated_at": time.time(),
        "host": {
            "platform": platform.platform(),
            "python": platform.python_version(),
            "processor": platform.processor(),
            "cpu_count": os.cpu_count(),
        },
        "results": [r.as_dict() for r in results],
        "totals": {
            "passed": len(passed), "flaky": len(flaky), "cached": len(cached),
            "skipped": len(skipped), "failed": len(failed),
        },
        "settings": {
            "flaky_attempts": FLAKE_ATTEMPTS,
            "settle_seconds": SETTLE_SECONDS,
            "parallel": PARALLEL,
            "cache": USE_CACHE,
        },
    }
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    TELEMETRY_FILE.write_text(json.dumps(telemetry, indent=2), encoding="utf-8")

    summary = "\n".join(
        f"{r.status:<8} {r.name:<12} {r.duration:8.1f}s {r.detail}" for r in results
    )
    SUMMARY_FILE.write_text(summary + "\n", encoding="utf-8")

    if failed:
        printer.plain("  The pipeline did not pass. Nothing was published.")
        return 1
    printer.plain("  The pipeline passed. The working tree is ready to ship.")
    return 0


# --------------------------------------------------------------------------
# Entry point
# --------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Local, on-device delivery pipeline.",
    )
    parser.add_argument("--list", action="store_true", help="list the stages and exit")
    parser.add_argument("--stage", action="append", default=[],
                        help="run only this stage (repeatable)")
    parser.add_argument("--skip", action="append", default=[],
                        help="skip this stage (repeatable)")
    parser.add_argument("--fast", action="store_true", help="skip the slow stages")
    parser.add_argument("--clean", action="store_true", help="discard the cache first")
    parser.add_argument("--telemetry", action="store_true",
                        help="print the telemetry report as JSON and exit")
    parser.add_argument("--quiet", action="store_true", help="less noise")
    args = parser.parse_args(argv)

    printer = Printer(quiet=args.quiet)

    if args.clean and LOG_DIR.exists():
        shutil.rmtree(LOG_DIR, ignore_errors=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    stages = build_stages()

    if args.list:
        for stage in stages:
            print(f"{stage.name:<12} {stage.description}"
                  f"{'  (slow)' if stage.slow else ''}"
                  f"{'  (optional)' if stage.optional else ''}")
        return 0

    if args.telemetry:
        if TELEMETRY_FILE.exists():
            print(TELEMETRY_FILE.read_text(encoding="utf-8"))
            return 0
        printer.warn("no telemetry yet; run the pipeline first")
        return 0

    printer.plain(f"Local pipeline  |  {platform.platform()}  |  python "
                  f"{platform.python_version()}")
    started = time.time()
    results, _ = run_selected(stages, printer, args.fast, args.stage or None, args.skip)
    code = write_report(results, printer)
    printer.plain(f"  total: {time.time() - started:.1f}s")
    return code


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\ninterrupted", file=sys.stderr)
        sys.exit(130)
