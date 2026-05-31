// Import a Supabase session WITHOUT driving a browser through Cloudflare.
//
// Use this when `npm run capture` gets stuck on Cloudflare's "verify you are
// human" challenge — that challenge trips on the Playwright-automated browser.
// Your NORMAL Chrome has already passed Cloudflare and is logged in, so we just
// copy the session JWT out of it.
//
// STEP 1 — in your normal Chrome, on https://payroll.abbilabs.com (logged in),
//          open DevTools (Cmd+Opt+J) → Console, paste this one line, hit Enter:
//
//   copy(JSON.stringify({tokenKey:Object.keys(localStorage).find(k=>/^sb-.*-auth-token$/.test(k)),token:localStorage.getItem(Object.keys(localStorage).find(k=>/^sb-.*-auth-token$/.test(k)))}))
//
//   (It copies the session to your clipboard. "undefined" copied = you're not
//    logged in on that tab — sign in first, then re-run the line.)
//
// STEP 2 — back in the terminal:
//
//   npm run import        # reads your clipboard (macOS pbpaste) and saves it
//
// Alternatives if clipboard reading is blocked:
//   pbpaste | npm run import          # pipe it in
//   npm run import -- path/to/file    # or read from a file you pasted into

import { execSync } from 'node:child_process';
import { mkdir, writeFile, readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const AUTH_DIR = path.join(__dirname, '.auth');
const SESSION_FILE = path.join(AUTH_DIR, 'supabase-session.json');
const DEFAULT_REF = 'cgsidolrauzsowqlllsz';
const DEFAULT_KEY = `sb-${DEFAULT_REF}-auth-token`;

async function readStdin() {
  if (process.stdin.isTTY) return '';
  const chunks = [];
  for await (const c of process.stdin) chunks.push(c);
  return Buffer.concat(chunks).toString('utf8');
}

function fromClipboard() {
  try {
    return execSync('pbpaste', { encoding: 'utf8' });
  } catch {
    return '';
  }
}

async function getRawInput() {
  const fileArg = process.argv[2];
  if (fileArg) {
    return { raw: await readFile(fileArg, 'utf8'), source: `file ${fileArg}` };
  }
  const piped = await readStdin();
  if (piped.trim()) return { raw: piped, source: 'stdin (piped)' };
  const clip = fromClipboard();
  if (clip.trim()) return { raw: clip, source: 'clipboard (pbpaste)' };
  return { raw: '', source: 'none' };
}

// Accept either: the {tokenKey, token} JSON from the console snippet, OR a bare
// token string (the value of the localStorage key), OR the value double-encoded.
function normalize(raw) {
  const trimmed = raw.trim().replace(/^['"]|['"]$/g, '');
  if (!trimmed) return null;

  // Case 1: the snippet's wrapper object.
  try {
    const obj = JSON.parse(trimmed);
    if (obj && typeof obj === 'object' && obj.token) {
      return { tokenKey: obj.tokenKey || DEFAULT_KEY, token: obj.token };
    }
    // Case 2: it parsed to the supabase session object itself (has access_token).
    if (obj && typeof obj === 'object' && (obj.access_token || obj.currentSession || obj.user)) {
      return { tokenKey: DEFAULT_KEY, token: trimmed };
    }
  } catch {
    /* not JSON — fall through */
  }

  // Case 3: a bare token string that itself is the stored value.
  return { tokenKey: DEFAULT_KEY, token: trimmed };
}

function describe(token) {
  let email = '(unknown)';
  let expiresAt = null;
  try {
    const parsed = JSON.parse(token);
    email = parsed?.user?.email || parsed?.currentSession?.user?.email || email;
    expiresAt = parsed?.expires_at || parsed?.currentSession?.expires_at || null;
  } catch {
    /* opaque token string — still usable */
  }
  return { email, expiresAt };
}

async function main() {
  const { raw, source } = await getRawInput();
  if (!raw.trim()) {
    console.error(
      '✗ Nothing to import.\n' +
        '  In your normal Chrome (logged in at payroll.abbilabs.com), open DevTools\n' +
        '  → Console and run:\n\n' +
        "    copy(JSON.stringify({tokenKey:Object.keys(localStorage).find(k=>/^sb-.*-auth-token$/.test(k)),token:localStorage.getItem(Object.keys(localStorage).find(k=>/^sb-.*-auth-token$/.test(k)))}))\n\n" +
        '  then run `npm run import` again.'
    );
    process.exit(1);
  }

  const norm = normalize(raw);
  if (!norm || !norm.token || norm.token === 'null' || norm.token === 'undefined') {
    console.error(
      `✗ The ${source} content didn't contain a session token (got "${(norm?.token || '').slice(0, 24)}…").\n` +
        '  Make sure you ran the console snippet ON the logged-in payroll.abbilabs.com tab\n' +
        '  (a copied "undefined" means that tab is not signed in).'
    );
    process.exit(1);
  }

  const { email, expiresAt } = describe(norm.token);
  await mkdir(AUTH_DIR, { recursive: true });
  await writeFile(
    SESSION_FILE,
    JSON.stringify({ tokenKey: norm.tokenKey, token: norm.token, capturedFor: email, expiresAt }, null, 2)
  );

  console.log(`✓ Imported session from ${source}`);
  console.log(`  user: ${email}`);
  if (expiresAt) {
    const mins = Math.round((expiresAt * 1000 - Date.now()) / 60000);
    console.log(
      mins > 0
        ? `  access token expires in ~${mins} min (supabase-js auto-refreshes during a run).`
        : `  ⚠ access token already expired ${-mins} min ago — re-copy it and import again.`
    );
  }
  console.log(`  saved → ${SESSION_FILE} (gitignored)`);
  console.log('\nNow run:  npm test\n');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
