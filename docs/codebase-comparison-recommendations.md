# Codebase Comparison: ABC HR & Payroll vs. NPM-Helper-App

*June 10, 2026 — feature, architecture, and UX/UI comparison with cross-pollination recommendations.*

Both apps solve the same domain problem (US employer, PH/overseas contractors, time tracking → payroll → Wise payout) but represent opposite engineering philosophies. ABC is a mature, battle-tested single-file app optimized for iteration speed; NPM-Helper is a modern, type-safe Next.js app optimized for correctness and maintainability.

---

## 1. At a glance

| Dimension | ABC HR & Payroll | NPM-Helper-App |
|---|---|---|
| Stack | Single-file React 18 (in-browser Babel), Supabase, Deno edge functions | Next.js 16 App Router, React 19, TypeScript strict, Tailwind 4 + CVA, Supabase SSR |
| Size | 12.3k-line `app/index.html` + 1.9k-line portal | ~75+ pages/components, modular `src/` layout |
| Type safety | None in frontend (TS only in edge functions) | Strict TS + Zod at every trust boundary |
| Money handling | Numeric values in DB (FX captured per payment) | Integer cents/centavos everywhere, never floats |
| Validation | Field-level, `aria-invalid`, inline errors | Zod server-side + `useActionState` with input preservation |
| Tests | Playwright E2E (modal a11y, syntax drift checks) | Vitest configured, **0 test files** |
| Audit trail | Full `audit_log` (actor, action, reason, JSONB detail) | None visible in UI |
| Destructive-action safety | Typed "DELETE" confirmation, reason prompts, lock/unlock with audit | Mostly absent — void/discard/offboard lack confirm dialogs |
| Mobile | 3 breakpoints, bottom nav, slide-up sheets, table→card stacking, 44px targets, safe-area insets | Responsive sidebar/hamburger; table→card in guidelines but **not implemented** |
| Dashboard | KPI tiles + pay-cycle pipeline + sparkline + SWR caching with freshness stamps | KPI tiles + prioritized needs-attention alert queue |
| Component system | Ad-hoc CSS classes (pills, tiles, banners), no extraction | Clean CVA-based UI kit (Button, Field, Alert, Badge, Table, Dialog, EmptyState, Skeleton) |
| Feature breadth | Payroll calc, 13th month, Wise draft/poll/reconcile, onboarding + e-sign, invoicing, reports, audit log | Adds: leave management, overage approval links, check OCR reconciliation, performance traffic lights, renewal tracking, CSV report suite |

---

## 2. Strengths and weaknesses

### ABC HR & Payroll

**Strengths**
- Operational safety is best-in-class: immutable locked pay periods, unlock-with-reason, typed-DELETE confirmations, comprehensive audit log, FX rate capture, Wise reconciliation matching.
- Mobile UX is genuinely finished: bottom nav, sheet modals with sticky action bars, CSS-only table→card stacking, no-zoom 16px inputs, reduced-motion support, skip link, focus trapping.
- Stale-while-revalidate caching makes the dashboard feel instant, with honest "updated 3m ago" freshness stamps.
- Excellent documentation (MANUAL, OPERATING_GUIDE, code-map, ux-ui-guidelines, engineering conventions) and a kill-switch/legacy fallback for risky redesigns.
- ID-first entity matching convention prevents duplicate-record bugs across Hubstaff/Wise syncs.

**Weaknesses**
- 12.3k-line monolith with no type safety; refactoring is risky and prop-shape bugs are invisible until runtime.
- Validation is field-level only — no cross-field rules, no form-level error summary.
- Long operations (Wise polling 100+ transfers) show only a spinner, violating its own >10s step-checklist guideline.
- In-memory search/filter won't scale past ~1k contractors; pagination is blunt.
- Sparse in-context help; the payment row is information-dense (10+ fields per mobile card).
- Tablet breakpoint (768–820px) has sidebar/bottom-nav overlap and topbar wrapping glitches.

### NPM-Helper-App

**Strengths**
- Engineering rigor: strict TS, Zod validation, `Result<T,E>` discriminated unions, integer-cents money, defense-in-depth auth (guards + server-action re-verification + RLS), masked PII logging.
- Reusable, accessible UI kit with CVA variants and consistent states (hover/focus/disabled/loading/error/empty) — every new screen inherits quality.
- The needs-attention alert queue on the dashboard is a superior prioritization pattern vs. passive tiles.
- Multi-mode time entry (punch clock with facility timezone, weekly table, calendar breakdown, daily total) with week color coding (red/green/amber vs. contracted hours).
- Broader workflow coverage: leave/holiday balances, overage approval links, check OCR reconciliation, 12-week performance traffic lights, renewal cadence alerts, soft-delete archive with retention windows.

**Weaknesses**
- **Zero tests** despite Vitest setup — unacceptable risk for payroll/invoice mutation code (week math, rounding, period boundaries).
- No audit trail in the UI: can't answer "who closed this period / approved this overage / voided this invoice."
- Destructive actions (void invoice, discard pay run, offboard) lack confirmation dialogs describing consequences.
- Missing invariant guards (close period twice, invoice same week twice).
- Mobile table→card is documented in guidelines but unimplemented; tables just overflow-scroll.
- Generic "Something went wrong" errors; overage approval links rely on manual copy-paste; renewal workflow feels unfinished.

---

## 3. Recommendations

### 3.1 Add to NPM-Helper-App (patterns proven in ABC)

| Priority | Recommendation | Why / how |
|---|---|---|
| **P0** | **Audit log table + UI** | ABC's `audit_log(actor, action, entity, reason, detail jsonb)` pattern. Payroll apps need answerable history. Log close/reopen period, void invoice, approve overage/leave, offboard. Pair with reason prompts on unlock-type actions. |
| **P0** | **Destructive-action confirmations** | Confirm dialog describing the consequence ("Voiding regenerates nothing; facility was already emailed"). For bulk/irreversible ops, ABC's typed-"DELETE" pattern. Their own CLAUDE.md requires this; the Dialog component already exists — wire it in. |
| **P0** | **Period lock/immutability invariants** | ABC's open→locked→paid state machine with immutable snapshots prevents the double-close and double-invoice bugs NPM currently has no guard for. Enforce in DB (state column + check in server action) not just UI. |
| **P1** | **Mobile table→card stacking** | ABC's CSS-only pattern: hide `thead` visually, `td::before { content: attr(data-label) }`, full-width 44px action buttons. NPM's guidelines mandate it; implement it in the shared `Table` component once and every screen gets it. |
| **P1** | **Stale-while-revalidate dashboard + freshness stamps** | ABC paints cached KPI tiles instantly, refreshes in background, shows "updated 3m ago." Trivial with React cache/sessionStorage; transforms perceived performance. |
| **P1** | **Unsaved-changes guard** | ABC's `useUnsavedGuard()` prevents losing half-filled forms (onboarding wizard, facility contracts) on navigation. |
| **P2** | **Pipeline/step visualization for pay runs** | ABC's pay-cycle pipeline (Time → Calc → Lock → Sent → Settled with done/active/todo circles and "3/5 sent" sub-labels) makes batch state legible at a glance — better than a status badge for the draft→prepared→funded→closed flow. |
| **P2** | **Bottom navigation on contractor portal mobile** | Contractors are phone-first. ABC's fixed 5-tab bottom bar + "More" sheet outperforms a hamburger for daily punch-clock use. |
| **P2** | **Wise reconciliation matching** | ABC's match-by-recipient+amount+date recovery flow for missing transfer IDs is hard-won operational logic worth porting. |

### 3.2 Add to ABC HR & Payroll (patterns proven in NPM-Helper)

| Priority | Recommendation | Why / how |
|---|---|---|
| **P0** | **Needs-attention alert queue on Overview** | NPM's prioritized, tone-sorted action list (overage approvals, overdue items, periods ready to close, variance flags) beats passive tiles — it tells the admin *what to do next*, not just what exists. ABC already computes most signals (pending approvals, failed payments, expiring docs); unify them into one ranked queue. |
| **P0** | **Progress checklist for long Wise operations** | NPM's feedback ladder (<100ms instant / >300ms skeleton / >10s step checklist) is in both apps' guidelines. ABC violates it during Wise polling — add "Checked 12 of 50 transfers…" using its existing progress-steps component. |
| **P1** | **Form-level error summary + cross-field validation** | NPM's Zod approach validates whole objects ("if PT, hourly rate required"). Add a Zod (or zod-mini) pass at edge functions and a clickable error summary above forms — anchors keyboard/screen-reader users to the failing field. |
| **P1** | **Verify integer-centavos money handling** | NPM never touches floats. Audit ABC's gross/net/13th-month math for float arithmetic; store and compute in centavos, format at render. Silent rounding drift in payroll is a real liability. |
| **P1** | **Result-type error handling in edge functions** | NPM's `{ ok: true } | { ok: false, error }` discriminated unions make edge-function failures explicit and would sharpen ABC's generic error toasts into specific, recoverable messages. |
| **P2** | **Multi-mode time entry for the portal** | NPM's punch clock (live timer in facility TZ) + weekly table + week color coding (red/green/amber vs. expected hours) would let ABC contractors self-report and immediately see variance — reducing the admin-side data-quality checks ABC currently runs after the fact. |
| **P2** | **Performance traffic lights + renewal cadence alerts** | NPM's 12-week consistency scoring (green/amber/red) and 90/60/30-day renewal alerts are cheap to compute from data ABC already has (time_entries, documents.expires_on) and slot naturally into Reports and the alert queue. |
| **P3** | **Gradual TypeScript adoption** | Full rewrite isn't warranted (the single-file model is a deliberate trade-off), but JSDoc `@ts-check` typedefs for core entities (Payment, PayPeriod, Worker) catch prop-shape bugs with zero build-step change. |

### 3.3 Shared gaps (both apps)

1. **Tests where money moves.** NPM has zero tests; ABC's Playwright covers a11y, not payroll math. Both need unit tests for period math, rounding, 13th-month accrual, week boundaries — the highest-value, lowest-cost coverage in either codebase.
2. **In-context help.** Both bury domain concepts (PDD lunch, overage, 13th month, variance threshold) in external docs. Add inline tooltips/hints on the field itself — NPM's `Field hint=` prop is the right vehicle; ABC has `.tip-wrap` ready.
3. **Specific error messages.** Replace "Something went wrong" with cause + recovery action ("Wise rate fetch failed — your draft is saved; retry in a minute"). Error states should preserve user work in both apps.

---

## 4. Suggested sequencing

**NPM-Helper first month:** audit log → destructive confirmations → period invariants → payroll math tests. (All correctness/safety; the UI kit makes each cheap.)

**ABC first month:** alert queue on Overview → Wise polling progress → form error summary → centavos audit. (All high-visibility UX wins with low regression risk; gate behind the existing legacy.html kill-switch pattern.)

The cleanest long-term play: treat NPM-Helper's `src/components/ui/` as the shared design-system reference, and treat ABC's safety/audit/mobile patterns as the shared operational-UX reference. Each app should converge on the other's strength.
