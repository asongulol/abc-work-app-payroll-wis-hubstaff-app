# Appendix 04 — Payroll pipeline: Time & Approval, Calculate, Process & Pay, Recon

> Granular build spec with `app/index.html` + edge-function line anchors. Master overview: [../FEATURES.md](../FEATURES.md).

## 0. Pipeline & employer/client model
Tabs (nav 12885): `time` TimeImport (4366), `payroll` Payroll (5950), `process` ProcessPayroll (8819), `batches` = same ProcessPayroll with `reconcileOnly:true`. Every tab pinned to `employerId` = **`11111111-1111-1111-1111-111111111111`** (Aaron Anderson E.H.S. LLC). All payroll (rates/periods/payments/time) lives at the employer; `hubstaff-sync` hardcodes `EMPLOYER_COMPANY_ID` and lands all time there. `companies.kind ∈ {employer,client}`.

## 1. Time & Approval — `TimeImport` (4366)
Card "Hubstaff time import". **Auto-reveal**: `revealApproval` (4376) flips true on mount if any `time_entries` with `approval != "approved"` exist (4382) → mounts `<TimeApproval>` (4932), else a card with "Create Manual Time Entry".

### Option A — CSV (4780)
`<input accept=.csv>` → `onFile` (4560) → `parseHubstaff` (4339, validates Member/Time off/Total columns, `hmsToSeconds` 4303) → `buildMatchTable` (4552). **Name matching:** `nameTokens` (4313, NFD strip, `Ma`→`Maria`, drop suffixes), `nameKey` (4323, sorted tokens), `looseKey` (4330, first+last). `indexLinks` (4526) builds `{byId, strict, loose}` from worker_companies keyed by **`hubstaff_user_id`** first. `matchExisting` (4546): ID-first → strict → loose. Preview table (4872): Hubstaff member / Match / Days worked / Tracked / PTO / Total / Activity / (+Add contractor on unmatched). Commit: **"Import {n} contractor(s) → pending"**.

### Option B — Hubstaff API (4785)
Org `<select>` (after **List my orgs** → `listOrgs` 4580) else `org id` text (localStorage `hs_org`). **Start** date auto-fills **Stop** = `periodFor(v).end`. **Import Time** → `syncFromHubstaff` (4598): consolidated → `hubstaff-sync {action:"sync_ingest"}` (server per-client); single → default per-member return → `commit(mt,p,true)` (skips preview). Edge `hubstaff-sync/index.ts` actions list_orgs(151)/list_projects(158)/get_user(187)/sync_ingest+cron_ingest(229)/activity_backfill(477)/default rollup(628, PTO from time_off_requests 653).

### Commit / overlap (4662)
`commit` builds one `time_entries` row per matched contractor per period day `{company_id,worker_id,source_name,work_date,tracked_seconds,pto_seconds,activity_pct,approval:"pending"}`; overlap detection by `source_name|work_date` → banner Overwrite/Skip/Cancel. `writeRows` (4696): one `import_batch_id`, upsert `onConflict:"company_id,source_name,work_date"`, backfills `hubstaff_user_id` on first match, logs `import`, prompts "Go to Review & Approve". `addContractor` (4404): match-before-create (ID-first → name keys → insert with 23505 race-recover). `deleteCurrentImport` (4755).

### TimeApproval grid (5232)
Card "Enter Manual Time". Queries active (`approval != "approved"`) + approved (limit 1000); `byPerson` sorted by name. Stats: period span, `periodDays`, `workingDays` (`countWorkingDays` 5280 minus weekday holidays). Row (5593): Contractor / Days in period / Working days / Days worked / **Tracked (editable** → `setContractorTotal` 5346, day-0) / PTO (read-only) / Total / Status. Actions: **Approve** (`setApproval` 5489 → on approve navigates to Calculate via `openPeriodForEdit`), **Add hours** (period-total or day-by-day, 5365/5408), **Delete** (snapshot+Undo; **guard** refuses dates in locked/paid periods, 5446), bulk **Approve all pending / Reject all pending** (5556). Previously-approved periods drill-down (5751).

## 2. Calculate — `Payroll` (5950)
Constants `HA_ANNUAL=20000, HA_ELIG_DAYS=180, PERIODS_PER_YEAR=24, FT_DAY_HOURS=8, PT_DAY_HOURS=4` (5802). 
- **`periodFor(dateStr)`** (5901): ≤15 → 1st–15th, payDate=last day of month; ≥16 → 16th–end, payDate=15th next month (arrears).
- `expectedHours(contract,start,end)` (5852): weekdays×dayH − weekday holidays×dayH. Holidays: `defaultHolidays`/`getHolidays`/`HolidayEditor` (5809-5915).
- `healthAllowance(hire,ps,pe)` (5864): 0 unless eligible (hire+180d) AND period contains hire anniversary → 20000.
- `thirteenthAccrual(rate,hire,periodEnd)` (5890): `(monthsWorkedInYear/12)×rate` = half annual.

### Batch list (6794) via `loadBatches` (6515)
SWR-cached; groups approved time + open periods with drafts; states paid/locked/draft/uncalculated; **Calculate** (`calcBatch` 6626) / **View** (`openBatch` 6633) / **Delete** (`deleteBatch` 6650, blocked locked/paid, typed DELETE) + Clean up empty drafts (6605).

### `calculate()` (6076)
Recalc guard (6083): if overrides/misc present → `confirmDanger` typed **RECALCULATE** spelling out wiped Misc + Undo. Fetch approved time + roster + rates + prior payments. `rateFor` (6160): effective-dated. Per row:
- `worked=(tracked+pto)/3600`, `exp`, `ratio=min(worked/exp,5)`.
- **gross** = `rate==null?null : (ratio>=1?rate:round2(ratio*rate))`.
- **ha** = eligible? healthAllowance : 0; **t13** = eligible & rate? thirteenthAccrual : 0; **pdd**(lunch)=0; **bonus**=0 (editable).
- **ded**(deduction_php) = `round2(rate−gross)` = **"Perf short"** (informational, NOT in net).
- **misc_items**=[], **net** = `gross + ha + t13 + pdd + bonus + miscSum`.
Sets unattributed/noLink banners; `saveDraft`.

### Editing
`recalcNet`/`patchRow` (6379), `miscTotal` (6369: other_earns/other_hours add, deduction subtract), `overrideGross`/`setPdd`/`setBonus`/`setT13`/`setMethod` (6387). **Table** (7013): Contractor/Worked/Exp/Ratio/Rate/**Gross(editable)**/[HA]/[13th]/[Lunch]/[Bonus]/Misc/**Net**/≈USD ref/**Via** `<select>`/Delete. **MiscModal** (7132): HA/13th/Lunch/Bonus + Other earns (other_earns) + Other hours (×hourlyRate, other_hours) + Deductions (deduction) + live Net impact; `commitSave` (7177) → `saveMiscForRow` (6291).

### Options & rate-stale (6960)
Include HA / Include 13th checkboxes; FX ref (`open.er-api.com` 6059); Expected-hours line + Edit holidays; **Rate-stale banner** (6981, `loadSaved` 6306 compares stored rate vs currently effective).

### Draft & lock
`saveDraft` (6249): upsert pay_periods `{state:"open"}` + payments (status draft) `onConflict:"pay_period_id,worker_id"`. **`lockAndSave`** (6706): gate; blocks null-net rows; confirms no-method/inactive; `state:"locked"`; prompts go to Process. **`unlockPeriod`** (6409): refuses paid; typed reason. `deleteStatement` (6458) / `deleteAllStatements` (6484, typed DELETE).

## 3. Process and Pay — `ProcessPayroll` (8819)
Card "Process payroll". Empty state (9636): "No payrolls ready… Waiting upstream: N pending time entries" + jump buttons (`prep` check 8902). Ready list (9657): Open & pay / Unlock.
- **`load(pid)`** (8926): payments ⨝ workers (incl. wise_recipient_id/uuid); flags `stale_inactive`, `method_drift`; advances to `paid` when all sent (8986).
- Summary (9697). Pay list (10067) header (10074): **Print / Download Wise File / Pay via Wise API / Check Wise status / Mark all paid / Mark all unpaid**; channel tabs Wise/BPI/Other/All (10094); table (10133) Contractor/Method/Recipient-Email/Amount/Status/Sent/(action).
- **Path 1 Manual Wise batch** (10294): `downloadWiseBatch` (9559) — Wise 10-col template (recipientId,name,recipientEmail,recipientDetail,sourceCurrency,targetCurrency,amountCurrency=target,amount,paymentReference="Payroll {end}",receiverType=PERSON), USD→PHP default, only rows with recipient_uuid, re-download guard.
- **Path 2 Individual files** (10337): `downloadIndividual` (9600) Contractor/Method/Wise id/Email/Amount/Pay date/Period.
- **Path 3 Wise API draft** (10345): `<WisePayouts>` (8513) → `wise-payouts {action:"batch"}`; **never funds** ("NO money has moved — open Wise to FUND").
- Statuses **draft|queued|sent|failed|reconciled**. `markPaid` (9002, Undo, steps paid→locked) / `markUnpaid` (9040) / `markAllUnpaid` (9078, typed UNPAID, skips Wise-transfer rows). Per-row: Wise → "Mark paid"; BPI → "Mark paid…" + date input (`confirmPaidWithDate` 9307); Unlock… reason (9321). `checkWiseStatus` (9095) → `wise-payouts {action:"status"}`.
- **FX**: payments.fx_rate = market rate at Calculate (ref); Wise batch is PHP→PHP so Wise locks the real USD-funded rate; `rates` action (edge 300) reads back the locked quote.
- **WiseApiDialog** (10364): Review→Confirm→Fund; **Fund disabled** ("API funding isn't enabled yet").

## 4. Review & Recon — `ProcessPayroll reconcileOnly` (8955)
Card "Reconcile with Wise"; dropdown over all locked+paid (9621); `<ReconcileOverview>` (8724). Read-only batch table (10014). Reconcile card (9713): **Import processed Wise CSV** (`onReconcileFile` 9198, `parseWiseProcessedCsv` 9140, backfills wise_transfer_id idempotently, flags variances, fuzzy suggestions, then poll). **Reconcile with Wise** (`reconcileWithWise` 9414): `{action:"match"}` (first match) + `refresh` (re-detect). History results (9836): matched_closest_date / matched_with_variance_overridden (auto-update DB, keep original_net_php) / ambiguous / unmatched (+ Link suggestions, `linkOrphanRecipient` 9345 with confirmDanger workerName). Delete single/whole-batch lives on Calculate (unlock first). `WiseReconciliation` (7981, in Configuration tab): Backfill all paid periods (`runBackfill` 8130 → match window 14), Email cross-check (`runEmailCheck` 8081), Cross-system drift scan (`runDriftScan` 7995).

## 5. Periods & money (reference)
- `periodFor` (5901) arrears. `money(n,cur)` (5806).
- **pay_periods**: id, company_id, period_start, period_end, pay_date, state(open|locked|paid), expected_hours_ft(80)/pt(40), locked_at. Conflict `(company_id,period_start,period_end)`.
- **payments**: id, company_id, pay_period_id, worker_id, expected_hours, worked_hours, performance_ratio, rate_php, gross_php, health_allowance_php, thirteenth_month_php, deduction_php, net_php, pdd_lunch_php, bonus_php, fx_rate, payout_currency('PHP' on write), payout_amount, payout_method, wise_transfer_id, status(draft|queued|sent|failed|reconciled), paid_at, note, wise_dates jsonb, wise_locked_at, original_net_php, misc_items jsonb. Conflict `(pay_period_id,worker_id)`.
- **time_entries**: id, company_id, worker_id?, source_name, work_date, tracked_seconds, pto_seconds, project, activity_pct, approval(pending|approved|rejected), approved_by/at, pay_period_id?, import_batch_id?. Conflict `(company_id,source_name,work_date)`.
- **rates**: worker_id, company_id, amount_php, period_basis('semi_monthly'), effective_start, effective_end?.
- **worker_companies**: worker_id, company_id, contract(FT|PT), hubstaff_name, hubstaff_user_id(bigint), status(active|inactive|ended), started_on, ended_on, bill_rate_usd, weekly_hours. Partial-unique `(company_id, hubstaff_user_id)`.
- **audit_log**: company_id, actor, action, entity, detail jsonb. `AUDIT_LABELS` (10448).

### Edge contracts
**wise-payouts** (`--no-verify-jwt`, in-code admin gate 184; **OWNER** for draft/batch; cron-secret for poll/match): profile/draft/batch (never funds)/status/rates/poll/match/recipients/get_recipient. **hubstaff-sync**: refresh token in api_tokens; EMPLOYER_COMPANY_ID; PTO from time_off_requests.

### Happy path
Time (import → approve → navigates to Calculate) → Calculate (calc → edit → Lock → go Process) → Process (Open & pay → path → Mark paid; all sent → paid) → Review (import CSV + reconcile → reconciled).
