import { openDb, setMeta } from "./db";
import type { EntryRow } from "./db";

const DEFAULT_BASE_URL = "http://localhost:8080/v1";

export interface SyncResult {
  fetched: number;
  inserted: number;
  updated: number;
  failed: number;
}

export async function syncFromServer(
  baseUrl: string = DEFAULT_BASE_URL,
): Promise<SyncResult> {
  const result: SyncResult = { fetched: 0, inserted: 0, updated: 0, failed: 0 };

  const db = await openDb();
  const [existing] = await db.executeSql(`SELECT id FROM entries`);
  const existingIds = new Set<string>();
  for (let i = 0; i < existing.rows.length; i++) {
    existingIds.add(existing.rows.item(i).id);
  }

  let cursor: string | null = null;
  do {
    const url = new URL(`${baseUrl}/entries`);
    url.searchParams.set("limit", "200");
    if (cursor) url.searchParams.set("cursor", cursor);

    const res = await fetch(url.toString());
    if (!res.ok) throw new Error(`Sync failed: ${res.status}`);
    const data = await res.json();

    for (const summary of data.items) {
      const entryRes = await fetch(`${baseUrl}/entries/${encodeURIComponent(summary.id)}`);
      if (!entryRes.ok) {
        result.failed++;
        continue;
      }
      const entry = await entryRes.json();
      result.fetched++;

      const row: EntryRow = {
        id: entry.id,
        title: entry.title,
        domain: entry.domain,
        difficulty: entry.difficulty,
        safety: entry.safety,
        verification_status: entry.verification_status,
        body: entry.body,
        tags: (entry.tags ?? []).join(","),
      };

      await db.executeSql(
        `INSERT OR REPLACE INTO entries
         (id, title, domain, difficulty, safety, verification_status, body, tags)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [row.id, row.title, row.domain, row.difficulty, row.safety,
         row.verification_status, row.body, row.tags],
      );
      await db.executeSql(`DELETE FROM entries_fts WHERE id = ?`, [row.id]);
      await db.executeSql(
        `INSERT INTO entries_fts (id, title, body, tags) VALUES (?, ?, ?, ?)`,
        [row.id, row.title, row.body, row.tags],
      );

      if (existingIds.has(row.id)) result.updated++;
      else result.inserted++;
    }

    cursor = data.next_cursor ?? null;
  } while (cursor);

  await setMeta("last_sync", new Date().toISOString());
  return result;
}
