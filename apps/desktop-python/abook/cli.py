"""The command line interface of the desktop reader.

The application is normally started through ``abook.py`` in the parent
directory, but this module is importable so that it can also be installed as
a console script and started with ``python -m abook``.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from . import __version__, configure_logging
from .corpus import find_repo_root, load_corpus, load_disclaimer
from .i18n import Translator
from .search import SearchEngine
from .settings import Settings
from .theme import THEMES

__all__ = ["build_parser", "main", "run_gui", "run_selftest"]

LOGGER = configure_logging()


def build_parser() -> argparse.ArgumentParser:
    """Return the command line parser of the application."""
    parser = argparse.ArgumentParser(
        prog="abook",
        description="Offline desktop reader for the A Book Of Life knowledge base.",
    )
    parser.add_argument(
        "--selftest",
        action="store_true",
        help="run the built-in checks and exit without opening a window",
    )
    parser.add_argument(
        "--version",
        action="store_true",
        help="print the application version and exit",
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=None,
        help="the repository root (discovered automatically by default)",
    )
    parser.add_argument(
        "--lang",
        default=None,
        help="the interface language, e.g. fr (uses the saved preference by default)",
    )
    parser.add_argument(
        "--theme",
        choices=list(THEMES),
        default=None,
        help="the colour theme (uses the saved preference by default)",
    )
    return parser


def run_selftest(root: Path | None = None) -> int:
    """Run the built-in checks and print a short report.

    Args:
        root: The repository root, discovered automatically when omitted.

    Returns:
        The process exit code: ``0`` when every check passed.
    """
    failures: list[str] = []

    def check(name: str, condition: bool, detail: str = "") -> None:
        """Record the outcome of one check."""
        marker = "ok  " if condition else "FAIL"
        line = f"  [{marker}] {name}"
        if detail:
            line = f"{line} - {detail}"
        print(line)
        if not condition:
            failures.append(name)

    print("abook desktop self-test")
    print(f"  version: {__version__}")

    try:
        repo = Path(root).resolve() if root is not None else find_repo_root()
    except FileNotFoundError as error:
        print(f"  [FAIL] repository - {error}")
        return 1
    print(f"  repository: {repo}")
    check("repository found", True)

    corpus = load_corpus(repo)
    check("corpus loaded", len(corpus) > 0, f"{len(corpus)} entries from {corpus.source}")
    check("domains known", len(corpus.domains) == 16, f"{len(corpus.domains)} domains")
    check(
        "every entry has metadata",
        all(entry.title and entry.domain and entry.id for entry in corpus.entries),
    )

    engine = SearchEngine(corpus)
    results = engine.search("water purification", limit=50)
    check("search finds entries", bool(results), f"{len(results)} results")
    if results:
        check(
            "title matches rank first",
            results[0].entry.title.lower().startswith("water purification"),
            f"best: {results[0].entry.title}",
        )
    filtered = engine.search("aid", domain="survival")
    check(
        "search honours the domain filter",
        all(result.entry.domain == "survival" for result in filtered),
        f"{len(filtered)} results",
    )

    strings_dir = repo / "i18n" / "strings"
    translator = Translator(strings_dir, "en")
    english = translator.t("site_name")
    translator.set_language("zz")
    check(
        "language fallback",
        translator.language == "en" and translator.t("site_name") == english,
        f"fell back to {translator.language}",
    )
    translator.set_language("fr")
    check("translation loaded", translator.t("site_name") != "", translator.t("site_name"))
    check(
        "languages offered",
        len(translator.available_languages()) >= 9,
        ", ".join(translator.available_languages()),
    )

    disclaimer = load_disclaimer(repo)
    check("disclaimer available", bool(disclaimer), f"{len(disclaimer)} characters")

    check(
        "version matches the manifest",
        corpus.version == __version__,
        f"{corpus.version} vs {__version__}",
    )

    if failures:
        print(f"\n{len(failures)} check(s) failed: {', '.join(failures)}")
        return 1
    print("\nall checks passed")
    return 0


def run_gui(
    root: Path | None = None, language: str | None = None, theme: str | None = None
) -> int:
    """Open the application window.

    Args:
        root: The repository root, discovered automatically when omitted.
        language: The interface language, or ``None`` to use the saved one.
        theme: The colour theme, or ``None`` to use the saved one.

    Returns:
        The process exit code.
    """
    try:
        repo = Path(root).resolve() if root is not None else find_repo_root()
    except FileNotFoundError as error:
        print(f"abook: {error}", file=sys.stderr)
        return 2

    settings = Settings.load()
    if language:
        settings.language = language
    if theme:
        settings.theme = theme

    translator = Translator(repo / "i18n" / "strings", settings.language)
    settings.language = translator.language

    from .ui import AbookApp

    app = AbookApp(repo, settings, translator)
    app.mainloop()
    return 0


def main(argv: list[str] | None = None) -> int:
    """Run the application.

    Args:
        argv: The command line arguments.  Defaults to ``sys.argv[1:]``.

    Returns:
        The process exit code.
    """
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.version:
        print(__version__)
        return 0
    if args.selftest:
        return run_selftest(args.root)
    return run_gui(args.root, args.lang, args.theme)
