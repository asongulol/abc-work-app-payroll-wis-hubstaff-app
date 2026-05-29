-- 2026-05-28 v2 — collapse redundant per-period rate rows (rewrite)
--
-- v1 used `with chrono as (...), redundant as (...) delete from rates where
-- id in (select id from redundant)` which on Supabase's SQL Editor appears to
-- have run as a SELECT only (no rows actually deleted). Rewrite to use a
-- single DELETE with a correlated subquery — simpler, no CTE-as-DELETE-source.
--
-- Run each numbered block separately if Supabase's editor refuses to run a
-- multi-statement file. They're independent and idempotent.

-- ============================================================
-- BLOCK 1: How many rows are about to be deleted? (dry-run preview)
-- ============================================================
select count(*) as rows_to_delete
from rates r1
where exists (
  select 1 from rates r2
  where r2.worker_id = r1.worker_id
    and r2.company_id = r1.company_id
    and r2.amount_php = r1.amount_php
    and r2.effective_start < r1.effective_start
    and not exists (
      -- ensure r2 is the IMMEDIATE predecessor (no row between r2 and r1
      -- for the same worker+company)
      select 1 from rates r3
      where r3.worker_id = r1.worker_id
        and r3.company_id = r1.company_id
        and r3.effective_start > r2.effective_start
        and r3.effective_start < r1.effective_start
    )
);

-- ============================================================
-- BLOCK 2: Actually delete (run this AFTER seeing the count above)
-- ============================================================
delete from rates r1
where exists (
  select 1 from rates r2
  where r2.worker_id = r1.worker_id
    and r2.company_id = r1.company_id
    and r2.amount_php = r1.amount_php
    and r2.effective_start < r1.effective_start
    and not exists (
      select 1 from rates r3
      where r3.worker_id = r1.worker_id
        and r3.company_id = r1.company_id
        and r3.effective_start > r2.effective_start
        and r3.effective_start < r1.effective_start
    )
);

-- ============================================================
-- BLOCK 3: After deletion, some rows that USED to be redundant may now have
-- a different "immediate predecessor" — re-run BLOCK 1+2 until rows_to_delete = 0.
-- (Chains of 3+ identical rows collapse one at a time.)
-- ============================================================

-- ============================================================
-- BLOCK 4: Once BLOCK 1 shows 0, recompute effective_end on the survivors
-- so the timeline is contiguous.
-- ============================================================
with ordered as (
  select id, worker_id, company_id, effective_start,
    lead(effective_start) over (partition by worker_id, company_id order by effective_start) as next_start
  from rates
)
update rates r
set effective_end = o.next_start
from ordered o
where r.id = o.id
  and (r.effective_end is distinct from o.next_start);

-- ============================================================
-- BLOCK 5: Verify — should show 1-4 rows per contractor for most workers.
-- ============================================================
select w.first_name || ' ' || w.last_name as name,
       count(*) as rate_rows
from rates r
join workers w on w.id = r.worker_id
where r.company_id = (select id from companies where name = 'Ability Builders')
group by w.id, w.first_name, w.last_name
order by w.last_name, w.first_name;
