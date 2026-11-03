/**
 * Ambient declarations for the globals the app relies on.
 */

import type { ContentPayload } from './types.js';

declare global {
  interface Window {
    /** The content payload embedded by `content.js` for `file://` usage. */
    __ABOOK_CONTENT__?: ContentPayload;
  }
}

export {};
