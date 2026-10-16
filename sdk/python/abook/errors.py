"""Exceptions raised by the SDK."""


class ABookError(Exception):
    """Base class for all SDK exceptions."""

    def __init__(self, message: str, status_code: int | None = None, payload: dict | None = None):
        super().__init__(message)
        self.status_code = status_code
        self.payload = payload or {}


class NotFoundError(ABookError):
    """404 — resource does not exist."""


class ValidationError(ABookError):
    """400/422 — invalid input."""


class RateLimitError(ABookError):
    """429 — too many requests."""

    def __init__(self, message: str, retry_after: int | None = None, **kw):
        super().__init__(message, **kw)
        self.retry_after = retry_after


class ServerError(ABookError):
    """5xx — server failure."""
