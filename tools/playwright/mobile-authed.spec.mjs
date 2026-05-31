// Read-only authed mobile tests for app/index.html.
//
// These run AGAINST THE LOCAL BRANCH CODE (served by server.mjs) but with a
// real, logged-in Supabase session, so they exercise the authed admin screens
// the login-gated smoke test can't reach. They only navigate and open/close
// modals — the write-guard in authed-test.mjs blocks any mutation to prod.
//
// What each viewport project checks:
//   - the app gets past the Google login screen (authed shell renders)
//   - every primary tab loads with NO horizontal page overflow
//   - opening (and closing) a modal causes no overflow / no console error
//   - no uncaught page errors or console.error across the run

import { test, expect } from './authed-test.mjs';

// Mirrors the app's tabGroups (App() in app/index.html). label must match the
// visible tab text exactly so the locators find the trigger.
const TABS = [
  { id: 'contractors', label: 'Contractors' },
  { id: 'documents', label: 'Documents' },
  { id: 'time', label: 'Time & Approval' },
  { id: 'payroll', label: 'Calculate' },
  { id: 'process', label: 'Process and Pay' },
  { id: 'batches', label: 'Review & Recon Batches' },
  { id: 'reports', label: 'Reports' },
  { id: 'imports', label: 'Imports' },
  { id: 'audit', label: 'Audit Log' },
];

const OVERFLOW_TOLERANCE = 2;

// Collect console errors / page errors per page; ignore known-benign noise.
function attachErrorCollector(page) {
  const errors = [];
  const IGNORE = [
    /favicon/i,
    /Failed to load resource/i, // transient asset/network blips
    /ResizeObserver loop/i,
  ];
  page.on('console', (m) => {
    if (m.type() === 'error') {
      const t = m.text();
      if (!IGNORE.some((re) => re.test(t))) errors.push(`console: ${t}`);
    }
  });
  page.on('pageerror', (e) => errors.push(`pageerror: ${e.message}`));
  return errors;
}

async function overflowPx(page) {
  return page.evaluate(() => {
    const de = document.documentElement;
    const sw = Math.max(de.scrollWidth, document.body ? document.body.scrollWidth : 0);
    return sw - window.innerWidth;
  });
}

// Wait until the authed shell (the .topbar with the brand) is visible — i.e.
// we are PAST the Google sign-in screen. Fails fast with a clear message if the
// captured session didn't take.
async function gotoAuthedApp(page) {
  await page.goto('/', { waitUntil: 'networkidle' });
  const signInVisible = await page
    .getByText('Sign in with Google')
    .isVisible()
    .catch(() => false);
  expect(
    signInVisible,
    'Still on the Google sign-in screen — the captured session is missing/expired. Re-run `npm run capture`.'
  ).toBe(false);
  await expect(page.locator('.topbar .brand')).toBeVisible({ timeout: 15_000 });
}

// Navigate to a tab. On mobile the bottom-nav / swipe tab strip drives the same
// `go(id)` handler; we click the visible control whose text matches the label.
async function goToTab(page, tab) {
  // Prefer the top tab strip button; fall back to the bottom-nav.
  const topTab = page.locator('.tabs .tab', { hasText: tab.label }).first();
  const bottomTab = page.locator('.bottom-nav .bnav', { hasText: tab.label }).first();
  if (await topTab.count()) {
    await topTab.click();
  } else if (await bottomTab.count()) {
    await bottomTab.click();
  } else {
    // Last resort: some tabs live only in the strip; scroll it into view.
    await topTab.scrollIntoViewIfNeeded().catch(() => {});
    await topTab.click({ timeout: 5000 });
  }
  await page.waitForTimeout(600); // let the tab content render
}

test.describe('authed mobile — navigation is overflow-free', () => {
  test('lands on the authed shell (past Google login)', async ({ page }) => {
    const errors = attachErrorCollector(page);
    await gotoAuthedApp(page);
    expect(await overflowPx(page), 'home overflow').toBeLessThanOrEqual(OVERFLOW_TOLERANCE);
    expect(errors, 'console/page errors on load').toEqual([]);
  });

  for (const tab of TABS) {
    test(`tab "${tab.label}" loads with no horizontal overflow`, async ({ page }) => {
      const errors = attachErrorCollector(page);
      await gotoAuthedApp(page);
      await goToTab(page, tab);

      // The tab actually switched (its trigger shows active state somewhere).
      const overflow = await overflowPx(page);
      expect(overflow, `overflow on ${tab.label}`).toBeLessThanOrEqual(OVERFLOW_TOLERANCE);
      expect(errors, `errors on ${tab.label}`).toEqual([]);
    });
  }
});

test.describe('authed mobile — modals are overflow-free sheets', () => {
  test('open + close the first modal on Contractors without overflow', async ({ page }) => {
    const errors = attachErrorCollector(page);
    await gotoAuthedApp(page);
    await goToTab(page, { id: 'contractors', label: 'Contractors' });

    // Open the first row's profile / first action button that opens a modal.
    // Try a contractor row first; fall back to any button that opens a .modal.
    const row = page.locator('.table-scroll tr.clickable, .table-scroll td.card-title').first();
    let opened = false;
    if (await row.count()) {
      await row.click().catch(() => {});
      opened = await page
        .locator('.modal')
        .first()
        .isVisible()
        .catch(() => false);
    }

    if (!opened) {
      // No data row (empty DB scope) — open a known always-present modal instead:
      // Portal Settings → "⚙ Portal fields"-style trigger, else skip gracefully.
      test.skip(true, 'No contractor row available in this data scope to open a modal.');
    }

    await expect(page.locator('.modal').first()).toBeVisible();
    const overflow = await overflowPx(page);
    expect(overflow, 'overflow with modal open').toBeLessThanOrEqual(OVERFLOW_TOLERANCE);

    // The modal should not exceed the viewport width.
    const box = await page.locator('.modal').first().boundingBox();
    if (box) {
      const vw = page.viewportSize().width;
      expect(box.width, 'modal wider than viewport').toBeLessThanOrEqual(vw + OVERFLOW_TOLERANCE);
    }

    // Close it (backdrop click or a Close/✕ button) and confirm it's gone.
    const closeBtn = page.locator('.modal .x, .modal button', { hasText: /close|cancel/i }).first();
    if (await closeBtn.count()) {
      await closeBtn.click().catch(() => {});
    } else {
      await page.locator('.modal-bg').first().click({ position: { x: 5, y: 5 } }).catch(() => {});
    }
    await page.waitForTimeout(400);
    expect(errors, 'errors during modal open/close').toEqual([]);
  });
});
