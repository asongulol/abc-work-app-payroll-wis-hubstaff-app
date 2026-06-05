// Headless test of the modal focus-trap algorithm used by useModalA11y.
// Builds a static modal DOM + the SAME keydown handler the hook ships, then
// drives real Chrome (puppeteer-core) to verify: focus moves in, Tab wraps at
// the boundaries, Shift+Tab wraps backward, focus can't escape, Escape closes
// only when escClose=true. Run: node tools/modal-a11y-check.mjs
import puppeteer from './node_modules/puppeteer-core/lib/esm/puppeteer/puppeteer-core.js';
import { writeFileSync } from 'node:fs';

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

// The focus-trap logic — must mirror useModalA11y's onKey exactly.
const TRAP = `
const SEL='a[href],button:not([disabled]),input:not([disabled]),select:not([disabled]),textarea:not([disabled]),[tabindex]:not([tabindex="-1"])';
function focusables(node){return Array.from(node.querySelectorAll(SEL)).filter(el=>el.offsetWidth>0||el.offsetHeight>0||el===document.activeElement);}
function onKey(e){
  const node=document.getElementById('modal');
  if(e.key==='Escape'){ if(window.__esc){ e.preventDefault(); e.stopPropagation(); window.__closed=true; } return; }
  if(e.key==='Tab'){
    const els=focusables(node); if(!els.length){ e.preventDefault(); return; }
    const first=els[0], last=els[els.length-1], active=document.activeElement;
    if(!node.contains(active)){ e.preventDefault(); first.focus(); return; }
    if(e.shiftKey && active===first){ e.preventDefault(); last.focus(); }
    else if(!e.shiftKey && active===last){ e.preventDefault(); first.focus(); }
  }
}
document.addEventListener('keydown', onKey, true);
const f=focusables(document.getElementById('modal')); if(f[0]) f[0].focus();
`;

function pageHtml(esc){
  return `<!doctype html><html><body>
    <button id="trigger">Open</button>
    <div class="modal-bg"><div id="modal" role="dialog" aria-modal="true">
      <h2 id="t">Title</h2>
      <button id="b-cancel">Cancel</button>
      <input id="b-input" />
      <button id="b-confirm">Confirm</button>
    </div></div>
    <button id="after">After (outside)</button>
    <script>window.__esc=${esc};window.__closed=false;${TRAP}</script>
  </body></html>`;
}

const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args:['--no-sandbox'] });
let failures = 0;
const check = (name, cond) => { console.log(`  ${cond?'PASS':'FAIL'}  ${name}`); if(!cond) failures++; };
const active = (page) => page.evaluate(()=>document.activeElement && document.activeElement.id);

try {
  // ---- escClose = true ----
  const page = await browser.newPage();
  writeFileSync('/tmp/_modal_esc.html', pageHtml('true'));
  await page.goto('file:///tmp/_modal_esc.html');
  check('focus moves to first control on open', await active(page) === 'b-cancel');
  await page.keyboard.press('Tab'); check('Tab -> input', await active(page) === 'b-input');
  await page.keyboard.press('Tab'); check('Tab -> confirm (last)', await active(page) === 'b-confirm');
  await page.keyboard.press('Tab'); check('Tab at last wraps -> first', await active(page) === 'b-cancel');
  await page.keyboard.down('Shift'); await page.keyboard.press('Tab'); await page.keyboard.up('Shift');
  check('Shift+Tab at first wraps -> last', await active(page) === 'b-confirm');
  await page.keyboard.press('Escape');
  check('Escape closes when escClose=true', await page.evaluate(()=>window.__closed) === true);

  // ---- escClose = false (data-entry forms) ----
  const page2 = await browser.newPage();
  writeFileSync('/tmp/_modal_noesc.html', pageHtml('false'));
  await page2.goto('file:///tmp/_modal_noesc.html');
  await page2.keyboard.press('Escape');
  check('Escape does NOT close when escClose=false', await page2.evaluate(()=>window.__closed) === false);
  // focus still trapped
  await page2.keyboard.press('Tab'); await page2.keyboard.press('Tab');
  check('focus stays inside dialog (no escClose)', await active(page2) === 'b-confirm');
} finally {
  await browser.close();
}
console.log(failures ? `\nFAIL (${failures})` : '\nALL FOCUS-TRAP CHECKS PASSED');
process.exit(failures ? 1 : 0);
