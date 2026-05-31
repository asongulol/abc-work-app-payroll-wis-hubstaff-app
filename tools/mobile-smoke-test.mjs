#!/usr/bin/env node
// Mobile smoke test for app/index.html (single-file CDN-Babel React app).
//
// What it checks, per viewport:
//   1. No NEW console errors / uncaught page errors vs. a recorded baseline
//      (catches JSX/Babel transform breakage and React render crashes).
//   2. No horizontal overflow (document scrollWidth > viewport width).
//
// Usage:
//   node mobile-smoke-test.mjs --baseline   # record current errors as the allowed baseline
//   node mobile-smoke-test.mjs              # compare against baseline + overflow check
//
// Exits non-zero on failure. Prints a JSON report to stdout.

import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import puppeteer from 'puppeteer-core';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..');
const APP_DIR = path.join(REPO_ROOT, 'app');
const BASELINE_PATH = path.join(__dirname, 'baseline.json');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

const VIEWPORTS = [
  { name: 'mobile-360', width: 360, height: 740 },
  { name: 'mobile-390', width: 390, height: 844 },
  { name: 'mobile-414', width: 414, height: 896 },
  { name: 'tablet-768', width: 768, height: 1024 },
  { name: 'desktop-1024', width: 1024, height: 768 },
];

// Allow a few px of slop for scrollbars / sub-pixel rounding.
const OVERFLOW_TOLERANCE = 2;

const isBaseline = process.argv.includes('--baseline');

const MIME = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
};

function startServer() {
  return new Promise((resolve) => {
    const server = http.createServer(async (req, res) => {
      try {
        let urlPath = decodeURIComponent(req.url.split('?')[0]);
        if (urlPath === '/') urlPath = '/index.html';
        const filePath = path.join(APP_DIR, urlPath);
        if (!filePath.startsWith(APP_DIR)) {
          res.writeHead(403);
          return res.end('forbidden');
        }
        const data = await readFile(filePath);
        res.writeHead(200, { 'Content-Type': MIME[path.extname(filePath)] || 'application/octet-stream' });
        res.end(data);
      } catch {
        res.writeHead(404);
        res.end('not found');
      }
    });
    server.listen(0, '127.0.0.1', () => resolve(server));
  });
}

// Normalize an error message so cache-busting numbers / urls / hex ids don't
// cause spurious baseline mismatches.
function normalize(msg) {
  return String(msg)
    .replace(/https?:\/\/[^\s)'"]+/g, '<url>')
    .replace(/:\d+:\d+/g, ':<pos>')
    .replace(/0x[0-9a-f]+/gi, '<hex>')
    .replace(/\b\d{3,}\b/g, '<n>')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 300);
}

async function captureViewport(browser, baseUrl, vp) {
  const page = await browser.newPage();
  await page.setViewport({ width: vp.width, height: vp.height, deviceScaleFactor: 2 });
  const errors = new Set();
  page.on('console', (m) => {
    if (m.type() === 'error') errors.add(normalize(m.text()));
  });
  page.on('pageerror', (e) => errors.add(normalize(e.message)));

  await page.goto(baseUrl, { waitUntil: 'networkidle2', timeout: 45000 }).catch((e) => {
    errors.add(normalize('NAV_FAIL ' + e.message));
  });
  // Give in-browser Babel + React a moment to transform & mount.
  await new Promise((r) => setTimeout(r, 2500));

  const probe = await page.evaluate(() => {
    const de = document.documentElement;
    const scrollW = Math.max(de.scrollWidth, document.body ? document.body.scrollWidth : 0);
    const root = document.getElementById('root');
    return {
      scrollWidth: scrollW,
      clientWidth: de.clientWidth,
      innerWidth: window.innerWidth,
      rootMounted: !!root && root.childElementCount > 0,
    };
  });

  await page.close();
  return { viewport: vp.name, width: vp.width, errors: [...errors], overflow: probe, rootMounted: probe.rootMounted };
}

async function main() {
  if (!existsSync(CHROME)) {
    console.error(JSON.stringify({ ok: false, reason: 'Chrome not found at ' + CHROME }, null, 2));
    process.exit(2);
  }
  const server = await startServer();
  const { port } = server.address();
  const baseUrl = `http://127.0.0.1:${port}/index.html`;

  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: 'new',
    args: ['--no-sandbox', '--disable-dev-shm-usage'],
  });

  const results = [];
  for (const vp of VIEWPORTS) {
    results.push(await captureViewport(browser, baseUrl, vp));
  }

  await browser.close();
  server.close();

  if (isBaseline) {
    const allErrors = new Set();
    for (const r of results) r.errors.forEach((e) => allErrors.add(e));
    writeFileSync(BASELINE_PATH, JSON.stringify({ errors: [...allErrors] }, null, 2));
    console.log(JSON.stringify({ ok: true, mode: 'baseline', recorded: allErrors.size, errors: [...allErrors] }, null, 2));
    process.exit(0);
  }

  const baseline = existsSync(BASELINE_PATH)
    ? new Set(JSON.parse(readFileSync(BASELINE_PATH, 'utf8')).errors)
    : new Set();

  const report = { ok: true, mode: 'check', viewports: [] };
  for (const r of results) {
    const newErrors = r.errors.filter((e) => !baseline.has(e));
    const overflowPx = r.overflow.scrollWidth - r.overflow.innerWidth;
    const hasOverflow = overflowPx > OVERFLOW_TOLERANCE;
    const pass = newErrors.length === 0 && !hasOverflow && r.rootMounted;
    if (!pass) report.ok = false;
    report.viewports.push({
      viewport: r.viewport,
      width: r.width,
      pass,
      rootMounted: r.rootMounted,
      newErrors,
      overflowPx,
      scrollWidth: r.overflow.scrollWidth,
      innerWidth: r.overflow.innerWidth,
    });
  }

  console.log(JSON.stringify(report, null, 2));
  process.exit(report.ok ? 0 : 1);
}

main().catch((e) => {
  console.error(JSON.stringify({ ok: false, reason: String(e && e.stack || e) }, null, 2));
  process.exit(2);
});
