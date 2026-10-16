"""pnk:// URI parsing and construction."""

from __future__ import annotations

from dataclasses import dataclass
from urllib.parse import quote, unquote, urlparse

PNK_SCHEME = "pnk"


@dataclass(frozen=True)
class PnkUri:
    """A parsed pnk:// URI.

    Two forms are supported:

    1. Entry URI:  pnk://<node_id>/<domain>/<slug>
    2. Bare PNK:   pnk:<ulid>/<domain>/<slug>
    """

    node_id: str
    domain: str
    slug: str
    entry_ulid: str | None = None

    def __str__(self) -> str:
        if self.entry_ulid:
            return f"pnk:{self.entry_ulid}/{self.domain}/{self.slug}"
        return f"pnk://{self.node_id}/{self.domain}/{self.slug}"

    @property
    def canonical(self) -> str:
        return str(self)


def parse(uri: str) -> PnkUri:
    if uri.startswith("pnk://"):
        parsed = urlparse(uri)
        node_id = parsed.netloc
        parts = [p for p in parsed.path.split("/") if p]
        if len(parts) != 2:
            raise ValueError(f"Invalid pnk:// URI: {uri}")
        return PnkUri(node_id=node_id, domain=parts[0], slug=parts[1])

    if uri.startswith("pnk:"):
        rest = uri[4:]
        parts = rest.split("/")
        if len(parts) == 3:
            return PnkUri(
                node_id="",
                entry_ulid=parts[0],
                domain=parts[1],
                slug=parts[2],
            )
        if len(parts) == 2:
            return PnkUri(node_id="", domain=parts[0], slug=parts[1])

    raise ValueError(f"Not a pnk URI: {uri}")


def build(node_id: str, domain: str, slug: str) -> str:
    return f"pnk://{node_id}/{quote(domain)}/{quote(slug)}"


def slug_from_title(title: str) -> str:
    out = []
    for ch in title.lower():
        if ch.isalnum():
            out.append(ch)
        elif ch in " -_":
            out.append("-")
    slug = "".join(out)
    while "--" in slug:
        slug = slug.replace("--", "-")
    return slug.strip("-")
