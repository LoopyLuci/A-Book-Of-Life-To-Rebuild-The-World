"""A small, dependency-free YAML reader for the subset used by this repository.

The knowledge base stores its metadata in YAML (``sidecars/**.pnk.yaml`` and
``i18n/strings/*.yaml``).  The desktop application must run without installing
anything, so this module implements the narrow subset of YAML that the corpus
actually uses.  The subset mirrors the one already implemented for the web
application in ``apps/web-ts/scripts/lib/yaml.mjs``:

* block mappings (``key: value``), including nested mappings,
* block sequences (``- item``), both indented under their key and at the same
  indentation as their key,
* sequences of mappings (``- title: X`` followed by ``  license: Y``),
* flow sequences (``[a, b, c]``) and flow mappings (``{a: 1}``),
* plain, single-quoted and double-quoted scalars,
* ``null`` / ``~``, booleans, integers and floats,
* whole-line and trailing ``#`` comments.

Anything outside that subset raises :class:`YamlParseError` rather than
silently producing a wrong value, so the caller can fall back to PyYAML when
that library happens to be installed.
"""

from __future__ import annotations

import re
from collections.abc import Mapping
from dataclasses import dataclass
from typing import Any

__all__ = ["YamlParseError", "parse_yaml", "parse_yaml_mapping"]

#: A plain (unquoted) mapping key, e.g. ``time_to_complete``.
PLAIN_KEY = re.compile(r"^[A-Za-z_][A-Za-z0-9_.-]*$")

_INTEGER = re.compile(r"^-?\d+$")
_FLOAT = re.compile(r"^-?(?:\d+\.\d*|\.\d+)$")


class YamlParseError(ValueError):
    """Raised when the input is not valid for the supported YAML subset."""


@dataclass(frozen=True)
class _Line:
    """One significant (non-blank, non-comment) line of a document."""

    indent: int
    text: str
    raw: str
    number: int


@dataclass
class _State:
    """The mutable cursor used while walking the lines of a document."""

    index: int


def parse_yaml(source: str) -> Any:
    """Parse a YAML document from the supported subset.

    Args:
        source: The document text.

    Returns:
        The parsed value: a mapping, a sequence, a scalar or ``None``.

    Raises:
        YamlParseError: If the document uses an unsupported construct.
    """
    lines = _read_lines(source)
    if not lines:
        return None
    state = _State(0)
    value = _parse_block(lines, state, lines[0].indent)
    if state.index < len(lines):
        raise YamlParseError(f'unexpected content "{lines[state.index].text}"')
    return value


def parse_yaml_mapping(source: str) -> dict[str, Any]:
    """Parse a YAML document and assert that the result is a mapping.

    Args:
        source: The document text.

    Returns:
        The mapping at the document root.

    Raises:
        YamlParseError: If the root of the document is not a mapping.
    """
    value = parse_yaml(source)
    if not isinstance(value, Mapping):
        raise YamlParseError("expected a mapping at the document root")
    return dict(value)


def _read_lines(source: str) -> list[_Line]:
    """Split a document into its significant lines."""
    lines: list[_Line] = []
    for number, raw in enumerate(source.splitlines(), start=1):
        if not raw.strip():
            continue
        text = _strip_comment(raw).strip()
        if not text:
            continue
        if text.startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        lines.append(_Line(indent=indent, text=text, raw=raw.rstrip(), number=number))
    return lines


def _strip_comment(raw: str) -> str:
    """Remove a trailing ``#`` comment that is not inside a quoted scalar."""
    out: list[str] = []
    quote = ""
    index = 0
    while index < len(raw):
        char = raw[index]
        if quote:
            out.append(char)
            if quote == '"' and char == "\\" and index + 1 < len(raw):
                out.append(raw[index + 1])
                index += 2
                continue
            if char == quote:
                quote = ""
        elif char in "\"'":
            quote = char
            out.append(char)
        elif char == "#" and (not out or out[-1] in " \t"):
            break
        else:
            out.append(char)
        index += 1
    return "".join(out)


def _parse_block(lines: list[_Line], state: _State, indent: int) -> Any:
    """Parse whatever block starts at the current line."""
    line = lines[state.index]
    if _is_sequence_item(line.text):
        return _parse_sequence(lines, state, indent)
    if _split_key(line.text) is not None:
        return _parse_mapping(lines, state, indent)
    state.index += 1
    return _parse_scalar(line.text)


def _is_sequence_item(text: str) -> bool:
    """Return ``True`` when *text* starts a block sequence item."""
    return text == "-" or text.startswith("- ")


def _parse_mapping(lines: list[_Line], state: _State, indent: int) -> dict[str, Any]:
    """Parse a block mapping at *indent*."""
    mapping: dict[str, Any] = {}
    while state.index < len(lines):
        line = lines[state.index]
        if line.indent < indent:
            break
        if line.indent > indent:
            raise YamlParseError(f'unexpected indentation in "{line.text}"')
        if _is_sequence_item(line.text):
            break
        parts = _split_key(line.text)
        if parts is None:
            raise YamlParseError(f'expected "key: value" but found "{line.text}"')
        state.index += 1
        key, rest = parts
        mapping[key] = (
            _parse_child_block(lines, state, indent)
            if rest == ""
            else _parse_scalar(rest)
        )
    return mapping


def _parse_child_block(lines: list[_Line], state: _State, parent_indent: int) -> Any:
    """Parse the value that belongs to a key whose value starts on the next line."""
    if state.index >= len(lines):
        return None
    nxt = lines[state.index]
    if nxt.indent > parent_indent:
        return _parse_block(lines, state, nxt.indent)
    # YAML also allows a sequence to sit at the same indentation as its key.
    if nxt.indent == parent_indent and _is_sequence_item(nxt.text):
        return _parse_sequence(lines, state, nxt.indent)
    return None


def _parse_sequence(lines: list[_Line], state: _State, indent: int) -> list[Any]:
    """Parse a block sequence at *indent*."""
    items: list[Any] = []
    while state.index < len(lines):
        line = lines[state.index]
        if line.indent != indent or not _is_sequence_item(line.text):
            break
        content_column = _dash_content_column(line)
        rest = "" if line.text == "-" else line.text[2:].strip()
        state.index += 1
        if rest == "":
            items.append(_parse_child_block(lines, state, indent))
            continue
        parts = _split_key(rest)
        if parts is not None and PLAIN_KEY.match(parts[0]):
            items.append(_parse_inline_mapping(lines, state, content_column, parts))
            continue
        items.append(_parse_scalar(rest))
    return items


def _dash_content_column(line: _Line) -> int:
    """Column at which the content of a ``-`` item starts."""
    column = line.indent + 1
    while column < len(line.raw) and line.raw[column] == " ":
        column += 1
    return column


def _parse_inline_mapping(
    lines: list[_Line], state: _State, indent: int, first: tuple[str, str]
) -> dict[str, Any]:
    """Parse a mapping whose first key was written on the ``-`` line itself."""
    mapping: dict[str, Any] = {}
    key, rest = first
    mapping[key] = (
        _parse_child_block(lines, state, indent)
        if rest == ""
        else _parse_scalar(rest)
    )
    while state.index < len(lines):
        line = lines[state.index]
        if line.indent != indent or _is_sequence_item(line.text):
            break
        parts = _split_key(line.text)
        if parts is None:
            raise YamlParseError(f'expected "key: value" but found "{line.text}"')
        state.index += 1
        key, rest = parts
        mapping[key] = (
            _parse_child_block(lines, state, indent)
            if rest == ""
            else _parse_scalar(rest)
        )
    return mapping


def _split_key(text: str) -> tuple[str, str] | None:
    """Split ``key: value`` into its parts.

    Returns ``None`` when the text is not a mapping entry.  A colon only
    separates a key from a value when it is followed by a space or ends the
    line, which keeps identifiers such as ``pnk:01HZX0K8J9Q7R3VY6T2M4B8N1W``
    intact.
    """
    if text.startswith('"') or text.startswith("'"):
        return None
    for position, char in enumerate(text):
        if char != ":":
            continue
        if position == len(text) - 1:
            return text[:position].strip(), ""
        if text[position + 1] == " ":
            return text[:position].strip(), text[position + 2 :].strip()
    return None


def _parse_scalar(text: str) -> Any:
    """Parse a scalar or a flow collection."""
    text = text.strip()
    if text == "":
        return None
    if len(text) >= 2 and text.startswith('"') and text.endswith('"'):
        return _unescape_double_quoted(text[1:-1])
    if len(text) >= 2 and text.startswith("'") and text.endswith("'"):
        return text[1:-1].replace("''", "'")
    if text.startswith("["):
        return _parse_flow_sequence(text)
    if text.startswith("{"):
        return _parse_flow_mapping(text)
    if text in ("null", "~"):
        return None
    if text == "true":
        return True
    if text == "false":
        return False
    if _INTEGER.match(text):
        return int(text)
    if _FLOAT.match(text):
        return float(text)
    return text


def _parse_flow_sequence(text: str) -> list[Any]:
    """Parse a flow sequence such as ``[a, b, c]``."""
    if not text.endswith("]"):
        raise YamlParseError("unterminated flow sequence")
    inner = text[1:-1].strip()
    if inner == "":
        return []
    return [_parse_scalar(item) for item in _split_flow_items(inner)]


def _parse_flow_mapping(text: str) -> dict[str, Any]:
    """Parse a flow mapping such as ``{a: 1}``."""
    if not text.endswith("}"):
        raise YamlParseError("unterminated flow mapping")
    inner = text[1:-1].strip()
    mapping: dict[str, Any] = {}
    if inner == "":
        return mapping
    for item in _split_flow_items(inner):
        parts = _split_key(item.strip())
        if parts is None:
            raise YamlParseError('expected "key: value" in flow mapping')
        mapping[parts[0]] = _parse_scalar(parts[1])
    return mapping


def _split_flow_items(inner: str) -> list[str]:
    """Split a flow collection body on the commas that separate its items."""
    items: list[str] = []
    current: list[str] = []
    depth = 0
    quote = ""
    for char in inner:
        if quote:
            current.append(char)
            if char == quote:
                quote = ""
            continue
        if char in "\"'":
            quote = char
            current.append(char)
            continue
        if char in "[{":
            depth += 1
        elif char in "]}":
            depth -= 1
        if char == "," and depth == 0:
            items.append("".join(current).strip())
            current = []
            continue
        current.append(char)
    items.append("".join(current).strip())
    return items


def _unescape_double_quoted(value: str) -> str:
    """Expand the escape sequences of a double-quoted scalar."""
    out: list[str] = []
    index = 0
    while index < len(value):
        char = value[index]
        if char != "\\":
            out.append(char)
            index += 1
            continue
        index += 1
        if index >= len(value):
            out.append("\\")
            break
        nxt = value[index]
        index += 1
        if nxt == "n":
            out.append("\n")
        elif nxt == "t":
            out.append("\t")
        elif nxt == "r":
            out.append("\r")
        elif nxt == "0":
            out.append("\0")
        elif nxt == '"':
            out.append('"')
        elif nxt == "\\":
            out.append("\\")
        elif nxt == "/":
            out.append("/")
        elif nxt == "u" and index + 4 <= len(value):
            out.append(chr(int(value[index : index + 4], 16)))
            index += 4
        else:
            out.append(nxt)
    return "".join(out)
