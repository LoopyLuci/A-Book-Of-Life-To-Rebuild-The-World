import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import {
  DEFAULT_LIMIT,
  buildSnippet,
  entrySummary,
  findMarks,
  scoreDocument,
  searchEntries,
  stripMarkdown,
  toSearchDocuments,
  tokenize,
  type SearchDocument,
} from '../src/search.js';

const DOCUMENTS: SearchDocument[] = [
  {
    id: 'pnk:1/survival/making-fire',
    title: 'Making Fire',
    tags: ['fire', 'survival', 'heat'],
    body: 'Fire provides warmth, light and cooking. Charcoal burns hotter and longer than wood.',
    domain: 'survival',
  },
  {
    id: 'pnk:2/water/water-purification',
    title: 'Water Purification',
    tags: ['water', 'purification', 'boiling'],
    body: 'Boiling, filtration and chlorination make unsafe water drinkable.',
    domain: 'water',
  },
  {
    id: 'pnk:3/materials/charcoal-production',
    title: 'Charcoal Production',
    tags: ['charcoal', 'kiln', 'fuel'],
    body: 'A kiln turns wood into charcoal. Charcoal burns hotter and longer than wood.',
    domain: 'materials',
  },
  {
    id: 'pnk:4/health/wound-care',
    title: 'Wound Care',
    tags: ['first-aid', 'bleeding'],
    body: 'Cleaning and dressing a wound prevents infection.',
    domain: 'health',
  },
];

describe('tokenizer', () => {
  it('lower-cases and splits on non-alphanumeric characters', () => {
    assert.deepEqual(tokenize('Water, Purification!'), ['water', 'purification']);
  });

  it('removes duplicates but keeps the order', () => {
    assert.deepEqual(tokenize('fire fire water'), ['fire', 'water']);
  });

  it('returns nothing for an empty query', () => {
    assert.deepEqual(tokenize('   '), []);
    assert.deepEqual(tokenize(''), []);
  });
});

describe('ranking', () => {
  it('ranks a title match above a tag match above a body match', () => {
    const results = searchEntries(DOCUMENTS, 'charcoal');
    assert.equal(results.length, 2);
    assert.equal(results[0]?.id, 'pnk:3/materials/charcoal-production');
    const titleScore = scoreDocument(DOCUMENTS[2]!, ['charcoal'], 'charcoal').score;
    const bodyScore = scoreDocument(DOCUMENTS[0]!, ['charcoal'], 'charcoal').score;
    assert.ok(titleScore > bodyScore);
  });

  it('prefers the entry whose title matches over one that only mentions the term', () => {
    const results = searchEntries(DOCUMENTS, 'water');
    assert.equal(results[0]?.id, 'pnk:2/water/water-purification');
  });

  it('scores a title match higher than a tag match', () => {
    const title = scoreDocument(DOCUMENTS[0]!, ['fire'], 'fire').score;
    const tag = scoreDocument(DOCUMENTS[2]!, ['fire'], 'fire').score;
    assert.ok(title > tag, 'title matches must outrank tag matches');
  });

  it('requires every term to match when that is possible', () => {
    const results = searchEntries(DOCUMENTS, 'charcoal kiln');
    assert.equal(results.length, 1);
    assert.equal(results[0]?.id, 'pnk:3/materials/charcoal-production');
  });

  it('falls back to partial matches when no entry matches every term', () => {
    const results = searchEntries(DOCUMENTS, 'charcoal unicorn');
    assert.ok(results.length > 0);
    assert.ok(results.every((result) => result.matchedTerms.length > 0));
  });

  it('finds partial words while the user is still typing', () => {
    const results = searchEntries(DOCUMENTS, 'purif');
    assert.equal(results[0]?.id, 'pnk:2/water/water-purification');
  });

  it('is case insensitive', () => {
    assert.equal(searchEntries(DOCUMENTS, 'WATER')[0]?.id, searchEntries(DOCUMENTS, 'water')[0]?.id);
  });

  it('returns nothing for an empty query', () => {
    assert.deepEqual(searchEntries(DOCUMENTS, ''), []);
    assert.deepEqual(searchEntries(DOCUMENTS, '   '), []);
  });

  it('breaks ties by title so that the order never changes between runs', () => {
    const tied: SearchDocument[] = [
      { id: 'b', title: 'Beta', tags: ['x'], body: 'shared body', domain: 'survival' },
      { id: 'a', title: 'Alpha', tags: ['x'], body: 'shared body', domain: 'survival' },
    ];
    const results = searchEntries(tied, 'shared');
    assert.deepEqual(results.map((result) => result.title), ['Alpha', 'Beta']);
    assert.deepEqual(
      searchEntries(tied, 'shared').map((result) => result.id),
      searchEntries(tied, 'shared').map((result) => result.id),
    );
  });
});

describe('limits', () => {
  it('returns at most fifty results by default', () => {
    const many: SearchDocument[] = Array.from({ length: 120 }, (_, index) => ({
      id: `entry-${index}`,
      title: `Fire entry ${index}`,
      tags: ['fire'],
      body: 'fire',
      domain: 'survival',
    }));
    const results = searchEntries(many, 'fire');
    assert.equal(DEFAULT_LIMIT, 50);
    assert.equal(results.length, 50);
  });

  it('honours an explicit limit', () => {
    assert.equal(searchEntries(DOCUMENTS, 'e', 2).length, 2);
  });
});

describe('snippets', () => {
  it('returns a snippet around the first match', () => {
    const { snippet, marks } = buildSnippet('alpha beta gamma delta epsilon zeta', ['delta']);
    assert.ok(snippet.includes('delta'));
    assert.ok(marks.length > 0);
    const mark = marks[0]!;
    assert.equal(snippet.slice(mark.start, mark.end), 'delta');
  });

  it('marks every occurrence of the query terms', () => {
    const text = 'water water everywhere';
    const marks = findMarks(text, ['water']);
    assert.equal(marks.length, 2);
    assert.equal(marks[0]?.start, 0);
    assert.equal(marks[1]?.start, 6);
  });

  it('falls back to the beginning of the body when nothing matches', () => {
    const { snippet, marks } = buildSnippet('a body without the term', ['absent']);
    assert.equal(marks.length, 0);
    assert.ok(snippet.length > 0);
  });

  it('highlights the match inside the snippet of a search result', () => {
    const results = searchEntries(DOCUMENTS, 'kiln');
    const result = results[0]!;
    assert.ok(result.marks.length > 0);
    const mark = result.marks[0]!;
    assert.equal(result.snippet.slice(mark.start, mark.end).toLowerCase(), 'kiln');
  });
});

describe('markdown stripping', () => {
  it('removes markup so that searches match prose', () => {
    const text = stripMarkdown('# Title\n\nSome **bold** and [a link](other.md) and `code`.');
    assert.ok(!text.includes('#'));
    assert.ok(!text.includes('**'));
    assert.ok(text.includes('bold'));
    assert.ok(text.includes('a link'));
    assert.ok(!text.includes('other.md'));
  });
});

describe('entry summaries', () => {
  const body = [
    '# Basic First Aid',
    '',
    '> **Domain:** survival | **Difficulty:** novice | **Safety:** yellow',
    '',
    '*Reference material only. Verify this information against primary sources',
    'and qualified professionals before acting on it. This entry is not a sole',
    'source of information.*',
    '',
    '## Overview',
    '',
    'Field first aid prioritizes: airway, breathing, circulation (ABC), then',
    'bleeding control, then shock prevention.',
  ].join('\n');

  it('skips the metadata blockquote and the disclaimer', () => {
    const summary = entrySummary(body);
    assert.ok(!summary.includes('Domain: survival'));
    assert.ok(!summary.includes('Reference material only'));
    assert.ok(!summary.includes('qualified professionals before'), 'the whole disclaimer paragraph must go');
    assert.ok(summary.startsWith('Field first aid prioritizes'), summary.slice(0, 60));
  });

  it('keeps the summary short', () => {
    const long = `${body}\n\n${'Extra prose. '.repeat(80)}`;
    const summary = entrySummary(long, 120);
    assert.ok(summary.length <= 121, `summary was ${summary.length} characters`);
    assert.ok(summary.endsWith('…'));
  });

  it('does not cut a word in half when a space is close by', () => {
    const summary = entrySummary(`${body}\n\n${'word '.repeat(80)}`, 100);
    assert.ok(!summary.endsWith('wor…'), `unexpected cut: ${summary.slice(-12)}`);
  });

  it('handles the carriage returns of the corpus', () => {
    const crlf = body.replace(/\n/g, '\r\n');
    const summary = entrySummary(crlf);
    assert.ok(summary.startsWith('Field first aid prioritizes'), summary.slice(0, 60));
    assert.ok(!summary.includes('\r'));
  });
});

describe('document conversion', () => {
  it('builds documents from entries', () => {
    const documents = toSearchDocuments([
      {
        id: 'pnk:1/survival/making-fire',
        slug: 'making-fire',
        domain: 'survival',
        title: 'Making Fire',
        tags: ['fire'],
        difficulty: 'novice',
        safety: 'yellow',
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
        body: '# Making Fire\n\nFire provides warmth.',
      },
    ]);
    assert.equal(documents.length, 1);
    assert.equal(documents[0]?.title, 'Making Fire');
    assert.ok(documents[0]?.body.includes('Fire provides warmth'));
    assert.ok(!documents[0]?.body.includes('#'));
  });
});
