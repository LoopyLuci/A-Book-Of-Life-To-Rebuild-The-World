#!/usr/bin/env node
/**
 * Compile the test sources and run the unit tests with Node's built-in test
 * runner. No test framework dependency is required.
 *
 * Usage: node scripts/test.mjs [--watch]
 */

import { spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { readdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const APP_DIR = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const TEST_OUT = join(APP_DIR, '.build', 'test');

/**
 * Run a local TypeScript compiler.
 *
 * @param {string} configPath Path of the tsconfig to build.
 */
function runTsc(configPath) {
  const tsc = require.resolve('typescript/bin/tsc');
  const result = spawnSync(process.execPath, [tsc, '-p', configPath], { stdio: 'inherit', cwd: APP_DIR });
  if (result.status !== 0) {
    throw new Error(`tsc failed (exit code ${result.status ?? 'unknown'})`);
  }
}

/**
 * Run the compiled test files.
 */
function runTests() {
  const testDir = join(TEST_OUT, 'test');
  const files = readdirSync(testDir)
    .filter((file) => file.endsWith('.test.js'))
    .sort()
    .map((file) => join(testDir, file));
  if (files.length === 0) {
    process.stderr.write('No compiled test files were found.\n');
    return 1;
  }
  process.stdout.write(`› running ${files.length} test files\n`);
  const result = spawnSync(process.execPath, ['--test', ...files], { stdio: 'inherit', cwd: APP_DIR });
  return result.status ?? 1;
}

try {
  runTsc(join(APP_DIR, 'tsconfig.test.json'));
  process.exitCode = runTests();
} catch (error) {
  process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`);
  process.exitCode = 1;
}
