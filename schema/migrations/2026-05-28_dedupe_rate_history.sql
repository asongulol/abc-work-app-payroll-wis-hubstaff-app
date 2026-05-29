-- 2026-05-28 — collapse redundant per-period rate rows into rate-CHANGE rows
--
-- Background:
--   The earlier historical backfill (payroll_history/backfill_payroll_history.sql)
--   inserted ONE rate row per (worker, company, period) — about 716 rows total.
--   Most contractors ended up with 30+ rate rows where 1-4 would suffice, because
--   consecutive periods at the same rate became duplicate rate rows. The Stream A
--   Rate-history UI shows all of them, which is correct-but-noisy.
--
-- Fix:
--   Walk each (worker, company) timeline chronologically and DELETE any rate row
--   whose amount equals the PREVIOUS row's amount. Keep only the rate-change
--   boundaries (the first appearance of each distinct amount in chronological
--   order). Then recompute effective_end so survivors form a contiguous timeline.
--
-- Safety:
--   - Read-then-delete inside a transaction.
--   - Only deletes rows whose amount equals the immediate predecessor — never
--     deletes a row that introduces a new amount.
--   - Idempotent: re-running has no effect once duplicates are gone.
--   - Does NOT touch payments. Rate snapshots stored on payments.rate_php are
--     unaffected (they're snapshots, not foreign keys).
--
-- This script does NOT change behavior of any existing calculation. It just
-- removes redundant rows so the rate-history UI is clean.

begin;

-- 1. Diagnostic: count rows before
select 'BEFORE' as phase, count(*) as rate_rows from rates
where company_id = (select id from companies where name = 'Ability Builders');

-- 2. Identify redundant rows.
--    For each rate row, look at the IMMEDIATELY-PREVIOUS row (same worker+company,
--    most recent effective_start that is strictly earlier). If their amounts match,
--    the current row is redundant.
with chrono as (
  select id, worker_id, company_id, amount_php, effective_start,
    lag(amount_php) over (
      partition by worker_id, company_id
      order by effective_start, created_at, id
    ) as prev_amount
  from rates
  where company_id = (select id from companies where name = 'Ability Builders')
),
redundant as (
  select id from chrono
  where prev_amount is not null
    and prev_amount = amount_php
)
delete from rates
where id in (select id from redundant);

-- 3. Recompute effective_end on every surviving row so the timeline is contiguous.
with ordered as (
  select id, worker_id, company_id, effective_start,
    lead(effective_start) over (partition by worker_id, company_id order by effective_start) as next_start
  from rates
  where company_id = (select id from companies where name = 'Ability Builders')
)
update rates r
set effective_end = o.next_start
from ordered o
where r.id = o.id
  and (r.effective_end is distinct from o.next_start);

-- 4. Diagnostic: count rows AFTER + per-contractor breakdown
select 'AFTER' as phase, count(*) as rate_rows from rates
where company_id = (select id from companies where name = 'Ability Builders');

select w.first_name || ' ' || w.last_name as name,
       count(*) as rate_rows_after_dedupe
from rates r
join workers w on w.id = r.worker_id
where r.company_id = (select id from companies where name = 'Ability Builders')
group by w.id, w.first_name, w.last_name
order by w.last_name, w.first_name;

commit;
