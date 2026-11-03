/**
 * Loading of the exported content payload.
 *
 * The app must work when it is opened straight from the filesystem, where
 * `fetch()` of a neighbouring file is blocked by the browser's file-origin
 * rules. The build therefore emits the payload twice: as `content.json` (used
 * when the app is served over HTTP) and as `content.js` (a classic script
 * that assigns the same payload to `window.__ABOOK_CONTENT__`). The loader
 * tries the network path first and falls back to the embedded copy.
 *
 * @module content
 */

import type { ContentPayload } from './types.js';

/** Path of the JSON payload, relative to the app root. */
export const CONTENT_URL = './content.json';

/**
 * Load the content payload.
 *
 * @param fetchImpl The fetch implementation to use.
 * @returns The payload.
 * @throws When the payload can be neither fetched nor found in the page.
 */
export async function loadContent(fetchImpl: typeof fetch = fetch): Promise<ContentPayload> {
  const embedded = typeof window === 'undefined' ? undefined : window.__ABOOK_CONTENT__;
  try {
    const response = await fetchImpl(CONTENT_URL, { cache: 'no-cache' });
    if (response.ok) {
      const payload = (await response.json()) as ContentPayload;
      if (payload && Array.isArray(payload.entries)) return payload;
    }
  } catch {
    /* file:// origins refuse to fetch; fall back to the embedded payload */
  }
  if (embedded && Array.isArray(embedded.entries)) return embedded;
  throw new Error(
    `Could not load the knowledge base. Expected ${CONTENT_URL} next to the app, or an embedded payload.`,
  );
}
