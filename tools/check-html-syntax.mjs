// Syntax-check the JSX inside the single-file in-browser-Babel apps. ESLint
// can't lint these cleanly (JSX in <script type="text/babel"> with implicit
// React/app globals), so we at least guarantee they PARSE via esbuild — a
// broken brace/tag here would white-screen the whole app in the browser.
//
// Run: node tools/check-html-syntax.mjs   (part of `npm run lint`)
import { readFileSync } from 'node:fs';
import { transform } from 'esbuild';

const FILES = ['app/index.html', 'portal/index.html'];
let bad = 0;

for (const f of FILES) {
  const html = readFileSync(new URL('../' + f, import.meta.url), 'utf8');
  const re = /<script[^>]*type=["']text\/babel["'][^>]*>([\s\S]*?)<\/script>/g;
  let m, code = '', blocks = 0;
  while ((m = re.exec(html))) { code += '\n' + m[1]; blocks++; }
  if (!blocks) { console.error(`${f}: no <script type="text/babel"> block found`); bad++; continue; }
  try {
    await transform(code, { loader: 'jsx', logLevel: 'silent' });
    console.log(`${f}: OK (${blocks} babel block${blocks > 1 ? 's' : ''})`);
  } catch (e) {
    bad++;
    console.error(`${f}: SYNTAX ERROR`);
    console.error((e && e.message) || e);
  }
}

// --- Agreement merge-engine drift guard ------------------------------------
// mergeAgreement / agAddendum / monthlyFromPeriod must stay identical (after
// normalization) across the admin app, the kill-switch classic copy, and the
// portal — they render the SAME shared agreement_templates. A silent drift here
// is a legal-integrity bug (legacy.html once dropped {{company_name}} /
// {{monthly_rate}} / addendum auto-append).
function extractFn(src, name) {
  const start = src.indexOf('function ' + name + '(');
  if (start < 0) return null;
  const open = src.indexOf('{', start);
  if (open < 0) return null;
  let depth = 0;
  for (let j = open; j < src.length; j++) {
    const c = src[j];
    if (c === '{') depth++;
    else if (c === '}') { depth--; if (depth === 0) return src.slice(start, j + 1); }
  }
  return null;
}
const norm = s => s.replace(/\/\/[^\n]*/g, '').replace(/\s+/g, ' ').trim();
const MERGE_FILES = ['app/index.html', 'portal/index.html', 'app/legacy.html'];
const MERGE_FNS = ['agAddendum', 'monthlyFromPeriod', 'mergeAgreement'];
const mergeSrcs = MERGE_FILES.map(f => readFileSync(new URL('../' + f, import.meta.url), 'utf8'));
for (const fn of MERGE_FNS) {
  const variants = mergeSrcs.map((s, i) => ({ file: MERGE_FILES[i], body: extractFn(s, fn) }));
  const missing = variants.filter(v => !v.body);
  if (missing.length) { bad++; console.error(`merge-drift: ${fn} not found in ${missing.map(m => m.file).join(', ')}`); continue; }
  const ref = norm(variants[0].body);
  const diff = variants.slice(1).filter(v => norm(v.body) !== ref);
  if (diff.length) { bad++; console.error(`merge-drift: ${fn} differs in ${diff.map(d => d.file).join(', ')} vs ${MERGE_FILES[0]}`); }
  else console.log(`merge-sync: ${fn} identical across ${MERGE_FILES.length} files`);
}

process.exit(bad ? 1 : 0);
