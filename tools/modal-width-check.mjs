// Headless repro for the mobile modal-width bug (KNOWN_ISSUE_modal_width.md).
// Extracts the REAL <style> from app/index.html and rebuilds the minimal DOM
// that triggers it: a Contractors-style card table (td.card-action with two
// width:100% nowrap buttons) with a width:100% modal open over it, at 360px.
// Measures whether the layout viewport / modal inflate past the device width.
//
// Run: node tools/modal-width-check.mjs   (needs tools/ deps + system Chrome)
import { readFileSync, writeFileSync } from 'node:fs';
import { existsSync } from 'node:fs';
import puppeteer from 'puppeteer-core';

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const APP = new URL('../app/index.html', import.meta.url);
const html = readFileSync(APP, 'utf8');
const styleMatch = html.match(/<style[^>]*>([\s\S]*?)<\/style>/);
const style = styleMatch ? styleMatch[1] : '';

// A faithful slice of the Contractors table card + an open modal, inside #root.
const page = `<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>${style}</style></head>
<body><div id="root">
  <div class="wrap"><div class="card">
    <div class="table-scroll"><table><thead><tr>
      <th>Name</th><th>Company</th><th>Role</th><th>Payout</th><th>Status</th><th></th>
    </tr></thead><tbody>
      <tr>
        <td class="card-title">Juan Dela Cruz Santos</td>
        <td data-label="Company">Ability Builders</td>
        <td data-label="Role">Behavior Technician</td>
        <td data-label="Payout">Wise</td>
        <td data-label="Status"><span class="pill active">active</span></td>
        <td class="card-action" style="text-align:right;white-space:nowrap">
          <button class="btn ghost sm">Edit</button>
          <button class="btn ghost sm">Deactivate</button>
        </td>
      </tr>
    </tbody></table></div>
  </div></div>
  <div class="modal-bg"><div class="modal"><h2>Edit contractor</h2>
    <p>Some modal content that should fit the device width.</p>
    <button class="btn">Save</button></div></div>
</div></body></html>`;

const tmp = new URL('./.modal-width-repro.html', import.meta.url);
writeFileSync(tmp, page);

if (!existsSync(CHROME)) { console.error('Chrome not found at ' + CHROME); process.exit(2); }

const DEVICES = [360, 390, 414];
const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox'] });
let worst = 0;
try {
  for (const w of DEVICES) {
    const p = await browser.newPage();
    await p.setViewport({ width: w, height: 800, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
    await p.goto(tmp.href, { waitUntil: 'load' });
    const m = await p.evaluate(() => {
      const modal = document.querySelector('.modal');
      const action = document.querySelector('td.card-action');
      return {
        innerWidth: window.innerWidth,
        docScrollWidth: document.documentElement.scrollWidth,
        modalWidth: Math.round(modal.getBoundingClientRect().width),
        actionScrollWidth: action.scrollWidth,
      };
    });
    const overflow = Math.max(m.docScrollWidth, m.modalWidth) - w;
    worst = Math.max(worst, overflow);
    const ok = m.modalWidth <= w + 1 && m.docScrollWidth <= w + 1;
    console.log(`@${w}px  modal=${m.modalWidth}  innerW=${m.innerWidth}  docScrollW=${m.docScrollWidth}  cardAction.scrollW=${m.actionScrollWidth}  ${ok ? 'OK' : 'OVERFLOW +' + overflow}`);
    await p.close();
  }
} finally { await browser.close(); }
console.log(worst <= 1 ? '\nPASS — no horizontal overflow; modal fits device width.' : `\nFAIL — worst overflow +${worst}px`);
process.exit(worst <= 1 ? 0 : 1);
