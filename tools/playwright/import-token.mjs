// Import a Supabase session WITHOUT driving a browser through Cloudflare.
//
// Use this when `npm run capture` gets stuck on Cloudflare's "verify you are
// human" challenge — that challenge trips on the Playwright-automated browser.
// Your NORMAL Chrome has already passed Cloudflare and is logged in, so we copy
// the session out of it.
//
// STEP 1 — in your normal Chrome, on https://payroll.abbilabs.com (LOGGED IN),
//          open DevTools (Cmd+Opt+J) → Console, paste this one line, Enter:
//
//   copy(JSON.stringify(Object.fromEntries(Object.entries(localStorage).filter(([k])=>k.startsWith('sb-')))))
//
//   (Copies ALL Supabase localStorage entries to your clipboard. If it copies
//    "{}", that tab isn't signed in — sign in, then re-run the line.)
//
// STEP 2 — terminal:
//
//   npm run import          # reads the clipboard (macOS pbpaste) and saves it
//
// Alternatives if clipboard reading is blocked:
//   pbpaste | npm run import
//   npm run import -- path/to/file
//
// Back-compat: the older single-token snippet ({tokenKey, token}) and a raw
// session object are also accepted.

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
  if (fileArg && !fileArg.startsWith('--')) {
    return { raw: await readFile(fileArg, 'utf8'), source: `file ${fileArg}` };
  }
  const piped = await readStdin();
  if (piped.trim()) return { raw: piped, source: 'stdin (piped)' };
  const clip = fromClipboard();
  if (clip.trim()) return { raw: clip, source: 'clipboard (pbpaste)' };
  return { raw: '', source: 'none' };
}

// Safe summary of whatever we received — NEVER prints token VALUES, only
// structure: byte length, JSON-parseability, and (safe) key NAMES. This is the
// thing that ends a blind debug loop.
function diagnose(raw) {
  const t = String(raw || '');
  const lines = [];
  lines.push(`  bytes: ${t.length}`);
  const head = t.replace(/\s+/g, ' ').trim().slice(0, 80);
  lines.push(`  first 80 chars: ${JSON.stringify(head)}`);
  let parsed;
  try {
    parsed = JSON.parse(t.trim().replace(/^['"]|['"]$/g, ''));
    if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
      const keys = Object.keys(parsed);
      lines.push(`  parsed JSON object, ${keys.length} key(s): [${keys.join(', ')}]`);
      const hasAuth = keys.some((k) => /-auth-token(\.\d+)?$/.test(k));
      lines.push(`  has an "…-auth-token" key: ${hasAuth ? 'YES' : 'NO'}`);
    } else {
      lines.push(`  parsed JSON, but it's a ${Array.isArray(parsed) ? 'array' : typeof parsed}, not an object map`);
    }
  } catch (e) {
    lines.push(`  not valid JSON (${e.message.slice(0, 60)})`);
  }
  return lines.join('\n');
}

// Coerce whatever was pasted into a {key:value} localStorage entries map.
function toEntries(raw) {
  const trimmed = raw.trim().replace(/^['"]|['"]$/g, '');
  if (!trimmed) return null;
  let obj;
  try {
    obj = JSON.parse(trimmed);
  } catch {
    return null;
  }
  if (!obj || typeof obj !== 'object') return null;

  // Case A: full localStorage map { "sb-…": "…", … } — every value a string.
  const keys = Object.keys(obj);
  const looksLikeMap =
    keys.length > 0 && keys.every((k) => typeof obj[k] === 'string') && keys.some((k) => k.startsWith('sb-'));
  if (looksLikeMap) {
    const entries = {};
    for (const k of keys) if (k.startsWith('sb-')) entries[k] = obj[k];
    return entries;
  }

  // Case B: legacy wrapper { tokenKey, token } where token is a STRING.
  if (typeof obj.token === 'string') {
    return { [obj.tokenKey || DEFAULT_KEY]: obj.token };
  }

  // Case C: a raw session object (has access_token) — store it under the key.
  if (obj.access_token || obj.currentSession || obj.user) {
    return { [DEFAULT_KEY]: trimmed };
  }

  return null;
}

// Reassemble the auth-token value (handling chunked …auth-token.0/.1 keys and a
// base64- prefix) just to print a friendly who/expiry line. Best-effort.
function describe(entries) {
  const exact = entries[DEFAULT_KEY] != null ? entries[DEFAULT_KEY] : null;
  let value = exact;
  if (value == null) {
    const chunks = Object.keys(entries)
      .filter((k) => /-auth-token\.\d+$/.test(k))
      .sort((a, b) => Number(a.split('.').pop()) - Number(b.split('.').pop()));
    if (chunks.length) value = chunks.map((k) => entries[k]).join('');
  }
  if (value == null) {
    const anyKey = Object.keys(entries).find((k) => /-auth-token$/.test(k));
    value = anyKey ? entries[anyKey] : '';
  }
  let decoded = String(value || '');
  if (decoded.startsWith('base64-')) {
    try {
      decoded = Buffer.from(decoded.slice(7), 'base64').toString('utf8');
    } catch {
      /* leave as-is */
    }
  }
  let email = '(unknown)';
  let expiresAt = null;
  try {
    const p = JSON.parse(decoded);
    const sess = p.currentSession || p;
    email = sess?.user?.email || email;
    expiresAt = sess?.expires_at || null;
  } catch {
    /* opaque — fine */
  }
  return { email, expiresAt, authLen: String(value || '').length };
}

async function main() {
  const { raw, source } = await getRawInput();

  // --inspect: just show what's on the clipboard (safe), don't save anything.
  if (process.argv.includes('--inspect')) {
    console.log(`Inspecting ${source}:`);
    console.log(diagnose(raw));
    process.exit(0);
  }

  if (!raw.trim()) {
    console.error(
      '✗ Nothing to import.\n' +
        '  In your normal Chrome (LOGGED IN at payroll.abbilabs.com), DevTools → Console, run:\n\n' +
        "    copy(JSON.stringify(Object.fromEntries(Object.entries(localStorage).filter(([k])=>k.startsWith('sb-')))))\n\n" +
        '  then run `npm run import` again.'
    );
    process.exit(1);
  }

  const entries = toEntries(raw);
  if (!entries || Object.keys(entries).length === 0) {
    console.error(`✗ The ${source} content wasn't a recognizable Supabase session.\n`);
    console.error('  --- what I actually received (safe diagnostic; token values redacted) ---');
    console.error(diagnose(raw));
    console.error(
      '\n  Likely fixes:\n' +
        '  • If "parsed JSON object, keys: []"  → that tab is NOT signed in, OR the\n' +
        '    snippet ran on the wrong origin. Open https://payroll.abbilabs.com, make\n' +
        '    sure you see the APP (not the "Sign in" screen), then re-run the snippet.\n' +
        '  • If "not valid JSON" or the text looks like a command/these instructions →\n' +
        "    copy() didn't reach the clipboard. Use the no-clipboard path instead:\n" +
        '      1) In the Console run (it PRINTS the JSON; no copy needed):\n' +
        "         JSON.stringify(Object.fromEntries(Object.entries(localStorage).filter(([k])=>k.startsWith('sb-'))))\n" +
        '      2) Select the printed string, copy it, paste into a file, then:\n' +
        '         npm run import -- /path/to/that-file.txt\n' +
        '  • To just see the keys without importing:  npm run import -- --inspect'
    );
    process.exit(1);
  }

  // Hard validation: a real auth-token value must exist and not be garbage.
  const authKey = Object.keys(entries).find((k) => /-auth-token(\.\d+)?$/.test(k));
  const authVal = authKey ? String(entries[authKey] || '') : '';
  if (!authKey) {
    console.error('✗ No "…-auth-token" entry found in the copied data — are you signed in on that tab?');
    process.exit(1);
  }
  if (authVal.includes('[object Object]') || authVal.length < 40) {
    console.error(
      `✗ The auth-token value looks invalid (${authVal.length} chars${
        authVal.includes('[object Object]') ? ', literally "[object Object]"' : ''
      }).\n` +
        '  Use the NEW snippet (it copies the whole localStorage map, not a single key):\n\n' +
        "    copy(JSON.stringify(Object.fromEntries(Object.entries(localStorage).filter(([k])=>k.startsWith('sb-')))))\n"
    );
    process.exit(1);
  }

  const { email, expiresAt, authLen } = describe(entries);
  await mkdir(AUTH_DIR, { recursive: true });
  await writeFile(
    SESSION_FILE,
    JSON.stringify(
      { format: 'localStorage-v2', entries, capturedFor: email, expiresAt, keyCount: Object.keys(entries).length },
      null,
      2
    )
  );

  console.log(`✓ Imported ${Object.keys(entries).length} Supabase localStorage entr${Object.keys(entries).length === 1 ? 'y' : 'ies'} from ${source}`);
  console.log(`  user: ${email}  (auth-token ${authLen} chars)`);
  if (expiresAt) {
    const mins = Math.round((expiresAt * 1000 - Date.now()) / 60000);
    console.log(
      mins > 0
        ? `  access token expires in ~${mins} min (supabase-js auto-refreshes during a run).`
        : `  ⚠ access token expired ${-mins} min ago — re-copy from your browser and import again.`
    );
  }
  console.log(`  saved → ${SESSION_FILE} (gitignored)`);
  console.log('\nNow run:  npm test\n');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
