// Precompile the single-file apps for deployment: transpile + minify the
// in-browser <script type="text/babel"> block with esbuild and drop the ~2.8 MB
// babel-standalone runtime, so the browser no longer downloads Babel or transpiles
// ~700 KB of JSX on every visit (the dominant time-to-interactive cost).
//
//   node tools/build-apps.mjs            # build all apps into dist/
//   node tools/build-apps.mjs --check    # build to memory only, fail on any error
//
// SOURCE OF TRUTH stays the JSX files in app/ and portal/ (edited normally). This
// tool NEVER mutates them — it writes compiled copies into dist/<app>/ and copies
// every sibling asset verbatim. The compiled block is wrapped in an IIFE so it
// keeps the exact module-scope (no global leakage) the current data-type="module"
// babel block has. Point each Cloudflare Worker's asset directory at dist/<app>
// (or add a wrangler build step that runs this) to ship the compiled output.
//
// Run `node tools/stamp-build.mjs` BEFORE this so the dist copies carry the build
// stamp + matching version.txt.
import { readFileSync, writeFileSync, mkdirSync, rmSync, readdirSync, copyFileSync, statSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { transform } from 'esbuild';

const ROOT = new URL('../', import.meta.url);
const checkOnly = process.argv.includes('--check');

// Which HTML files in each app dir get compiled (the rest are copied verbatim).
const APPS = [
  { dir: 'app', html: ['index.html', 'legacy.html'] },
  { dir: 'portal', html: ['index.html'] },
];

const BABEL_BLOCK = /<script\b[^>]*type=["']text\/babel["'][^>]*>([\s\S]*?)<\/script>/g;
// babel-standalone CDN tag (any version), to be removed once we precompile.
const BABEL_CDN = /[ \t]*<script\b[^>]*src=["'][^"']*babel-standalone[^"']*["'][^>]*>\s*<\/script>\s*\n?/g;

async function compileHtml(rel, html) {
  if (!BABEL_BLOCK.test(html)) {
    throw new Error(`${rel}: no <script type="text/babel"> block found — nothing to compile`);
  }
  BABEL_BLOCK.lastIndex = 0;
  let blocks = 0, errors = 0;
  // Replace each babel block with a precompiled classic <script>.
  const out = await replaceAsync(html, BABEL_BLOCK, async (_full, code) => {
    blocks++;
    let res;
    try {
      res = await transform(code, {
        loader: 'jsx', jsx: 'transform',           // classic React.createElement runtime (matches babel-standalone default)
        minify: true, target: 'es2019', logLevel: 'silent',
      });
    } catch (e) {
      errors++;
      console.error(`${rel}: SYNTAX ERROR in babel block\n${(e && e.message) || e}`);
      return _full; // leave as-is; caller throws below
    }
    // Wrap in an IIFE to preserve the module-scope encapsulation the original
    // data-type="module" block had (no top-level leakage to global scope).
    return `<script>(function(){"use strict";\n${res.code.trim()}\n})();</script>`;
  });
  if (errors) throw new Error(`${rel}: ${errors} babel block(s) failed to compile`);
  const cleaned = out.replace(BABEL_CDN, '');
  if (BABEL_CDN.test(out) === false) {
    console.warn(`${rel}: WARN — babel-standalone CDN tag not found (already removed?)`);
  }
  const beforeKB = (Buffer.byteLength(html) / 1024).toFixed(0);
  const afterKB = (Buffer.byteLength(cleaned) / 1024).toFixed(0);
  console.log(`compiled ${rel}: ${blocks} block(s), ${beforeKB} KB → ${afterKB} KB`);
  return cleaned;
}

// async String.replace
async function replaceAsync(str, re, fn) {
  const parts = [];
  let last = 0, m;
  re.lastIndex = 0;
  while ((m = re.exec(str))) {
    parts.push(str.slice(last, m.index));
    parts.push(await fn(m[0], ...m.slice(1)));
    last = m.index + m[0].length;
  }
  parts.push(str.slice(last));
  return parts.join('');
}

function p(rel) { return fileURLToPath(new URL(rel, ROOT)); }

let failed = 0;
const distRoot = p('dist');
if (!checkOnly) { try { rmSync(distRoot, { recursive: true, force: true }); } catch { /* none */ } }

for (const app of APPS) {
  const srcDir = p(app.dir + '/');
  const outDir = p('dist/' + app.dir + '/');
  if (!checkOnly) mkdirSync(outDir, { recursive: true });
  for (const name of readdirSync(srcDir)) {
    if (statSync(srcDir + name).isDirectory()) continue;
    if (app.html.includes(name)) {
      try {
        const compiled = await compileHtml(app.dir + '/' + name, readFileSync(srcDir + name, 'utf8'));
        if (!checkOnly) writeFileSync(outDir + name, compiled);
      } catch (e) { failed++; console.error((e && e.message) || e); }
    } else if (!checkOnly) {
      copyFileSync(srcDir + name, outDir + name);   // _headers, favicon, logo, version.txt, …
    }
  }
}

if (failed) { console.error(`\nbuild-apps: ${failed} file(s) failed`); process.exit(1); }
console.log(checkOnly ? '\nbuild-apps: check OK' : `\nbuild-apps: wrote dist/ (point Cloudflare asset dirs at dist/app and dist/portal)`);
