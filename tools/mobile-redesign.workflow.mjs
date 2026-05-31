export const meta = {
  name: 'mobile-redesign',
  description: 'Implement the 6-phase mobile-first redesign of app/index.html, with code review + headless smoke test gating each phase',
  phases: [
    { title: 'Phase 0 — Foundation & Audit' },
    { title: 'Phase 1 — Navigation & App Shell' },
    { title: 'Phase 2 — Tables to Cards' },
    { title: 'Phase 3 — Forms & Modals' },
    { title: 'Phase 4 — Dashboard & Cards' },
    { title: 'Phase 5 — Polish & QA' },
  ],
}

const REPO = '/Users/olivertrinidad/Documents/GitHub/abc-work-app-payroll-mobile'
const APP = REPO + '/app/index.html'
const SMOKE = `cd ${REPO}/tools && node mobile-smoke-test.mjs`

const SHARED = `
You are working on a SINGLE production file: ${APP}
It is a ~13,100-line single-file React app:
- React 18 + ReactDOM + @babel/standalone (JSX is transpiled IN THE BROWSER at runtime), Tailwind via CDN (cdn.tailwindcss.com), Supabase JS. App mounts at <div id="root">.
- Tailwind DEFAULT breakpoints: sm=640px, md=768px, lg=1024px, xl=1280px. The existing DESKTOP layout already relies heavily on \`lg:\` (≈295 uses) and \`md:\` (≈124).
- There is an inline <style> block; a small mobile fragment already exists (a @media (max-width:640px) block, an .mobile-card class, an h1 size rule). Build on it; do not duplicate it.

HARD RULES (violating any = failure):
1. Edit ONLY ${APP}. Touch NOTHING else (no tools/, no new files).
2. PURE UI/UX (CSS + JSX/className) ONLY. Do NOT change Supabase queries, edge functions, auth, state logic, event handlers, or any business logic.
3. MOBILE-FIRST + ADDITIVE: base/unprefixed classes target small screens; layer desktop with md:/lg:. PRESERVE the desktop experience at ≥1024px EXACTLY — do not remove or weaken existing lg:/md: behavior.
4. Keep the single-file architecture. No new dependencies, no build step, no <script src> changes.
5. Because Babel transforms JSX in-browser, a syntax error breaks the WHOLE app. Keep JSX valid: balanced tags, valid className strings, no stray braces.
6. Preserve accessibility: keep ARIA labels, focus states, keyboard nav; touch targets ≥44px on mobile.
7. Use the Read/Edit tools. For a file this large, locate the relevant sections with Grep first, then make targeted Edits. Do NOT rewrite the whole file.
`

const REVIEW_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['summary', 'acceptanceMet', 'findings'],
  properties: {
    summary: { type: 'string' },
    acceptanceMet: { type: 'boolean', description: "Does the diff satisfy this phase's acceptance criteria?" },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['severity', 'mustFix', 'title', 'location', 'detail'],
        properties: {
          severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
          mustFix: { type: 'boolean', description: 'true for critical/high issues that must be fixed before commit' },
          title: { type: 'string' },
          location: { type: 'string', description: 'approx line(s) or component name' },
          detail: { type: 'string' },
          suggestedFix: { type: 'string' },
        },
      },
    },
  },
}

const SMOKE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['passed', 'exitCode', 'failingViewports', 'newErrors'],
  properties: {
    passed: { type: 'boolean' },
    exitCode: { type: 'number' },
    failingViewports: { type: 'array', items: { type: 'string' } },
    newErrors: { type: 'array', items: { type: 'string' } },
    rawTail: { type: 'string', description: 'last ~1500 chars of the JSON report' },
  },
}

const IMPL_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['summary', 'sectionsTouched'],
  properties: {
    summary: { type: 'string' },
    sectionsTouched: { type: 'array', items: { type: 'string' } },
    notes: { type: 'string' },
  },
}

const COMMIT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['committed', 'sha', 'message'],
  properties: {
    committed: { type: 'boolean' },
    sha: { type: 'string' },
    message: { type: 'string' },
    filesInCommit: { type: 'array', items: { type: 'string' } },
  },
}

const PHASES = [
  {
    title: 'Phase 0 — Foundation & Audit',
    commitType: 'chore',
    body: `PHASE 0 — Foundation & Audit (NO visible change on any screen).
Objective: responsive groundwork.
- Verify <meta name="viewport"> is present and correct (width=device-width, initial-scale=1.0). Fix if wrong.
- In the inline <style>, add CSS custom properties documenting breakpoints and a spacing scale (e.g. --bp-sm, --bp-md, --bp-lg, --space-1..--space-6). Comment them.
- Add mobile utility classes: .hide-mobile (display:none below 640px), .show-mobile (shown only below 640px), .stack-mobile (flex-direction:column / single-column below 640px). Use @media (max-width:640px) and keep them additive.
- Audit fixed-width / overflow-prone areas (wide tables, modals, button rows) and drop concise inline {/* TODO:mobile - ... */} JSX comments OR <!-- TODO:mobile --> markers near them so later phases can find them. Do not restyle yet.
ACCEPTANCE: zero visual diff at any width; utilities defined; viewport correct.`,
  },
  {
    title: 'Phase 1 — Navigation & App Shell',
    commitType: 'feat',
    body: `PHASE 1 — Navigation & App Shell.
- Make the top-level nav/header mobile-friendly: a hamburger menu OR bottom tab bar below 768px; keep the existing desktop nav at lg:.
- Logo/title scales and truncates gracefully on narrow screens.
- Sticky header using env(safe-area-inset-top) for notched phones.
- Make sub-tab rows (profile tabs, admin tabs) horizontally scrollable / collapsible on mobile instead of wrapping or overflowing.
ACCEPTANCE: nav usable one-handed at 360px; NO horizontal page scroll; desktop nav unchanged at ≥1024px.`,
  },
  {
    title: 'Phase 2 — Tables to Cards',
    commitType: 'feat',
    body: `PHASE 2 — Tables → Responsive Cards (the #1 mobile pain point).
- Convert wide data tables (contractor lists, payroll runs, time entries) to stacked label/value CARD layouts below 768px while KEEPING the real <table> at md:/≥768px. Prefer CSS (e.g. data-label attributes + @media) so logic/markup stays intact; if JSX duplication is needed, render desktop table inside a \`hidden md:block\` wrapper and mobile cards inside a \`md:hidden\` wrapper using the SAME data — do not change the data source.
- Any table that must stay tabular on mobile: wrap in an overflow-x:auto container with a visible scroll affordance.
- Row actions become tap-friendly buttons ≥44px.
ACCEPTANCE: no data table causes horizontal PAGE scroll at 360px; all row actions reachable; desktop tables unchanged.`,
  },
  {
    title: 'Phase 3 — Forms & Modals',
    commitType: 'feat',
    body: `PHASE 3 — Forms & Modals.
- Modals become full-screen / slide-up sheets below 640px; stay centered dialogs at desktop.
- Form fields stack single-column on mobile; preserve multi-column grids at md:/lg:.
- Inputs/labels ≥16px font on mobile to prevent iOS auto-zoom.
- Sticky action bar (Save/Cancel) pinned to the bottom of modals on mobile, with safe-area inset.
ACCEPTANCE: every form/modal fully usable at 360px; no clipped/unreachable buttons; desktop dialogs unchanged.`,
  },
  {
    title: 'Phase 4 — Dashboard & Cards',
    commitType: 'feat',
    body: `PHASE 4 — Dashboard & Cards.
- Stat/summary grids reflow multi-column → single or two-column below 640px.
- Charts/visualizations scale to container width (max-width:100%, responsive height).
- Tune card padding and font sizes for small screens.
ACCEPTANCE: dashboard readable and reflowed at 360px; no overflow; desktop grid unchanged.`,
  },
  {
    title: 'Phase 5 — Polish & QA',
    commitType: 'style',
    body: `PHASE 5 — Polish & QA (final pass).
- Tap-target audit: ensure interactive elements ≥44px on mobile.
- Tighten spacing rhythm and font legibility at 360/390/414px; verify tablet 768px.
- Resolve any remaining {/* TODO:mobile */} markers left from Phase 0.
- Fix any lingering overflow, z-index, or safe-area issues.
- Re-confirm desktop ≥1024px is visually unchanged.
ACCEPTANCE: clean mobile walkthrough at all widths; desktop unchanged; no TODO:mobile markers left unaddressed.`,
  },
]

async function runSmoke(phaseTitle, attemptLabel) {
  return agent(
    `Run the mobile smoke test and report results.
Run exactly this command: ${SMOKE}
It prints a JSON report and exits 0 (pass) or non-zero (fail).
Parse the JSON. "passed" = top-level "ok" is true. Collect any viewport whose pass===false into failingViewports (use its "viewport" name), and union all "newErrors" arrays into newErrors. Put the last ~1500 chars of the JSON into rawTail. Report the process exit code in exitCode.
Do NOT edit any files. Just run and report.`,
    { label: `smoke:${attemptLabel}`, phase: phaseTitle, schema: SMOKE_SCHEMA, model: 'haiku' }
  )
}

const results = []

for (let i = 0; i < PHASES.length; i++) {
  const p = PHASES[i]
  phase(p.title)
  log(`▶ ${p.title}`)

  // 1. Implement
  const impl = await agent(
    `${SHARED}\n\nIMPLEMENT THIS PHASE:\n${p.body}\n\nMake the edits now using Grep + Read + Edit. When done, report what you changed. Do NOT commit, do NOT run git, do NOT run the smoke test — later steps handle that.`,
    { label: `implement`, phase: p.title, schema: IMPL_SCHEMA }
  )

  // 2. Code review (of the uncommitted diff vs last commit)
  const review = await agent(
    `${SHARED}\n\nYou are an adversarial CODE REVIEWER. Review ONLY the uncommitted changes for this phase.
Inspect the diff: \`cd ${REPO} && git --no-pager diff HEAD -- app/index.html\`. You may also Read ${APP} for context. Do NOT edit anything.

This phase's intent and acceptance criteria:
${p.body}

Check rigorously:
- Did any HARD RULE get violated? (files other than app/index.html changed; logic/auth/Supabase/handler edits; new deps; desktop lg:/md: behavior removed or weakened; broken/unbalanced JSX; lost ARIA/focus.)
- Is the change actually mobile-first & additive, and does it meet the acceptance criteria?
- Correctness bugs, dead code, duplicated markup that could desync, z-index/overflow traps.
Mark findings critical/high (mustFix=true) only when they break a hard rule, break the build/render, regress desktop, or fail the acceptance criteria. Report concise, specific findings.`,
    { label: `review`, phase: p.title, schema: REVIEW_SCHEMA }
  )

  const mustFix = (review?.findings || []).filter((f) => f.mustFix)
  log(`  review: ${review?.findings?.length || 0} findings, ${mustFix.length} must-fix, acceptanceMet=${review?.acceptanceMet}`)

  // 3. Apply must-fix findings
  let fixApplied = false
  if (mustFix.length > 0) {
    fixApplied = true
    await agent(
      `${SHARED}\n\nA code review of this phase's uncommitted changes found MUST-FIX issues. Fix ONLY these, with minimal targeted Edits to ${APP}. Do not introduce new scope. Do not commit or run git.\n\nMUST-FIX FINDINGS:\n${JSON.stringify(mustFix, null, 2)}`,
      { label: `fix`, phase: p.title }
    )
  }

  // 4. Smoke-test gate, with bounded repair loop
  let smoke = await runSmoke(p.title, 'v1')
  let repairs = 0
  while (smoke && !smoke.passed && repairs < 2) {
    repairs++
    log(`  smoke FAILED (attempt ${repairs}) → repairing. failing=${(smoke.failingViewports || []).join(',')}`)
    await agent(
      `${SHARED}\n\nThe headless mobile smoke test FAILED after this phase's changes. Fix ${APP} so it passes. The gate fails on: a NEW console/Babel error (often a JSX syntax error that prevents the app from mounting), the React tree not mounting, or horizontal overflow ( document scrollWidth > viewport innerWidth ) at a viewport.
Failing viewports: ${JSON.stringify(smoke.failingViewports)}
New errors: ${JSON.stringify(smoke.newErrors)}
Report tail: ${smoke.rawTail || ''}
Diagnose the root cause in the changes you/we just made (check JSX balance and any element that can exceed the viewport width), fix it with targeted Edits, then stop (do not run git, do not run the test).`,
      { label: `repair:v${repairs}`, phase: p.title }
    )
    smoke = await runSmoke(p.title, `v${repairs + 1}`)
  }

  // 5. Commit (local only, never push)
  let commit = null
  if (smoke && smoke.passed) {
    commit = await agent(
      `Create a LOCAL git commit (do NOT push).
Run: \`cd ${REPO} && git add app/index.html && git --no-pager diff --cached --stat\` then commit with:
- subject: \`${p.commitType}(mobile): ${p.title.replace(/^Phase \d+ — /, '').toLowerCase()}\`
- a one-line body summarizing the change
- a trailer line exactly: \`Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>\`
Only app/index.html should be staged. After committing, report the short SHA (\`git rev-parse --short HEAD\`), the final message, and the files in the commit. Do NOT push, do NOT touch any other branch.`,
      { label: `commit`, phase: p.title, schema: COMMIT_SCHEMA, model: 'haiku' }
    )
    log(`  ✅ committed ${commit?.sha} — ${p.title}`)
  } else {
    log(`  ⛔ smoke still failing after ${repairs} repair(s); NOT committing ${p.title}. Halting.`)
  }

  results.push({
    phase: p.title,
    impl: impl?.summary,
    sectionsTouched: impl?.sectionsTouched,
    reviewSummary: review?.summary,
    acceptanceMet: review?.acceptanceMet,
    findings: review?.findings,
    mustFixCount: mustFix.length,
    fixApplied,
    repairs,
    smokePassed: !!(smoke && smoke.passed),
    smokeFailingViewports: smoke?.failingViewports || [],
    committed: !!(commit && commit.committed),
    sha: commit?.sha || null,
  })

  // Hard stop if a phase could not be made green — later phases build on this file.
  if (!(smoke && smoke.passed)) {
    log(`Stopping the workflow: ${p.title} did not reach a green smoke test.`)
    break
  }
}

return { phases: results }
