import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { bodyWithoutDuplicateTitle, parseRoute } from '../src/app.js';
import { loadContent } from '../src/content.js';
import type { ContentPayload, Entry } from '../src/types.js';

/**
 * Build a minimal entry for the route tests.
 *
 * @param id The entry id.
 * @param domain The domain slug.
 * @param slug The entry slug.
 * @returns The entry.
 */
function makeEntry(id: string, domain: string, slug: string): Entry {
  return {
    id,
    slug,
    domain,
    title: slug,
    tags: [],
    difficulty: 'novice',
    safety: 'green',
    timeToComplete: 'hours',
    verification: { status: 'draft', date: '', reviewers: [], testedBy: '', location: '', notes: '' },
    sources: [],
    links: [],
    prerequisites: [],
    materials: [],
    tools: [],
    hazards: [],
    limits: [],
    geographicApplicability: [],
    language: 'en',
    media: [],
    extras: {
      yield: '',
      season: '',
      storage: '',
      cost: '',
      lifespan: '',
      maintenance: '',
      resourceBudget: { batch: '', laborHours: 0, energyKwh: 0, waterLiters: 0 },
    },
    body: '',
  };
}

const entries = new Map<string, Entry>([
  ['survival/making-fire', makeEntry('pnk:1/survival/making-fire', 'survival', 'making-fire')],
]);

describe('entry bodies', () => {
  it('drops a heading that only repeats the title', () => {
    const body = '# Basic First Aid\n\n## Overview\n\nField first aid.';
    assert.equal(bodyWithoutDuplicateTitle(body, 'Basic First Aid'), '\n## Overview\n\nField first aid.');
  });

  it('keeps a heading that says something different', () => {
    const body = '# Basic First Aid\n\n## Overview\n\nField first aid.';
    assert.equal(bodyWithoutDuplicateTitle(body, 'Something else'), body);
  });

  it('keeps a body without a heading', () => {
    const body = 'Just a paragraph.';
    assert.equal(bodyWithoutDuplicateTitle(body, 'Anything'), body);
  });

  it('handles the carriage returns of the corpus', () => {
    const body = '# Basic First Aid\r\n\r\n## Overview\r\n\r\nField first aid.';
    assert.equal(bodyWithoutDuplicateTitle(body, 'Basic First Aid'), '\n## Overview\n\nField first aid.');
  });
});

describe('routing', () => {  it('reads the empty hash as the full list', () => {
    const route = parseRoute('', entries);
    assert.equal(route.kind, 'list');
    assert.equal(route.kind === 'list' ? route.domain : undefined, null);
  });

  it('reads a domain route', () => {
    const route = parseRoute('#/domain/survival', entries);
    assert.equal(route.kind, 'list');
    assert.equal(route.kind === 'list' ? route.domain : undefined, 'survival');
  });

  it('reads a search query', () => {
    const route = parseRoute('#/domain/survival?q=fire', entries);
    assert.equal(route.kind === 'list' ? route.query : undefined, 'fire');
  });

  it('reads an entry route', () => {
    const route = parseRoute('#/entry/survival/making-fire', entries);
    assert.equal(route.kind, 'entry');
    assert.equal(route.kind === 'entry' ? route.key : undefined, 'survival/making-fire');
  });

  it('falls back to the list for an unknown entry', () => {
    const route = parseRoute('#/entry/survival/does-not-exist', entries);
    assert.equal(route.kind, 'list');
  });

  it('decodes encoded segments', () => {
    const route = parseRoute('#/entry/survival/making-fire', entries);
    assert.equal(route.kind, 'entry');
  });
});

describe('content loading', () => {
  const payload = {
    manifestVersion: '0.1.0-alpha',
    entries: [],
  } as unknown as ContentPayload;

  it('uses the fetched payload when the network works', async () => {
    const fetched = { ...payload, entries: [{ id: 'fetched' }] } as unknown as ContentPayload;
    const fakeFetch = (async () => ({
      ok: true,
      json: async () => fetched,
    })) as unknown as typeof fetch;
    const loaded = await loadContent(fakeFetch);
    assert.equal(loaded.entries.length, 1);
  });

  it('falls back to the embedded payload when the fetch is blocked', async () => {
    Object.defineProperty(globalThis, 'window', { value: globalThis, configurable: true, writable: true });
    (globalThis as { __ABOOK_CONTENT__?: ContentPayload }).__ABOOK_CONTENT__ = payload;
    const blockedFetch = (async () => {
      throw new Error('Failed to fetch');
    }) as unknown as typeof fetch;
    const loaded = await loadContent(blockedFetch);
    assert.equal(loaded.manifestVersion, '0.1.0-alpha');
  });

  it('reports a clear error when nothing can be loaded', async () => {
    Object.defineProperty(globalThis, 'window', { value: globalThis, configurable: true, writable: true });
    delete (globalThis as { __ABOOK_CONTENT__?: ContentPayload }).__ABOOK_CONTENT__;
    const blockedFetch = (async () => {
      throw new Error('Failed to fetch');
    }) as unknown as typeof fetch;
    await assert.rejects(() => loadContent(blockedFetch), /Could not load the knowledge base/);
  });
});
