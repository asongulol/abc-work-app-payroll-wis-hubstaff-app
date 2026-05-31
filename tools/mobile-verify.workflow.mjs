export const meta = {
  name: 'mobile-verify',
  description: 'Adversarially verify the committed mobile redesign against the pre-redesign baseline — find real defects on screens the login-only smoke test could not reach, refute each, return a confirmed punch-list',
  phases: [
    { title: 'Audit' },
    { title: 'Refute' },
    { title: 'Synthesize' },
  ],
}

const REPO = '/Users/olivertrinidad/Documents/GitHub/abc-work-app-payroll-mobile'
const APP = REPO + '/app/index.html'
const BASE = '6b68619' // last commit BEFORE any mobile-redesign work (pre-redesign baseline)
const HEAD = '24a653b' // Phase 5 commit (current)

const CONTEXT = `
TARGET FILE: ${APP} — a single-file React app (~8,330 lines): React 18 + ReactDOM + @babel/standalone (JSX transpiled IN-BROWSER), Tailwind CDN, Supabase. Mounts at <div id="root">.
A 6-phase mobile-first redesign was just committed on top of pre-redesign baseline commit ${BASE}. The full redesign diff is:
  cd ${REPO} && git --no-pager diff ${BASE} ${HEAD} -- app/index.html
You can view the ORIGINAL (pre-redesign) file with:  git show ${BASE}:app/index.html
and the CURRENT file with:  git show ${HEAD}:app/index.html  (or just Read ${APP}).

WHY THIS AUDIT EXISTS: the per-phase gate was a headless smoke test, but the app is behind a Google login gate, so the test only ever rendered the LOGIN screen. Every substantive change (nav shell, tables→cards, modals, dashboard) lives on AUTHED screens the test never exercised. Your job is to find REAL defects in those unverified areas by reading the JSX + CSS together. Use Grep/Read; do NOT edit anything.

HARD RULES the redesign was required to honor (a violation is a real finding):
1. Only app/index.html changed (the tools/ harness is out of scope — ignore it).
2. Pure UI/UX (CSS + className). No Supabase/auth/handler/state-logic changes.
3. Desktop preserved at >=1024px EXACTLY. Mobile-first/additive: new rules gated behind media queries; any change to a BASE (unprefixed) CSS rule must be visually inert at >=1024px.
4. Single file, no new deps.
5. JSX must stay valid (in-browser Babel; one syntax slip blanks the whole app).
6. Accessibility preserved; touch targets >=44px on mobile.
`

const FINDINGS_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['dimension', 'summary', 'findings'],
  properties: {
    dimension: { type: 'string' },
    summary: { type: 'string' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['id', 'severity', 'title', 'evidence', 'whyReal', 'suggestedFix'],
        properties: {
          id: { type: 'string', description: 'short stable slug, e.g. dup-chevron-mobile' },
          severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
          title: { type: 'string' },
          evidence: { type: 'string', description: 'exact line numbers / class names / code quoted from the CURRENT file' },
          whyReal: { type: 'string', description: 'concrete reason this is a defect (broken render, desktop regression, dead style, unreachable control, a11y loss, etc.)' },
          suggestedFix: { type: 'string' },
        },
      },
    },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['id', 'confirmed', 'confidence', 'reasoning', 'severityAdjusted'],
  properties: {
    id: { type: 'string' },
    confirmed: { type: 'boolean', description: 'true only if the defect is REAL after a genuine attempt to refute it' },
    confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
    reasoning: { type: 'string', description: 'the refutation attempt and its outcome — quote the code/selector that decides it' },
    severityAdjusted: { type: 'string', enum: ['critical', 'high', 'medium', 'low', 'invalid'] },
  },
}

const DIMENSIONS = [
  {
    key: 'desktop-preservation',
    prompt: `${CONTEXT}\n\nDIMENSION: DESKTOP PRESERVATION (>=1024px must be byte-for-byte equivalent to baseline ${BASE}).
Walk the full diff (git diff ${BASE} ${HEAD} -- app/index.html). For EVERY change to a BASE (unprefixed, non-media-query) CSS rule or to JSX, decide whether it can alter rendering at >=1024px. Flag anything that does: base-rule property changes that aren't inert at desktop (e.g. min-height, overflow, flex changes that affect wide layouts), new DOM wrappers that reflow desktop, classNames added that match a desktop-active rule, or media-query upper-bounds that accidentally reach 1024px. Confirm the .tabs base rule and .topbar match baseline behavior at desktop. Report only desktop-affecting issues here.`,
  },
  {
    key: 'modals-sheets',
    prompt: `${CONTEXT}\n\nDIMENSION: MODALS & SHEETS (Phase 3). The mobile sticky bar is CSS \`.modal .actions{position:sticky;bottom:0;display:flex!important;flex-direction:column-reverse!important;justify-content:stretch!important;...}\` (~line 299) plus \`.modal{padding-bottom:calc(84px + safe-area)}\` reserve on mobile, full-width \`.modal{max-width:100%!important}\`.
There are exactly 3 \`className="actions"\` rows: line 1015 (inline justifyContent:flex-end), line 5446 (\`{...sectionStyle, display:flex, justifyContent:space-between, alignItems:center}\`), line 8074 (justifyContent:space-between).
INVESTIGATE: (a) Is EACH of the 3 \`.actions\` rows actually inside a \`.modal\`? For any that is NOT inside a modal, the \`.modal .actions\` selector won't touch it (fine) — but confirm. For the line-5446 row in particular, determine whether it is a modal footer or a page/section header; if it IS inside a modal, does turning it into a column-reverse sticky bottom bar make sense, or does it wrongly pin a section header? (b) Do all 7 modals actually render their buttons inside a \`.actions\` div, or do some modals have footer buttons in other containers that therefore get NO sticky bar / NO full-width treatment on mobile (acceptance gap)? (c) Does the 84px padding-bottom reserve leave dead space on modals whose \`.actions\` is NOT sticky? (d) Does \`.modal{max-width:100%!important}\` fight any modal that needs a fixed width? Report concrete per-modal findings.`,
  },
  {
    key: 'tables-cards',
    prompt: `${CONTEXT}\n\nDIMENSION: TABLES → CARDS (Phase 2). Mobile (<=767px) CSS turns \`.table-scroll:not(.keep-table) > table\` into stacked cards using \`td[data-label]::before\`, \`.card-title\`, \`.card-action\`, \`.card-skip\`.
INVESTIGATE every \`<table>\` in the file: (a) Is it inside a \`.table-scroll\` wrapper (so it either stacks as cards or, with \`.keep-table\`, side-scrolls) OR will it overflow the page at 360px? Find any bare \`<table>\` NOT wrapped. (b) For converted tables, do their data \`<td>\`s carry \`data-label\` (else mobile cards show value with no label)? (c) The Reports pay-period table: on DESKTOP only the \`.card-skip\` chevron (line 5648) shows and the duplicate inline chevron was removed (good) — but on MOBILE \`.card-skip{display:none}\`, so the period card now has NO expand/collapse affordance. Is that a real usability defect? (d) Any nested table (direct-child combinator) wrongly transformed or wrongly skipped? Report concrete findings with line numbers.`,
  },
  {
    key: 'nav-shell',
    prompt: `${CONTEXT}\n\nDIMENSION: NAV & APP SHELL (Phase 1). Mobile shows BOTH (i) the existing \`.tabs\` strip restyled to a horizontal swipe row (\`@media(max-width:820px) .tabs{flex-wrap:nowrap;overflow-x:auto}\`, ~line 183) AND (ii) a NEW bottom nav \`<nav className="bottom-nav" aria-label="Primary">\` (JSX ~line 8317, CSS ~line 234) with \`.bnav\` buttons keyed on \`tab===id\`.
INVESTIGATE: (a) Do the bottom-nav buttons actually navigate — read the JSX ~8317-8330, confirm each button's onClick calls the same handler the top tabs use (go()/setTab) and isn't a no-op. (b) REDUNDANCY: on a phone the user sees a top swipe-tab strip AND a bottom nav simultaneously — is that confusing/duplicated, or does bottom-nav show a curated subset? Quote what tabs each shows. (c) Does the bottom-nav cover content (fixed at viewport bottom) without the page reserving bottom padding, hiding the last rows of long screens? Check for a body/.wrap padding-bottom that clears the bottom-nav height. (d) a11y: aria-current on the active bnav? labels present? (e) z-index/safe-area sanity. Report concrete findings.`,
  },
  {
    key: 'tap-overflow',
    prompt: `${CONTEXT}\n\nDIMENSION: TAP TARGETS & OVERFLOW (Phase 5). Mobile CSS adds \`@media(max-width:640px){ .btn{min-height:44px;display:inline-flex;...} select,input,textarea{min-height:44px} .table-scroll:not(.keep-table) ...{overflow-wrap:anywhere;word-break:break-word} }\`.
INVESTIGATE: (a) \`select,input,textarea{min-height:44px}\` is unscoped — it also hits the ~11 \`type=checkbox\`/\`type=radio\` inputs, reserving 44px box height and possibly mis-aligning them with inline labels on phones. Find those inputs (line numbers) and judge if alignment breaks. (b) \`.btn{display:inline-flex}\` on mobile — are there any \`.btn\` elements relying on \`display:block\`/inline default that this changes layout for? Are all \`.btn\` actually \`<button>\` (no anchor-styled .btn that inline-flex would shift)? (c) Any remaining standalone interactive controls < 44px on mobile that no rule upgrades (e.g. \`.btn.sm\` outside tables/modals, icon-only buttons, the \`.x\` close)? (d) Any element that can still exceed viewport width at 360px (long unbroken strings outside .table-scroll, fixed px widths, min-width on a base rule)? Report concrete findings.`,
  },
]

phase('Audit')
log('Auditing the committed redesign across 5 dimensions on the authed-screen blind spot…')

// Pipeline: each dimension is audited, then each of its findings is adversarially refuted —
// no barrier, so a dimension's findings start refutation as soon as that audit returns.
const perDimension = await pipeline(
  DIMENSIONS,
  (d) => agent(d.prompt, { label: `audit:${d.key}`, phase: 'Audit', schema: FINDINGS_SCHEMA, agentType: 'Explore' }),
  (audit, d) => {
    const findings = (audit?.findings || []).filter((f) => f.severity === 'critical' || f.severity === 'high' || f.severity === 'medium')
    if (findings.length === 0) return { dimension: d.key, audit, verified: [] }
    return parallel(
      findings.map((f) => () =>
        agent(
          `${CONTEXT}\n\nADVERSARIALLY REFUTE this claimed defect in the CURRENT committed file. Try hard to prove it is NOT a real problem — check whether the CSS selector actually applies at the relevant width, whether the element is really in the asserted container, whether desktop is genuinely affected, whether the app still renders. Only confirm if it survives a genuine refutation attempt. If uncertain, lean toward confirmed=false with low confidence and say what to check.\n\nCLAIM (id=${f.id}, severity=${f.severity}):\nTitle: ${f.title}\nEvidence: ${f.evidence}\nWhy claimed real: ${f.whyReal}\nSuggested fix: ${f.suggestedFix}`,
          { label: `refute:${f.id}`, phase: 'Refute', schema: VERDICT_SCHEMA, agentType: 'Explore' }
        ).then((v) => ({ finding: f, verdict: v }))
      )
    ).then((verified) => ({ dimension: d.key, audit, verified: verified.filter(Boolean) }))
  }
)

phase('Synthesize')
const confirmed = []
const dismissed = []
for (const dim of perDimension.filter(Boolean)) {
  for (const vf of dim.verified) {
    const rec = {
      dimension: dim.dimension,
      id: vf.finding.id,
      severity: vf.verdict?.severityAdjusted && vf.verdict.severityAdjusted !== 'invalid' ? vf.verdict.severityAdjusted : vf.finding.severity,
      title: vf.finding.title,
      evidence: vf.finding.evidence,
      suggestedFix: vf.finding.suggestedFix,
      confidence: vf.verdict?.confidence,
      verdictReasoning: vf.verdict?.reasoning,
    }
    if (vf.verdict?.confirmed) confirmed.push(rec)
    else dismissed.push(rec)
  }
}

confirmed.sort((a, b) => {
  const o = { critical: 0, high: 1, medium: 2, low: 3 }
  return (o[a.severity] ?? 9) - (o[b.severity] ?? 9)
})

log(`Confirmed defects: ${confirmed.length} | Dismissed claims: ${dismissed.length}`)
return { confirmed, dismissed }
