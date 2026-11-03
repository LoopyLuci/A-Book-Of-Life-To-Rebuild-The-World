"""Offline desktop reader for the *A Book Of Life To Rebuild The World* corpus.

The package is deliberately dependency free: everything it needs at runtime is
part of CPython 3.11 (``tkinter``, ``sqlite3``, ``tomllib``, ``logging``).
The knowledge base is read straight from the repository checkout -- the
Markdown bodies in ``domains/`` and the metadata sidecars in ``sidecars/`` --
so the application never needs the network.

Modules:
    :mod:`abook.corpus`
        Locate the repository and load sidecars plus Markdown bodies.
    :mod:`abook.search`
        BM25-flavoured ranking over titles, tags and bodies.
    :mod:`abook.i18n`
        Runtime translations loaded from ``i18n/strings/<lang>.yaml``.
    :mod:`abook.theme`
        Light and dark colour palettes.
    :mod:`abook.settings`
        Persisted user preferences.
    :mod:`abook.ui`
        The tkinter user interface.
"""

from __future__ import annotations

import logging
import os
from pathlib import Path

__all__ = [
    "APP_NAME",
    "DEFAULT_VERSION",
    "LOG_FILE_NAME",
    "__version__",
    "configure_logging",
    "log_dir",
    "repo_root",
]

#: The distribution name of the application.
APP_NAME = "abook-desktop"

#: Fallback version, used when no ``manifest.toml`` can be found.
DEFAULT_VERSION = "0.1.0-alpha"

#: Name of the log file written under :func:`log_dir`.
LOG_FILE_NAME = "abook.log"

#: Name of the directory that holds the log file and the settings file.
STATE_DIR_NAME = ".abook-desktop"


def _find_manifest(start: Path) -> Path | None:
    """Walk up from *start* looking for a ``manifest.toml``."""
    for directory in (start, *start.parents):
        candidate = directory / "manifest.toml"
        if candidate.is_file():
            return candidate
    return None


def repo_root(start: Path | None = None) -> Path | None:
    """Return the repository root, i.e. the directory holding ``manifest.toml``.

    The search starts at *start* (the caller's file by default) and walks up
    towards the filesystem root, so the application works no matter which
    working directory it was launched from.

    Args:
        start: The file or directory to start from.  Defaults to this module.

    Returns:
        The repository root, or ``None`` when no manifest was found.
    """
    candidates: list[Path] = []
    if start is not None:
        candidates.append(Path(start).resolve())
    candidates.append(Path(__file__).resolve())
    for candidate in candidates:
        base = candidate if candidate.is_dir() else candidate.parent
        manifest = _find_manifest(base)
        if manifest is not None:
            return manifest.parent
    return None


def _read_manifest_version() -> str:
    """Read ``project.version`` from the repository manifest."""
    root = repo_root()
    if root is None:
        return DEFAULT_VERSION
    try:
        import tomllib

        with (root / "manifest.toml").open("rb") as handle:
            manifest = tomllib.load(handle)
    except (OSError, ValueError):  # pragma: no cover - defensive
        return DEFAULT_VERSION
    version = manifest.get("project", {}).get("version")
    if isinstance(version, str) and version:
        return version
    return DEFAULT_VERSION


#: The application version, taken from ``manifest.toml`` when it is available.
__version__ = _read_manifest_version()


def log_dir() -> Path:
    """Return the directory that holds the log file and the saved settings.

    The location can be overridden with the ``ABOOK_HOME`` environment
    variable, which is useful for tests and portable installs.
    """
    override = os.environ.get("ABOOK_HOME")
    if override:
        return Path(override).expanduser()
    return Path.home() / STATE_DIR_NAME


def configure_logging(level: int = logging.INFO) -> logging.Logger:
    """Configure the application logger to write to a file, never to the console.

    The log lives next to the saved settings so that a GUI run leaves no
    trace in the terminal that started it.

    Args:
        level: The minimum level that is written to the log file.

    Returns:
        The configured ``abook`` logger.
    """
    logger = logging.getLogger("abook")
    logger.setLevel(level)
    logger.propagate = False
    if logger.handlers:
        return logger
    try:
        directory = log_dir()
        directory.mkdir(parents=True, exist_ok=True)
        handler: logging.Handler = logging.FileHandler(
            directory / LOG_FILE_NAME, encoding="utf-8"
        )
    except OSError:  # pragma: no cover - read-only home directories
        handler = logging.NullHandler()
    else:
        handler.setFormatter(
            logging.Formatter("%(asctime)s %(levelname)-8s %(name)s: %(message)s")
        )
    logger.addHandler(handler)
    return logger
