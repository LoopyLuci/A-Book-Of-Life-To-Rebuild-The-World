export interface PnkUri {
  nodeId: string;
  entryUlid?: string;
  domain: string;
  slug: string;
}

const PNK_SCHEME = "pnk:";

export function parsePnk(uri: string): PnkUri {
  if (uri.startsWith("pnk://")) {
    const rest = uri.slice("pnk://".length);
    const slash = rest.indexOf("/");
    if (slash < 0) throw new Error(`Invalid pnk URI: ${uri}`);
    const nodeId = rest.slice(0, slash);
    const parts = rest.slice(slash + 1).split("/").filter(Boolean);
    const domain = parts[0];
    const slug = parts[1];
    if (parts.length !== 2 || domain === undefined || slug === undefined) {
      throw new Error(`Invalid pnk URI: ${uri}`);
    }
    return { nodeId, domain, slug };
  }
  if (uri.startsWith(PNK_SCHEME)) {
    const parts = uri.slice(PNK_SCHEME.length).split("/");
    if (parts.length === 3) {
      const entryUlid = parts[0];
      const domain = parts[1];
      const slug = parts[2];
      if (entryUlid === undefined || domain === undefined || slug === undefined) {
        throw new Error(`Invalid pnk URI: ${uri}`);
      }
      return { nodeId: "", entryUlid, domain, slug };
    }
    if (parts.length === 2) {
      const domain = parts[0];
      const slug = parts[1];
      if (domain === undefined || slug === undefined) {
        throw new Error(`Invalid pnk URI: ${uri}`);
      }
      return { nodeId: "", domain, slug };
    }
  }
  throw new Error(`Not a pnk URI: ${uri}`);
}

export function buildPnk(nodeId: string, domain: string, slug: string): string {
  return `pnk://${nodeId}/${encodeURIComponent(domain)}/${encodeURIComponent(slug)}`;
}

export function formatEntryUri(ulid: string, domain: string, slug: string): string {
  return `pnk:${ulid}/${domain}/${slug}`;
}

export function slugify(title: string): string {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}
