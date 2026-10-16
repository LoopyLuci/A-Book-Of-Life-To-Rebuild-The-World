import SQLite from "react-native-sqlite-storage";

SQLite.DEBUG(false);
SQLite.enablePromise(true);

const DB_NAME = "abook.db";

export interface EntryRow {
  id: string;
  title: string;
  domain: string;
  difficulty: string;
  safety: string;
  verification_status: string;
  body: string;
  tags: string;
}

let dbPromise: Promise<SQLite.SQLiteDatabase> | null = null;

export function openDb(): Promise<SQLite.SQLiteDatabase> {
  if (!dbPromise) {
    dbPromise = SQLite.openDatabase({ name: DB_NAME, location: "default" })
      .then(async (db) => {
        await db.executeSql(`
          CREATE TABLE IF NOT EXISTS entries (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            domain TEXT NOT NULL,
            difficulty TEXT NOT NULL,
            safety TEXT NOT NULL,
            verification_status TEXT NOT NULL,
            body TEXT NOT NULL,
            tags TEXT NOT NULL
          );
        `);
        await db.executeSql(`
          CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts
          USING fts4(id, title, body, tags);
        `);
        await db.executeSql(`
          CREATE TABLE IF NOT EXISTS meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          );
        `);
        return db;
      });
  }
  return dbPromise;
}

export async function upsertEntries(entries: EntryRow[]): Promise<void> {
  const db = await openDb();
  await db.transaction(async (tx) => {
    for (const e of entries) {
      await tx.executeSql(
        `INSERT OR REPLACE INTO entries
         (id, title, domain, difficulty, safety, verification_status, body, tags)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [e.id, e.title, e.domain, e.difficulty, e.safety, e.verification_status, e.body, e.tags],
      );
      await tx.executeSql(`DELETE FROM entries_fts WHERE id = ?`, [e.id]);
      await tx.executeSql(
        `INSERT INTO entries_fts (id, title, body, tags) VALUES (?, ?, ?, ?)`,
        [e.id, e.title, e.body, e.tags],
      );
    }
  });
}

export async function searchEntries(query: string, limit = 20): Promise<EntryRow[]> {
  const db = await openDb();
  const [results] = await db.executeSql(
    `SELECT e.* FROM entries_fts f
     JOIN entries e ON e.id = f.id
     WHERE entries_fts MATCH ?
     LIMIT ?`,
    [query, limit],
  );
  const rows: EntryRow[] = [];
  for (let i = 0; i < results.rows.length; i++) {
    rows.push(results.rows.item(i) as EntryRow);
  }
  return rows;
}

export async function getEntry(id: string): Promise<EntryRow | null> {
  const db = await openDb();
  const [results] = await db.executeSql(`SELECT * FROM entries WHERE id = ?`, [id]);
  if (results.rows.length === 0) return null;
  return results.rows.item(0) as EntryRow;
}

export async function setMeta(key: string, value: string): Promise<void> {
  const db = await openDb();
  await db.executeSql(`INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)`, [key, value]);
}

export async function getMeta(key: string): Promise<string | null> {
  const db = await openDb();
  const [results] = await db.executeSql(`SELECT value FROM meta WHERE key = ?`, [key]);
  if (results.rows.length === 0) return null;
  return results.rows.item(0).value;
}
