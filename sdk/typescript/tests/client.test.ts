import { describe, it, expect, vi } from "vitest";
import { Client } from "../src/client.js";
import { NotFoundError } from "../src/errors.js";
import { parsePnk, buildPnk, slugify } from "../src/pnk.js";

function mockFetch(handler: (url: URL) => Response) {
  return vi.fn(async (input: string | URL) => {
    const url = typeof input === "string" ? new URL(input) : input;
    return handler(url);
  }) as unknown as typeof fetch;
}

describe("Client", () => {
  it("searches and returns results", async () => {
    const fetchImpl = mockFetch((url) => {
      expect(url.pathname).toBe("/v1/search");
      return new Response(
        JSON.stringify({
          query: "fire",
          results: [
            {
              id: "pnk:TEST/survival/making-fire",
              title: "Making Fire",
              domain: "survival",
              difficulty: "novice",
              safety: "yellow",
              score: 0.9,
            },
          ],
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    });
    const c = new Client({ fetch: fetchImpl });
    const results = await c.search("fire");
    expect(results).toHaveLength(1);
    expect(results[0]!.title).toBe("Making Fire");
  });

  it("throws NotFoundError on 404", async () => {
    const fetchImpl = mockFetch(
      () =>
        new Response(JSON.stringify({ detail: "Entry not found" }), {
          status: 404,
          headers: { "Content-Type": "application/json" },
        }),
    );
    const c = new Client({ fetch: fetchImpl });
    await expect(c.getEntry("pnk:X/missing/slug")).rejects.toBeInstanceOf(
      NotFoundError,
    );
  });
});

describe("PNK", () => {
  it("parses entry URI", () => {
    const uri = parsePnk("pnk:01HZX0/survival/making-fire");
    expect(uri.entryUlid).toBe("01HZX0");
    expect(uri.domain).toBe("survival");
  });

  it("parses node URI", () => {
    const uri = parsePnk("pnk://node-a/survival/making-fire");
    expect(uri.nodeId).toBe("node-a");
  });

  it("round-trips", () => {
    const s = buildPnk("node-a", "survival", "making-fire");
    const p = parsePnk(s);
    expect(p.nodeId).toBe("node-a");
    expect(p.slug).toBe("making-fire");
  });

  it("slugifies", () => {
    expect(slugify("Making Fire!")).toBe("making-fire");
  });
});
