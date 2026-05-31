// Shared test fixture: a `test` that
//   1. injects the captured prod Supabase session into the LOCAL origin's
//      localStorage before any page script runs (origin-independent JWT), and
//   2. installs a network WRITE-GUARD so no test can ever mutate prod data:
//      GET/HEAD and auth-token refresh pass through; any POST/PATCH/PUT/DELETE
//      to the Supabase REST / RPC / Storage / Edge-Function endpoints is blocked
//      and recorded. Reads against your real data are allowed (read-only).
//
// Import { test, expect } from this file instead of '@playwright/test'.

import base, { expect } from '@playwright/test';
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SESSION_FILE = path.join(__dirname, '.auth', 'supabase-session.json');

function loadSession() {
  if (!existsSync(SESSION_FILE)) {
    throw new Error(
      `No captured session at ${SESSION_FILE}. Run \`npm run capture\` first (completes the Google login once).`
    );
  }
  const { tokenKey, token } = JSON.parse(readFileSync(SESSION_FILE, 'utf8'));
  if (!tokenKey || !token) throw new Error('Captured session file is missing tokenKey/token.');
  return { tokenKey, token };
}

// A mutating request to one of these Supabase data paths is a prod write — block it.
const WRITE_PATHS = ['/rest/v1/', '/rpc/', '/functions/v1/', '/storage/v1/object'];
const MUTATING = new Set(['POST', 'PUT', 'PATCH', 'DELETE']);

export const test = base.extend({
  // Per-test record of anything the guard blocked (asserted in afterEach).
  blockedWrites: [
    async ({}, use) => {
      await use([]);
    },
    { scope: 'test' },
  ],

  context: async ({ context }, use) => {
    const { tokenKey, token } = loadSession();

    // Seed the session BEFORE the app's inline script runs, on whatever origin
    // the test navigates to (here: the local server). supabase-js reads this
    // key in getSession() and treats us as logged in.
    await context.addInitScript(
      ([k, v]) => {
        try {
          window.localStorage.setItem(k, v);
        } catch (e) {
          /* ignore */
        }
      },
      [tokenKey, token]
    );

    await use(context);
  },

  page: async ({ page, blockedWrites }, use) => {
    // Network write-guard. Allow the auth token endpoint (session refresh) even
    // though it's a POST; block mutations to the data endpoints.
    await page.route('**/*', async (route) => {
      const req = route.request();
      const url = req.url();
      const method = req.method();
      const isSupabase = url.includes(`.supabase.co`);
      const isAuth = url.includes('/auth/v1/'); // token refresh, user info
      const hitsData = WRITE_PATHS.some((p) => url.includes(p));

      if (isSupabase && !isAuth && hitsData && MUTATING.has(method)) {
        blockedWrites.push(`${method} ${url}`);
        // Fulfill with a benign response so the UI doesn't throw — but nothing
        // reaches the database.
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

// After every test: fail loudly if the guard had to block a write — it means a
// test triggered a mutation it shouldn't have (these tests are read-only).
test.afterEach(async ({ blockedWrites }, testInfo) => {
  if (blockedWrites.length > 0) {
    testInfo.annotations.push({
      type: 'blocked-writes',
      description: blockedWrites.join('\n'),
    });
    throw new Error(
      `Read-only violation: this test triggered ${blockedWrites.length} write(s) that the guard blocked:\n` +
        blockedWrites.join('\n')
    );
  }
});

export { expect };
