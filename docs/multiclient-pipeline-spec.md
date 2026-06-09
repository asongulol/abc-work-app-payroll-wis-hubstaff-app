I now have all the load-bearing facts verified against live DB and code. Key corrections to fold into the spec:

1. **Design 1 primary rule is wrong** — confirmed: 0 workers with >1 active link; the 4 dual workers' only active link is Baby Talks (0 history), Ability is `ended` (all their money). History-anchored primary required.
2. **`worker_companies.id` is random uuid** — MIN(id) tiebreak is not "earliest."
3. **The deployed sync ALREADY does per-project routing + drops unmapped + has the PTO `if(companyId)` drop bug** (line 330). "Realign" = revert an already-shipped Phase B, not modify a clean single-company sync. The designs misdescribe the starting state.
4. **3 projects already map to Baby Talks** in hubstaff_projects — so cron is NOT a no-op; once a Baby-mapped project gets time it writes Baby rows. Mitigation (freeze cron to `[companyId]`) is mandatory.
5. **Wise match auto-override** (597-600, 812-815) confirmed — money-corruption bug for consolidated transfers.
6. Lock trigger protected cols confirmed (net_php 379, payout_amount 382); settlement cols permitted.
7. App call sites, lock-overlap pattern, RPC pattern, RLS helper `my_admin_company_ids()`, time_entries unique key — all confirmed.

Here is the final spec.

---

# Multi-Client Payroll Pipeline — Final Implementation Spec

**Project:** `cgsidolrauzsowqlllsz` (PRODUCTION). **Files:** `supabase/functions/hubstaff-sync/index.ts`, `supabase/functions/wise-payouts/index.ts`, `schema/schema.sql`, `app/index.html`. **Verified against live DB + deployed code on 2026-06-09.**

> **Reality check that overrides both designs:** The deployed `hubstaff-sync` (`index.ts:222`) ALREADY does per-project→client routing, ALREADY drops unmapped seconds (`index.ts:309`), and ALREADY drops ALL PTO in consolidated mode (`index.ts:330`, guarded `if (companyId)` which is false when `company_id` is omitted). `hubstaff_projects` already has 11 rows, **3 of them mapped to 123 Baby Talks** (verified). So Phase 1 is **reverting a half-shipped split**, not modifying a pristine single-company sync. Treat the current prod sync as a known-buggy intermediate state.

---

## 1. Summary

One employer (Aaron Anderson) runs a single Hubstaff org (258598) whose contractors actually serve multiple client companies (today: Ability Builders has 100% of money — 10,514 time_entries / 1,067 payments; 123 Baby Talks and 1 World Realty have 0/0). The pipeline imports **all** of the org's tracked+PTO time and lands every worker's day on their **primary client** (history-anchored: the company where their pay already lives), never dropping a matched contractor (Phase 1). A separate, idempotent **classify** step then re-reads Hubstaff's per-project daily rows and **MOVES** (never copies) each worker-day's seconds into the correct client rows under a strict conservation invariant, auto-assigning client links as needed and refusing to touch locked/approved/paid time (Phase 2). At payout, contractors are paid **one Wise transfer per pay cycle = the sum of their net across all clients**, with the transfer id/fx stamped onto every per-client `payments` row so poll/match/reconcile move them together (Phase 3). Finally, read-only per-client **invoicing** rolls up `payments`/`time_entries` by `company_id` into persisted invoice snapshots (Phase 4). Every phase is additive, reversible, and a verified byte-identical no-op while only one client has money — multi-client paths stay dormant until a project is mapped to a second client AND a real worker logs time there.

---

## 2. Schema changes (all additive + reversible)

> RLS pattern for every new money/client table: `(select is_owner()) or company_id in (select unnest(public.my_admin_company_ids()))` — `my_admin_company_ids()` exists (`schema/migrations/2026-06-08_rls_perf_money_tables.sql:18`). The designs' `is_company_admin`/`my_admin_company_ids` references are correct.

### 2.1 Phase 1 — **NO DDL.** 
Primary client is **derived**, not stored. (Optional `worker_companies.is_primary` deferred — derivation keeps single-client behavior byte-identical with zero migration on live money data.)

### 2.2 Phase 2 — `time_entry_client_splits` + `reclassify_worker_day` RPC

**Migration `schema/migrations/2026-06-10_time_entry_client_splits.sql`:**

```sql
-- Per-(company, worker, work_date) breakdown of how a day's Hubstaff seconds split
-- across CLIENT companies. Idempotency/audit ledger for classify_to_clients.
-- KEY GRAIN FIX (critique #2): time_entries is unique on (company_id, source_name,
-- work_date), and a worker maps 1:1 to a (company, work_date) row TODAY (verified:
-- 0 days with >1 source_name per company/worker/day). This table keys on
-- (worker_id, work_date, company_id) and that grain MUST equal time_entries' grain.
-- Phase 2 ASSERTS one-row-per-(company,worker,day) at runtime before moving (see 4.x).
create table if not exists public.time_entry_client_splits (
  worker_id        uuid not null references public.workers(id)   on delete cascade,
  work_date        date not null,
  company_id       uuid not null references public.companies(id) on delete cascade,
  tracked_seconds  integer not null default 0,
  pto_seconds      integer not null default 0,
  hubstaff_user_id bigint,
  classified_at    timestamptz not null default now(),
  primary key (worker_id, work_date, company_id)
);
create index if not exists tecs_company_date_idx on public.time_entry_client_splits (company_id, work_date);
alter table public.time_entry_client_splits enable row level security;
drop policy if exists tecs_admin_all on public.time_entry_client_splits;
create policy tecs_admin_all on public.time_entry_client_splits for all to authenticated
  using      ((select is_owner()) or company_id in (select unnest(public.my_admin_company_ids())))
  with check ((select is_owner()) or company_id in (select unnest(public.my_admin_company_ids())));
-- Rollback: drop table if exists public.time_entry_client_splits;
```

**RPC `reclassify_worker_day(p jsonb)`** (mirrors `set_time_entry_activity`, `schema/migrations/2026-06-06_set_time_entry_activity.sql`; service_role only). Contract — does ALL of the following in ONE transaction (this is the load-bearing constraint; never split into separate PostgREST calls):

- Input: `{ worker_id, work_date, stored_total_tracked, stored_total_pto, targets:[{company_id, source_name, tracked_seconds, pto_seconds, activity_pct}] }`.
- **Guard (skip whole worker-day, return `{skipped:'locked'|'approved'}` if any fail):**
  - For **every company in `targets` AND the current row's source company** (both source and destination — critique gap): a `pay_periods` row with `state in ('locked','paid')` whose `[period_start, period_end]` overlaps `work_date`. Query mirrors `app/index.html:5054-5057`.
  - Any `payments` row with `wise_locked_at is not null` for that worker in an overlapping period (a paid period must not be re-based).
  - Any existing `time_entries` row at `(company, worker, work_date)` with `approval <> 'pending'` (mirrors `index.ts:400`).
- **Conservation assert (reconcile against STORED, not just fetched — critique gap):** `sum(targets.tracked) + sum(targets.pto)` must be `<= stored_total_tracked + stored_total_pto`; if it differs by more than 0, **report a `delta` in the return value, do not silently absorb**. (Hubstaff late-edits cause drift; surfacing it is required.)
- **Move:** UPSERT each target row `on conflict (company_id, source_name, work_date)` (merge — preserves `pay_period_id`/`import_batch_id`/`approved_*`); then **DELETE** any `time_entries` row for this `(worker_id, work_date)` on a company NOT in `targets` whose share is now 0. New-company rows get `pay_period_id = NULL` (the guard above already prevented writing into a locked destination period).
- Upsert `time_entry_client_splits` for each target.

```sql
create or replace function public.reclassify_worker_day(p jsonb) returns jsonb
  language plpgsql security definer set search_path to 'public' as $$ /* body per contract above */ $$;
revoke all on function public.reclassify_worker_day(jsonb) from public, anon, authenticated;
grant execute on function public.reclassify_worker_day(jsonb) to service_role;
-- Rollback: drop function if exists public.reclassify_worker_day(jsonb);
```

> **Do NOT** add `hubstaff_project_id` to `time_entries`: classify collapses multiple projects-of-one-client into one row, so a single project id per row is lossy. The splits table is the breakdown home. (`project text` at `schema.sql:160` is dead — never written; leave it.)

### 2.3 Phase 3 — optional `wise_consolidation_id` (recommended)

```sql
-- Migration schema/migrations/2026-06-11_wise_consolidation_id.sql
alter table public.payments add column if not exists wise_consolidation_id uuid;
create index if not exists payments_consolidation_idx on public.payments (wise_consolidation_id)
  where wise_consolidation_id is not null;
-- Rollback: alter table public.payments drop column if exists wise_consolidation_id;
```

NULL = standalone/single-client (today). NOT in the lock trigger's protected list (`schema.sql:366-384`), so writable on locked rows like `wise_transfer_id`. **HARD GUARDRAIL in migration comment: do NOT add `unique(wise_transfer_id)`** — one transfer intentionally maps to N rows.

### 2.4 Phase 4 — `invoices`, `invoice_lines`, `invoice_counters`

**Migration `schema/migrations/2026-06-12_invoices.sql`.** Use the partial unique index ONLY — **do NOT also write the inline `unique(company_id, pay_period_id)`** (critique: the blanket unique blocks void+regenerate, defeating the partial index).

```sql
create table if not exists public.invoices (
  id            uuid primary key default gen_random_uuid(),
  company_id    uuid not null references public.companies(id) on delete restrict,
  pay_period_id uuid references public.pay_periods(id) on delete set null,
  period_start  date not null,
  period_end    date not null,
  invoice_no    text not null unique,
  status        text not null default 'draft' check (status in ('draft','sent','paid','void')),
  currency      text not null default 'PHP',
  subtotal_php  numeric(12,2) not null default 0,
  total_hours   numeric(10,2) not null default 0,
  markup_pct    numeric(6,3)  not null default 0,   -- HOOK (owner unspecified) = 0
  markup_php    numeric(12,2) not null default 0,
  total_php     numeric(12,2) not null default 0,   -- subtotal_php + markup_php
  client_name   text, notes text,
  generated_by  uuid default auth.uid(),
  generated_at  timestamptz not null default now(),
  sent_at timestamptz, paid_at timestamptz, voided_at timestamptz,
  created_at    timestamptz not null default now()
  -- NO inline unique(company_id,pay_period_id) here.
);
create unique index if not exists invoices_one_live_per_period
  on public.invoices (company_id, pay_period_id) where status <> 'void';
create index if not exists invoices_company_id_idx on public.invoices (company_id);
create index if not exists invoices_period_idx on public.invoices (period_start, period_end);

create table if not exists public.invoice_lines (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  worker_id  uuid references public.workers(id) on delete set null,
  worker_name text,
  payment_id uuid references public.payments(id) on delete set null,
  hours numeric(10,2) not null default 0,
  rate_php numeric(12,2),
  amount_php numeric(12,2) not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists invoice_lines_invoice_id_idx on public.invoice_lines (invoice_id);

create table if not exists public.invoice_counters (year int primary key, last_seq int not null default 0);

alter table public.invoices enable row level security;
alter table public.invoice_lines enable row level security;
alter table public.invoice_counters enable row level security;
drop policy if exists invoices_admin_all on public.invoices;
create policy invoices_admin_all on public.invoices for all to authenticated
  using      ((select is_owner()) or company_id in (select unnest(public.my_admin_company_ids())))
  with check ((select is_owner()) or company_id in (select unnest(public.my_admin_company_ids())));
drop policy if exists invoice_lines_admin_all on public.invoice_lines;
create policy invoice_lines_admin_all on public.invoice_lines for all to authenticated
  using      (exists (select 1 from public.invoices i where i.id = invoice_id and ((select is_owner()) or i.company_id in (select unnest(public.my_admin_company_ids())))))
  with check (exists (select 1 from public.invoices i where i.id = invoice_id and ((select is_owner()) or i.company_id in (select unnest(public.my_admin_company_ids())))));
drop policy if exists invoice_counters_admin_all on public.invoice_counters;
create policy invoice_counters_admin_all on public.invoice_counters for all to authenticated using (is_admin()) with check (is_admin());
-- Rollback: drop table if exists public.invoice_lines; drop table public.invoices; drop table public.invoice_counters;
```

**`allocate_invoice_no(p_year int)`** — security-definer RPC doing `UPDATE invoice_counters SET last_seq = last_seq + 1 ... RETURNING` (atomic; drop the browser-write counter path — critique #4 on race). Returns `INV-{year}-{seq:04d}`. Header/lines insert via RLS-scoped browser client.

---

## 3. Phase 1 — Sync realign (employer-wide import to primary client)

**Goal:** Split the conflated `cron_ingest`/`sync_ingest` (`index.ts:222`) into two functions sharing helpers (`nameTokens`/`nameKey`/`looseKey` at `index.ts:255-263`, `pageAll`). Consolidated `sync_ingest` imports the whole org to each worker's **primary client**; per-project routing moves OUT of sync into Phase 2.

### 3.1 Primary-client derivation — **HISTORY-ANCHORED (corrects Design 1)**

Design 1's "primary = lowest `started_on` among ACTIVE links, tie-broken by `id`" is **wrong on live data**:
- **0** workers have >1 active link (verified). 
- The 4 named workers (Catalino, Velante, Gamboa, Gatchalian) have their ONLY active link on **123 Baby Talks** (0 te / 0 pay), while **all** their pay history (1,264 te / 123 pay combined) is on **Ability** where the link is `status='ended'`, `started_on=NULL`. Design 1's rule would write all their new time to the empty Baby Talks → opens a phantom pay surface, risks double-count.
- `worker_companies.id` = `uuid default gen_random_uuid()` (verified) → "MIN(id) = earliest" is **false**; it's a random total order. Use it only as a last-resort tiebreak, never call it "earliest."

**Correct rule `primaryClient(worker_id)`:**
1. **History anchor (wins):** the `company_id` with the most `payments` for that worker; tie → most `time_entries`; tie → latest `time_entries.work_date`. (Keeps the 4 on Ability.)
2. **Net-new worker (no history):** the active link with lowest `started_on` (NULLS LAST); tie → `ended_on IS NULL` first; final tiebreak → `id`.
3. This also resolves "only-link-is-ended" members (the common case here — 24 ended vs 29 active links): a worker with history but no active link still imports to their history company. Owner model = "nobody dropped." Surface ended-only workers in the report so the owner can decide.

### 3.2 Edge: rewritten consolidated `sync_ingest`

1. Fetch **all** `worker_companies` once (NO `company_id` filter — drop the `company_id=in.(targetCompanies)` at `index.ts:351-354`): `select=company_id,worker_id,hubstaff_name,hubstaff_user_id,status,started_on,ended_on,id,workers(first_name,last_name,status)`.
2. Build a **single flat** `{byId, strict, loose}` index (not per-company `idx[co]` of `index.ts:356-369`). `byId[hubstaff_user_id]=worker_id` (id-first). For name-key collisions between **different workers**, resolve by **worker-level history** (worker with existing payments/most-recent activity), NOT "primary company" (Design 1's rule is circular). Log every name-only resolution. (Verified live: 0 loose-name collisions today, but 12 active links lack `hubstaff_user_id`, so the surface is live — prioritize backfilling those 12 via the persist step.)
3. Build `primaryClient` per §3.1.
4. Members → names exactly as `index.ts:268-283`.
5. `activities/daily` for `[start,stop]` (`index.ts:298-301`), but **aggregate per-user-per-day SUMMING across `project_id`** (drop `coOf`/`projMap`/`unmappedSecs` — `index.ts:288-312`): `trackedDay[uid][day] += a.tracked`, `overallDay[uid][day] += a.overall`.
6. **PTO keyed by `uid` only** and bucketed to `primaryClient[worker]` — **fixes the PTO-drop bug** (`index.ts:330` `if (companyId)` is false in consolidated mode → today consolidated PTO is silently lost). Remove the `companyId` guard; always accumulate `ptoDay[uid][day]`.
7. Per uid: `hit = match(byId/strict/loose)`. If no match → `unmatched.add(name)`, continue (match-before-create). `co = primaryClient[hit.worker_id]`. Collect distinct primary cos → scope the canonical-source and decided-row queries to those cos (logic identical to `index.ts:378-404`). Build per-day rows `{company_id:co, worker_id, source_name:src, work_date, tracked_seconds, pto_seconds, activity_pct, approval:'pending'}`, skipping empty days and decided rows (`index.ts:435-447`). Persist `hubstaff_user_id` on name-matched primary link (`index.ts:466-471`).
8. Upsert `on_conflict=company_id,source_name,work_date`, `merge-duplicates,return=minimal` (`index.ts:457-461` — guarantees `pay_period_id`/`import_batch_id`/`approved_*` survive).
9. Return `{ok, window, members_seen, rows_written, ids_persisted, skipped_decided, unmatched, ended_only_workers}`. **Keep `clients_attributed`, `unmapped_seconds` in the response as `0`/`null`** for one release so the app banner (`app:4212,4216`) doesn't break before its own deploy.

### 3.3 Edge: frozen `cron_ingest` + **mandatory** cron fix

Keep `cron_ingest` on its own branch with the current per-company code BUT **restrict `targetCompanies` to `[companyId]` only — drop `projMap` from cron** (mandatory, not optional). Verified: 3 projects already map to Baby Talks, so the moment a Baby-mapped project logs time, today's cron WOULD write Baby rows (`index.ts:338` `targetCompanies = [companyId, ...Object.values(projMap)]`). If cron writes Baby and consolidated sync writes Ability for the same person/day under different `source_name`s → two rows across two companies pre-classification → breaks Phase 2 conservation. Freezing cron to the worker's single company eliminates this.

### 3.4 App `TimeImport` (`app/index.html`)

- Consolidated branch (`4204-4219`): keep `action:'sync_ingest'` call with `{org_id,start,stop}` unchanged (`4209`). Update copy: drop "attributes each project's time to its client" / "unmapped projects skipped"; new: `"Synced org-wide: ${rows_written} daily entries imported to each contractor's primary client. Client classification is a separate step."` Drop the `unmappedH` line (`4212,4218`). Keep the unmatched-member line. Reword banner at `4374`.
- **Single-client branch (`4221-4252`) + `commit`/`writeRows` (`4255+`): DO NOT TOUCH.** It uses the default `/v2` rollup (no `action`), client-side match, writes to one `companyId`. Byte-identical path preserved.

### 3.5 Single-client parity (Phase 1)
With all money on Ability and the history-anchored rule, every matched member resolves to Ability → consolidated sync writes only Ability rows on the same conflict key = the same rows today's per-project path produces for Ability. The 4 dual workers stay on Ability (their history company). Cron, frozen to `[companyId]`, is unchanged for Ability. Single-client UI path untouched.

---

## 4. Phase 2 — Classify hours to clients (new edge action `classify_to_clients`)

**Where:** new action in `hubstaff-sync/index.ts`, gated by the admin-bearer block (NOT secret-gated). Inputs `{action:'classify_to_clients', org_id, start, stop}`, no `company_id`. **Hard prerequisite: Phase 1 must be deployed first** — classify's conservation assumes sync wrote the FULL day to the primary; if it runs against already-project-split rows the invariant is false on arrival.

**MOVE-not-duplicate algorithm:**

1. **Re-fetch per-project truth:** `activities/daily` for `[start,stop]` (one row per user/project/day). Load `hubstaff_projects` (`hubstaff_project_id → company_id`). Load members→names. (DB-only split is impossible — `time_entries.project` is dead; the per-project breakdown exists only in Hubstaff.)
2. **Build split `[uid][work_date][co]`:** `co = projMap[project_id]`; **unmapped → primary client** (never drop). Accumulate tracked per co; track overall per co for `activity_pct = round(overall/tracked*100)` recomputed **per client** (weighted, not copied — critique). **PTO → primary client bucket** (no project). Invariant: `Σ_co split == day total`.
3. **Resolve uid→worker_id:** id-first on `worker_companies.hubstaff_user_id`, then strict/loose name, persisting id on first name-match.
4. **AUTO-ASSIGN (match-before-create, opt-in/reported):** for a client the worker isn't linked to, INSERT `worker_companies(worker_id, company_id, status='active', hubstaff_user_id, hubstaff_name)` `on conflict (worker_id, company_id) do nothing`. **Surface every created link AND every "auto-linked, needs rate" in the report** — a link with no `rates` row yields null gross and silently drops the worker from that client's payroll (`app:5783`); and new active links flip RLS scope (`my_admin_company_ids`). Make auto-assign **report-for-confirmation**, not silent, on live data. Do not create a link that contradicts an existing `ended` link without surfacing it.
5. **MOVE via `reclassify_worker_day` RPC** (one txn per worker-day):
   - **Pre-assert grain:** confirm the source `(company, worker, work_date)` is a single row (verified true today: 0 multi-source_name days). If not, report and skip — do not move.
   - **Guard:** date-overlap lock on `pay_periods.state in ('locked','paid')` for **both source and destination** companies (`app:5054-5057` pattern) + `payments.wise_locked_at` + `approval <> 'pending'`. Skip whole worker-day on any hit; report.
   - Canonical `source_name` per `(co, worker)` reused from existing rows (`index.ts:378-390`) so UPSERT hits the same unique key.
   - UPSERT each target client row (`merge`, preserves `pay_period_id`); **DELETE** any row on a company not in the target set whose share is now 0 — **same transaction** (a mid-failure split would leave seconds on two clients = double-count).
   - **Conservation vs STORED:** validate `Σ targets ≤ stored row total`; report any delta (don't absorb).
   - Upsert `time_entry_client_splits`.
6. **Report** `{window, workers_classified, clients_touched, links_created, links_need_rate, rows_moved, skipped_locked, skipped_approved, skipped_grain, conservation_deltas, unmapped_seconds_left_on_primary}`.

**Idempotency:** always recompute from the **absolute** `activities/daily` total (never deltas). Re-run unchanged map → UPSERT no-op, no delete, splits re-stamped. Re-run after map edit (B→C) → C gains, B shrinks/deletes in one txn, splits self-heal. **Approved-row protection:** decided + locked/paid + wise_locked rows are never moved.

**Single-client parity:** Today's 8 Ability-mapped projects + unmapped→primary all route to Ability for Ability workers → `split[uid][day]` has one client, no new links, UPSERT no-op, no delete. The 3 Baby-mapped projects are dormant until a worker logs time on them. (Note: classify is NOT globally dormant because 3 Baby mappings exist — it activates the instant a real worker logs Baby-project time, which is the true activation gate.)

---

## 5. Phase 3 — Consolidated payout

**Approach:** opt-in "consolidated" mode in existing `WisePayouts` (`app:8029+`) + existing `batch` action (`index.ts:249`). **No new edge action, no new grouping table for v1.** Grouping key = the pay-cycle triple `(period_start, period_end, pay_date)` — the same calendar cycle appears as N `pay_periods` rows (one per company; `pay_periods` is `unique(company_id, period_start, period_end)`). Aggregate `net_php` per worker across those N → ONE transfer → stamp the id/fx onto ALL N `payments` rows.

**Grouping (front-end, `consolidated=true`):**
1. Replace single-period load (`app:8041-8047,8053`) with a cycle load: query `pay_periods` across visible companies `in ('locked','paid')`, group by `(period_start,period_end,pay_date)`, present triples in the dropdown.
2. Resolve the N `pay_period` ids for the triple; fetch `payments` `.in('pay_period_id', ids)` selecting `worker_id,company_id,net_php,wise_transfer_id,fx_rate,status,payout_method,workers(...)`.
3. Aggregate per worker: `amount = Σ net_php`; keep per-client breakdown. **`include` = has recipient AND NONE of the worker's cycle rows already carries a `wise_transfer_id`** — exclude the whole worker if any row is stamped (not just that row); single-period path keeps skipping stamped rows (`app:8078` `!!def && !p.wise_transfer_id`). **Pick ONE path per cycle (consolidated XOR per-period), never both** → prevents double-pay.
4. `createBatch` (`app:8092`): items = one per worker, `amount_php = summed`. Same `batch` action (`index.ts:249-284`) — one transfer per item, no edge change for the draft.
5. **Post-batch stamp (replaces `app:8108-8113`):** per worker, ONE atomic PostgREST update: `client.from('payments').update({wise_transfer_id:String(r.transfer_id), fx_rate:r.fx_rate, status:'queued', wise_consolidation_id:<uuid>}).in('pay_period_id', cyclePeriodIds).eq('worker_id', r.worker_id)`. One statement per worker across N rows (not N statements) → no half-linked cycle.

**Poll (`index.ts:327-407`) — NO CHANGE.** Selects all rows with `wise_transfer_id not null` (`343-347`), fetches per row, PATCHes by id (`387`), auto-locks via `wise_locked_at` (`393`). N rows sharing one id each flip to sent. Idempotent. (Optional: dedupe GETs by transfer_id.)

**Match (`index.ts:417-916`) — REQUIRED fix (highest-severity money bug, verified):** Both the refresh fast-path (`597-600`) and discovery (`812-815`) do `original_net_php = dbAmt; net_php = wiseAmt`. For a consolidated transfer, `wiseAmt = targetValue = the SUM`, while each member row's `dbAmt = its share` → `Math.abs(diff) <= 1.00` fails → it overwrites that client's `net_php` to the full sum (e.g. ₱10k row → ₱30k). On an unlocked row this silently inflates one client's billing 3×; on a locked row the trigger (`net_php` protected, `schema.sql:379`) throws a 500 mid-reconcile. **Mitigation (mandatory before any multi-client cycle reconciles):**
- Detect group membership: a `wise_transfer_id` shared by >1 payment row, or `wise_consolidation_id is not null`.
- For grouped rows: compute `dbAmt = Σ net_php across rows sharing this transfer_id`, compare to `targetValue` with the ±1 tolerance applied to the **SUM**, and **never write `net_php`/`original_net_php` on a member row** (skip the override entirely).
- For first-time discovery: gate the amount-override (`812-815`) behind "this worker has exactly one payment row in the window" (consolidated always stamps the id at batch time, so discovery never needs to find grouped transfers).

**Reconcile (`ReconcileOverview app:8240-8263`) — NO CHANGE.** Per-row; a sent+matched row is ready regardless of siblings.

**Lock trigger — safe for the stamp:** `wise_transfer_id, fx_rate, status, paid_at, wise_dates, wise_locked_at, wise_consolidation_id` are all PERMITTED-on-locked (not in `schema.sql:366-384`). `net_php`(379)/`payout_amount`(382) protected — which is exactly why the match fix must not rewrite member `net_php`.

**Single-client parity:** one client → cycle resolves to one `pay_period` per worker → sum = that one row → items identical to today. The embed in `ProcessPayroll` (`app:9865`) keeps passing `presetPeriodId` (single period/company). `wise_consolidation_id` NULL everywhere. Stamp `.in(pay_period_id,[one]).eq(worker_id)` ≡ today's `.eq(pay_period_id).eq(worker_id)` (`app:8112`). Match fix never fires (>1-row condition never true today).

---

## 6. Phase 4 — Invoicing/billing

**Model:** persisted-on-generate (header + lines), seeded by reading existing `payments`/`time_entries` rolled up by `company_id` (the same axis Reports uses). Read-only AR — never writes `payments`/`time_entries`.

**Data model:** §2.4. Cost basis = `payments.net_php` per `(company_id, pay_period_id)`. Markup hook defaults 0 → `total == subtotal == Σ net_php`.

**Generate (only write path):**
1. Admin picks a CLIENT (`companyId`) + a locked/paid `pay_period`. **Disabled in `consolidated` mode** (mirror `app:8137`) and **gated to `state in ('locked','paid')`** (mirror `app:8044`) — don't snapshot an open period that reconcile (`original_net_php`) will later change.
2. Preview (no write): `payments.select('worker_id,worked_hours,rate_php,net_php,workers(...)').eq('company_id',companyId).eq('pay_period_id',periodId)` (same shape as `app:7077,8059`). Lines: `{worker_id, worker_name:fullName(p.workers) (app:807), hours:worked_hours, rate_php, amount_php:net_php, payment_id}`. `subtotal=Σ net_php`, `total_hours=Σ worked_hours`, `markup_php=round(subtotal*markup_pct/100,2)`.
3. Generate: `allocate_invoice_no(year)` RPC → insert header (`draft`) + lines. `logEvent(...)` (`app:844`). Partial unique index blocks a 2nd live invoice per `(company, period)`; UI offers View / Void & regenerate.
4. View/Print/Export read the **snapshot** (authoritative — reproducible AR). Print: clone `printDoc` (`app:10268-10296`), all interpolated values through `escapeHtml` (`app:10122`), money via `money(n,'PHP')` (`app:5400`). CSV: `downloadCSV` (`app:8223`).

**Status:** draft→sent→paid, optional void (frees the partial-unique slot). Lines immutable; regenerate = void + new.

**UI placement (`app/index.html`):** add `'invoicing'` to restore-list (~`11686`); `["invoicing","Invoicing"]` to the **Review** group (~`11840`, next to Reports — NOT next to Process/Pay); `invoicing:"🧾"` to NAV_ICON (~`11845`); lazy mount alongside Reports (~`11905`, `seenTabs.has("invoicing")` gate so no queries until opened). New `<Invoicing client companyId consolidated/>` after Reports (~`7251`), reusing `useQuery/pageAll/money/fullName/downloadCSV/escapeHtml/logEvent`.

**Hard dependency (the unowned seam — see Risks):** invoicing rolls up per-client `payments` rows. Phase 3 **retains** N per-client rows (stamps the same transfer id on each) — that invariant is the linchpin letting consolidated payout AND per-client invoicing read the same `payments` table without double-count. But **nothing yet CREATES a per-client `payments` row for a newly-classified client** — see Risk R1.

**Single-client parity:** Ability invoice = `payments.eq('company_id',Ability).eq('pay_period_id',pid)` = exactly today's Reports numbers; markup 0 → total = cost. 3 new tables + 1 lazy read-only tab; zero change to existing tables/RLS/payout/sync.

---

## 7. Per-phase VERIFY (money-safe) + deploy notes

> You cannot test multi-client end-to-end until a real assignment+time exists. Every check below is either read-only or asserts byte-identical no-op on prod. Do the activation rehearsal on a Supabase **branch** (per staging convention).

**Deploy notes (apply to all phases):**
- **App** = git push to `main` → Cloudflare auto-deploy. **Edge** = `supabase functions deploy hubstaff-sync` / `wise-payouts`. **Migrations** = `mcp Supabase apply_migration` (project applies via MCP) or `supabase db push`.
- **Edge "no change" gotcha:** the CLI skips deploy if it thinks nothing changed — bump a version comment / confirm via `supabase functions list` and a live `members_seen` response after deploy.
- **Decouple edge↔app:** edge and app deploy separately. Keep removed response fields (`clients_attributed`, `unmapped_seconds`) as `0`/`null` for one release so the app banner survives until its own push.
- **Order is mandatory:** Phase 1 (revert sync) → Phase 2 (classify, scaffold dormant) → Phase 3 (payout mode, dormant) → Phase 4 (invoicing, dormant). Activation (first Baby-project worker time) comes LAST, on a branch first.

**Phase 1:**
- Read-only pre-check (already run): 0 workers with >1 active link; the 4 dual workers' history is 100% Ability; `worker_companies.id` is random uuid. ✔ confirms history-anchored rule.
- Dry-run `sync_ingest` on a branch DB for a recent window; assert: (a) the 4 workers' rows land on **Ability**, not Baby; (b) `rows_written` and per-Ability totals equal the current per-project path's Ability output; (c) consolidated **PTO total now matches** the single-client `/v2` rollup's `pto_total` (regression for the `index.ts:330` fix); (d) no Baby Talks rows written.
- Cron: after freezing to `[companyId]`, run cron for Ability on the branch; assert written rows identical and zero Baby rows.

**Phase 2:**
- With current map (8 Ability, 3 Baby) but no Baby worker-time: run `classify_to_clients`; assert `rows_moved=0`, `links_created=0`, `time_entries` byte-identical, splits mirror time_entries 1:1.
- Conservation kill-test (branch): inject a 2-client day, kill the connection between the RPC's UPSERT and DELETE; assert the txn fully rolls back (no seconds on two clients).
- Lock guard test: mark a period locked/paid covering a worker-day; assert classify skips it (`skipped_locked` in report) and moves nothing.
- Auto-assign test: map a Baby project + add branch time; assert link created with `status='active'`, "needs rate" surfaced, and the worker does NOT silently vanish from payroll without a flag.

**Phase 3:**
- Dormant check: run a single-client cycle through consolidated mode on a branch; assert items/amounts/stamp identical to per-period path, `wise_consolidation_id` NULL.
- Match-fix test (branch): create 2 per-client rows sharing one transfer_id summing to the transfer's `targetValue`; run `match --refresh`; assert NEITHER row's `net_php` is overwritten and both reconcile. Then flip one row to locked and assert no 500.
- **CHECK to add:** for any cycle, `Σ(payments.net_php where wise_transfer_id=X)` must equal the Wise transfer `targetValue` (±1 on the sum).
- Double-pay guard: stamp one cycle row, then attempt the other path; assert the worker is fully excluded.

**Phase 4:**
- Generate an Ability invoice for a locked period; assert `subtotal == total == Σ net_php` and equals the Reports figure; markup 0.
- Void+regenerate; assert the partial unique index allows the new draft (confirms the inline-unique was NOT shipped).
- `allocate_invoice_no` race: two concurrent generates; assert no duplicate `invoice_no`.
- Print/CSV: confirm `escapeHtml` on worker/client/notes; CSV totals row matches header.

---

## 8. Do-NOT / risks

**R1 — Unowned seam (highest priority, in none of the 4 designs): per-client `payments` row CREATION.** Phase 2 produces per-client `time_entries`/`splits`; Phase 3 and Phase 4 both CONSUME per-client `payments` rows; **no phase BUILDS them.** Today payroll (`Payroll`/`ProcessPayroll`) builds `payments` per `(pay_period_id, worker_id)` for ONE company via that company's `pay_period`. A multi-client worker only gets N `payments` rows if payroll is run per client AND a `pay_period` exists for each client for that cycle — and nothing guarantees a Baby Talks `pay_period` is created on first classification. **This is the true activation work item; scope it before activating multi-client.** Until then a multi-client worker risks fragmented pay or mis-billed invoices.

**R2 — Do NOT use Design 1's active-link primary rule.** It sends the 4 dual workers' pay to an empty Baby Talks. Use history-anchored primary (§3.1).

**R3 — Do NOT call `MIN(id)` "earliest."** `worker_companies.id` is random uuid; use it only as a last-resort total order.

**R4 — Do NOT ship the deployed sync as-is.** It drops all consolidated PTO (`index.ts:330`) and drops unmapped seconds (`index.ts:309`). Phase 1 fixes PTO; Phase 2 owns unmapped→primary.

**R5 — Do NOT leave cron on `projMap`.** Freeze to `[companyId]` (mandatory) — 3 Baby mappings already exist; otherwise cron and sync write two rows for one person/day across two companies.

**R6 — Do NOT split the classify MOVE across PostgREST calls.** UPSERT + DELETE must be one `reclassify_worker_day` transaction, or a mid-failure double-counts.

**R7 — Do NOT check locks only on the source company.** Check date-overlap locks/paid/wise_locked on BOTH source and destination; new rows must not enter a locked destination period.

**R8 — Do NOT ship the consolidated payout without the match-override fix.** It's a verified money-corruption bug (inflates one client's `net_php` to the group sum). Mandatory prerequisite, not an optimization.

**R9 — Do NOT add `unique(wise_transfer_id)`.** One transfer maps to N rows by design.

**R10 — Do NOT ship the inline `unique(company_id, pay_period_id)` on invoices.** Only the partial `where status <> 'void'` index — the blanket unique blocks void+regenerate.

**R11 — Do NOT auto-assign silently.** New active links flip RLS scope and a rate-less link silently drops a worker from payroll. Report links_created + needs_rate for confirmation.

**R12 — Open product questions (flag to owner before first REAL invoice/multi-client pay):** (a) billing basis — net pass-through vs gross vs margin (markup hook is the seam); (b) currency — `net_php` is PHP but clients are US LLCs (USD invoicing needs a currency/fx snapshot); (c) ended-only workers still active in Hubstaff — import to history company or report?

**R13 — Conservation drift:** Hubstaff late-edits mean a fresh `activities/daily` fetch can differ from what sync stored. Reconcile against the STORED total, surface `conservation_deltas`, never silently absorb. Manual client moves (hand-edited `worker_companies`) get overwritten by the project map on next classify — document that manual moves must also update `hubstaff_projects`.

**R14 — Splits grain:** the splits PK and the move assume one `time_entries` row per `(company, worker, day)` (verified true today: 0 multi-source_name days). Phase 2 asserts this at runtime and skips/reports if a future row violates it.