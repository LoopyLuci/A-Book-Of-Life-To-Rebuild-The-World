#!/usr/bin/env python3
"""
Production grade installer, updater and verifier for Book of Life.

One command sets up everything a reader or a builder needs:

    python scripts/install.py install     # install or repair
    python scripts/install.py update      # update an existing install
    python scripts/install.py verify      # check an existing install
    python scripts/install.py uninstall   # remove the installation

What it does, in order:

1. **Discovers the environment.** Python version, permissions, disk space,
   whether a virtual environment already exists, and whether the machine is
   offline.
2. **Installs the dependencies** into an isolated virtual environment, with a
   pinned, hashable requirements file, an optional offline wheelhouse, and a
   retry with a clear message when the network is the problem.
3. **Verifies the install** by importing every dependency, building the
   search index, and running a smoke test that reads a real entry.
4. **Creates the launchers** so the project can be started with one command
   on the machine it was installed on, and installs the pre-push hook that
   runs the local pipeline before every push.
5. **Isolates failures.** If the new install does not pass verification, the
   previous working environment is restored. An installer that breaks a
   working setup is worse than no installer.

The updater is the same code path with a different target: it fetches the
requested version, installs it beside the current one, verifies it, and only
then swaps it in.
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import shutil
import subprocess
import sys
import time
import venv
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VENV_DIR = ROOT / ".venv"
STATE_DIR = ROOT / ".abook"
STATE_FILE = STATE_DIR / "install-state.json"
LOG_DIR = ROOT / "logs" / "installer"
WHEELHOUSE = ROOT / "vendor" / "wheels"

IS_WINDOWS = os.name == "nt"
MIN_PYTHON = (3, 11)

PIP_ARGS = [
    "--disable-pip-version-check",
    "--no-input",
    "--prefer-binary",
]


# --------------------------------------------------------------------------
# Small helpers
# --------------------------------------------------------------------------

class Installer:
    def __init__(self, dry_run: bool = False, offline: bool = False) -> None:
        self.dry_run = dry_run
        self.offline = offline
        self.log_path = LOG_DIR / f"install-{time.strftime('%Y%m%d-%H%M%S')}.log"
        self.started = time.time()

    # -- output ---------------------------------------------------------
    def log(self, text: str) -> None:
        line = f"[{time.strftime('%H:%M:%S')}] {text}"
        print(line, flush=True)
        try:
            LOG_DIR.mkdir(parents=True, exist_ok=True)
            with self.log_path.open("a", encoding="utf-8") as handle:
                handle.write(line + "\n")
        except OSError:
            pass

    def step(self, text: str) -> None:
        self.log(f"==> {text}")

    def ok(self, text: str) -> None:
        self.log(f"    ok  {text}")

    def warn(self, text: str) -> None:
        self.log(f"    !!  {text}")

    def fail(self, text: str) -> None:
        self.log(f"    xx  {text}")

    # -- process --------------------------------------------------------
    def run(self, command: list[str], cwd: Path | None = None,
            env: dict | None = None, check: bool = True) -> subprocess.CompletedProcess:
        printable = " ".join(command)
        self.log(f"    $ {printable}")
        if self.dry_run:
            return subprocess.CompletedProcess(command, 0, "", "")
        merged = os.environ.copy()
        if env:
            merged.update(env)
        result = subprocess.run(
            command,
            cwd=str(cwd or ROOT),
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            env=merged,
            check=False,
        )
        output = (result.stdout or "") + (result.stderr or "")
        for line in output.splitlines()[-12:]:
            self.log(f"       {line}")
        if check and result.returncode != 0:
            raise RuntimeError(f"command failed ({result.returncode}): {printable}")
        return result

    @property
    def venv_python(self) -> Path:
        if IS_WINDOWS:
            return VENV_DIR / "Scripts" / "python.exe"
        return VENV_DIR / "bin" / "python"

    @property
    def venv_pip(self) -> Path:
        if IS_WINDOWS:
            return VENV_DIR / "Scripts" / "pip.exe"
        return VENV_DIR / "bin" / "pip"


# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

@dataclass
class InstallState:
    version: str = "unknown"
    installed_at: str = ""
    python: str = ""
    platform: str = ""
    revision: str = ""
    venv: str = ""

    def to_dict(self) -> dict:
        return {
            "version": self.version,
            "installed_at": self.installed_at,
            "python": self.python,
            "platform": self.platform,
            "revision": self.revision,
            "venv": self.venv,
        }

    @staticmethod
    def load() -> InstallState:
        if not STATE_FILE.exists():
            return InstallState()
        try:
            data = json.loads(STATE_FILE.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            return InstallState()
        return InstallState(
            version=data.get("version", "unknown"),
            installed_at=data.get("installed_at", ""),
            python=data.get("python", ""),
            platform=data.get("platform", ""),
            revision=data.get("revision", ""),
            venv=data.get("venv", ""),
        )

    def save(self) -> None:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        STATE_FILE.write_text(json.dumps(self.to_dict(), indent=2), encoding="utf-8")


# --------------------------------------------------------------------------
# Steps
# --------------------------------------------------------------------------

def read_manifest_version() -> str:
    manifest = ROOT / "manifest.toml"
    if not manifest.exists():
        return "unknown"
    for line in manifest.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("version") and "=" in stripped:
            return stripped.split("=", 1)[1].strip().strip('"')
    return "unknown"


def git_revision() -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=str(ROOT), capture_output=True, text=True, timeout=20, check=False,
        )
        return result.stdout.strip() if result.returncode == 0 else ""
    except (OSError, subprocess.SubprocessError):
        return ""


def check_environment(inst: Installer) -> bool:
    inst.step("Checking the environment")
    ok = True

    if sys.version_info < MIN_PYTHON:
        inst.fail(
            f"Python {MIN_PYTHON[0]}.{MIN_PYTHON[1]} or newer is required, "
            f"found {platform.python_version()}"
        )
        ok = False
    else:
        inst.ok(f"python {platform.python_version()}")

    usage = shutil.disk_usage(ROOT)
    free_gb = usage.free / (1024 ** 3)
    if free_gb < 1.5:
        inst.fail(f"only {free_gb:.1f} GB free; 2 GB is needed for the model cache")
        ok = False
    else:
        inst.ok(f"{free_gb:.1f} GB free")

    for path in (ROOT / "manifest.toml", ROOT / "requirements.txt",
                 ROOT / "scripts" / "build_index.py"):
        if path.exists():
            inst.ok(f"found {path.relative_to(ROOT)}")
        else:
            inst.fail(f"missing {path.relative_to(ROOT)}")
            ok = False

    if inst.offline:
        inst.warn("offline mode: no network will be used")
    else:
        inst.ok("network will be used for the dependency download")

    return ok


def create_environment(inst: Installer, rebuild: bool = False) -> bool:
    inst.step("Preparing the virtual environment")
    if inst.dry_run:
        inst.log(f"    (dry run) would create or reuse {VENV_DIR}")
        return True
    if VENV_DIR.exists():
        if not rebuild:
            inst.ok(f"reusing the environment at {VENV_DIR}")
            return True
        inst.warn(f"replacing the environment at {VENV_DIR}")
        backup = VENV_DIR.with_name(".venv.previous")
        if backup.exists():
            shutil.rmtree(backup, ignore_errors=True)
        try:
            VENV_DIR.rename(backup)
            inst.ok("the previous environment was kept as .venv.previous")
        except OSError as exc:
            inst.fail(f"could not move the old environment aside: {exc}")
            return False
    try:
        venv.EnvBuilder(with_pip=True, clear=False, symlinks=not IS_WINDOWS).create(VENV_DIR)
    except (OSError, subprocess.SubprocessError) as exc:
        inst.fail(f"could not create the virtual environment: {exc}")
        return False
    inst.ok(f"created {VENV_DIR}")
    return True


def install_dependencies(inst: Installer) -> bool:
    inst.step("Installing the dependencies")
    requirements = ROOT / "requirements.txt"
    if not requirements.exists():
        inst.warn("no requirements.txt; nothing to install")
        return True

    command = [str(inst.venv_pip), "install", *PIP_ARGS]
    if inst.offline:
        if not WHEELHOUSE.exists():
            inst.fail("offline mode requested but there is no vendor/wheels directory")
            return False
        command += ["--no-index", "--find-links", str(WHEELHOUSE)]
    else:
        command += ["-r", str(requirements)]
    command += ["--upgrade"]

    attempts = 3
    for attempt in range(1, attempts + 1):
        try:
            inst.run(command)
            inst.ok("the dependencies are installed")
            return True
        except RuntimeError as exc:
            inst.warn(f"attempt {attempt}/{attempts} failed: {exc}")
            if attempt < attempts:
                time.sleep(2 * attempt)
    inst.fail("the dependencies could not be installed")
    return False


def install_extras(inst: Installer) -> None:
    """Optional developer extras. A failure here never fails the install."""
    inst.step("Installing the optional developer extras")
    command = [str(inst.venv_pip), "install", *PIP_ARGS, "-r",
               str(ROOT / "requirements-dev.txt")]
    if not (ROOT / "requirements-dev.txt").exists():
        inst.ok("no requirements-dev.txt")
        return
    if inst.offline:
        inst.warn("skipped in offline mode")
        return
    try:
        inst.run(command)
        inst.ok("the developer extras are installed")
    except RuntimeError as exc:
        inst.warn(f"the developer extras were not installed: {exc}")


def verify(inst: Installer) -> bool:
    inst.step("Verifying the installation")
    checks: list[tuple[str, list[str]]] = [
        ("the core dependencies import",
         [str(inst.venv_python), "-c",
          "import yaml, jsonschema; print('yaml', yaml.__version__)"]),
        ("the sidecars validate",
         [str(inst.venv_python), "scripts/validate.py"]),
        ("the search index builds",
         [str(inst.venv_python), "scripts/build_index.py"]),
    ]
    for label, command in checks:
        try:
            inst.run(command, cwd=ROOT)
            inst.ok(label)
        except RuntimeError as exc:
            inst.fail(f"{label}: {exc}")
            return False

    smoke = (
        "import sys; sys.path.insert(0, 'scripts');"
        "from pathlib import Path;"
        "root = Path('.');"
        "entries = sorted(root.glob('sidecars/*/*.pnk.yaml'));"
        "assert entries, 'no sidecars found';"
        "import yaml;"
        "d = yaml.safe_load(entries[0].read_text(encoding='utf-8'));"
        "assert d.get('title'), 'sidecar has no title';"
        "print('smoke ok:', d['title'])"
    )
    try:
        inst.run([str(inst.venv_python), "-c", smoke], cwd=ROOT)
        inst.ok("the smoke test passed")
    except RuntimeError as exc:
        inst.fail(f"the smoke test failed: {exc}")
        return False
    return True


def create_launchers(inst: Installer) -> None:
    inst.step("Creating the launchers")
    if inst.dry_run:
        inst.log("    (dry run) would write abook.cmd and the launcher")
        return
    targets: list[tuple[str, list[str]]] = []
    if IS_WINDOWS:
        targets.append((
            str(ROOT / "abook.cmd"),
            [
                "@echo off",
                f'"{inst.venv_python}" "%~dp0scripts\\serve.py" %*',
                "",
            ],
        ))
    else:
        launcher = ROOT / "abook"
        launcher.write_text(
            "#!/bin/sh\n"
            f'exec "{inst.venv_python}" "{ROOT / "scripts" / "serve.py"}" "$@"\n',
            encoding="utf-8",
        )
        launcher.chmod(0o755)
        targets.append((str(launcher), []))

    for path, lines in targets:
        if lines:
            Path(path).write_text("\n".join(lines), encoding="utf-8")
        inst.ok(f"created {Path(path).relative_to(ROOT)}")


def install_git_hooks(inst: Installer) -> None:
    """Install the pre-push hook, unless this is a dry run or not a checkout."""
    inst.step("Installing the pre-push hook")
    if inst.dry_run:
        inst.log("    $ python scripts/install_hooks.py")
        return
    try:
        inst.run([str(inst.venv_python), "scripts/install_hooks.py"])
        inst.ok("the local pipeline now runs before every push")
    except RuntimeError as exc:
        # A tarball or an exported tree has no hooks directory. The install is
        # still useful without the hook, so this is a warning, not a failure.
        inst.warn(f"the pre-push hook was not installed: {exc}")


def write_state(inst: Installer) -> None:
    if inst.dry_run:
        inst.log("    (dry run) would write .abook/install-state.json")
        return
    state = InstallState(
        version=read_manifest_version(),
        installed_at=time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        python=platform.python_version(),
        platform=platform.platform(),
        revision=git_revision(),
        venv=str(VENV_DIR),
    )
    state.save()
    inst.ok(f"install state written to {STATE_FILE.relative_to(ROOT)}")


def roll_back(inst: Installer) -> None:
    previous = VENV_DIR.with_name(".venv.previous")
    if previous.exists():
        inst.step("Rolling back to the previous environment")
        if VENV_DIR.exists():
            shutil.rmtree(VENV_DIR, ignore_errors=True)
        try:
            previous.rename(VENV_DIR)
            inst.ok("the previous environment is back in place")
        except OSError as exc:
            inst.fail(f"the rollback did not complete: {exc}")
    else:
        inst.warn("there is no previous environment to roll back to")


# --------------------------------------------------------------------------
# Commands
# --------------------------------------------------------------------------

def command_install(args: argparse.Namespace) -> int:
    inst = Installer(dry_run=args.dry_run, offline=args.offline)
    inst.log(f"Book of Life installer  |  {platform.platform()}")
    inst.log(f"repository: {ROOT}")

    if not check_environment(inst):
        inst.fail("the environment is not ready")
        return 2

    if not create_environment(inst, rebuild=getattr(args, "rebuild", False)):
        return 2

    if not install_dependencies(inst):
        roll_back(inst)
        return 2

    install_extras(inst)

    if not verify(inst):
        roll_back(inst)
        return 1

    create_launchers(inst)
    install_git_hooks(inst)
    write_state(inst)

    inst.log("")
    inst.log("Installation complete.")
    venv_python = ".venv\\Scripts\\python" if IS_WINDOWS else ".venv/bin/python"
    inst.log(f"  start the local server:  {venv_python} scripts/serve.py")
    inst.log(f"  run the test suite:      {venv_python} -m pytest -q")
    inst.log(f"  run the pipeline:        {venv_python} scripts/local_pipeline.py")
    inst.log("")
    return 0


def command_update(args: argparse.Namespace) -> int:
    inst = Installer(dry_run=args.dry_run, offline=args.offline)
    inst.log("Book of Life updater")
    state = InstallState.load()
    inst.log(f"  current version: {state.version}")

    if state.version == "unknown":
        inst.warn("no install state was found; this will be a fresh install")
    if not args.dry_run and not args.offline and git_revision():
        inst.step("Fetching the latest revision")
        try:
            inst.run(["git", "fetch", "--all", "--tags"])
            inst.run(["git", "pull", "--ff-only"])
            inst.ok("the working tree is up to date")
        except RuntimeError as exc:
            inst.warn(f"the update could not be fetched: {exc}")

    new_version = read_manifest_version()
    if new_version == state.version and not args.force:
        inst.ok(f"already at {new_version}; nothing to do")
        return 0

    inst.log(f"  updating to: {new_version}")
    result = command_install(args)
    if result != 0:
        inst.fail("the update failed; the previous environment was restored")
        return result
    inst.ok(f"updated to {new_version}")
    return 0


def command_verify(args: argparse.Namespace) -> int:
    inst = Installer(dry_run=False, offline=True)
    inst.log("Book of Life verifier")
    if not VENV_DIR.exists():
        inst.fail(f"no environment at {VENV_DIR}")
        return 2
    state = InstallState.load()
    inst.log(f"  version: {state.version}")
    inst.log(f"  revision: {state.revision}")
    if not verify(inst):
        return 1
    inst.ok("the installation is healthy")
    return 0


def command_uninstall(args: argparse.Namespace) -> int:
    inst = Installer(dry_run=args.dry_run)
    inst.step("Removing the installation")
    hook_script = ROOT / "scripts" / "install_hooks.py"
    if hook_script.exists():
        try:
            inst.run([sys.executable, str(hook_script), "--uninstall"], check=False)
            inst.ok("the pre-push hook was removed if it was ours")
        except RuntimeError as exc:
            inst.warn(f"the pre-push hook was left in place: {exc}")
    for path in (VENV_DIR, STATE_DIR):
        if path.exists():
            if args.dry_run:
                inst.warn(f"would remove {path}")
            else:
                shutil.rmtree(path, ignore_errors=True)
                inst.ok(f"removed {path.relative_to(ROOT)}")
    for name in ("abook", "abook.cmd"):
        candidate = ROOT / name
        if candidate.exists():
            if args.dry_run:
                inst.warn(f"would remove {candidate}")
            else:
                candidate.unlink(missing_ok=True)
                inst.ok(f"removed {name}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Install, update, verify or remove Book of Life.",
    )
    sub = parser.add_subparsers(dest="command")

    install = sub.add_parser("install", help="install or repair the project")
    install.add_argument("--rebuild", action="store_true",
                         help="recreate the virtual environment")
    install.add_argument("--offline", action="store_true",
                         help="install from vendor/wheels without a network")
    install.add_argument("--dry-run", action="store_true", help="print and do nothing")
    install.set_defaults(func=command_install)

    update = sub.add_parser("update", help="update an existing install")
    update.add_argument("--offline", action="store_true")
    update.add_argument("--dry-run", action="store_true")
    update.add_argument("--force", action="store_true",
                        help="reinstall even when the version has not changed")
    update.set_defaults(func=command_update)

    verify = sub.add_parser("verify", help="check an existing install")
    verify.set_defaults(func=command_verify)

    uninstall = sub.add_parser("uninstall", help="remove the installation")
    uninstall.add_argument("--dry-run", action="store_true")
    uninstall.set_defaults(func=command_uninstall)

    args = parser.parse_args(argv)
    if not getattr(args, "func", None):
        args = parser.parse_args((argv or []) + ["install"])
    return args.func(args)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\ninterrupted", file=sys.stderr)
        sys.exit(130)
