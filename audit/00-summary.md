# 00 — Audit Synthesis (ABC Kids HR & Payroll App)

Read-only mapping-and-recommendation engagement. Five parallel tracks investigated the system; this document merges them, de-duplicates overlaps, **surfaces disagreements rather than averaging them**, and ends with the changes I would make first.

**Scope (per owner):** full system — admin/payroll SPA [app/index.html](../app/index.html) (~12.7k lines), contractor portal [portal/index.html](../portal/index.html) (~2.1k lines), 10 Deno edge functions, and the live Supabase schema (project `cgsidolrauzsowqlllsz`, **production**). `app/legacy.html` (frozen `?ui=classic` rollback) was noted, not audited.

**UX standard (per owner):** the brief named `ux-ui-guidelines-v2.md`, which is **ABSENT** from the repo; Track 2 evaluated against [docs/ux-ui-guidelines.md](../docs/ux-ui-guidelines.md) (v1; its `:163` self-labels source as "v2"). Flagged in the open-questions log.

**System goals (G1–G9)** are OBSERVED from [README.md](../README.md), not merely inferred — the README documents the employer/client model, payroll lifecycle, and all 10 functions. They are still listed for confirmation in §6.

> G1 pay PH contractors PHP via Wise from Hubstaff time · G2 Hubstaff sync (CSV + daily cron) → time_entries · G3 biweekly payroll: time→approval→calc→Wise **draft** (human funds)→reconcile · G4 client invoicing per-hour **and** per-session · G5 onboarding sign→profile→docs→HR review/countersign · G6 contractor self-service portal · G7 multi-company admin scoping · G8 document/compliance expiry · G9 security (RLS, caller-auth, payment lock).

**How to read confidence:** findings are labelled **OBSERVED** (read in code/schema) or **INFERRED**. Several high-impact items are **INFERRED-HIGH** — derived from two independently-observed facts but not runtime-verified (this was a static, read-only pass). Those are marked **⚠ verify-first** and gated at the top of §7. Per-finding evidence (file:line, table.column) lives in the track artifacts: [01-inventory](01-inventory.md) · [02-ux](02-ux.md) · [03-workflows](03-workflows.md) · [04-database](04-database.md) · [05-gaps](05-gaps.md).

---

## 1. Master catalog — features / pages / modals + appropriateness verdict

Merged from Track 1 (inventory) + Track 2 (verdicts). Verdict legend: **keep** · **revise** (mostly interaction-state/a11y or modal-vs-page, not redesign) · consolidate/remove (none — see §4).

### Admin app — top-level tabs (routing = single `tab` useState, [app/index.html:13365](../app/index.html#L13365); no URL/router)

| # | Screen (tab) | file:line | User task | Verdict | Note |
|---|---|---|---|---|---|
| 1 | Overview | 12206 | Landing KPI dashboard | keep | attention-first tiles |
| 2 | Contractors (roster) | 2565 | List→detail; add/deactivate/delete | keep | tables→cards on mobile |
| 3 | Hiring & Onboarding | 11962 | Hire queue + review pipeline | keep | distinct task from roster |
| 4 | Documents | 7467 | Doc list + expiry tracking | keep | verify empty-state copy |
| 5 | Time & Approval | 4393 | Import time + approve (TimeApproval embedded) | keep | naming vs "Imports" tab is confusing |
| 6 | Calculate (Payroll) | 6025 | Compute pay statements; lock batch | keep | core compute step |
| 7 | Process and Pay | 9098 | Open locked batch; Wise drafts / files | keep | money-safety UX present |
| 8 | Review & Recon Batches | 9098 (`reconcileOnly`) | Reconcile locked+paid batches | keep | same component as #7, intentional split (code comment :9989) |
| 9 | Reports | 7608 | 3 stacked sub-reports | keep | per-contractor / history / utilization |
| 10 | Invoicing | 13048 | Build client invoice (per-hour + per-session) | keep | only tab with its own client picker |
| 11 | Service Sessions | 12865 | Approve contractor-logged flat-fee sessions | keep | client-scoped |
| 12 | Imports (DeleteImports) | 4971 | Bulk-delete imported time + draft batch | **revise** | confirm it routes through styled DangerConfirm, not `window.confirm` |
| 13 | Audit Log | 10735 | Browse audit trail | keep | filters + CSV |
| 14 | Configuration | 13327 | Hub → 6 config modals + inline reconciliation | keep | good progressive disclosure |

Pre-shell: ConnectScreen 1201, SignInScreen 1221 (Google), NotAuthorized 1251, AccessError 1268 — keep.

### Admin app — notable modals/sub-views

| Modal / sub-view | file:line | Verdict | Note |
|---|---|---|---|
| ProfileModal (4 sub-tabs: Profile/Pay/Personal/Portal) | 2837 | **revise** | heavy editing inside a dialog — borderline; consider full-page profile |
| AddContractorWizard (3-step) | 2206 | **revise** | multi-step data-entry trapped in a 560px modal — full-page job per guideline |
| AdminsModal | 1284 | **revise** | remove/cancel-invite uses `window.confirm` (:1368) |
| AnnouncementsModal | 2140 | **revise** | delete uses `window.confirm` (:2164) |
| MiscModal 7256 · CommandPalette 12501 · CompaniesModal 12591 · HubstaffProjectsModal 13253 · PortalSettingsModal 2088 · BulkImport 1694 · PullRecipients 8509 · AgreementTemplatesModal 11644 · OnboardingConfigModal 11702 · CountersignModal 10959 · ToolsProvisionModal 11228 · ReasonPicker/DeferPicker 11608/11574 · WiseApiDialog 10643 | — | keep | each maps to a real, infrequent task; correctly modal-sized |
| DangerConfirm 12072 · UnsavedChangesModal 1661 | — | keep | the styled money/destructive guards |

### Contractor portal — tabs + flows

| Screen | file:line | Verdict | Note |
|---|---|---|---|
| Login | 661 | keep | exemplary form (labels, autocomplete, Turnstile, inline error) |
| SetPassword | 2148 | keep | single-purpose |
| OnboardingFlow (3 stages) | 1883 | keep | correctly full-page multi-stage, progress saved |
| Home (hero/pay card/activity/mood) | 1418 | keep | delightful + functional |
| PaySlips | 731 | **revise** | `<div onClick>` expander, not keyboard-operable; text "Loading…", no skeleton |
| TimeView | 799 | **revise** | same non-keyboard expander |
| SessionsView | 864 | keep | self-log; delete is `window.confirm`, no undo |
| DocsView | 952 | keep | upload + outstanding badge |
| ProfileView | 1041 | keep | self-edit with portal-field gating |
| AgreementViewer | 1772 | **revise** | `role=dialog` but no focus-trap/restore/Escape |
| DocReminder / Mood check-in / ToolsPopup | 1232/1564/2210 | **revise** | same modal-a11y gap; emojis `<span role=button>` not keyboard-operable |
| UnsavedGuardModal | 485 | keep | the one portal modal done right — use as a11y template |

**Verdict tally:** keep = 24 · revise = 12 · consolidate = 0 · remove = 0 (UI). The information architecture is disciplined (5 sidebar groups, each ≤6 items, within the ≤7 guideline). Most "revise" verdicts are **portal accessibility + interaction-state** fixes, plus two "modal→full-page" reshapes.

---

## 2. Cross-track convergences & disagreements

### Convergences (≥2 tracks independently → high confidence)
- **Two confirm systems coexist** — styled `DangerConfirm` vs native `window.confirm`/`prompt` (27 admin + 2 portal sites). Tracks 1, 2, 5. *Money-moving paths already use typed-confirm; the long tail is consistency/polish.*
- **Portal accessibility deficit** — no focus styles, no focus-management in dialogs, non-keyboard expanders, text spinners (no skeletons). Tracks 2, 5.
- **Client billing (G4) is half-built** — invoices generate/print/CSV but cannot be **delivered**, "sent"/"paid" are status flips with no timestamp/amount, no AR aging, `invoice_no` not uniquely constrained. Tracks 3 (Flow 3), 4 (invoices cols, invoice_no), 5 (#2/#4 blockers).
- **Email pipelines are inert in prod** (no Resend/Gmail secrets) — the entire compliance + onboarding reminder loop is passive. Tracks 1 (cron-only fns), 3, 5 (#1 blocker).
- **Duplicated logic across edge functions** — name-normalization (3×) and required-doc defaults (4×); drift risk. Tracks 3, 4.
- **`wise-payouts` caller-auth is now CLOSED** (contradicts the 2026-06-06 memo's "zero caller auth = CRITICAL"). Tracks 4, 5 — and independently re-verified in code earlier this session ([wise-payouts/index.ts:253-298](../supabase/functions/wise-payouts/index.ts#L253-L298)). **Memo item resolved.**

### Disagreements (surfaced, not averaged — these need an owner call)
- **D1 — `portal_notifications`:** Track 4 = "dormant pending-feature table, keep & confirm intent"; Track 5 = "fully orphaned dead schema, no producer anywhere." *Both agree: 0 code references. The split is keep-for-roadmap vs cut.* → Owner decides if in-portal notifications are planned.
- **D2 — `shift_schedule`:** Track 5 flags a `shift_schedule` **table** as dead schema; Track 4's live inventory (28 tables) shows **no such table** — the portal uses `workers.shift_start/end`. → Likely the migration name `2026-06-04_shift_schedule_and_mood_kind.sql` is misleading (added columns/enum, not a table). **Verify whether the table exists at all**; if not, the "dead table" gap is moot.
- **D3 — `onboarding_reminders`:** Track 4 = "RLS-enabled-no-policy, likely an oversight"; Track 5 = "pending email-reminder feature." Both: empty + dormant. Minor.
- **D4 — confirm-dialog severity:** Track 2 = "polish, not a money-safety hole (money paths already typed-confirm)"; Track 5 = "policy gap vs CLAUDE.md money rule (invoice generate/void/mark-paid have no confirm)." *Reconciled: invoice actions don't move money (status flips), so it's consistency/policy, not money-safety. Not a true contradiction.*

---

## 3. Prioritized recommendations roadmap (impact × effort)

I = impact, E = effort. ⚠ = INFERRED-HIGH, verify before changing. All money/auth/schema changes go through staging first per project convention.

### Quick wins (high impact, low effort)
| # | Change | I/E | Goal | Source |
|---|---|---|---|---|
| Q1 | **Set Resend + Gmail secrets in prod** → activates doc-expiry + hiring-review digests + new-hire emails. Operational, not code. | H/L | G5,G8 | T5#1 |
| Q2 | ⚠ **Reconcile poll candidate set = `status.in.(draft,queued)`** (today `only_drafts:true` filters `draft` only, so API-batched `queued` rows aren't auto-marked paid). | H/L | G3 | T3 A8 |
| Q3 | ⚠ **Align `match` callers to `window_days:7`** (server-safe default is overridden to 14 at [app/index.html:8259](../app/index.html#L8259),[:9795](../app/index.html#L9795) — the value the code comments blame for a prior ambiguous-pair incident). | H/L | G3 | T3 A7 |
| Q4 | **Regenerate or delete `schema/schema.sql`** (stale: 12 of 28 tables, wrong `contract_type` enum). It will mislead every future dev/agent. | M/L | — | T4#1 |
| Q5 | **Add indexes on hot/unindexed FKs** — `payments.worker_id` (1,086 rows, grows每 period; contractor reads filter it), `documents.company_id/reviewed_by`. | M/L | G9 perf | T4 |
| Q6 | ⚠ **`REVOKE EXECUTE FROM anon`** on mutating SECURITY DEFINER RPCs (`set_worker_tools`, `set_tools_requested`) **after confirming** they don't internally verify caller→worker. Potential unauth write into the credential blob. | H/L | G9 | T4 leak#7 |
| Q7 | **Make portal list expanders/emojis keyboard-operable** (`<button>` or `tabIndex`+key handler) and **add a portal `:focus-visible` ring**. Cheap a11y compliance. | M/L | G6 | T2 #1,#3 |

### Medium (high/medium impact, medium effort)
| # | Change | I/E | Goal | Source |
|---|---|---|---|---|
| M1 | ⚠ **Fix FX semantics.** Calculate stores a market rate on `payments.fx_rate`; `createBatch` overwrites it with the Wise **PHP→PHP** quote rate ≈ **1.0**, so all post-batch USD reference is wrong and the real USD-funding rate is never captured. Stop the overwrite; capture the true funding rate or drop USD display. | H/M | G1,G3 | T3 A6 |
| M2 | **Unify onboarding stage-3 completion** — `portal-self.finish_onboarding` counts only `approved`; `portal-review.reEvalStage3` also clears `waived`/`deferred`, so a waived-last-doc contractor is onboarded by HR but blocked from self-finishing. | M/M | G5 | T3 Flow4 |
| M3 | **Move holiday config to the DB** (today per-browser localStorage → two admins compute different expected-hours → different proration → different net pay). | M/M | G3 | T3 A2 |
| M4 | **Invoice settlement model** — add `amount_paid`/`paid_at`/`sent_at`/`due_date` + a uniqueness constraint on `invoice_no` (allocation is non-atomic `count(*)+1`). Enables AR aging/overdue/partial-payment. | M/M | G4 | T4, T5#4 |
| M5 | **Port `useModalA11y` to the portal** (focus-trap/restore/Escape) + **portal skeletons** for PaySlips/Time/Docs. | M/M | G6 | T2 #2,#5 |
| M6 | **Migrate remaining `window.confirm` → styled `DangerConfirm`** (27 admin + 2 portal), incl. invoice generate/void/mark-paid. | M/M | UX | T2#4, T5 B4 |
| M7 | **Harden the company boundary** — add FK (or rekey to `user_id`) for `admin_companies.admin_email → admin_users.email`. The whole tenant boundary currently rests on unconstrained `lower(email)` equality. | M/M | G7,G9 | T4 smell#5 |
| M8 | **Add `>=0` / sanity CHECKs** (`time_entries.tracked_seconds/pto_seconds`, payments money cols) and a **rate-overlap `EXCLUDE`** on `rates` (de-dupe scripts in history imply overlaps occurred). | M/M | G3 | T4 |

### Larger refactors (high impact, high effort — plan deliberately)
| # | Change | I/E | Goal | Source |
|---|---|---|---|---|
| L1 | **Invoice delivery** — email/PDF to `companies.contacts` (and possibly a client-visible link). Completes G4 "generation → delivery". | H/H | G4 | T5#2 |
| L2 | **Service-session bulk import** — wire the already-provisioned `import_batch_id`/`external_ref` idempotency columns (per-session billing is unusable at real visit volume by hand). | H/H | G4 | T5#3 |
| L3 | **Contractor + admin payslip PDF** — portable pay record (zero `jsPDF`/`print` in portal today). | M/M | G6,G3 | T5#5 |
| L4 | **Extract shared modules** for name-normalization + required-doc defaults across edge functions (kills 3×/4× duplication & drift). | M/M | G2,G5 | T3 |
| L5 | **AddContractorWizard / ProfileModal → full-page** (create/edit) per the forms guideline; stops modal-bound heavy entry. | M/H | UX | T2 |
| L6 | **Normalize the worker payout model** — `payout_method` + `payout_account` jsonb + `gcash/paymaya/paypal/wise_tag` + `wise_recipients` jsonb + `wise_recipient_id/uuid` are overlapping representations of "how to pay." | M/H | G1 | T4 smell#4 |

---

## 4. Consolidated remove / consolidate / dead-weight list

**UI screens/modals to remove or merge: NONE.** Every screen maps to a real task; the closest call (`process`/`batches` double-mount) is a documented, intentional progressive-disclosure split. The lever to shrink surface area is the modal→page reshape (L5), not deletion.

**Schema / code dead-weight (candidates, verify intent first):**
- **`v_payouts_by_period` (view)** — TRUE ORPHAN, 0 references anywhere. Safe to drop. (T4)
- **`portal_notifications`** — 0 rows, 0 code writers/readers. Keep only if the in-portal notifications feature is on the roadmap (D1), else cut.
- **`onboarding_reminders`** — 0 rows, dormant; also RLS-enabled-no-policy. Keep if the reminder feature is planned (tie to Q1), else cut. (D3)
- **`shift_schedule`** — verify the table even exists (D2); if it doesn't, nothing to remove.
- **Edge actions with no UI caller** — `wise-payouts`: `draft`, `rates`, `profile`, `find_transfers_by_recipient`; these are implemented but unreachable from either app. Confirm whether they're intended server/cron-only or dead. (T1)
- **Duplicated code** (not removal, but consolidation): name-normalization 3×, required-doc defaults 4× (L4); invoice `total` formula duplicated in `generate` + `exportCsv`; net computed in 3 places.

---

## 5. Database findings — highest risk first

RLS is **enabled on all 28 tables** and the company/worker scoping rule (use `is_company_admin()`/`admin_can_see_worker()`, not bare `is_admin()`) is implemented **consistently** — a genuine strength. Highest-risk items:

1. **⚠ Mutating SECURITY DEFINER RPCs callable by `anon`** — `set_worker_tools(worker_id, creds)` / `set_tools_requested` are reachable via `/rest/v1/rpc/*` by the anon role. If they don't internally verify caller→worker, that's an unauthenticated write into the credential blob. **Verify, then `REVOKE EXECUTE FROM anon`.** (Q6)
2. **Company boundary rests on unconstrained text equality** — `admin_companies.admin_email` has no FK to `admin_users.email`; all scoping helpers match by `lower(email)`. A stale/mismatched/case-different email silently grants or drops cross-company access. (M7)
3. **`schema/schema.sql` is materially stale** (12/28 tables; `contract_type` enum `FT,PT` vs live `FT,PT,PH,PS,PHS`) yet partially hand-patched — an actively misleading artifact. (Q4)
4. **Payment "lock" ≠ immutable** — `trg_payments_lock_enforce` is UPDATE-only; a DELETE+re-INSERT, or clearing `wise_locked_at` first, bypasses it. Acceptable by design but "locked" is not a hard guarantee.
5. **PHI/sensitive data** — `service_sessions` holds minors' early-intervention data (`child_initials`, `eiid`, `case_ref`); `onboarding_signatures` holds forensic e-sign data (`ip_address`, `device_fingerprint`, XSS-prone `signature_data`). RLS is tight today; `app_secrets`/`api_tokens` store tokens as **plaintext** rather than using the available Vault.
6. **Missing constraints/indexes** — 9 unindexed FKs (esp. `payments.worker_id`); no `>=0` money/seconds checks; no employer-uniqueness on `companies`; no rate-overlap exclusion; no FK on `*.agreement_kind → agreement_templates`. (Q5, M8)
7. **JSON-blob overuse** — structured, queryable data (payout methods, recipients, onboarding spec) encoded as opaque jsonb; only `payments.misc_items` has a typeof check. (L6)
8. **Perf-flavored RLS** — `auth_rls_initplan` (call `(select auth.uid())`) and ~18 `multiple_permissive_policies`; cheap to optimize as `workers`/`time_entries` grow.

Full per-table inventory, ER diagram, and policy matrix in [04-database.md](04-database.md).

---

## 6. Assumptions & open-questions log (for owner review)

### Inferred goals to confirm
- **G1–G9** are taken from README.md (well-grounded, but confirm they're current and complete — e.g. is electronic invoice delivery in-scope for G4? Is an in-portal notifications feature planned?).

### INFERRED-HIGH items requiring runtime/code verification before action
- **V1 (Q2):** does the default reconcile poll actually leave `queued` rows unreconciled in production? (status-set vs filter-literal both observed; runtime effect inferred.)
- **V2 (M1):** confirm `payments.fx_rate` is being overwritten with ≈1.0 after batching (PHP→PHP quote) and that downstream USD figures are consequently wrong.
- **V3 (Q6):** read the bodies of `set_worker_tools`/`set_tools_requested` — do they verify the caller maps to the target worker? (Determines whether the anon EXECUTE grant is exploitable.)
- **V4 (M2):** confirm the waived-last-doc contractor is actually blocked by `finish_onboarding` in practice.
- **V5:** can `match refresh` PATCH `net_php` on a row whose `wise_locked_at` is set? (possible locked-amount rewrite path.)

### Open questions (owner)
- **Q-a:** Is `ux-ui-guidelines-v2.md` supposed to exist? Track 2 used v1; confirm or provide v2.
- **Q-b:** Are `RESEND_API_KEY` / Gmail app-password set in prod now? (If yes, gap #1 downgrades from blocker.)
- **Q-c:** Is electronic invoice delivery (email/PDF) a required G4 deliverable, or is manual print-and-send acceptable?
- **Q-d:** Expected sessions/client/period? (Determines whether "no bulk session import" is a blocker or nice-to-have.)
- **Q-e:** Keep or cut the dormant tables (`portal_notifications`, `onboarding_reminders`, `shift_schedule?`, `v_payouts_by_period`)? (D1–D3, §4.)
- **Q-f:** Is billing hours-billed (`tracked_seconds`, no approval filter) intentionally decoupled from pay hours (approved + PTO)? An invoice can bill hours payroll later rejects. (T3 Flow 3.)
- **Q-g:** Are the unreachable `wise-payouts` actions (`draft`/`rates`/`profile`/`find_transfers_by_recipient`) intended server-only, or dead?

### Standing assumptions
- Single employer (Aaron Anderson EHS LLC) — multiple code comments warn the invoicing/PHS-session math breaks if a second employer is added.
- Clients are billed out-of-band (no client login) — makes "no client portal" a nice-to-have, not a blocker.
- Grep over the single-file apps is a faithful proxy for "table/feature used" (they embed literal PostgREST table names).
- All verdicts are from **static source reading**; no app was rendered and no DB rows were mutated. A 30-min keyboard + axe-DevTools pass on the portal would confirm the a11y findings.

---

## 6b. Verification results (V1–V5, run 2026-06-20)

The INFERRED-HIGH items were verified against the live DB + function bodies. **Three of five are defended or dormant** — verification materially de-risked the audit.

| Item | Verdict | Evidence | Revised action |
|---|---|---|---|
| **V1** queued reconcile skip | **LATENT (not active)** | Code confirmed ([app:8814](../app/index.html#L8814) sets `queued`; poll defaults `draft`-only). Prod: **0 `queued` rows**, 0 draft/sent rows have a batch transfer → `createBatch` has never run in prod. | Keep the one-line fix (`status.in.(draft,queued)`) but it's **"fix before enabling API payouts,"** not urgent. |
| **V2** FX≈1.0 overwrite | **LATENT; active-claim REFUTED** | `createBatch` would write `quote.rate ?? 1` from a PHP→PHP quote ([wise-payouts:523](../supabase/functions/wise-payouts/index.ts#L523)), but **every prod row has market fx (55–62), 0 near 1.0** — never batched. | Fix when wiring the API-batch path (don't write the PHP→PHP rate); not corrupting any current data. |
| **V3** anon-callable `set_worker_tools`/`set_tools_requested` | **REFUTED (defended)** | Both bodies begin `if not admin_can_see_worker(p_worker_id) then raise exception` — anon's NULL `auth.uid()` fails the check. The anon EXECUTE grant is harmless. | Downgrade from top DB risk to **optional defense-in-depth** (`REVOKE EXECUTE FROM anon`). |
| **V4** onboarding stage-3 divergence | **CONFIRMED** | `reEvalStage3` counts approved/waived/deferred (portal-review:55,61); `finish_onboarding` counts approved only (portal-self:215). Window is narrow (a waive normally fires reEvalStage3 → completed_at → self-finish short-circuits). | Keep M2: align `finish_onboarding`'s query + fix the false "mirrors exactly" comment. |
| **V5** locked-amount rewrite via match-refresh | **REFUTED (defended)** | `payments_lock_enforce` trigger protects `net_php`/`original_net_php`; once `wise_locked_at` set, any change **raises** (would fail loudly, not silently). | No action needed; the DB lock holds. |

**Net effect on §5 DB risks:** the #1 item (anon RPCs) is defended (V3) and the payment-lock concern (#4) is stronger than rated (V5). **Net effect on §3 roadmap:** Q2/M1 reclassify from "active money risk" to "fix before enabling API payouts" (dormant); Q6 reclassifies to optional hardening.

---

## 7. The first 3–5 changes I would make, and why

> Updated after §6b verification — the original top-three (queued reconcile, anon RPCs) turned out dormant/defended.

Ordered to retire risk and unblock goals at the lowest cost. Verification (§6b) cleared the original top-two, so the confirmed-actionable items now lead.

1. **Set the prod email secrets (Q1).** One operational step reactivates the entire G5/G8 compliance + onboarding reminder loop, which is currently dead despite being fully built. Highest goal-unblock per minute, zero code.

2. **Align onboarding stage-3 completion (M2 / V4 — CONFIRMED).** Make `finish_onboarding` count `approved/waived/deferred` like `reEvalStage3`, and fix its false "mirrors exactly" comment. Closes a real (if narrow) self-finish dead-end where a waived-last-doc contractor is stuck. Small, confirmed, no money risk.

3. **Regenerate/delete the stale `schema/schema.sql` (Q4).** Five minutes; removes a landmine that already shows the wrong `contract_type` enum and will mislead every future change. Do this before any schema work in M4/M7/M8.

4. **Align `match` callers to `window_days:7` (Q3).** Code-confirmed: every UI caller passes 14 — the value the code comments blame for a prior ambiguous-pair incident. Two call-site edits; reduces mis-match risk on the live reconcile path.

5. **Clear the dormant API-payout landmines before that feature ships (Q2 + M1).** Verification showed the queued-reconcile skip and the FX≈1.0 overwrite are **latent** (createBatch has never run; 0 queued rows, 0 fx≈1). They are not hurting current data, but both must be fixed *as part of* enabling API payouts — fold them into that work, not before.

*De-prioritized by verification:* Q6 (anon RPC revoke) is now optional defense-in-depth — the function bodies already gate via `admin_can_see_worker()` (V3); the payment lock is sound (V5).

*Everything above is investigate-and-document only — no code, schema, or config was modified during this audit (the only files written are the six artifacts in `audit/`). Implementation awaits your review.*
