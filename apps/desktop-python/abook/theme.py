"""Colour palettes for the light and dark themes.

The palettes are plain data: every widget in the user interface is styled from
a :class:`Palette`, so switching the theme is a matter of re-applying one.
"""

from __future__ import annotations

from dataclasses import dataclass

__all__ = ["DARK_THEME", "LIGHT_THEME", "Palette", "THEMES", "get_palette"]


@dataclass(frozen=True)
class Palette:
    """The colours of one theme."""

    name: str
    background: str
    panel: str
    foreground: str
    muted: str
    accent: str
    accent_foreground: str
    border: str
    selection: str
    selection_foreground: str
    danger: str
    warning: str
    success: str
    code_background: str
    link: str
    quote: str


LIGHT_THEME = Palette(
    name="light",
    background="#f7f7f5",
    panel="#ffffff",
    foreground="#1c1c1a",
    muted="#6b6b66",
    accent="#1f6f8b",
    accent_foreground="#ffffff",
    border="#d6d6d0",
    selection="#cfe3ec",
    selection_foreground="#10262f",
    danger="#a4232b",
    warning="#8a6100",
    success="#2f6b32",
    code_background="#f2f2ef",
    link="#1f6f8b",
    quote="#5b5b56",
)

DARK_THEME = Palette(
    name="dark",
    background="#16181b",
    panel="#1e2126",
    foreground="#e6e6e1",
    muted="#9a9a94",
    accent="#6fb6d4",
    accent_foreground="#0d1114",
    border="#333840",
    selection="#274b5c",
    selection_foreground="#eaf4f8",
    danger="#e0737a",
    warning="#d9a441",
    success="#77bd7c",
    code_background="#1b1e22",
    link="#6fb6d4",
    quote="#a3a39c",
)

#: The themes the application offers.
THEMES: tuple[str, ...] = ("light", "dark")


def get_palette(theme: str) -> Palette:
    """Return the palette of *theme*.

    Args:
        theme: Either ``"light"`` or ``"dark"``.  Unknown values fall back to
            the light theme.

    Returns:
        The matching palette.
    """
    if theme == "dark":
        return DARK_THEME
    return LIGHT_THEME
