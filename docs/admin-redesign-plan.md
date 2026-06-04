# Admin App Redesign Plan — Guideline-Aligned, Reversible

**Target:** `app/index.html` (admin, single-file in-browser-Babel React, ~9,450 lines), served at payroll.abbilabs.com via Cloudflare (git-connected to `main`, auto-deploy ~15s).
**Driver:** `docs/ux-ui-guidelines.md` (owner's research-backed UX/UI guidelines) + the gaps found in the structural audit (2026-06-04).
**Status:** PLAN — not yet started. The site works ~95%; redesign must be reversible at every step.

## Owner decisions (2026-06-04)
1. **Rollback = frozen `legacy.html` + runtime toggle + git tag** (instant per-user AND global revert, no redeploy).
2. **Scope = full redesign, all 6 phases.**
3. **Build location = isolated git worktree** off `main` (same approach that worked for the mobile-first redesign — see `project_mobile_redesign`).

---

## Guiding principles (from the guidelines)
- **Function first; beauty is functional.** Don't let polish hide a broken workflow — this is a money app.
- **Additive & mobile-first.** RECURRING TRAP (from the mobile redesign): a property added to a BASE (unprefixed) CSS rule leaks to desktop. Gate mobile-only rules inside `@media`; preserve desktop >=1024px.
- **Reversible per phase.** Each phase ships independently, is smoke-tested, and can be flipped off via the kill-switch.

---

## Phase 0 — Safety harness & rollback (DO FIRST)

### A. Worktree
- Create a worktree off `main` (e.g. `/Users/olivertrinidad/Documents/GitHub/abc-work-app-payroll-admin-redesign`, branch `feature/admin-redesign`). All edits happen there, never on `main` directly. Retire with `git worktree remove`, not `rm -rf`.

### B. Frozen legacy escape hatch
- Copy current `app/index.html` -> `app/legacy.html` **byte-for-byte** (the known-good 95% site). Commit once. Do NOT maintain it afterward — it's a frozen escape hatch, retired once the new design is proven.
- Verify Cloudflare serves `/legacy.html` (check the routing/`_routes`/wrangler config; confirm payroll.abbilabs.com/legacy.html resolves to `app/legacy.html`). If the host rewrites all paths to index.html, adjust config so legacy.html is reachable.
- Git-tag the known-good commit: `ui-classic-<yyyy-mm-dd>` (hard restore point + Cloudflare "rollback to previous deployment" as backstop).

### C. Runtime kill-switch (no redeploy to revert)
- Add an early inline script in `app/index.html` (before React mounts):
  - `?ui=classic` -> set `localStorage.eis_ui='classic'`; `?ui=new` -> clear it.
  - if `eis_ui==='classic'` -> `location.replace('/legacy.html'+location.hash)`.
- `legacy.html` gets a small top banner: "Classic design — Try the new design" linking to `/?ui=new`.
- New app topbar gets a quiet "Switch to classic" link -> `/?ui=classic`.
- Net effect: any user can instantly bounce to the old site; flipping the global default is a one-line change; Cloudflare/git tag is the hard backstop.

### D. Test harness (reuse + extend the mobile-redesign tooling)
- `npm run lint:html` (esbuild JSX check) — every edit.
- `tools/mobile-smoke-test.mjs` (headless Chrome at 360/390/414/768/1024; asserts React mounts, no new console errors vs baseline, no horizontal overflow). NOTE: only renders the login screen.
- `tools/modal-width-check.mjs` (rebuilds Contractors card + modal from real `<style>`; asserts zero overflow at 360/390/414).
- `tools/playwright/` (44 authed read-only tests at 360/390/414/768; network guard blocks writes). Session import via `npm run import` (see `project_mobile_redesign` for the clipboard dance).
- Update `tools/baseline.json` intentionally when console output legitimately changes.

**DoD:** legacy.html live + reachable; toggle works both ways; git tag pushed; smoke green on an unchanged worktree build.

---

## Phase 1 — Foundation (tokens, type, color, a11y contrast)
- **WCAG AA contrast audit + fix.** Gold `#D4A24C` on white is ~2:1 — fails AA for text. Restrict gold to large/non-text or pair with sufficient-contrast text; verify muted `#5c6677`/subtle `#8b94a4` meet 4.5:1; fix any failures. Tool: contrast-check the token pairs.
- **8pt spacing scale.** Reconcile the 4px token scale with ad-hoc 18/20px values into one disciplined scale.
- **Type scale.** Limit sizes/weights; hierarchy via weight first, then spacing; body line length ~50-75ch.
- **60-30-10.** Neutral-dominant surfaces, navy structure, gold accent ONLY on the single primary action per screen. Audit for accent overuse.
- **Semantic landmarks.** `<header>` (topbar), `<nav>` (tab bar), `<main>` (content), `<section>` per screen. Improve `:focus-visible` coverage.
- Mostly CSS + light JSX; low risk; immediately visible polish.
- **DoD:** AA contrast passes; landmarks present; smoke + modal-width green; desktop >=1024px visually unchanged except intended polish.

## Phase 2 — Feedback & perceived speed
- **Skeleton loaders** for data tables/cards (replace "Loading…" text); reserve space to kill layout shift.
- **Step-checklist + elapsed time** for >10s ops: payroll calculate, Wise draft/poll, time import, FX/rate fetch. Replaces disabled-button/spinner.
- Explicit success confirmations; optimistic updates with rollback where safe.
- **DoD:** every >10s op shows a step checklist; first paint shows skeletons; no layout shift on data load.

## Phase 3 — Forms & data entry (Baymard)
- Single-column modal layouts (ContractorProfile etc.).
- Inline validation on blur with field-level error text in plain language; preserve input on error/nav; correct input types (email/tel/number/date); disable submit in-flight.
- Mark required AND optional explicitly.
- Suppress duplicate entry: prefill known values, reuse captured data, flag missing rather than block.
- **DoD:** modals single-column; inline errors; no retype-on-error; required/optional labeled.

## Phase 4 — Payroll-critical safety & provenance
- **Risk-proportional confirmation.** Replace native `window.confirm()` on irreversible money actions (lock payroll, revert-to-unpaid, Wise draft/mark-paid, force-delete contractor) with a typed-confirmation modal naming the consequence + showing impact (build on the existing "billing-dirty" multi-contractor tracker). Keep soft confirms for low-risk; add Undo for reversible (e.g. approve time).
- **Data provenance** on money/time/status fields: where the value came from + when updated + verified. E.g. fx rate source + lock date (Wise vs market approximation — see `project_wise_fx_and_import_dupes`), hours source (Hubstaff API / CSV / manual) + sync time, payment status timestamps.
- **Recognition over recall:** hover tooltips on status pills, payout-method/payment-status enums, and period codes.
- Strengthen hierarchy on totals/variances; flag anomalies (time/pay mismatches, not-calculated periods, unreconciled Wise) instead of making the admin scan.
- **DoD:** typed confirm on the 4 irreversible actions; provenance visible on money/time fields; tooltips on coded values.

## Phase 5 — Dashboard & IA
- **Attention-first landing** surfacing what needs action: open-period status, pending approvals, drafts to send, unreconciled Wise, expiring docs, anomalies — not raw tables.
- Breadcrumbs for deep flows (period -> batch -> statement).
- Empty states that explain + offer the first action; in-context help tooltips.
- Nav is already 3 grouped sections (Setup / Run payroll / Review) — keep grouped (<=7 rule satisfied via grouping).
- **DoD:** dashboard surfaces actionable items; breadcrumbs on nested flows; empty states actionable.

## Phase 6 — Polish, motion, consistency, final a11y
- Consolidate button variants; one-symbol-one-meaning icon audit; document motion tokens (durations/easing/density); micro-interactions = trigger -> rules -> feedback -> loop.
- Full keyboard-nav + screen-reader pass; final adversarial QA via the workflow harnesses.
- Remove the kill-switch + retire `legacy.html` ONLY after sign-off and a stable period in prod.
- **DoD:** keyboard/SR pass clean; motion tokens documented; adversarial QA defects all resolved.

---

## Per-phase workflow (every phase)
edit in worktree -> `npm run lint:html` -> mobile-smoke + modal-width harness (+ Playwright when a session is handy) -> `npm run stamp` -> merge to `main` (auto-deploys) -> verify in prod behind/with toggle -> if regression: flip `?ui=classic` (instant) and fix.

## Risks & watch-items
- **CSS base-leak trap** (see above) — the #1 recurring bug on this file.
- **Gold AA contrast** — the most likely "looks fine but fails a11y" issue; handle in Phase 1.
- **legacy.html routing** — confirm Cloudflare serves it before relying on it (Phase 0 B).
- **Money-table read-only during QA** — Playwright network guard already blocks writes; keep it.
- **Brand identity preserved** — navy/gold stays; we only constrain *where* gold is used for AA, not the brand.
