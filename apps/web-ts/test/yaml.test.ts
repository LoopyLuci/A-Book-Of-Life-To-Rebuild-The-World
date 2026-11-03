import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { YamlParseError, parseYaml, parseYamlMapping } from '../scripts/lib/yaml.mjs';
import { TomlParseError, parseToml } from '../scripts/lib/toml.mjs';

describe('yaml scalars', () => {
  it('reads plain scalars', () => {
    const value = parseYamlMapping('title: Making Fire\ndifficulty: novice');
    assert.equal(value['title'], 'Making Fire');
    assert.equal(value['difficulty'], 'novice');
  });

  it('reads quoted scalars', () => {
    const value = parseYamlMapping(`a: "double"\nb: 'single'\nc: ''`);
    assert.equal(value['a'], 'double');
    assert.equal(value['b'], 'single');
    assert.equal(value['c'], '');
  });

  it('reads numbers and booleans', () => {
    const value = parseYamlMapping('labor_hours: 3\nenergy_kwh: 1.5\nverified: true\nmissing: false');
    assert.equal(value['labor_hours'], 3);
    assert.equal(value['energy_kwh'], 1.5);
    assert.equal(value['verified'], true);
    assert.equal(value['missing'], false);
  });

  it('keeps identifiers that contain a colon intact', () => {
    const value = parseYamlMapping('id: pnk:01HZX0K8J9Q7R3VY6T2M4B8N1W/survival/basic-first-aid');
    assert.equal(value['id'], 'pnk:01HZX0K8J9Q7R3VY6T2M4B8N1W/survival/basic-first-aid');
  });

  it('skips comments and blank lines', () => {
    const value = parseYamlMapping('# a comment\n\ntitle: Fire\n');
    assert.equal(value['title'], 'Fire');
  });
});

describe('yaml collections', () => {
  it('reads flow sequences', () => {
    const value = parseYamlMapping('tags: [first-aid, cpr, bleeding]\nempty: []');
    assert.deepEqual(value['tags'], ['first-aid', 'cpr', 'bleeding']);
    assert.deepEqual(value['empty'], []);
  });

  it('reads block sequences indented under their key', () => {
    const value = parseYamlMapping('prerequisites:\n  - pnk:1/survival/simple-tools\n  - pnk:2/materials/charcoal');
    assert.deepEqual(value['prerequisites'], ['pnk:1/survival/simple-tools', 'pnk:2/materials/charcoal']);
  });

  it('reads block sequences at the same indentation as their key', () => {
    const value = parseYamlMapping('tags:\n- biology\n- cells\n- microscopy');
    assert.deepEqual(value['tags'], ['biology', 'cells', 'microscopy']);
  });

  it('reads sequences of mappings', () => {
    const value = parseYamlMapping('sources:\n- title: OpenStax Biology\n  license: CC-BY-4.0\n- title: WHO Manual');
    const sources = value['sources'] as Array<Record<string, unknown>>;
    assert.equal(sources.length, 2);
    assert.equal(sources[0]?.['title'], 'OpenStax Biology');
    assert.equal(sources[0]?.['license'], 'CC-BY-4.0');
    assert.equal(sources[1]?.['title'], 'WHO Manual');
  });

  it('reads nested mappings', () => {
    const value = parseYamlMapping('resource_budget:\n  batch: 10 kg\n  labor_hours: 0\nverification:\n  status: draft');
    const budget = value['resource_budget'] as Record<string, unknown>;
    assert.equal(budget['batch'], '10 kg');
    assert.equal(budget['labor_hours'], 0);
    const verification = value['verification'] as Record<string, unknown>;
    assert.equal(verification['status'], 'draft');
  });

  it('reads a realistic sidecar', () => {
    const source = [
      'id: pnk:01HZX0K8J9Q7R3VY6T2M4B8N1W/survival/basic-first-aid',
      'title: Basic First Aid',
      'domain: survival',
      'tags: [first-aid, cpr, bleeding]',
      'difficulty: novice',
      'safety: yellow',
      'time_to_complete: hours',
      'prerequisites: []',
      'materials_required: []',
      'sources:',
      '  - title: WHO Basic Emergency Care',
      'verification:',
      '  status: peer-reviewed',
      '  date: "2026-02-20"',
      'links:',
      '  - pnk:01M52TVK0262WR91WPZ1FVPE6X/health/wound-care',
      'geographic_applicability: [universal]',
      'language: en',
      'media: []',
    ].join('\n');
    const value = parseYamlMapping(source);
    assert.equal(value['title'], 'Basic First Aid');
    assert.equal(value['safety'], 'yellow');
    assert.deepEqual(value['links'], ['pnk:01M52TVK0262WR91WPZ1FVPE6X/health/wound-care']);
    const verification = value['verification'] as Record<string, unknown>;
    assert.equal(verification['status'], 'peer-reviewed');
    assert.equal(verification['date'], '2026-02-20');
  });

  it('reports unsupported documents instead of guessing', () => {
    assert.throws(() => parseYaml('key: |\n  block scalar\n'), YamlParseError);
  });

  it('returns null for an empty document', () => {
    assert.equal(parseYaml(''), null);
    assert.equal(parseYaml('\n\n'), null);
  });
});

describe('toml', () => {
  it('reads tables and scalars', () => {
    const value = parseToml('[project]\nname = "book-of-life"\nversion = "0.1.0-alpha"\n');
    const project = value['project'] as Record<string, unknown>;
    assert.equal(project['name'], 'book-of-life');
    assert.equal(project['version'], '0.1.0-alpha');
  });

  it('reads arrays that span several lines', () => {
    const value = parseToml('[domains]\nlist = [\n  "survival",\n  "water",\n]\n');
    const domains = value['domains'] as Record<string, unknown>;
    assert.deepEqual(domains['list'], ['survival', 'water']);
  });

  it('reads booleans and numbers', () => {
    const value = parseToml('a = true\nb = false\nc = 42\nd = 1.5');
    assert.equal(value['a'], true);
    assert.equal(value['b'], false);
    assert.equal(value['c'], 42);
    assert.equal(value['d'], 1.5);
  });

  it('rejects unsupported values', () => {
    assert.throws(() => parseToml('when = 2026-02-20'), TomlParseError);
  });
});
