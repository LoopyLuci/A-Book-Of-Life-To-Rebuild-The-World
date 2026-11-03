#!/usr/bin/env node
/**
 * Development server: builds the app, serves `dist/` over HTTP and rebuilds
 * when a source file changes.
 *
 * Usage: node scripts/dev.mjs [--port 5173] [--no-open]
 */

import { createServer } from 'node:http';
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, statSync, watch } from 'node:fs';
import { dirname, extname, join, normalize, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const APP_DIR = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const DIST_DIR = join(APP_DIR, 'dist');

/**
 * @param {string[]} argv
 * @returns {{port: number}}
 */
function parseArgs(argv) {
  let port = 5173;
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--port') {
      const value = argv[i + 1];
      if (value !== undefined) {
        port = Number.parseInt(value, 10);
        i += 1;
      }
    }
  }
  return { port: Number.isFinite(port) ? port : 5173 };
}

/** @type {Record<string, string>} */
const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.map': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
};

/**
 * Rebuild the application.
 */
function rebuild() {
  const result = spawnSync(process.execPath, [join(APP_DIR, 'scripts', 'build.mjs'), '--skip-export', '--quiet'], {
    stdio: 'inherit',
    cwd: APP_DIR,
  });
  if (result.status !== 0) process.exitCode = 1;
}

const { port } = parseArgs(process.argv.slice(2));

process.stdout.write('› building…\n');
rebuild();

const server = createServer((request, response) => {
  const url = new URL(request.url ?? '/', `http://localhost:${port}`);
  const requested = decodeURIComponent(url.pathname);
  const relativePath = requested === '/' ? 'index.html' : requested.replace(/^\/+/, '');
  const target = resolve(DIST_DIR, normalize(relativePath));

  if (!target.startsWith(DIST_DIR + sep) && target !== DIST_DIR) {
    response.writeHead(403).end('Forbidden');
    return;
  }
  if (!existsSync(target) || statSync(target).isDirectory()) {
    response.writeHead(404, { 'content-type': 'text/plain; charset=utf-8' }).end('Not found');
    return;
  }
  const type = MIME_TYPES[extname(target).toLowerCase()] ?? 'application/octet-stream';
  response.writeHead(200, { 'content-type': type, 'cache-control': 'no-cache' });
  response.end(readFileSync(target));
});

server.listen(port, () => {
  process.stdout.write(`› serving dist/ on http://localhost:${port}\n`);
});

let pending = /** @type {NodeJS.Timeout | null} */ (null);
const scheduleRebuild = () => {
  if (pending !== null) clearTimeout(pending);
  pending = setTimeout(() => {
    pending = null;
    process.stdout.write('› change detected, rebuilding…\n');
    rebuild();
  }, 150);
};

watch(join(APP_DIR, 'src'), { recursive: true }, scheduleRebuild);
watch(join(APP_DIR, 'index.html'), scheduleRebuild);
