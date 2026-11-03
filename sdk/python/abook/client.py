"""Synchronous and asynchronous HTTP clients."""

from __future__ import annotations

import asyncio
from collections.abc import Iterator
from typing import Any

import httpx

from .errors import (
    NotFoundError,
    RateLimitError,
    ServerError,
    ValidationError,
)
from .models import (
    Edge,
    Entry,
    EntrySummary,
    FieldTest,
    LinkGraph,
    Resolution,
    SearchResult,
    Stats,
    Verification,
    VerificationEvent,
    Version,
)

DEFAULT_BASE_URL = "http://localhost:8080/v1"
DEFAULT_TIMEOUT = 30.0


def _raise_for_status(response: httpx.Response) -> None:
    if response.is_success:
        return
    payload: dict[str, Any] = {}
    try:
        payload = response.json()
    except (ValueError, TypeError):
        # The body is not JSON; the status line is the best error we have.
        payload = {}
    message = payload.get("detail") or response.text or response.reason_phrase
    code = response.status_code
    if code == 404:
        raise NotFoundError(message, status_code=code, payload=payload)
    if code in (400, 422):
        raise ValidationError(message, status_code=code, payload=payload)
    if code == 429:
        retry = response.headers.get("Retry-After")
        raise RateLimitError(
            message,
            retry_after=int(retry) if retry and retry.isdigit() else None,
            status_code=code,
            payload=payload,
        )
    if code >= 500:
        raise ServerError(message, status_code=code, payload=payload)
    raise ServerError(message, status_code=code, payload=payload)


def _parse_search(r: dict) -> SearchResult:
    return SearchResult(**r)


def _parse_entry(r: dict) -> Entry:
    return Entry(
        id=r["id"],
        title=r["title"],
        domain=r["domain"],
        difficulty=r["difficulty"],
        safety=r["safety"],
        verification_status=r.get("verification_status", ""),
        tags=r.get("tags", []),
        body=r.get("body", ""),
        metadata=r.get("metadata", {}),
    )


class Client:
    """Synchronous client."""

    def __init__(
        self,
        base_url: str = DEFAULT_BASE_URL,
        *,
        timeout: float = DEFAULT_TIMEOUT,
        api_key: str | None = None,
        client: httpx.Client | None = None,
    ):
        headers = {"User-Agent": "abook-python-sdk/1.0"}
        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"
        self._client = client or httpx.Client(
            base_url=base_url, timeout=timeout, headers=headers
        )

    # -- context manager -----------------------------------------------------

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()

    def close(self) -> None:
        self._client.close()

    # -- system --------------------------------------------------------------

    def health(self) -> dict:
        r = self._client.get("/health")
        _raise_for_status(r)
        return r.json()

    def version(self) -> Version:
        r = self._client.get("/version")
        _raise_for_status(r)
        return Version(**r.json())

    def stats(self) -> Stats:
        r = self._client.get("/stats")
        _raise_for_status(r)
        data = r.json()
        return Stats(
            total=data["total"],
            by_status=data.get("by_status", {}),
            by_domain=data.get("by_domain", {}),
            by_safety=data.get("by_safety", {}),
            by_difficulty=data.get("by_difficulty", {}),
        )

    # -- search --------------------------------------------------------------

    def search(
        self,
        query: str,
        *,
        domain: str | None = None,
        difficulty: str | None = None,
        safety: str | None = None,
        language: str = "en",
        limit: int = 20,
    ) -> list[SearchResult]:
        params: dict[str, Any] = {"q": query, "limit": limit, "language": language}
        if domain:
            params["domain"] = domain
        if difficulty:
            params["difficulty"] = difficulty
        if safety:
            params["safety"] = safety
        r = self._client.get("/search", params=params)
        _raise_for_status(r)
        return [_parse_search(x) for x in r.json()["results"]]

    # -- entries -------------------------------------------------------------

    def iter_entries(
        self,
        *,
        domain: str | None = None,
        status: str | None = None,
        limit_per_page: int = 100,
    ) -> Iterator[EntrySummary]:
        cursor: str | None = None
        while True:
            params: dict[str, Any] = {"limit": limit_per_page}
            if domain:
                params["domain"] = domain
            if status:
                params["status"] = status
            if cursor:
                params["cursor"] = cursor
            r = self._client.get("/entries", params=params)
            _raise_for_status(r)
            data = r.json()
            for item in data["items"]:
                yield EntrySummary(**item)
            cursor = data.get("next_cursor")
            if not cursor:
                break

    def get_entry(self, entry_id: str) -> Entry:
        r = self._client.get(f"/entries/{entry_id}")
        _raise_for_status(r)
        return _parse_entry(r.json())

    def get_links(self, entry_id: str) -> LinkGraph:
        r = self._client.get(f"/entries/{entry_id}/links")
        _raise_for_status(r)
        data = r.json()
        return LinkGraph(
            id=data["id"],
            outgoing=[Edge(**e) for e in data.get("outgoing", [])],
            incoming=[Edge(**e) for e in data.get("incoming", [])],
        )

    # -- verification --------------------------------------------------------

    def get_verification(self, entry_id: str) -> Verification:
        r = self._client.get(f"/verification/{entry_id}")
        _raise_for_status(r)
        return Verification(**r.json())

    def get_ledger(self, *, since: str | None = None, limit: int = 100) -> list[VerificationEvent]:
        params: dict[str, Any] = {"limit": limit}
        if since:
            params["since"] = since
        r = self._client.get("/verification/ledger", params=params)
        _raise_for_status(r)
        return [VerificationEvent(**e) for e in r.json()["events"]]

    def get_field_tests(self) -> list[FieldTest]:
        r = self._client.get("/verification/field-tests")
        _raise_for_status(r)
        return [FieldTest(raw=x) for x in r.json()["field_tests"]]

    # -- federation ----------------------------------------------------------

    def federation_manifest(self) -> dict:
        r = self._client.get("/federation/manifest")
        _raise_for_status(r)
        return r.json()

    def resolve(self, uri: str) -> Resolution:
        r = self._client.get("/federation/resolve", params={"uri": uri})
        _raise_for_status(r)
        return Resolution(**r.json())

    def peers(self) -> list[dict]:
        r = self._client.get("/federation/peers")
        _raise_for_status(r)
        return r.json()["peers"]


class AsyncClient:
    """Asynchronous client (mirrors Client)."""

    def __init__(
        self,
        base_url: str = DEFAULT_BASE_URL,
        *,
        timeout: float = DEFAULT_TIMEOUT,
        api_key: str | None = None,
        client: httpx.AsyncClient | None = None,
    ):
        headers = {"User-Agent": "abook-python-sdk/1.0"}
        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"
        self._client = client or httpx.AsyncClient(
            base_url=base_url, timeout=timeout, headers=headers
        )

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc):
        await self.close()

    async def close(self) -> None:
        await self._client.aclose()

    async def health(self) -> dict:
        r = await self._client.get("/health")
        _raise_for_status(r)
        return r.json()

    async def version(self) -> Version:
        r = await self._client.get("/version")
        _raise_for_status(r)
        return Version(**r.json())

    async def stats(self) -> Stats:
        r = await self._client.get("/stats")
        _raise_for_status(r)
        data = r.json()
        return Stats(
            total=data["total"],
            by_status=data.get("by_status", {}),
            by_domain=data.get("by_domain", {}),
            by_safety=data.get("by_safety", {}),
            by_difficulty=data.get("by_difficulty", {}),
        )

    async def search(self, query: str, **kwargs) -> list[SearchResult]:
        params: dict[str, Any] = {"q": query, "limit": kwargs.get("limit", 20)}
        for key in ("domain", "difficulty", "safety", "language"):
            if kwargs.get(key):
                params[key] = kwargs[key]
        r = await self._client.get("/search", params=params)
        _raise_for_status(r)
        return [_parse_search(x) for x in r.json()["results"]]

    async def get_entry(self, entry_id: str) -> Entry:
        r = await self._client.get(f"/entries/{entry_id}")
        _raise_for_status(r)
        return _parse_entry(r.json())

    async def get_verification(self, entry_id: str) -> Verification:
        r = await self._client.get(f"/verification/{entry_id}")
        _raise_for_status(r)
        return Verification(**r.json())

    async def search_many(self, queries: list[str]) -> list[list[SearchResult]]:
        return await asyncio.gather(*(self.search(q) for q in queries))
