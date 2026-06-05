// Stamp the current build time (+ short git sha) into both single-file apps so
// the footer "Build …" shows which version is live. Run before committing a
// deploy:  node tools/stamp-build.mjs
//
// Replaces the `const BUILD = "...";` line in app/index.html and
// portal/index.html with a fresh PHT timestamp. The sha is the CURRENT HEAD
// (i.e. the commit this build is based on) — good enough to identify the build.
import { readFileSync, writeFileSync } from 'node:fs';
import { execSync } from 'node:child_process';

const now = new Date();
const stamp = new Intl.DateTimeFormat('en-CA', {
  timeZone: 'Asia/Manila', year: 'numeric', month: '2-digit', day: '2-digit',
  hour: '2-digit', minute: '2-digit', hour12: false,
}).format(now).replace(',', '') + ' PHT';

let sha = '';
try { sha = execSync('git rev-parse --short HEAD', { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim(); } catch { /* not a git checkout */ }
const build = sha ? `${stamp} · ${sha}` : stamp;

for (const f of ['app/index.html', 'portal/index.html']) {
  const url = new URL('../' + f, import.meta.url);
  const src = readFileSync(url, 'utf8');
  const next = src.replace(/const BUILD = "[^"]*";/, `const BUILD = "${build}";`);
  if (next === src) { console.error(`WARN: BUILD marker not found in ${f}`); continue; }
  writeFileSync(url, next);
  // Tiny sibling file the running app fetches (no-store) to detect a new deploy
  // and self-reload — so a normal refresh always lands on the latest build, no
  // hard refresh needed. Must equal the BUILD constant above.
  const dir = f.replace(/\/index\.html$/, '');
  writeFileSync(new URL('../' + dir + '/version.txt', import.meta.url), build + '\n');
  console.log(`stamped ${f}: ${build}`);
}
