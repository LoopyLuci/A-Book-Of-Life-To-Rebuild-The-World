"""Runtime translations for the desktop application.

The user interface strings live in the repository, in
``i18n/strings/<lang>.yaml``; ``en.yaml`` is the canonical catalogue.  The
reader loads the catalogue of the selected language and falls back to English
when a language file is missing, unreadable or incomplete, so the application
always starts even when a translation has been removed.

The nine languages the application offers are listed in
:data:`CANONICAL_LANGUAGES`.  A language is only offered when its catalogue
file exists on disk.
"""

from __future__ import annotations

import logging
from collections.abc import Mapping
from pathlib import Path
from typing import Any

from .corpus import parse_yaml_text

LOGGER = logging.getLogger(__name__)

__all__ = [
    "CANONICAL_LANGUAGES",
    "DEFAULT_STRINGS",
    "LANGUAGE_NAMES",
    "Translator",
]

#: The languages the application offers, in the order they are listed.
CANONICAL_LANGUAGES: tuple[str, ...] = ("en", "es", "fr", "de", "pt", "hi", "ar", "sw", "zh")

#: The name of every language, written in that language.
LANGUAGE_NAMES: Mapping[str, str] = {
    "en": "English",
    "es": "Español",
    "fr": "Français",
    "de": "Deutsch",
    "pt": "Português",
    "hi": "हिन्दी",
    "ar": "العربية",
    "sw": "Kiswahili",
    "zh": "中文",
    "it": "Italiano",
}

#: The English strings the application needs, used when no catalogue can be
#: read at all.  The keys mirror ``i18n/strings/en.yaml``.
DEFAULT_STRINGS: Mapping[str, str] = {
    "site_name": "A Book Of Life To Rebuild The World",
    "tagline": "An offline-first knowledge base for rebuilding civilization.",
    "search_placeholder": "Search {count} entries…",
    "domains": "Domains",
    "entries": "Entries",
    "difficulty": "Difficulty",
    "difficulty_novice": "Novice",
    "difficulty_apprentice": "Apprentice",
    "difficulty_journeyman": "Journeyman",
    "difficulty_master": "Master",
    "safety": "Safety",
    "time_to_complete": "Time to complete",
    "prerequisites": "Prerequisites",
    "materials": "Materials & Tools",
    "procedure": "Procedure",
    "safety_notes": "Safety Notes",
    "verification": "Verification",
    "sources": "Sources",
    "status_draft": "Draft",
    "status_peer_reviewed": "Peer-Reviewed",
    "status_field_tested": "Field-Tested",
    "status_deprecated": "Deprecated",
    "safety_green": "Safe",
    "safety_yellow": "Caution",
    "safety_red": "Danger",
    "app_title": "A Book Of Life — Desktop Reader",
    "search": "Search",
    "filter_domain": "Domain",
    "filter_safety": "Safety",
    "all_domains": "All domains",
    "all_safety_levels": "All safety levels",
    "language": "Language",
    "theme": "Theme",
    "theme_light": "Light",
    "theme_dark": "Dark",
    "about": "About",
    "version": "Version",
    "close": "Close",
    "ok": "OK",
    "recently_read": "Recently read",
    "results": "Results",
    "no_results": "No matching entries",
    "result_count": "{count} results",
    "entry_count": "{count} entries",
    "loading": "Loading the corpus…",
    "loading_progress": "Loading {done} of {total} entries…",
    "loading_failed": "The corpus could not be loaded: {error}",
    "ready": "Ready",
    "index_source": "Index: {source}",
    "index_source_db": "build/index.db",
    "index_source_scan": "corpus scan",
    "quick_jump": "Quick jump",
    "quick_jump_hint": "Type a title, slug or tag…",
    "clear": "Clear",
    "select_entry": "Select an entry to read it.",
    "domain_overview": "Domain overview",
    "tags": "Tags",
    "path": "Path",
    "disclaimer": "Disclaimer",
    "disclaimer_acknowledge": "I have read and understood the disclaimer.",
    "disclaimer_required": "Tick the box to acknowledge the disclaimer.",
    "disclaimer_full": "The full disclaimer is in docs/DISCLAIMER.md.",
    "shortcuts": "Shortcuts",
    "shortcut_search": "Ctrl+F — focus search",
    "shortcut_jump": "Ctrl+K — quick jump",
    "shortcut_about": "F1 — about",
    "shortcut_quit": "Ctrl+Q — quit",
    "domain_entry_count": "{count} entries in this domain",
}


def _stringify(value: Any) -> str:
    """Coerce a catalogue value into a plain string."""
    if value is None:
        return ""
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


class Translator:
    """The catalogue of one language, with an English fallback.

    Args:
        strings_dir: The directory that holds ``<lang>.yaml`` catalogues.
        language: The language to load first.
        fallback_language: The language used when the requested one is
            unavailable.
    """

    def __init__(
        self,
        strings_dir: Path,
        language: str = "en",
        fallback_language: str = "en",
    ) -> None:
        self._strings_dir = Path(strings_dir)
        self._fallback_language = fallback_language
        self._fallback_strings = self._load_catalogue(fallback_language)
        self._strings: dict[str, str] = {}
        self._language = fallback_language
        self.set_language(language)

    # ------------------------------------------------------------------
    # Loading
    # ------------------------------------------------------------------
    def _load_catalogue(self, language: str) -> dict[str, str]:
        """Read the catalogue of *language*, returning an empty mapping on failure."""
        path = self._strings_dir / f"{language}.yaml"
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            LOGGER.warning("no catalogue for %s at %s", language, path)
            return {}
        try:
            data = parse_yaml_text(text)
        except Exception:  # noqa: BLE001 - a broken catalogue must not stop the app
            LOGGER.exception("could not parse the catalogue for %s", language)
            return {}
        if not isinstance(data, Mapping):
            LOGGER.warning("the catalogue for %s is not a mapping", language)
            return {}
        return {str(key): _stringify(value) for key, value in data.items()}

    def set_language(self, language: str) -> bool:
        """Switch to *language*.

        Args:
            language: The language code, e.g. ``"fr"``.

        Returns:
            ``True`` when the requested catalogue was loaded, ``False`` when the
            fallback language was used instead.
        """
        catalogue = self._load_catalogue(language)
        if not catalogue and language != self._fallback_language:
            LOGGER.warning("falling back to %s", self._fallback_language)
            self._language = self._fallback_language
            self._strings = dict(self._fallback_strings)
            return False
        self._language = language
        self._strings = catalogue
        return True

    # ------------------------------------------------------------------
    # Access
    # ------------------------------------------------------------------
    @property
    def language(self) -> str:
        """Return the language code that is currently active."""
        return self._language

    @property
    def strings_dir(self) -> Path:
        """Return the directory the catalogues are read from."""
        return self._strings_dir

    def t(self, key: str, **params: Any) -> str:
        """Return the string for *key*.

        The current language wins, then the fallback language, then the built-in
        English defaults, and finally the key itself so that a missing string
        is visible but never fatal.

        Args:
            key: The catalogue key.
            **params: Values for the ``{placeholder}`` fields of the string.

        Returns:
            The translated string.
        """
        value = self._strings.get(key)
        if value is None:
            value = self._fallback_strings.get(key)
        if value is None:
            value = DEFAULT_STRINGS.get(key)
        if value is None:
            return key
        if params:
            try:
                return value.format(**params)
            except (KeyError, IndexError, ValueError):
                LOGGER.debug("could not interpolate %s", key)
                return value
        return value

    def available_languages(self) -> tuple[str, ...]:
        """Return the languages that can be selected.

        A language is offered when its catalogue file exists; the canonical
        order is preserved and any extra language is appended alphabetically.
        """
        found: list[str] = []
        try:
            for path in self._strings_dir.glob("*.yaml"):
                code = path.stem.lower()
                if code not in found:
                    found.append(code)
        except OSError:  # pragma: no cover - defensive
            return (self._fallback_language,)
        ordered = [code for code in CANONICAL_LANGUAGES if code in found]
        ordered.extend(sorted(code for code in found if code not in CANONICAL_LANGUAGES))
        if self._fallback_language not in ordered:
            ordered.insert(0, self._fallback_language)
        return tuple(ordered)

    def language_name(self, language: str) -> str:
        """Return the display name of *language*."""
        return LANGUAGE_NAMES.get(language, language)
