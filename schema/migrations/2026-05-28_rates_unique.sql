-- 2026-05-28 — prevent duplicate rates for the same (worker, company, day)
--
-- Background:
--   The saveRate() code in the front-end tries hard to avoid creating
--   duplicate rate rows for the same effective_start, but without a DB
--   constraint, races and bugs can still produce duplicates (we found
--   four for Hazzan earlier today). With duplicates present the load
--   query's tiebreaker matters and gets it wrong.
--
-- Fix:
--   Add UNIQUE (worker_id, company_id, effective_start) so any future
--   attempt to insert a duplicate fails loudly at the DB level. The
--   front-end's same-day-update path already converts a duplicate-write
--   attempt into an UPDATE, so this constraint should not cause
--   user-visible errors under normal use.
--
-- Safety:
--   Will fail if duplicates currently exist. Run the diagnostic query
--   first to find any; clean them up; then re-run the ALTER.

-- 1. Diagnostic: any duplicates?
select worker_id, company_id, effective_start, count(*) as dup_count
from rates
group by worker_id, company_id, effective_start
having count(*) > 1;

-- 2. If the diagnostic returns rows, fix them first (manually or with a
--    DELETE that keeps the newest row per group). Don't auto-delete here —
--    the user should review what's being deleted.

-- 3. Add the constraint.
alter table rates
  add constraint rates_uniq_worker_company_effstart
  unique (worker_id, company_id, effective_start);

-- 4. Verify
select conname, contype
from pg_constraint
where conrelid = 'public.rates'::regclass
  and conname = 'rates_uniq_worker_company_effstart';
