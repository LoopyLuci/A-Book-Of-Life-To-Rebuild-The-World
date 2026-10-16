export class ABookError extends Error {
  readonly statusCode?: number;
  readonly payload?: unknown;

  constructor(message: string, statusCode?: number, payload?: unknown) {
    super(message);
    this.name = "ABookError";
    this.statusCode = statusCode;
    this.payload = payload;
  }
}

export class NotFoundError extends ABookError {
  constructor(message: string, statusCode = 404, payload?: unknown) {
    super(message, statusCode, payload);
    this.name = "NotFoundError";
  }
}

export class ValidationError extends ABookError {
  constructor(message: string, statusCode = 400, payload?: unknown) {
    super(message, statusCode, payload);
    this.name = "ValidationError";
  }
}

export class RateLimitError extends ABookError {
  readonly retryAfter?: number;
  constructor(message: string, retryAfter?: number, payload?: unknown) {
    super(message, 429, payload);
    this.name = "RateLimitError";
    this.retryAfter = retryAfter;
  }
}

export class ServerError extends ABookError {
  constructor(message: string, statusCode = 500, payload?: unknown) {
    super(message, statusCode, payload);
    this.name = "ServerError";
  }
}
