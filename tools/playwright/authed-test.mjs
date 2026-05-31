// Shared test fixture: a `test` that
//   1. injects the captured prod Supabase session into the LOCAL origin's
//      localStorage before any page script runs, and
//   2. installs a network WRITE-GUARD so no test can ever mutate prod data.
//
// SESSION FORMAT (robust v2): we store the FULL set of `sb-*` localStorage
// entries as a key→value map, not a single token. supabase-js v2 may store the
// session base64-encoded and/or split across chunk keys (`…-auth-token.0`,
// `.1`) plus a code-verifier key — injecting every entry verbatim reproduces
// the exact browser state and avoids any encoding/chunking/coercion pitfalls.
// (Legacy {tokenKey, token} files are still accepted for back-compat.)
//
// Import { test, expect } from this file instead of '@playwright/test'.

import base, { expect } from '@playwright/test';
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SESSION_FILE = path.join(__dirname, '.auth', 'supabase-session.json');

// Returns { [localStorageKey]: stringValue, ... } to seed on the local origin.
function loadEntries() {
  if (!existsSync(SESSION_FILE)) {
    throw new Error(
      `No captured session at ${SESSION_FILE}. Run \`npm run import\` (or \`npm run capture\`) first — see tools/playwright/README.md.`
    );
  }
  const data = JSON.parse(readFileSync(SESSION_FILE, 'utf8'));

  let entries = null;
  if (data.entries && typeof data.entries === 'object') {
    entries = data.entries; // v2 format
  } else if (data.tokenKey && data.token) {
    entries = { [data.tokenKey]: data.token }; // legacy single-token format
  }

  if (!entries || Object.keys(entries).length === 0) {
    throw new Error(`Captured session at ${SESSION_FILE} has no localStorage entries — re-run \`npm run import\`.`);
  }

  // Guard against the classic "[object Object]" / empty garbage that silently
  // leaves you on the sign-in screen: there must be a real auth-token value.
  const authKey = Object.keys(entries).find((k) => /-auth-token(\.\d+)?$/.test(k));
  const authVal = authKey ? String(entries[authKey] || '') : '';
  if (!authKey || authVal.length < 40 || authVal.includes('[object Object]')) {
    throw new Error(
      `Captured session looks invalid (auth-token value is ${authVal.length} chars${
        authVal.includes('[object Object]') ? ', literally "[object Object]"' : ''
      }). Re-run \`npm run import\` with the localStorage snippet from README.md.`
    );
  }
  return entries;
}

const WRITE_PATHS = ['/rest/v1/', '/rpc/', '/functions/v1/', '/storage/v1/object'];
const MUTATING = new Set(['POST', 'PUT', 'PATCH', 'DELETE']);

export const test = base.extend({
  blockedWrites: [
    async ({}, use) => {
      await use([]);
    },
    { scope: 'test' },
  ],

  context: async ({ context }, use) => {
    const entries = loadEntries();
    // Seed every captured entry BEFORE the app's inline script runs, so
    // supabase-js getSession() finds a complete, correctly-encoded session.
    await context.addInitScript((map) => {
      try {
        for (const [k, v] of Object.entries(map)) window.localStorage.setItem(k, v);
      } catch (e) {
        /* ignore */
      }
    }, entries);
    await use(context);
  },

  page: async ({ page, blockedWrites }, use) => {
    await page.route('**/*', async (route) => {
      const req = route.request();
      const url = req.url();
      const method = req.method();
      const isSupabase = url.includes('.supabase.co');
      const isAuth = url.includes('/auth/v1/'); // token refresh / user info — allowed
      const hitsData = WRITE_PATHS.some((p) => url.includes(p));

      if (isSupabase && !isAuth && hitsData && MUTATING.has(method)) {
        blockedWrites.push(`${method} ${url}`);
        return route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({ blockedByTest: true }),
        });
      }
      return route.continue();
    });
    await use(page);
  },
});

test.afterEach(async ({ blockedWrites }, testInfo) => {
  if (blockedWrites.length > 0) {
    testInfo.annotations.push({ type: 'blocked-writes', description: blockedWrites.join('\n') });
    throw new Error(
      `Read-only violation: this test triggered ${blockedWrites.length} write(s) that the guard blocked:\n` +
        blockedWrites.join('\n')
    );
  }
});

export { expect };
