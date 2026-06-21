# Track 3 — Workflow & Algorithm Analysis

Read-only audit of the ABC Kids HR & Payroll app. Lane: end-to-end **flow correctness** + business-logic **algorithm correctness / edge-cases / simplification**. Aesthetics (Track 2) and broad missing-feature enumeration (Track 5) are out of scope, but logic gaps that break a flow are flagged here.

Evidence labels: **OBSERVED** = read directly in code (cited file:line / edge-fn action). **INFERRED** = deduced from surrounding code. **ASSUMPTION** = ambiguous, stated explicitly. **ABSENT** = searched, not found.

Primary sources read in full or in the cited ranges:
- `supabase/functions/wise-payouts/index.ts` (1–1303, full)
- `supabase/functions/hubstaff-sync/index.ts` (1–717, full)
- `supabase/functions/portal-self/index.ts`, `portal-review/index.ts`, `portal-sign/index.ts` (full)
- `app/index.html` payroll/invoicing/import/lock blocks (4366–4719, 5541–5598, 5862–5988, 6034–6520, 6823–6882, 8715–8836, 9000–9020, 9132–9332, 9540–9800, 13085–13190) + helpers (10923–10952)
- `portal/index.html` session logging (860–905)

---

## Flow 1 — Time: Hubstaff import (CSV) + daily cron_ingest → time_entries → approval/lock

### 1a. CSV upload (manual)
**Happy path**
1. Admin opens Time tab; `TimeImport` loads this company's `worker_companies` name→worker_id map, incl. inactive (`app/index.html:4420`). OBSERVED.
2. User drops a Hubstaff daily CSV; `parseHubstaff(text)` (`:4366`) reads the header, requires `"Time off"` and `"Total worked"` columns (`:4374`), and slices the date columns between `Member` and `Time off` (`:4375`). OBSERVED.
3. `buildMatchTable` matches each member name to a worker (ID-first via `hubstaff_user_id`, then name keys). INFERRED from `matches`/`commit` usage.
4. `commit()` builds one `time_entries` row per matched member × date (`:4694–4702`) with `tracked_seconds`, `pto_seconds:0` (CSV has no PTO source, `:4699`), `approval:"pending"`. OBSERVED.
5. Overlap detection: queries existing `(source_name, work_date)` in the date span and pauses for user choice if any collide (`:4705–4716`). OBSERVED.
6. `writeRows` inserts/updates; rows land as `approval:"pending"`. OBSERVED.

### 1b. Daily cron_ingest (server)
**Happy path** (`hubstaff-sync` action `cron_ingest`)
1. pg_cron (04:00 Manila) POSTs with `x-cron-secret`; gate validates against `app_secrets.cron_secret` (`hubstaff-sync:232–235`). OBSERVED.
2. Window = `[today − lookback_days, today]`, lookback default 3, clamped 0–31 (`:252`). OBSERVED.
3. Pull org members → user_ids → names (bulk `/users?id[]=` then per-user fallback) (`:275–290`). OBSERVED.
4. Pull `activities/daily`, sum `tracked` and `overall` per user/day across projects (`:301–312`). OBSERVED.
5. Pull `time_off_requests`, keep `status==="approved"`, sum `amount_used` per in-window day into `ptoDay` (`:316–331`). OBSERVED.
6. Match each user to a worker: **ID-first** (`byId[uid]`), then strict sorted-token name key, then loose first+last (`:352–353`); unmatched are **reported, never inserted** (match-before-create, `:370`). OBSERVED — conforms to the ID-first convention.
7. All time lands on the **EMPLOYER** company id (`:371`, `EMPLOYER` constant `:45`), not the client. OBSERVED — matches employer/client model.
8. Protect human decisions: rows with `approval != 'pending'` are skipped (`:401–411, :427`). OBSERVED.
9. UPSERT on `(company_id, source_name, work_date)` with `merge-duplicates` (`:444–448`), updating only payload columns so `pay_period_id`/`import_batch_id` survive. OBSERVED.
10. Persist `hubstaff_user_id` on links that matched by name (`:453–458`) → next run is ID-based. OBSERVED — self-healing, matches convention.
11. `activity_pct = round(overall/tracked*100)` populated server-side (`:429`); browser sync leaves it null. OBSERVED.

### 1c. Approval / lock
1. `TimeImport` auto-reveals the approval grid if any non-approved rows already exist (`:4409–4416`) — prevents cron-ingested pending rows hiding behind the import step. OBSERVED (good).
2. `setApproval(ids,"approved")` chunks the id list at 100 to dodge PostgREST URL-length truncation (`:5547–5552`) — fixes a prior "approve all did nothing" bug. OBSERVED (good).
3. Approving navigates to Calculate, anchored on the approved rows' own dates → `periodFor(anchor)` (`:5577–5579`). OBSERVED.

**Friction**
- CSV `source_name` matching can silently drop rows whose name doesn't resolve; surfaced later in Calculate as `unattributed`/`noLink` (`app/index.html:6332–6351`) rather than at import time. INFERRED.
- Two parallel ingest paths (browser CSV `commit` vs server `cron_ingest`/`sync_ingest`) reimplement name-normalization. The README claims `cron_ingest` "mirrors the app's importer EXACTLY" (`hubstaff-sync:217`) — true today, but it is **duplicated code** (three copies of `nameTokens/nameKey/looseKey`: `hubstaff-sync:262–270`, `:498–500`, plus the browser). Drift risk. SIMPLIFICATION: extract a shared module.

**Dead ends**
- None blocking. Unmatched members are reported, not lost.

**Unnecessary steps**
- `activity_backfill` re-pulls members/names/activities identically to `cron_ingest` (`hubstaff-sync:503–540`) — near-total duplication of the ingest preamble for an informational-only column.

---

## Flow 2 — Payroll run: time → rate → net PHP → Wise draft/batch → (manual fund) → poll/match reconcile → status/lock

**Happy path**
1. **Calculate** (`ProcessPayroll`/Payroll `calculate()` ~`app/index.html:6276`): builds the pay set = workers with approved time ∪ PHS workers with approved sessions (`:6274–6275`). OBSERVED.
2. Worked hours = Σ(`tracked_seconds + pto_seconds`)/3600 (PTO paid like worked time, `:6263–6265, :6279`). OBSERVED.
3. Rate row = effective-dated pick for the period (`rateRowFor`, `:6250–6255`). OBSERVED.
4. Gross by contract type (see Algorithms): salary-proration for FT/PT, units×rate for PHS (`:6292–6302`). OBSERVED.
5. Add HA + 13th + PDD + bonus + misc → `net` (`:6315`); `usd_ref = net/fx` reference only (`:6326`). OBSERVED.
6. `saveDraft` upserts `pay_periods` (state `open`) + `payments` (status `draft`) on conflict keys (`:6364–6386`). OBSERVED.
7. **Lock & Save** (`lockAndSave`, `:6823`): blocks if any row has `net==null` (no rate, `:6828–6834`); warns on missing payout method / inactive workers; flips `pay_periods.state='locked'` and re-upserts payments (`:6851–6868`). OBSERVED.
8. **Wise draft/batch** (`createBatch`, `:8790`): calls `wise-payouts` action `batch` → creates a Wise batch-group + one quote+transfer per item (`wise-payouts:484–528`); **never funds** (`:526–527`). On success the app writes `wise_transfer_id`, `fx_rate`, and **`status:"queued"`** back to payments (`app/index.html:8813–8815`). OBSERVED.
9. **Manual fund**: a human completes/funds the batch in Wise; OR per-row API fund via `fundOne`→action `fund` (`:8715`, `wise-payouts:337–482`), owner-gated + idempotent (`funded_at` guard, `:355–380`). OBSERVED.
10. **Reconcile**: `poll` updates terminal-success transfers to `status:'sent'`, `paid_at`=Wise real sent date, and auto-sets `wise_locked_at` (`wise-payouts:572–651`). `match` backfills `wise_transfer_id` for unmatched rows by recipient+amount+date window (`:662–1160`). OBSERVED.
11. **Mark paid / period state**: `markPaid` sets status and steps the period; `mark_unpaid` reverses, stepping `paid`→`locked` (`app/index.html:9281–9332`). OBSERVED.

**Friction**
- The payment status machine has **two pre-sent states** (`draft` from saveDraft/lock, `queued` from API batch) but reconciliation defaults treat only `draft` as a candidate — see **Dead ends** and Cross-flow risks. OBSERVED.
- FX is fetched once at Calculate time (`open.er-api.com`, `:6136–6143`) and frozen into `payments.fx_rate`, but it is **market FX, not the Wise locked rate** — the README itself notes Wise is USD-funded at a different rate. The `usd_ref` everywhere is therefore systematically off. See Algorithms / FX. OBSERVED.

**Dead ends (logic gap that breaks the flow)**
- **`queued` rows can be skipped by the default Reconcile poll.** `createBatch` sets `status:"queued"` (`app/index.html:8813–8815`), but `poll`'s default `only_drafts:true` filters `status=eq.draft` only (`wise-payouts:580, 590–591`), and the UI calls poll with `only_drafts:true` (`app/index.html:9552`). An API-batched (queued, never draft) row therefore is **not** auto-reconciled by the default pass; it relies on the `includeSent`/`only_drafts:false` path (`:9775`) or on `match`. INFERRED-HIGH (status set vs filter literal both OBSERVED; runtime effect inferred). **Recommend**: poll should select `status.in.(draft,queued)`.

**Unnecessary steps**
- `draft` action and `batch` action duplicate the quote→transfer body almost verbatim (`wise-payouts:198–243` vs `:496–524`), including the C5 Wisetag detection regex. SIMPLIFICATION: factor a shared `quoteAndTransfer(profileId, item, batchGroupId?)`.
- Both `createBatch` and `poll`/`match` write `fx_rate`/`wise_dates`/`paid_at` to payments via separate REST round-trips; the post-batch fan-out (`:8812–8823`) is already chunked, fine, but `fx_rate` stored from the quote is the market-ish Wise quote rate while Calculate stored `open.er-api.com` rate — two different fx sources land on the same row at different times. OBSERVED — see FX algorithm.

---

## Flow 3 — Client invoicing: per-hour AND per-session/flat-fee → invoice generation

**Happy path** (`Invoicing` component, `app/index.html:13085–13190`)
1. Pick a single client + date window. Load active roster's `bill_rate_usd`/`session_rate_usd`/`role` from `worker_companies` (`rateBy`, INFERRED from `:13104`).
2. **Per-hour source**: sum `tracked_seconds` from `time_entries` on the **EMPLOYER** company for the rostered workers (`:13085–13090`); PTO already excluded (only `tracked_seconds` summed, `:13089`). OBSERVED — correct per model (clients aren't billed PTO).
3. **Per-session source**: sum `units` from `service_sessions` where `company_id = client` AND `approval='approved'` (`:13094–13099`); duration ignored, flat fee. OBSERVED.
4. Session-only workers no longer on the active roster are still billed (approved session = committed work); name + `session_rate_usd` pulled regardless of status (`:13104–13112`). OBSERVED (good).
5. Billing set = active roster ∪ workers with approved sessions (`:13114`). A worker can yield **two lines** (hourly + session) (`:13115`). OBSERVED.
6. Line amounts: hourly `round(hours*bill_rate*100)/100` (`:13123`); session `round(units*session_rate*100)/100` (`:13127`). Zero-qty lines dropped; zero-**rate** lines kept (billed $0, flagged) (`:13116–13117, 13135`). OBSERVED.
7. `generate()`: allocate invoice no via `allocate_invoice_no` RPC, insert `invoices` (subtotal, `total=round(subtotal*(1+markup/100)*100)/100`) + `invoice_lines` (`:13139–13157`). Unique constraint `one_live_per_period` blocks a duplicate live invoice (`:13149`). OBSERVED.
8. Print/CSV mirror the math (`:13163–13190`). OBSERVED.

**Friction**
- Session source is scoped by `company_id=client` directly, but the per-hour source is employer-scoped then filtered to the client's roster (`ids`). Two different scoping mechanisms for the same invoice — correct today (one employer) but the in-code note at `:6240–6243` warns this breaks if a second employer is added. OBSERVED.
- Hourly billing uses **raw `tracked_seconds`**, not the *approved/locked* hours used for payroll. An invoice can bill hours that payroll later rejects/adjusts (no `approval='approved'` filter on the invoice time query, `:13085–13087`). INFERRED — possible payroll/invoice divergence. ASSUMPTION: acceptable because billing and pay are independent, but worth confirming with the owner.

**Dead ends**
- None.

**Unnecessary steps**
- `exportCsv` recomputes `total` from `markup` (`:13182`) instead of reusing the `generate()` total; harmless but a second source of the same formula (drift risk if markup rounding changes).

---

## Flow 4 — Onboarding: sign → profile → docs → HR review → countersign → onboarded gate

**Happy path**
1. **Stage 1 sign** (`portal-sign`): caller→active worker via `contractor_logins` (`portal-sign:62–65`). Enforces signing **order** from config (`:116–124`), **scroll-to-bottom** (`:90`), captures IP/UA server-side (`:151–152`), drawn-signature data must be a bounded `data:image…base64` URI (`:99–106`, XSS hardening). Signature row is **immutable** (`ignore-duplicates` = ON CONFLICT DO NOTHING, `:142–144`). Stage advances **monotonically** via RANK (`:169–173`). Soft legal-name mismatch flag, never blocks (`:126–131, :181`). OBSERVED — robust.
2. **Stage 2 profile** (`portal-self` `complete_tab`): requires `stage1_complete` first (`:285`); blocks edits once `completed_at` set (`:288`); writes only `SAFE_FIELDS` (`:28–38, :293`); re-reads authoritative row and validates per tab (`:300–308`); `stage2_complete` when contact+personal+payout validate (`:308`). OBSERVED.
3. **Stage 3 docs**: contractor uploads; HR reviews via `portal-review` (approve / needs_replacement / waive / defer / set_signed_date) (`portal-review:138`). NBI freshness guard, day-accurate, admin-overridable (`:195–200`). OBSERVED.
4. **Stage-3 re-evaluation** (`reEvalStage3`, `portal-review:47–91`): completion is a **pure function** of current cleared docs (approved-per-side ∪ waived ∪ deferred); sided kinds require every configured side approved (`:65–72`). A rejection flips `stage3_complete` false but **`completed_at` is monotonic — never cleared** (`:79–85`). OBSERVED — deliberate (won't silently revoke portal access).
5. **Countersign** (`portal-countersign`): admin countersignature on agreements. OBSERVED (file present; not deep-read).
6. **Onboarded gate**: full = stage1 ∧ stage2 ∧ stage3 (`portal-review:76`); `finish_onboarding` (`portal-self:199–240`) lets the contractor self-complete when all required docs are approved — covers the **no-required-docs** case where HR review never fires completion (`:197–198`). `advance_from_stage1` unsticks a reopened-but-already-signed contractor (`:248–276`). OBSERVED — good edge handling.

**Friction**
- Required-doc/agreement default lists are **hardcoded in three edge functions** (`portal-self:211`, `portal-self:259`, `portal-review:50`, `portal-sign:31`). If the config is empty they each fall back to their own literal — must be kept in sync manually. SIMPLIFICATION: one shared default. OBSERVED.
- `finish_onboarding` (`portal-self`) and `reEvalStage3` (`portal-review`) independently compute stage-3 completion with **slightly different rules**: `finish_onboarding` counts only `approved` (`portal-self:215`), while `reEvalStage3` also counts `waived`/`deferred` as cleared (`portal-review:55, 61`). A contractor whose last required doc was **waived** (not approved) can be onboarded by HR's `reEvalStage3` but would be **rejected by his own `finish_onboarding`** ("docs_pending"). INFERRED-HIGH — divergent completion logic. **Recommend** unifying.

**Dead ends**
- None observed; the two unstick actions (`advance_from_stage1`, `finish_onboarding`) specifically remove the historical dead-ends.

**Unnecessary steps**
- Each onboarding edge fn re-reads `portal_settings.onboarding_config` and re-derives the required list per call; acceptable for an edge fn but duplicated.

---

## Flow 5 — Portal contractor session logging + overrides/adjustments

**Happy path**
1. `SessionsView` (`portal/index.html:864`): loads own worker id, `my_clients()` RPC (id+name, no rates, `:875`), and own `service_sessions` (`:876`). OBSERVED.
2. Log: pick client + date + units + type/case-ref; `units=parseInt(units,10)` validated `≥0` (`:886–887`); insert with `approval:"pending"`, `worker_id`+`company_id=client` (`:889–891`). OBSERVED.
3. Admin approves in Service Sessions tab (`app/index.html:12949` `setApproval`, chunked at 100). OBSERVED.
4. Approved sessions feed **both** payroll (PHS per-session gross, `:6244–6247, 6296`) and invoicing (`:13094`). OBSERVED.

**Overrides / adjustments (admin side)**
- **Gross override** (`overrideGross`, `:6504–6509`): manual gross replaces computed; `overridden` flag drives the lock-time note (`:6384`).
- **Misc items** (`saveMiscForRow`/`miscTotal`, `:6407–6492`): other_earns/other_hours add, `kind:"deduction"` subtracts; folded into net via `recalcNet` (`:6496–6500`).
- **13th override** blank→reverts to computed (`setT13`, `:6516–6519`).
- **Matcher amount override** (server): when a single Wise transfer's amount ≠ `net_php`, `match` auto-overrides `net_php` to Wise's value and preserves `original_net_php` — **only when unambiguous** (`wise-payouts:1056–1086`; refresh path `:842–845`). OBSERVED — this is the "adjusted disbursement" path.

**Friction**
- Units allow `0` (`portal/index.html:887` permits `u>=0`; insert proceeds). A 0-unit approved session bills/pays $0 — harmless but clutters approval queues. INFERRED.
- A contractor can `del` only **pending** sessions in the UI label (`:898`), but the delete query has **no `approval='pending'` filter** (`:900`) — RLS is the only guard. If RLS permits, an approved session could be deleted after it fed an invoice/payroll. INFERRED — verify RLS (Track 1's lane, flagged here as a flow integrity risk).

**Dead ends**
- "Not assigned to a client" shows an explanatory empty state, not a dead end (`:913–914`). OBSERVED.

---

## Flow 6 — Coverage-gap detection / shift schedule flags

**ABSENT.** Searched `app/index.html`, `portal/index.html`, and the docs for `coverage`, `coverage gap`, `shift_schedule`, `schedule gap`, `uncovered`, `missed shift`, `no-show` — **zero matches**. The only schedule concept is the free-text `schedule` token merged into agreements (`app/index.html:10933, 10946–10951`) and the agreement's DST note; there is **no detection of missing/under-covered shifts** against an expected schedule. INFERRED: out of scope for the current system. (Track 5 owns "should this exist"; noted here only to confirm absence.)

---

## Algorithms

### A1 — Net-pay calculation
- **Location**: `app/index.html:6292–6315` (compute), `recalcNet` `:6496–6500`, `miscTotal` `:6486–6492`.
- **Computes**: `net = gross + ha + t13 + pdd + bonus + miscTotal`, each `.toFixed(2)`; `null` net when gross can't be computed (no rate / PHS basis unset).
- **Correctness**: Sound. `null`-net rows are blocked at lock (`:6828`), so a no-rate worker can't be silently dropped. PHS-unset is hard-flagged (`phs_unset`, `:6295, 6323`) so a blank `pay_basis` never silently becomes `worked×rate`. OBSERVED — these are good guards.
- **Edge cases**:
  - Rounding: per-component `.toFixed(2)` then summed — last-cent drift is possible vs summing-then-rounding, but each component is already a money value, so acceptable.
  - `ded` ("rate − gross" performance shortfall) is **informational only**, deliberately NOT in net (`:6484–6485`). Correct, but it is still persisted to `deduction_php` (`:6380`) — a reader of the column alone could misread it as a real deduction. INFERRED minor.
  - Negative net: misc deductions can drive net below 0 with no floor — Wise draft skips `amount_php<=0` (`wise-payouts:312`), so a negative-net worker silently drops from the draft. INFERRED edge case.
- **Simplification**: net is computed in three places (Calculate `:6315`, `recalcNet` `:6498`, `saveDraft` re-maps); centralize on `recalcNet`.

### A2 — Salary proration (FT/PT) + performance ratio
- **Location**: `expectedHours` `:5926–5936`; ratio/gross `:6298–6302`.
- **Computes**: `expectedHours = max(0, weekdays*dayH − weekdayHolidays*dayH)` (FT=8h/day, PT=4h/day, `:5863`); `ratio = min(worked/exp, 5)`; gross = `rate` if `ratio≥1` else `ratio*rate` (semi-monthly salary is fixed; over-100% capped to full rate, under-100% prorated). OBSERVED.
- **Correctness**: Matches the "workbook V" cap of 5 (`:6299`). The `ratio≥1 → full rate` rule means over-delivery is never overpaid (correct for fixed salary).
- **Edge cases**:
  - `exp==0` (a period with only holidays/weekends, or a contract returning 0): `worked/exp` → `Infinity`, `min(Inf,5)=5`, then `ratio≥1` → gross=`rate`. So an FT/PT worker in a zero-expected period gets **full salary** regardless of worked hours. INFERRED — probably fine for fixed salary, but undefined/`NaN` risk if `worked` also 0 and `exp` 0 → `0/0=NaN`; `min(NaN,5)=NaN`, `NaN>=1` is false → gross=`NaN*rate=NaN` → net NaN → blocked at lock. INFERRED — should guard `exp>0`.
  - **Timezone**: `expectedHours` builds dates as `new Date(start+"T00:00:00")` (local browser TZ, `:5929`), and weekday counting uses `getDay()` (local). On an admin machine **not** in a TZ where the boundary is stable, the weekday set could shift by one day vs Manila. INFERRED — low risk (date-only, no time component crossing midnight in most US/PH offsets) but not TZ-pinned like the portal's `ageManila`.
  - Holidays are weekday-only (`holidaysInRange(...,true)`, `:5934`) and editable per year in localStorage (`getHolidays`, `:5907`) — **per-browser**, not shared. Two admins can compute different expected hours. INFERRED — correctness risk for proration.
- **Simplification**: holiday config should live in the DB (currently localStorage `:5993, 5997`).

### A3 — PHS (per-hour / per-session) gross
- **Location**: `:6293–6296`; pay-basis source of truth = `worker_companies.pay_basis` (`:6286`).
- **Computes**: PHS → `exp=0, ratio=1, ded=0`; if basis is `per_session` → `gross = sessions*rate`, if `hourly` → `gross = worked*rate`; else `gross=null` + `phs_unset`. OBSERVED.
- **Correctness**: Good — no expected-hours/proration applied to PHS, and a stale/blank basis can't turn a salary into an hourly rate (`:6289–6291`). 13th and proration correctly excluded for PHS (`:6306` gates `!isPHS`).
- **Edge cases**:
  - Per-session sessions are summed **across all the worker's clients** (`:6240–6247`) — correct under one employer; in-code note flags the multi-employer hazard (double-pay). OBSERVED-and-acknowledged.
  - `sessions` come from `service_sessions.units` with no per-client rate snapshot — payroll uses the **employer-level `rates`** row, invoicing uses **`worker_companies.session_rate_usd`**; these are independent numbers (pay vs bill), which is correct by design.

### A4 — Health allowance
- **Location**: `healthAllowance` `:5939–5948`; constants `HA_ANNUAL=20000, HA_ELIG_DAYS=180` (`:5862`).
- **Computes**: `0` until 180 days after hire; then the **full ₱20,000** in the single period that contains the hire-date anniversary (month/day, day clamped to 28), provided the anniversary ≥ eligibility. OBSERVED.
- **Correctness**: Pays the full annual HA once per year in the anniversary period. Plausible business rule.
- **Edge cases**:
  - Anniversary day clamped to 28 (`Math.min(h.getDate(),28)`, `:5945`) — a 29/30/31-hired worker's HA always lands by the 28th. Minor, intentional.
  - First-year boundary: if hire-anniversary < eligibility date (i.e., hired <180 days before the first anniversary — impossible since anniversary is 365 days out) — guard `anniv>=elig` (`:5946`) is belt-and-suspenders. OK.
  - `new Date(hire)` parses a date-only string as **UTC midnight** then compares to local-parsed period bounds — possible 1-day TZ skew at period edges. INFERRED low risk.

### A5 — 13th-month accrual
- **Location**: `thirteenthAccrual` `:5965–5968`, `monthsWorkedInYear` `:5955–5963`.
- **Computes**: `accrual = (monthsWorked/12) * ratePhp`, where the full annual 13th = `monthsWorked/12 * (rate*2)` (monthly = per-period × 2) and this is **half** of it (paid across two periods). `monthsWorked` = whole+partial months from Jan 1 (or hire date) to period end, partial = `(dayDiff)/30`, clamped 0–12. OBSERVED.
- **Correctness**: The per-period accrual being exactly half the annual is internally consistent with the semi-monthly model. The `/30` partial-month approximation is a standard simplification.
- **Edge cases**:
  - `monthsWorked` partial uses `(end.getDate() − from.getDate())/30` which can be **negative** when end-day < from-day (e.g., hired on the 25th, period ends on the 5th) → the months delta from the y/m difference compensates, but the `/30` term can shave a fraction; clamped at `max(0,…)` overall. INFERRED — minor.
  - Editable per-payee (`setT13`), blank reverts to computed (`:6516–6519`). OK.
  - Gated on `thirteenth_month_eligible` AND `!isPHS` AND `rate!=null` (`:6306`). Correct.

### A6 — FX handling (USD-funded vs market FX)
- **Location**: market fetch `:6034–6036, 6136–6143`; stored on payments `:6382, 6864`; `usd_ref = net/fx` everywhere; Wise quote rate stored separately at batch (`wise-payouts:209, 523`; written back `app/index.html:8814`).
- **Computes**: `usd_ref` = PHP net ÷ market PHP-per-USD (open.er-api.com), reference only.
- **Correctness assessment**: **This is the single biggest semantic gap.** README and memory both state Wise is **USD-funded at a locked rate that differs from the stored market FX**. The app stores TWO different FX numbers on the same payment at different times: (1) `open.er-api.com` market rate at Calculate (`:6140`), and (2) the **Wise quote `rate`** at batch (`:8814`) — but for **PHP→PHP** transfers the Wise quote `rate` is `1` (`wise-payouts:201–210` requests `sourceCurrency:"PHP", targetCurrency:"PHP"`), so the stored `fx_rate` from batching is **1.0**, overwriting the market rate. INFERRED-HIGH. Net effect: `usd_ref` derived later from `fx_rate=1` would equal the PHP amount; any USD reporting off `fx_rate` is wrong. The truly correct USD-funding rate (Wise's USD→PHP source rate) is **never captured** because the quote is PHP→PHP. **Recommend**: capture the real USD→PHP funding rate from Wise (or stop showing USD entirely), and don't let batch overwrite the market `fx_rate` with `1`.
- **Edge cases**: `fx` defaults to 58.0 and is editable (`:6034, 7086`); if the live fetch fails, the last value sticks (`:6143`). `usd_ref` guards `!fx` → null (`:6326`). Division by a zero fx is guarded.
- **Simplification**: one fx field with a clear meaning (market reference vs Wise funding) instead of two writers stomping the same column.

### A7 — Wise reconciliation matcher (`match`)
- **Location**: `wise-payouts:662–1160`.
- **Computes**: For unmatched payments, pulls Wise transfer history (union window, paged to 50×100), filters out `cancelled` ghosts (`:760`), indexes live transfers by recipient (numeric `targetAccount` primary, UUID secondary, + historical `wise_recipients`), then per payment: recipient match → ±`windowDays` date filter → exact-amount (±₱1.00) match → write `wise_transfer_id`; multi-match resolved by **closest pay_date** unless a true ±1-day tie (`:976–1000`); single-candidate amount mismatch → **auto-override** `net_php`, preserve `original_net_php` (`:1056–1060`); multi-candidate mismatch → surfaced, not auto-fixed. Orphan diagnostic offers one-click link candidates with ambiguity flags (`:1089–1152`). OBSERVED.
- **Correctness**: Carefully engineered; the ±₱1 tolerance, cancelled-ghost filter, and closest-date tie-break are all justified in-comment by real incidents (2026-05-28/05-29). ID-first recipient matching with historical-recipient union is exactly the documented convention.
- **Edge cases**:
  - **Window default mismatch**: `match` default `window_days=7` (`:672`), but the UI invokes it with `window_days:14` (`app/index.html:8259, 9795`) and the comment warns ±14 caused the original ambiguous pairs (`:669–671`). So the safer default is **overridden by the caller to the value that caused the bug**. INFERRED-HIGH — flag: callers should use 7, or the default should win. ⚠
  - Refresh fast-path always treats the existing link as unambiguous and auto-overrides amount (`:842–845`) — correct only if the stored `wise_transfer_id` is trusted; a wrong prior link would be reinforced.
  - Duplicate transfer IDs: dedup by transfer id across recipient keys (`:898–910`); cancelled ghosts removed before indexing — both addressed.
  - Locked rows: `match`/`poll` set `wise_locked_at` on terminal-success (`:959, 638`); they don't re-check an already-locked amount, but `refresh` can still PATCH `net_php` — a locked-amount edit path. INFERRED — verify this can't silently re-write a locked payment's amount.
- **Simplification**: the exact-match, closest-date, and variance branches each repeat the `fetchWiseDates` + sentIso + patch-build + PATCH boilerplate (4–5 near-identical blocks, `:944–1086`). Extract a `writeMatch(payment, transfer, {override})`.

### A8 — `poll` reconcile status policy
- **Location**: `wise-payouts:572–651`.
- **Computes**: terminal-success states (`outgoing_payment_sent`/`completed`/`sent`) → `status:'sent'`, `paid_at`=real Wise date, `wise_locked_at`=now (auto-lock). In-flight set surfaced; others left unchanged. OBSERVED.
- **Correctness**: Idempotent, uses real Wise dates not `now()`. Good.
- **Edge case (the Flow-2 dead end)**: default `only_drafts:true` → `status=eq.draft` filter excludes **`queued`** rows created by `createBatch` (`:580, 590`; status set at `app/index.html:8814`). API-batched rows aren't auto-reconciled by the default poll. ⚠ **Recommend** `status.in.(draft,queued)`.

### A9 — Invoice math
- **Location**: `:13119–13132` (lines/subtotal), `:13142` (total/markup).
- **Computes**: line `= round(qty*rate*100)/100`; subtotal `= round(Σlines*100)/100`; total `= round(subtotal*(1+markup/100)*100)/100`. OBSERVED.
- **Correctness**: Consistent rounding (2dp) across preview/generate/print/CSV. Hourly qty = `round(sec/3600*100)/100`.
- **Edge cases**: zero-rate lines kept at $0 and flagged (`:13135`); markup of 0 omits the markup row in print (`:13175`); negative markup not guarded (input `min="0"` only client-side, `:13207`). INFERRED minor.
- **Simplification**: total formula duplicated in `generate` and `exportCsv` (`:13142, 13182`).

### A10 — Period derivation (semi-monthly, arrears)
- **Location**: `periodFor` `:5976–5987`.
- **Computes**: days 1–15 → period 1–15, pay = end of same month; days 16–EOM → period 16–EOM, pay = 15th of next month (Dec wraps to Jan). 24 periods/yr (`:5862`). OBSERVED.
- **Correctness**: Clean. `lastDay(y,m)` via `new Date(y,m+1,0)` handles month lengths/leap years.
- **Edge cases**: half-months are **not equal length** (15 vs 13–16 days) but salary is fixed per period — so per-day value differs across halves; intentional for a fixed semi-monthly salary, but proration (`worked/expected`) uses each half's own weekday count, so it's internally consistent. OK.
- **Biweekly note**: the Wise matcher reasons about a "biweekly payroll cadence" (`wise-payouts:42, 668`) while payroll is actually **semi-monthly** (24/yr, not 26). The ±7-day window assumption ("half the biweekly cadence") is built on a slightly wrong cadence model — semi-monthly periods can be as close as 13 days apart, so ±7 is still safe, but the reasoning is off. INFERRED — cosmetic, not a live bug.

---

## Cross-flow risks

1. **Payment status state machine is under-specified.** Pre-sent rows can be `draft` (saveDraft/lock) or `queued` (API batch, `app/index.html:8814`). The default Reconcile poll only looks at `draft` (`wise-payouts:580`). Result: **API-batched payments are not auto-marked paid by the default poll** and depend on `match` or an `only_drafts:false` call. Unify the candidate set to `(draft,queued)`. (A2/A8/Flow 2.)

2. **Two FX writers, one column.** Calculate writes a market rate to `payments.fx_rate` (`:6382`); `createBatch` overwrites it with the Wise **PHP→PHP quote rate ≈ 1** (`:8814`). Downstream `usd_ref`/USD totals (`:7639, 6470`) are therefore unreliable after batching. The real USD-funding rate is never captured. (A6.)

3. **Two stage-3 completion deciders disagree.** `portal-self.finish_onboarding` counts only `approved` docs; `portal-review.reEvalStage3` also clears on `waived`/`deferred`. A waived-last-doc contractor can be onboarded by HR but blocked from self-finishing. (Flow 4.)

4. **Idempotency / locking is mostly sound but has two soft spots.** (a) `match refresh` can PATCH `net_php` on a row even when `wise_locked_at` is set (`:842–845`) — confirm a locked amount can't be silently rewritten. (b) Per-row fund is idempotent (`funded_at` guard, `wise-payouts:355–380`) — good. (c) Period-level `mark_unpaid` steps `paid→locked` but won't act on rows already `sent`/`wise_locked_at` per the `unlockPeriod` guard (`app/index.html:9132–9139`) — good.

5. **Match window default vs caller value.** Server default `window_days=7` (safe, justified) but every UI caller passes `14` (`:8259, 9795`) — the exact value the comments blame for ambiguous pairs (`wise-payouts:669–671`). Align callers to 7.

6. **Holiday config is per-browser (localStorage).** Two admins computing the same FT/PT period can get different `expectedHours` → different proration → different net. (A2.) Move to DB.

7. **Duplicated name-normalization & required-doc defaults across edge functions** (3× each). Drift between the browser importer, `cron_ingest`, and `activity_backfill`, and between the four onboarding fns, is a latent correctness risk. (Flow 1 / Flow 4.)

8. **Invoice bills raw `tracked_seconds`, payroll pays approved (tracked+PTO).** Invoice hours and payroll hours are computed from different filters (`:13085` no approval filter, PTO-excluded; `:6260–6265` approved-only, PTO-included). Intentional (bill ≠ pay) but means an invoice can bill hours that were later rejected in payroll. Confirm with owner. (Flow 3.)

---

## Assumptions & absences

- **ABSENT**: coverage-gap detection / shift-schedule flags (Flow 6) — no code in either app or the docs.
- **ABSENT in this read**: `buildMatchTable` body, `portal-countersign` internals, `documents-expiry-check`/`hiring-docs-review-check` internals (not in lane — they're email digests, no pay/time/invoice math). Their existence is OBSERVED; logic not deep-read.
- **ASSUMPTION**: RLS is the only guard on the portal session `del` (`portal/index.html:900`, no `approval` filter) and on the invoice/session scoping — RLS correctness is Track 1's lane; flagged here only as a flow-integrity dependency.
- **ASSUMPTION**: `worker_companies.pay_basis` / `contract` / `bill_rate_usd` / `session_rate_usd` semantics are as named (read from usage, not from schema in this track).
- **INFERRED-HIGH** items (status filter vs status-set effect, FX double-write, two completion deciders) are derived from two independently OBSERVED facts each; runtime confirmation (DB inspection) was not performed (read-only audit, no DB queries run).
