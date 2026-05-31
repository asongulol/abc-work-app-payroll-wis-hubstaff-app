export const meta = {
  name: 'data-label-completion',
  description: 'Finish Phase 2: add data-label/card-title to the secondary .table-scroll tables that still stack label-less on mobile. Parallel read-only analysis → single serialized writer → smoke test.',
  phases: [
    { title: 'Analyze' },
    { title: 'Write' },
    { title: 'Verify' },
  ],
}

const REPO = '/Users/olivertrinidad/Documents/GitHub/abc-work-app-payroll-mobile'
const APP = REPO + '/app/index.html'
const SMOKE = `cd ${REPO}/tools && node mobile-smoke-test.mjs`

// Current .table-scroll wrapper line numbers (approximate — agents Read fresh).
const TABLE_LINES = [1281, 1858, 3167, 3849, 4202, 4980, 5149, 5542, 5638, 5804, 6067, 6192, 6295, 6447, 7308, 7406, 7529, 7556, 7777, 8159]

const RULES = `
TARGET FILE (edit ONLY this): ${APP} — single-file React app, JSX transpiled in-browser by Babel (a syntax slip blanks the whole app).
CONTEXT: Phase 2 of a mobile redesign turns every \`.table-scroll:not(.keep-table) > table\` into a stacked label/value CARD layout below 768px via CSS. Each mobile card row shows the value on the right and, as its left-hand label, the value of the cell's \`data-label\` attribute. Cells classed \`card-title\` render as a full-width heading (no label), \`card-action\` as a full-width >=44px button row, \`card-skip\` are hidden. WITHOUT data-label, a data cell stacks with NO field name — that is the bug we are fixing.

HARD RULES:
- Add ONLY: \`data-label="…"\` attributes on data <td>s, \`className="card-title"\`/\`card-action\` on the identifying/action cells, or \`keep-table\` on the wrapper. NOTHING else — no logic, no query, no handler, no value changes, no desktop CSS.
- The data-label text must match that column's <thead> <th> header (concise). The first/identifying column (name/date/period) becomes card-title (no data-label). Cells holding only buttons become card-action.
- A table with MANY columns (>~5) or a matrix/grid where stacking would be unreadable: prefer adding \`keep-table\` to the wrapper instead (it side-scrolls on mobile) — do NOT data-label it.
- Tables that ALREADY have data-label/card-title on their data cells are DONE — do not touch them.
- Preserve desktop exactly: data-label/className additions are invisible at >=768px. Keep JSX balanced.
`

const PLAN_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['tables'],
  properties: {
    tables: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['approxLine', 'whatItIs', 'status', 'instructions'],
        properties: {
          approxLine: { type: 'number' },
          whatItIs: { type: 'string', description: 'e.g. "rate history", "pay summary by contractor"' },
          status: { type: 'string', enum: ['already-labeled', 'needs-labels', 'use-keep-table'] },
          headerColumns: { type: 'array', items: { type: 'string' }, description: 'the <th> texts in order' },
          instructions: { type: 'string', description: 'precise, cell-by-cell: which <td> gets which data-label, which becomes card-title/card-action, or "add keep-table to wrapper". Quote enough surrounding code that the writer can locate each cell unambiguously. Empty/“none needed” if already-labeled.' },
        },
      },
    },
  },
}

const WRITE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['tablesEdited', 'dataLabelsAdded', 'keepTableAdded', 'summary'],
  properties: {
    tablesEdited: { type: 'number' },
    dataLabelsAdded: { type: 'number' },
    keepTableAdded: { type: 'number' },
    summary: { type: 'string' },
    perTable: { type: 'array', items: { type: 'string' } },
  },
}

const SMOKE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['passed', 'failingViewports', 'newErrors'],
  properties: {
    passed: { type: 'boolean' },
    failingViewports: { type: 'array', items: { type: 'string' } },
    newErrors: { type: 'array', items: { type: 'string' } },
  },
}

// ---- Phase 1: parallel read-only analysis ----
phase('Analyze')
log(`Analyzing ${TABLE_LINES.length} .table-scroll tables for missing data-labels…`)

// 5 groups of ~4 tables each.
const GROUPS = []
const per = Math.ceil(TABLE_LINES.length / 5)
for (let i = 0; i < TABLE_LINES.length; i += per) GROUPS.push(TABLE_LINES.slice(i, i + per))

const plans = await parallel(
  GROUPS.map((g, gi) => () =>
    agent(
      `${RULES}\n\nYou are analyzing (READ-ONLY — do NOT edit) these .table-scroll tables near lines: ${g.join(', ')}.
For EACH: Read the table (the \`<div className="table-scroll"><table>\` … \`</table></div>\` block and its <thead>). Decide status:
- already-labeled: its data <td>s already carry data-label or card-title → no work.
- needs-labels: data <td>s lack data-label → produce precise, unambiguous instructions to add data-label (matching each column's <th>), mark the identifying cell card-title, mark button-only cells card-action.
- use-keep-table: too many columns / matrix → instruct to add \`keep-table\` to the wrapper instead.
Return the structured plan. Quote enough real code in instructions that a writer can locate each cell without guessing. Do NOT edit anything.`,
      { label: `analyze:g${gi + 1}`, phase: 'Analyze', schema: PLAN_SCHEMA, agentType: 'Explore' }
    )
  )
)

const allTables = plans.filter(Boolean).flatMap((p) => p.tables || [])
const todo = allTables.filter((t) => t.status === 'needs-labels' || t.status === 'use-keep-table')
log(`Analysis: ${allTables.length} tables examined, ${todo.length} need work (${allTables.filter(t=>t.status==='already-labeled').length} already labeled).`)

if (todo.length === 0) {
  return { skipped: true, reason: 'All .table-scroll tables already labeled or keep-table.', examined: allTables.length }
}

// ---- Phase 2: single serialized writer (only one agent touches the file) ----
phase('Write')
const writer = await agent(
  `${RULES}\n\nApply this labeling plan to ${APP}. You are the ONLY writer. Work table-by-table, in any order. For EACH table below: use Grep/Read to locate the exact current cells, then add the data-label / card-title / card-action attributes (or the keep-table class) EXACTLY as the plan describes. Re-read each cell's current text right before editing so your Edit old_string matches byte-for-byte. Make minimal, surgical Edits — add attributes only; change nothing else. After all edits, do a final Read sanity pass on a couple of the tables to confirm JSX is balanced. Do NOT run git. Do NOT run the smoke test (a later step does).\n\nPLAN (${todo.length} tables needing work):\n${JSON.stringify(todo, null, 2)}`,
  { label: 'writer', phase: 'Write', schema: WRITE_SCHEMA }
)
log(`Writer: edited ${writer?.tablesEdited} tables, +${writer?.dataLabelsAdded} data-labels, +${writer?.keepTableAdded} keep-table.`)

// ---- Phase 3: smoke gate + bounded repair ----
phase('Verify')
async function smoke(tag) {
  return agent(
    `Run exactly: ${SMOKE}\nIt prints JSON and exits 0 (pass) / non-zero (fail). passed = top-level "ok" true. Collect failing viewports and union newErrors. Do NOT edit.`,
    { label: `smoke:${tag}`, phase: 'Verify', schema: SMOKE_SCHEMA, model: 'haiku' }
  )
}
let s = await smoke('v1')
let repairs = 0
while (s && !s.passed && repairs < 2) {
  repairs++
  log(`Smoke FAILED (attempt ${repairs}) — repairing. ${JSON.stringify(s.failingViewports)} ${JSON.stringify(s.newErrors)}`)
  await agent(
    `${RULES}\n\nThe smoke test FAILED after the data-label edits — most likely a JSX syntax slip (an unbalanced tag/brace from an attribute insertion) that stops the app mounting, or a new console error. Failing viewports: ${JSON.stringify(s.failingViewports)}. New errors: ${JSON.stringify(s.newErrors)}. Find and fix the broken edit in ${APP} with a minimal targeted Edit, then stop (no git, no smoke).`,
    { label: `repair:v${repairs}`, phase: 'Verify' }
  )
  s = await smoke(`v${repairs + 1}`)
}

return {
  examined: allTables.length,
  neededWork: todo.length,
  writer,
  smokePassed: !!(s && s.passed),
  repairs,
  alreadyLabeled: allTables.filter((t) => t.status === 'already-labeled').map((t) => t.whatItIs),
}
