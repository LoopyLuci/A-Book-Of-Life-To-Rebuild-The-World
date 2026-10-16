import {
  ABookError,
  NotFoundError,
  RateLimitError,
  ServerError,
  ValidationError,
} from "./errors.js";
import type {
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
} from "./models.js";

export const DEFAULT_BASE_URL = "http://localhost:8080/v1";

export interface ClientOptions {
  baseUrl?: string;
  apiKey?: string;
  timeoutMs?: number;
  fetch?: typeof fetch;
}

export interface SearchOptions {
  domain?: string;
  difficulty?: string;
  safety?: string;
  language?: string;
  limit?: number;
}

export interface ListEntriesOptions {
  domain?: string;
  status?: string;
  limit?: number;
}

export class Client {
  private readonly baseUrl: string;
  private readonly apiKey?: string;
  private readonly timeoutMs: number;
  private readonly fetchImpl: typeof fetch;

  constructor(opts: ClientOptions = {}) {
    this.baseUrl = (opts.baseUrl ?? DEFAULT_BASE_URL).replace(/\/+$/, "");
    this.apiKey = opts.apiKey;
    this.timeoutMs = opts.timeoutMs ?? 30_000;
    this.fetchImpl = opts.fetch ?? fetch;
  }

  // ---------------------------------------------------------------------

  private async request<T>(
    path: string,
    params: Record<string, string | number | undefined> = {},
  ): Promise<T> {
    const url = new URL(this.baseUrl + path);
    for (const [k, v] of Object.entries(params)) {
      if (v !== undefined && v !== null && v !== "") {
        url.searchParams.set(k, String(v));
      }
    }

    const headers: Record<string, string> = {
      Accept: "application/json",
      "User-Agent": "abook-typescript-sdk/1.0",
    };
    if (this.apiKey) headers.Authorization = `Bearer ${this.apiKey}`;

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    let res: Response;
    try {
      res = await this.fetchImpl(url.toString(), {
        headers,
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timer);
    }

    if (!res.ok) {
      const payload = await safeJson(res);
      const message =
        (payload && typeof payload === "object" && "detail" in payload
          ? String((payload as { detail: unknown }).detail)
          : undefined) ?? res.statusText;
      const code = res.status;
      if (code === 404) throw new NotFoundError(message, code, payload);
      if (code === 400 || code === 422) throw new ValidationError(message, code, payload);
      if (code === 429) {
        const ra = res.headers.get("Retry-After");
        throw new RateLimitError(
          message,
          ra ? Number(ra) : undefined,
          payload,
        );
      }
      if (code >= 500) throw new ServerError(message, code, payload);
      throw new ABookError(message, code, payload);
    }
    return (await res.json()) as T;
  }

  // -- system -----------------------------------------------------------

  async health(): Promise<{ status: string; index_exists: boolean }> {
    return this.request("/health");
  }

  async version(): Promise<Version> {
    return this.request("/version");
  }

  async stats(): Promise<Stats> {
    return this.request("/stats");
  }

  // -- search -----------------------------------------------------------

  async search(query: string, opts: SearchOptions = {}): Promise<SearchResult[]> {
    const data = await this.request<{ results: SearchResult[] }>("/search", {
      q: query,
      domain: opts.domain,
      difficulty: opts.difficulty,
      safety: opts.safety,
      language: opts.language,
      limit: opts.limit,
    });
    return data.results;
  }

  // -- entries ----------------------------------------------------------

  async *iterateEntries(
    opts: ListEntriesOptions = {},
  ): AsyncGenerator<EntrySummary> {
    let cursor: string | undefined;
    do {
      const data = await this.request<{
        items: EntrySummary[];
        next_cursor?: string | null;
      }>("/entries", {
        domain: opts.domain,
        status: opts.status,
        limit: opts.limit ?? 100,
        cursor,
      });
      for (const item of data.items) yield item;
      cursor = data.next_cursor ?? undefined;
    } while (cursor);
  }

  async getEntry(entryId: string): Promise<Entry> {
    return this.request(`/entries/${encodeURIComponent(entryId)}`);
  }

  async getLinks(entryId: string): Promise<LinkGraph> {
    return this.request(`/entries/${encodeURIComponent(entryId)}/links`);
  }

  // -- verification -----------------------------------------------------

  async getVerification(entryId: string): Promise<Verification> {
    return this.request(`/verification/${encodeURIComponent(entryId)}`);
  }

  async getLedger(opts: { since?: string; limit?: number } = {}): Promise<VerificationEvent[]> {
    const data = await this.request<{ events: VerificationEvent[] }>(
      "/verification/ledger",
      { since: opts.since, limit: opts.limit },
    );
    return data.events;
  }

  async getFieldTests(): Promise<FieldTest[]> {
    const data = await this.request<{ field_tests: FieldTest[] }>(
      "/verification/field-tests",
    );
    return data.field_tests;
  }

  // -- federation -------------------------------------------------------

  async federationManifest(): Promise<Record<string, unknown>> {
    return this.request("/federation/manifest");
  }

  async resolve(uri: string): Promise<Resolution> {
    return this.request("/federation/resolve", { uri });
  }

  async peers(): Promise<Array<Record<string, unknown>>> {
    const data = await this.request<{ peers: Array<Record<string, unknown>> }>(
      "/federation/peers",
    );
    return data.peers;
  }
}

async function safeJson(res: Response): Promise<unknown> {
  try {
    return await res.json();
  } catch {
    return undefined;
  }
}
