-- 2026-05-28 — Stream D: backfill rate history from /payroll_history Excel files
-- 35 rate-change events across 24 contractors.
-- Excluded 1 contractor(s) with hourly/irregular rate patterns:
--   Ramon Vizmonte (distinct=15, range=[12.50, 7483.12])
--
-- Effective dates rule (per Oliver 2026-05-28): when a rate change is detected,
-- the new rate's effective_start is the first day of the period IMMEDIATELY
-- BEFORE the period where the new rate first appears in the data. For the FIRST
-- ever observed rate, effective_start is the first day of that period itself.
--
-- Idempotent: ON CONFLICT (worker_id, company_id, effective_start) DO UPDATE.
-- Requires the unique constraint from 2026-05-28_rates_unique.sql.

begin;

insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 15000.00, 'semi_monthly', date '2024-02-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 11250.00, 'semi_monthly', date '2024-04-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 11587.50, 'semi_monthly', date '2025-02-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 11935.12, 'semi_monthly', date '2026-03-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 12500.00, 'semi_monthly', date '2024-12-16'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Angelica') and lower(w.last_name) = lower('Conejos')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 10000.00, 'semi_monthly', date '2024-12-16'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 25000.00, 'semi_monthly', date '2024-04-16'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 11000.00, 'semi_monthly', date '2024-12-16'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 22500.00, 'semi_monthly', date '2024-02-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 25000.00, 'semi_monthly', date '2025-01-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 18207.00, 'semi_monthly', date '2024-02-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 10000.00, 'semi_monthly', date '2024-04-16'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Jam') and lower(w.last_name) = lower('Cruz')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 34700.00, 'semi_monthly', date '2024-02-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Janice') and lower(w.last_name) = lower('Quiros')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 10000.00, 'semi_monthly', date '2024-02-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('John') and lower(w.last_name) = lower('Mistica')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 10600.00, 'semi_monthly', date '2025-05-16'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('John') and lower(w.last_name) = lower('Mistica')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 19000.00, 'semi_monthly', date '2026-01-16'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('John') and lower(w.last_name) = lower('Mistica')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 15000.00, 'semi_monthly', date '2024-02-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Karlos') and lower(w.last_name) = lower('Sagun')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 12500.00, 'semi_monthly', date '2024-02-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 6250.00, 'semi_monthly', date '2024-12-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 10000.00, 'semi_monthly', date '2024-02-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Loren') and lower(w.last_name) = lower('Zagado')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 9000.00, 'semi_monthly', date '2024-12-16'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Manuella') and lower(w.last_name) = lower('Gamboa')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 10000.00, 'semi_monthly', date '2025-05-16'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Manuella') and lower(w.last_name) = lower('Gamboa')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 10000.00, 'semi_monthly', date '2024-02-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 10300.00, 'semi_monthly', date '2025-02-16'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 10609.00, 'semi_monthly', date '2026-03-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 31290.00, 'semi_monthly', date '2024-02-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 25000.00, 'semi_monthly', date '2024-02-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Valerie') and lower(w.last_name) = lower('Bantilan')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 10000.00, 'semi_monthly', date '2025-07-16'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 10000.00, 'semi_monthly', date '2026-01-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 15000.00, 'semi_monthly', date '2026-02-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 10000.00, 'semi_monthly', date '2026-02-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 5000.00, 'semi_monthly', date '2026-02-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 10000.00, 'semi_monthly', date '2026-02-16'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 17500.00, 'semi_monthly', date '2024-02-01'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Kristine') and lower(w.last_name) = lower('Mascardo')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;
insert into rates (worker_id, company_id, amount_php, period_basis, effective_start)
select w.id, c.id, 9000.00, 'semi_monthly', date '2024-12-16'
from workers w
join companies c on c.name = 'Ability Builders'
where lower(w.first_name) = lower('Nicole') and lower(w.last_name) = lower('Magada')
on conflict (worker_id, company_id, effective_start) do update set amount_php = excluded.amount_php;

-- Recompute effective_end for every rate row so the timeline is contiguous.
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

-- Verify: rate timeline per contractor.
select w.first_name || ' ' || w.last_name as name,
       r.effective_start, r.effective_end, r.amount_php
from rates r
join workers w on w.id = r.worker_id
where r.company_id = (select id from companies where name = 'Ability Builders')
order by w.last_name, w.first_name, r.effective_start;

commit;