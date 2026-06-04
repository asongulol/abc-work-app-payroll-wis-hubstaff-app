# Known issue: mobile modals render wider than the viewport — RESOLVED 2026-06-04

**Status: FIXED** (on `main`). Root cause confirmed and fixed at the source: in
mobile card-mode `td.card-action` was `display:block`, so its two `width:100%`
buttons (with inline `white-space:nowrap`) sat side-by-side and blew the cell's
min-content to ~560px, inflating the layout viewport and dragging the
`width:100%` modal wide. Fix = make `td.card-action` a flex COLUMN
(`display:flex;flex-direction:column;align-items:stretch;gap:6px;min-width:0`)
plus `min-width:0` on its `.btn`s, so the buttons stack (the intended mobile
design) and can't establish a wide min-content. No ancestor `overflow` clip is
used, so nothing is hidden (unlike the reverted `#root{overflow-x:clip}` try).

**Verified** headlessly with `tools/modal-width-check.mjs` (system Chrome via
puppeteer-core), which rebuilds the Contractors card + open modal from the app's
real `<style>`: before = modal 604/664/712 @ 360/390/414 (reproduced the exact
bug); after = 360/390/414 with zero horizontal overflow. Re-run anytime:
`node tools/modal-width-check.mjs`. The full authed Playwright suite's 3 `modal`
tests should now pass too — run for the official 44/44 when a fresh session is
handy (`cd tools/playwright && npm run import && npm test -- -g modal`).

---
Historical analysis (kept for reference):

## Symptom
`mobile-authed.spec.mjs` › "open + close the first modal on Contractors":
the `.modal` measures ~604px at a 360px device width (664 @390, 712 @414) —
roughly viewport × 1.68.

## Root cause (measured, high confidence)
It is NOT the modal itself. With the modal open, `window.innerWidth` /
`documentElement.scrollWidth` inflate from 360 → 604, i.e. the **mobile layout
viewport expands**, and the modal (which is `width:100%`) stretches to match.

Measured chain:
- In mobile card-mode the `.table-scroll:not(.keep-table)` wrapper is set to
  `overflow-x:visible` (app/index.html, the Phase-2 `@media (max-width:767px)`
  block, the `.table-scroll:not(.keep-table){overflow-x:visible}` line).
- The background Contractors table's action cell `td.card-action`
  ("Edit"/"Deactivate") holds two `width:100%` `.btn`s laid out inline with
  `white-space:nowrap` → ~560px of content in a ~280px cell.
- Because nothing at the page level clips horizontal overflow, that content
  leaks out and inflates the layout viewport → drags the modal wide.

## What was tried and RULED OUT (do not repeat)
Per-element fixes do NOT work because the cause is a missing page-level clip:
- `.modal{min-width:0}` / `overflow-x:hidden` — no effect (modal is a victim).
- `.bottom-nav` flex/`width:100vw`/`contain` and `td.card-action`
  stack/`white-space:normal`/`overflow:hidden` — all still measured 600–604.

## The candidate that worked in ISOLATION but FAILED the full suite
`@media (max-width:767px){#root{overflow-x:clip}}` brought innerWidth + modal
width back to exactly 360 in a focused measurement (4 root/wrapper clip
variants all passed in isolation). BUT a full authed-suite run with it showed a
**new** crop of `toBeVisible` failures at mobile-360 — `overflow-x:clip` at
`#root` appears to clip/hide content the tests expect visible (or that run was
polluted by stale test servers; two `node server.mjs` procs were found running).
It was reverted; nothing of it is committed.

## Recommended next step (fresh session)
1. Kill ALL stale `node server.mjs` / `playwright` procs first; confirm ports
   4178/419x free. The dueling servers likely corrupted at least one run.
2. Re-test `#root{overflow-x:clip}` in a clean env with ONE full suite. If the
   `toBeVisible` failures are real (not pollution), the safer fix is to contain
   overflow on a wrapper that is NOT an ancestor whose clip hides content — e.g.
   wrap each card-mode table row's overflow, or make `td.card-action` a real
   column (`display:flex;flex-direction:column`) AND add `min-width:0` on the
   stacked `.table-scroll` cells so the action buttons can't establish a wide
   min-content. Measure innerWidth (not just modal width) after EACH change.
3. Only commit after a genuine 44/44 green full run + login smoke still green.

## Repro / diagnostic tooling
- Run the failing tests: `cd tools/playwright && npm test -- -g "modal"`.
- The session must be imported first (`npm run import`; see README + the
  Cloudflare note). Token expires ~1h.
- Diagnostic scripts used to find the root cause were throwaways and have been
  removed; recreate as needed (they injected the session, opened the modal at
  360px, and bisected the DOM for the element whose hiding restored
  innerWidth≈360 — that method is what isolated the cause to the page-level
  clip, so reuse it).
