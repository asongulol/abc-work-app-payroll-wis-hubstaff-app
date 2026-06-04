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

process.exit(bad ? 1 : 0);
