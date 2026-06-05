// Headless layout check for the Phase-7 sidebar nav. Injects the app's REAL
// <style> into a mock shell (topbar + sidebar + content + bottom bar) and
// verifies at several widths: sidebar shows on desktop / hides on mobile, the
// bottom bar is the inverse, the collapse class shrinks the rail, and there is
// no horizontal page overflow. Run: node tools/nav-layout-check.mjs
import puppeteer from './node_modules/puppeteer-core/lib/esm/puppeteer/puppeteer-core.js';
import { readFileSync, writeFileSync } from 'node:fs';

const CHROME='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
// Read the file under test from argv (defaults to the admin-redesign worktree, since
// puppeteer lives in THIS repo's tools/node_modules but the nav lives on the branch).
const FILE=process.argv[2]||'/Users/olivertrinidad/Documents/GitHub/abc-work-app-payroll-admin-redesign/app/index.html';
const html=readFileSync(FILE,'utf8');
const css=html.match(/<style>([\s\S]*?)<\/style>/)[1];

const GROUPS=[['Home',[['overview','Overview']]],['Setup',[['contractors','Contractors'],['onboarding','Onboarding'],['documents','Documents']]],
  ['Run payroll',[['time','Time & Approval'],['payroll','Calculate'],['process','Process and Pay']]],
  ['Review',[['batches','Review & Recon Batches'],['reports','Reports'],['imports','Imports'],['audit','Audit Log']]]];
const sidebar=GROUPS.map(([lbl,items])=>`<div class="side-group"><div class="side-group-label">${lbl}</div>`+
  items.map(([id,t])=>`<button class="side-item${id==='overview'?' active':''}"><span class="side-ico">●</span><span class="side-label">${t}</span></button>`).join('')+`</div>`).join('');
const bottom=['Home','Time','Calc','Pay','More'].map(t=>`<button class="bnav"><span class="bnav-ico">●</span><span>${t}</span></button>`).join('');
const page=(collapsed)=>`<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>${css}</style></head>
<body><header class="topbar"><h1 class="brand">HR &amp; Payroll</h1></header>
<div class="shell"><nav class="sidebar${collapsed?' collapsed':''}">${sidebar}</nav>
<main class="wrap" id="main"><div style="height:1600px">tall content</div></main></div>
<nav class="bottom-nav">${bottom}</nav></body></html>`;

const browser=await puppeteer.launch({executablePath:CHROME,headless:'new',args:['--no-sandbox']});
let fail=0; const ck=(n,c)=>{console.log(`  ${c?'PASS':'FAIL'}  ${n}`);if(!c)fail++;};
const metrics=p=>p.evaluate(()=>{
  const sb=document.querySelector('.sidebar'), bn=document.querySelector('.bottom-nav');
  const de=document.documentElement;
  return { side:sb?Math.round(sb.getBoundingClientRect().width):0,
           sideDisp:sb?getComputedStyle(sb).display:'none',
           bnDisp:bn?getComputedStyle(bn).display:'none',
           overflow:de.scrollWidth-de.clientWidth };
});
try{
  writeFileSync('/tmp/_nav.html',page(false));
  for(const w of [1440,1024,769]){
    const p=await browser.newPage(); await p.setViewport({width:w,height:900}); await p.goto('file:///tmp/_nav.html');
    const m=await metrics(p);
    ck(`@${w}: sidebar visible (${m.side}px)`, m.sideDisp!=='none' && m.side>150);
    ck(`@${w}: bottom bar hidden`, m.bnDisp==='none');
    ck(`@${w}: no horizontal overflow (${m.overflow})`, m.overflow<=1);
    await p.close();
  }
  for(const w of [768,414,360]){
    const p=await browser.newPage(); await p.setViewport({width:w,height:780}); await p.goto('file:///tmp/_nav.html');
    const m=await metrics(p);
    ck(`@${w}: sidebar hidden`, m.sideDisp==='none' || m.side===0);
    ck(`@${w}: bottom bar visible`, m.bnDisp!=='none');
    ck(`@${w}: no horizontal overflow (${m.overflow})`, m.overflow<=1);
    await p.close();
  }
  // collapsed rail
  writeFileSync('/tmp/_nav_c.html',page(true));
  const pc=await browser.newPage(); await pc.setViewport({width:1440,height:900}); await pc.goto('file:///tmp/_nav_c.html');
  const mc=await metrics(pc);
  ck(`collapsed: rail is narrow (${mc.side}px, expect ~60)`, mc.side>40 && mc.side<90);
  ck(`collapsed: still no overflow (${mc.overflow})`, mc.overflow<=1);
}finally{ await browser.close(); }
console.log(fail?`\nFAIL (${fail})`:'\nALL NAV LAYOUT CHECKS PASSED');
process.exit(fail?1:0);
