/**
 * Entry point of the A Book Of Life web application.
 *
 * @module main
 */

import { createApp } from './app.js';
import { loadContent } from './content.js';

/**
 * Show a readable error when the knowledge base cannot be loaded.
 *
 * @param error The error that was raised.
 */
function showFailure(error: unknown): void {
  const view = document.querySelector('#view');
  const message = error instanceof Error ? error.message : String(error);
  if (!view) {
    document.body.textContent = `The knowledge base could not be loaded: ${message}`;
    return;
  }
  const panel = document.createElement('div');
  panel.className = 'load-error';
  panel.setAttribute('role', 'alert');
  const heading = document.createElement('h2');
  heading.textContent = 'The knowledge base could not be loaded';
  const detail = document.createElement('p');
  detail.textContent = message;
  const hint = document.createElement('p');
  hint.className = 'muted';
  hint.textContent = 'Run "npm run build" to generate content.json next to the application.';
  panel.append(heading, detail, hint);
  view.replaceChildren(panel);
}

/**
 * Load the content and start the application.
 */
async function bootstrap(): Promise<void> {
  try {
    const payload = await loadContent();
    createApp(payload).start();
  } catch (error) {
    showFailure(error);
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    void bootstrap();
  });
} else {
  void bootstrap();
}
