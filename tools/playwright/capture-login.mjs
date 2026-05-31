// One-time (per ~hour, until the token expires) login capture.
//
// Opens the REAL production app in a visible Chrome window so you can complete
// the Google sign-in (which is only whitelisted for the prod origin). Once the
// Supabase session lands in localStorage, it saves the auth token to a
// gitignored file that the tests inject into the local origin.
//
// Run:  npm run capture     (from tools/playwright/)
//
// Nothing here writes to your data — it only reads the session token your own
// browser already received.

import { chromium } from '@playwright/test';
import { mkdir, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const AUTH_DIR = path.join(__dirname, '.auth');
const SESSION_FILE = path.join(AUTH_DIR, 'supabase-session.json');

const PROD_URL = process.env.PROD_URL || 'https://payroll.abbilabs.com/';
const SUPABASE_REF = 'cgsidolrauzsowqlllsz';
const TOKEN_KEY = `sb-${SUPABASE_REF}-auth-token`;
const TIMEOUT_MS = 5 * 60 * 1000; // 5 minutes to finish the Google login

async function main() {
  await mkdir(AUTH_DIR, { recursive: true });

  const browser = await chromium.launch({ channel: 'chrome', headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log(`\n→ Opening ${PROD_URL}`);
  console.log('→ Complete the Google sign-in in the window that opened.');
  console.log('  Waiting for the Supabase session to appear (up to 5 min)…\n');

  await page.goto(PROD_URL, { waitUntil: 'domcontentloaded' });

  const deadline = Date.now() + TIMEOUT_MS;
  let token = null;
  while (Date.now() < deadline) {
    token = await page.evaluate((key) => window.localStorage.getItem(key), TOKEN_KEY).catch(() => null);
    if (token) break;
    await page.waitForTimeout(1000);
  }

  if (!token) {
    console.error('✗ Timed out without a session. Did the Google login complete?');
    await browser.close();
    process.exit(1);
  }

  // Sanity: pull the user email out of the token for confirmation.
  let email = '(unknown)';
  let expiresAt = null;
  try {
    const parsed = JSON.parse(token);
    email = parsed?.user?.email || email;
    expiresAt = parsed?.expires_at || null;
  } catch {
    /* token is an opaque string in some supabase-js versions; still usable */
  }

  await writeFile(
    SESSION_FILE,
    JSON.stringify({ tokenKey: TOKEN_KEY, token, capturedFor: email, expiresAt }, null, 2)
  );

  console.log(`✓ Session captured for ${email}`);
  if (expiresAt) {
    const mins = Math.round((expiresAt * 1000 - Date.now()) / 60000);
    console.log(`  Access token expires in ~${mins} min (supabase-js will auto-refresh during a test run).`);
  }
  console.log(`  Saved to ${SESSION_FILE} (gitignored).`);
  console.log('\nNow run:  npm test\n');

  await browser.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
