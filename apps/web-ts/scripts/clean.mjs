#!/usr/bin/env node
/**
 * Remove the generated build artefacts.
 *
 * Usage: node scripts/clean.mjs
 */

import { rmSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const APP_DIR = resolve(dirname(fileURLToPath(import.meta.url)), '..');

for (const target of ['dist', '.build']) {
  rmSync(join(APP_DIR, target), { recursive: true, force: true });
  process.stdout.write(`› removed ${target}/\n`);
}
