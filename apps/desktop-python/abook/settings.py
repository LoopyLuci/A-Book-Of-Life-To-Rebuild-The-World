"""Persisted user preferences.

The preferences -- the language, the theme, the window geometry and the list
of recently read entries -- are stored as a small JSON document under the
user's home directory, next to the application log.  A missing or corrupt
file is not an error: the defaults are used instead.
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from . import log_dir

LOGGER = logging.getLogger(__name__)

__all__ = ["MAX_RECENT", "SETTINGS_FILENAME", "Settings"]

#: The name of the settings file.
SETTINGS_FILENAME = "settings.json"

#: How many entries the "recently read" list keeps.
MAX_RECENT = 25

#: The default window size.
DEFAULT_WIDTH = 1280
DEFAULT_HEIGHT = 820


@dataclass
class Settings:
    """The preferences of one user."""

    language: str = "en"
    theme: str = "light"
    window_width: int = DEFAULT_WIDTH
    window_height: int = DEFAULT_HEIGHT
    window_x: int | None = None
    window_y: int | None = None
    recently_read: list[str] = field(default_factory=list)

    # ------------------------------------------------------------------
    # Persistence
    # ------------------------------------------------------------------
    @classmethod
    def default_path(cls) -> Path:
        """Return the path of the settings file."""
        return log_dir() / SETTINGS_FILENAME

    @classmethod
    def load(cls, path: Path | None = None) -> Settings:
        """Load the preferences, falling back to the defaults.

        Args:
            path: The settings file.  Defaults to :meth:`default_path`.

        Returns:
            The stored preferences, or the defaults when the file is missing or
            cannot be understood.
        """
        target = Path(path) if path is not None else cls.default_path()
        try:
            raw = target.read_text(encoding="utf-8")
        except OSError:
            return cls()
        try:
            data = json.loads(raw)
        except ValueError:
            LOGGER.warning("the settings file %s is corrupt, using the defaults", target)
            return cls()
        if not isinstance(data, dict):
            LOGGER.warning("the settings file %s is not an object, using the defaults", target)
            return cls()
        return cls.from_mapping(data)

    @classmethod
    def from_mapping(cls, data: dict[str, Any]) -> Settings:
        """Build the preferences from a parsed JSON object."""
        settings = cls()
        language = data.get("language")
        if isinstance(language, str) and language:
            settings.language = language
        theme = data.get("theme")
        if isinstance(theme, str) and theme:
            settings.theme = theme
        width = data.get("window_width")
        if isinstance(width, int) and width > 0:
            settings.window_width = width
        height = data.get("window_height")
        if isinstance(height, int) and height > 0:
            settings.window_height = height
        for name in ("window_x", "window_y"):
            value = data.get(name)
            if isinstance(value, int):
                setattr(settings, name, value)
        recent = data.get("recently_read")
        if isinstance(recent, list):
            settings.recently_read = [item for item in recent if isinstance(item, str)]
        return settings

    def save(self, path: Path | None = None) -> None:
        """Write the preferences to disk.

        Failures are logged but never raised: losing the window size is not
        worth interrupting the application for.

        Args:
            path: The settings file.  Defaults to :meth:`default_path`.
        """
        target = Path(path) if path is not None else self.default_path()
        payload = {
            "language": self.language,
            "theme": self.theme,
            "window_width": self.window_width,
            "window_height": self.window_height,
            "window_x": self.window_x,
            "window_y": self.window_y,
            "recently_read": list(self.recently_read),
        }
        try:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        except OSError:
            LOGGER.warning("could not write the settings to %s", target)

    # ------------------------------------------------------------------
    # Recently read
    # ------------------------------------------------------------------
    def remember_entry(self, entry_id: str) -> None:
        """Put *entry_id* at the top of the recently read list."""
        if not entry_id:
            return
        self.recently_read = [entry_id] + [
            item for item in self.recently_read if item != entry_id
        ]
        del self.recently_read[MAX_RECENT:]

    def forget_entry(self, entry_id: str) -> None:
        """Remove *entry_id* from the recently read list."""
        self.recently_read = [item for item in self.recently_read if item != entry_id]
