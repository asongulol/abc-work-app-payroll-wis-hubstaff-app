-- 2026-05-28 — Reimport for period 2026-04-16 to 2026-04-30 from Excel
-- Source: aaron-anderson-ehs-llc_daily_report_2026-04-16_to_2026-04-30.xlsx
-- 18 contractors. Overwrites tracked_seconds, pto_seconds per day,
-- and payments.net_php with Adjusted Disbursement.
--
-- DOES preserve: wise_transfer_id, wise_dates, wise_locked_at, payments.id,
--                worker_id, payout_method.
-- DOES set: payments.original_net_php = old net_php (if not already set) so the
--           audit trail shows what the DB said before this reimport.
--
-- RUN EACH BLOCK SEPARATELY in DBeaver. They're independent.

-- ============================================================
-- Contractor: Angelika Faith Alo  (db match: Angelika / Alo)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Angelika Faith Alo', date '2026-04-16', 29999, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Angelika Faith Alo', date '2026-04-17', 29932, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Angelika Faith Alo', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Angelika Faith Alo', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Angelika Faith Alo', date '2026-04-20', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Angelika Faith Alo', date '2026-04-21', 30273, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Angelika Faith Alo', date '2026-04-22', 30349, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Angelika Faith Alo', date '2026-04-23', 30596, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Angelika Faith Alo', date '2026-04-24', 29722, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Angelika Faith Alo', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Angelika Faith Alo', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Angelika Faith Alo', date '2026-04-27', 24214, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Angelika Faith Alo', date '2026-04-28', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Angelika Faith Alo', date '2026-04-29', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Angelika Faith Alo', date '2026-04-30', 30173, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (7426.073232323232)
update payments p
set net_php = 7426.07,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika') and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 7426.07) > 0.01;

-- ============================================================
-- Contractor: Barrie Lee Deonaldo  (db match: Barrie / Deonaldo)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Barrie Lee Deonaldo', date '2026-04-16', 30111, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Barrie Lee Deonaldo', date '2026-04-17', 30079, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Barrie Lee Deonaldo', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Barrie Lee Deonaldo', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Barrie Lee Deonaldo', date '2026-04-20', 30142, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Barrie Lee Deonaldo', date '2026-04-21', 30381, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Barrie Lee Deonaldo', date '2026-04-22', 30488, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Barrie Lee Deonaldo', date '2026-04-23', 30078, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Barrie Lee Deonaldo', date '2026-04-24', 29916, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Barrie Lee Deonaldo', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Barrie Lee Deonaldo', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Barrie Lee Deonaldo', date '2026-04-27', 29885, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Barrie Lee Deonaldo', date '2026-04-28', 30125, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Barrie Lee Deonaldo', date '2026-04-29', 30023, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Barrie Lee Deonaldo', date '2026-04-30', 30487, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (30000.0)
update payments p
set net_php = 30000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie') and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 30000.00) > 0.01;

-- ============================================================
-- Contractor: Engelbert Prim  (db match: Engelbert / Prim)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Engelbert Prim', date '2026-04-16', 28663, 28836, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Engelbert Prim', date '2026-04-17', 30401, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Engelbert Prim', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Engelbert Prim', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Engelbert Prim', date '2026-04-20', 29571, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Engelbert Prim', date '2026-04-21', 29512, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Engelbert Prim', date '2026-04-22', 29523, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Engelbert Prim', date '2026-04-23', 28800, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Engelbert Prim', date '2026-04-24', 15372, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Engelbert Prim', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Engelbert Prim', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Engelbert Prim', date '2026-04-27', 30038, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Engelbert Prim', date '2026-04-28', 23271, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Engelbert Prim', date '2026-04-29', 37100, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Engelbert Prim', date '2026-04-30', 29087, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (24568.97095959596)
update payments p
set net_php = 24568.97,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert') and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 24568.97) > 0.01;

-- ============================================================
-- Contractor: Ivy Gino  (db match: Ivy / Gino)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ivy Gino', date '2026-04-16', 15820, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ivy Gino', date '2026-04-17', 16089, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ivy Gino', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ivy Gino', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ivy Gino', date '2026-04-20', 16367, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ivy Gino', date '2026-04-21', 16438, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ivy Gino', date '2026-04-22', 15236, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ivy Gino', date '2026-04-23', 14857, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ivy Gino', date '2026-04-24', 14575, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ivy Gino', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ivy Gino', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ivy Gino', date '2026-04-27', 28869, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ivy Gino', date '2026-04-28', 28947, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ivy Gino', date '2026-04-29', 28864, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ivy Gino', date '2026-04-30', 21994, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (6883.080808080808)
update payments p
set net_php = 6883.08,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy') and lower(w.last_name) = lower('Gino')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 6883.08) > 0.01;

-- ============================================================
-- Contractor: Leslie Mae Ann Calandria  (db match: Leslie / Calandria)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Leslie Mae Ann Calandria', date '2026-04-16', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Leslie Mae Ann Calandria', date '2026-04-17', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Leslie Mae Ann Calandria', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Leslie Mae Ann Calandria', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Leslie Mae Ann Calandria', date '2026-04-20', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Leslie Mae Ann Calandria', date '2026-04-21', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Leslie Mae Ann Calandria', date '2026-04-22', 15418, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Leslie Mae Ann Calandria', date '2026-04-23', 14501, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Leslie Mae Ann Calandria', date '2026-04-24', 14719, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Leslie Mae Ann Calandria', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Leslie Mae Ann Calandria', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Leslie Mae Ann Calandria', date '2026-04-27', 14522, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Leslie Mae Ann Calandria', date '2026-04-28', 14536, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Leslie Mae Ann Calandria', date '2026-04-29', 14500, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Leslie Mae Ann Calandria', date '2026-04-30', 14553, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (4054.174558080808)
update payments p
set net_php = 4054.17,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie') and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 4054.17) > 0.01;

-- ============================================================
-- Contractor: Althea Dianalan  (db match: Althea / Dianalan)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Althea Dianalan', date '2026-04-16', 30267, 28800, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Althea Dianalan', date '2026-04-17', 29394, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Althea Dianalan', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Althea Dianalan', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Althea Dianalan', date '2026-04-20', 29685, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Althea Dianalan', date '2026-04-21', 26798, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Althea Dianalan', date '2026-04-22', 29275, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Althea Dianalan', date '2026-04-23', 30116, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Althea Dianalan', date '2026-04-24', 29879, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Althea Dianalan', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Althea Dianalan', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Althea Dianalan', date '2026-04-27', 29587, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Althea Dianalan', date '2026-04-28', 29288, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Althea Dianalan', date '2026-04-29', 29059, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Althea Dianalan', date '2026-04-30', 29358, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (11935.125)
update payments p
set net_php = 11935.12,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea') and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 11935.12) > 0.01;

-- ============================================================
-- Contractor: Beverly Catalino  (db match: Beverly / Catalino)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Beverly Catalino', date '2026-04-16', 30664, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Beverly Catalino', date '2026-04-17', 29835, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Beverly Catalino', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Beverly Catalino', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Beverly Catalino', date '2026-04-20', 30111, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Beverly Catalino', date '2026-04-21', 31610, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Beverly Catalino', date '2026-04-22', 30268, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Beverly Catalino', date '2026-04-23', 31636, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Beverly Catalino', date '2026-04-24', 31137, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Beverly Catalino', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Beverly Catalino', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Beverly Catalino', date '2026-04-27', 29077, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Beverly Catalino', date '2026-04-28', 29771, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Beverly Catalino', date '2026-04-29', 31313, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Beverly Catalino', date '2026-04-30', 29312, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (25000.0)
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly') and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 25000.00) > 0.01;

-- ============================================================
-- Contractor: Cecilia Velante  (db match: Cecilia / Velante)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Cecilia Velante', date '2026-04-16', 31209, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Cecilia Velante', date '2026-04-17', 29628, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Cecilia Velante', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Cecilia Velante', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Cecilia Velante', date '2026-04-20', 30419, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Cecilia Velante', date '2026-04-21', 31129, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Cecilia Velante', date '2026-04-22', 30358, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Cecilia Velante', date '2026-04-23', 30686, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Cecilia Velante', date '2026-04-24', 29465, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Cecilia Velante', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Cecilia Velante', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Cecilia Velante', date '2026-04-27', 31541, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Cecilia Velante', date '2026-04-28', 30226, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Cecilia Velante', date '2026-04-29', 29288, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Cecilia Velante', date '2026-04-30', 31775, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (33310.0)
update payments p
set net_php = 33310.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia') and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 33310.00) > 0.01;

-- ============================================================
-- Contractor: Ferdinand P. Mabanta Jr.  (db match: Ferdinand / Mabanta)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ferdinand P. Mabanta Jr.', date '2026-04-16', 29268, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ferdinand') and lower(w.last_name) = lower('Mabanta')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ferdinand P. Mabanta Jr.', date '2026-04-17', 30828, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ferdinand') and lower(w.last_name) = lower('Mabanta')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ferdinand P. Mabanta Jr.', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ferdinand') and lower(w.last_name) = lower('Mabanta')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ferdinand P. Mabanta Jr.', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ferdinand') and lower(w.last_name) = lower('Mabanta')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ferdinand P. Mabanta Jr.', date '2026-04-20', 30711, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ferdinand') and lower(w.last_name) = lower('Mabanta')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ferdinand P. Mabanta Jr.', date '2026-04-21', 30469, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ferdinand') and lower(w.last_name) = lower('Mabanta')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ferdinand P. Mabanta Jr.', date '2026-04-22', 22103, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ferdinand') and lower(w.last_name) = lower('Mabanta')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ferdinand P. Mabanta Jr.', date '2026-04-23', 30060, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ferdinand') and lower(w.last_name) = lower('Mabanta')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ferdinand P. Mabanta Jr.', date '2026-04-24', 29990, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ferdinand') and lower(w.last_name) = lower('Mabanta')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ferdinand P. Mabanta Jr.', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ferdinand') and lower(w.last_name) = lower('Mabanta')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ferdinand P. Mabanta Jr.', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ferdinand') and lower(w.last_name) = lower('Mabanta')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ferdinand P. Mabanta Jr.', date '2026-04-27', 29470, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ferdinand') and lower(w.last_name) = lower('Mabanta')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ferdinand P. Mabanta Jr.', date '2026-04-28', 27344, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ferdinand') and lower(w.last_name) = lower('Mabanta')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ferdinand P. Mabanta Jr.', date '2026-04-29', 30277, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ferdinand') and lower(w.last_name) = lower('Mabanta')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ferdinand P. Mabanta Jr.', date '2026-04-30', 30782, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ferdinand') and lower(w.last_name) = lower('Mabanta')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (31250.0)
update payments p
set net_php = 31250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ferdinand') and lower(w.last_name) = lower('Mabanta')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 31250.00) > 0.01;

-- ============================================================
-- Contractor: Francine Therese Pangilinan  (db match: Francine / Pangilinan)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Francine Therese Pangilinan', date '2026-04-16', 30287, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Francine') and lower(w.last_name) = lower('Pangilinan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Francine Therese Pangilinan', date '2026-04-17', 29348, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Francine') and lower(w.last_name) = lower('Pangilinan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Francine Therese Pangilinan', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Francine') and lower(w.last_name) = lower('Pangilinan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Francine Therese Pangilinan', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Francine') and lower(w.last_name) = lower('Pangilinan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Francine Therese Pangilinan', date '2026-04-20', 31999, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Francine') and lower(w.last_name) = lower('Pangilinan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Francine Therese Pangilinan', date '2026-04-21', 29716, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Francine') and lower(w.last_name) = lower('Pangilinan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Francine Therese Pangilinan', date '2026-04-22', 30459, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Francine') and lower(w.last_name) = lower('Pangilinan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Francine Therese Pangilinan', date '2026-04-23', 30247, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Francine') and lower(w.last_name) = lower('Pangilinan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Francine Therese Pangilinan', date '2026-04-24', 29060, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Francine') and lower(w.last_name) = lower('Pangilinan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Francine Therese Pangilinan', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Francine') and lower(w.last_name) = lower('Pangilinan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Francine Therese Pangilinan', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Francine') and lower(w.last_name) = lower('Pangilinan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Francine Therese Pangilinan', date '2026-04-27', 7386, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Francine') and lower(w.last_name) = lower('Pangilinan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Francine Therese Pangilinan', date '2026-04-28', 30200, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Francine') and lower(w.last_name) = lower('Pangilinan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Francine Therese Pangilinan', date '2026-04-29', 29241, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Francine') and lower(w.last_name) = lower('Pangilinan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Francine Therese Pangilinan', date '2026-04-30', 32440, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Francine') and lower(w.last_name) = lower('Pangilinan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (9797.443181818182)
update payments p
set net_php = 9797.44,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Francine') and lower(w.last_name) = lower('Pangilinan')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 9797.44) > 0.01;

-- ============================================================
-- Contractor: Giovanni German  (db match: Giovanni / German)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Giovanni German', date '2026-04-16', 29306, 28800, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Giovanni German', date '2026-04-17', 30569, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Giovanni German', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Giovanni German', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Giovanni German', date '2026-04-20', 29647, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Giovanni German', date '2026-04-21', 29652, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Giovanni German', date '2026-04-22', 29098, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Giovanni German', date '2026-04-23', 29441, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Giovanni German', date '2026-04-24', 31070, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Giovanni German', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Giovanni German', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Giovanni German', date '2026-04-27', 29328, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Giovanni German', date '2026-04-28', 29780, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Giovanni German', date '2026-04-29', 29358, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Giovanni German', date '2026-04-30', 28800, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (18207.0)
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni') and lower(w.last_name) = lower('German')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 18207.00) > 0.01;

-- ============================================================
-- Contractor: Justina Mae Lalosa  (db match: Justina / Lalosa)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Justina Mae Lalosa', date '2026-04-16', 29190, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Justina Mae Lalosa', date '2026-04-17', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Justina Mae Lalosa', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Justina Mae Lalosa', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Justina Mae Lalosa', date '2026-04-20', 29423, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Justina Mae Lalosa', date '2026-04-21', 29203, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Justina Mae Lalosa', date '2026-04-22', 29402, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Justina Mae Lalosa', date '2026-04-23', 29224, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Justina Mae Lalosa', date '2026-04-24', 29341, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Justina Mae Lalosa', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Justina Mae Lalosa', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Justina Mae Lalosa', date '2026-04-27', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Justina Mae Lalosa', date '2026-04-28', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Justina Mae Lalosa', date '2026-04-29', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Justina Mae Lalosa', date '2026-04-30', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (8323.058712121212)
update payments p
set net_php = 8323.06,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina') and lower(w.last_name) = lower('Lalosa')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 8323.06) > 0.01;

-- ============================================================
-- Contractor: Ma. Anna Theresa Rillera  (db match: Maria Anna / Rillera)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Anna Theresa Rillera', date '2026-04-16', 31120, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Maria Anna') and lower(w.last_name) = lower('Rillera')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Anna Theresa Rillera', date '2026-04-17', 31035, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Maria Anna') and lower(w.last_name) = lower('Rillera')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Anna Theresa Rillera', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Maria Anna') and lower(w.last_name) = lower('Rillera')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Anna Theresa Rillera', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Maria Anna') and lower(w.last_name) = lower('Rillera')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Anna Theresa Rillera', date '2026-04-20', 29838, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Maria Anna') and lower(w.last_name) = lower('Rillera')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Anna Theresa Rillera', date '2026-04-21', 34536, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Maria Anna') and lower(w.last_name) = lower('Rillera')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Anna Theresa Rillera', date '2026-04-22', 32895, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Maria Anna') and lower(w.last_name) = lower('Rillera')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Anna Theresa Rillera', date '2026-04-23', 29724, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Maria Anna') and lower(w.last_name) = lower('Rillera')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Anna Theresa Rillera', date '2026-04-24', 30275, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Maria Anna') and lower(w.last_name) = lower('Rillera')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Anna Theresa Rillera', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Maria Anna') and lower(w.last_name) = lower('Rillera')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Anna Theresa Rillera', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Maria Anna') and lower(w.last_name) = lower('Rillera')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Anna Theresa Rillera', date '2026-04-27', 30021, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Maria Anna') and lower(w.last_name) = lower('Rillera')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Anna Theresa Rillera', date '2026-04-28', 30971, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Maria Anna') and lower(w.last_name) = lower('Rillera')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Anna Theresa Rillera', date '2026-04-29', 29176, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Maria Anna') and lower(w.last_name) = lower('Rillera')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Anna Theresa Rillera', date '2026-04-30', 30073, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Maria Anna') and lower(w.last_name) = lower('Rillera')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (38300.0)
update payments p
set net_php = 38300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Maria Anna') and lower(w.last_name) = lower('Rillera')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 38300.00) > 0.01;

-- ============================================================
-- Contractor: Ma. Luisa Marcelo  (db match: Ma. / Marcelo)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Luisa Marcelo', date '2026-04-16', 31724, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Luisa Marcelo', date '2026-04-17', 31356, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Luisa Marcelo', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Luisa Marcelo', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Luisa Marcelo', date '2026-04-20', 30695, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Luisa Marcelo', date '2026-04-21', 30488, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Luisa Marcelo', date '2026-04-22', 33402, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Luisa Marcelo', date '2026-04-23', 31176, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Luisa Marcelo', date '2026-04-24', 30364, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Luisa Marcelo', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Luisa Marcelo', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Luisa Marcelo', date '2026-04-27', 30644, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Luisa Marcelo', date '2026-04-28', 31315, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Luisa Marcelo', date '2026-04-29', 29836, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Ma. Luisa Marcelo', date '2026-04-30', 30580, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (10000.0)
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.') and lower(w.last_name) = lower('Marcelo')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 10000.00) > 0.01;

-- ============================================================
-- Contractor: Melissa Victoria Santos  (db match: Melissa / Santos)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Melissa Victoria Santos', date '2026-04-16', 28964, 7200, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Melissa Victoria Santos', date '2026-04-17', 30465, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Melissa Victoria Santos', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Melissa Victoria Santos', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Melissa Victoria Santos', date '2026-04-20', 28875, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Melissa Victoria Santos', date '2026-04-21', 28889, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Melissa Victoria Santos', date '2026-04-22', 29197, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Melissa Victoria Santos', date '2026-04-23', 28910, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Melissa Victoria Santos', date '2026-04-24', 29232, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Melissa Victoria Santos', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Melissa Victoria Santos', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Melissa Victoria Santos', date '2026-04-27', 29916, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Melissa Victoria Santos', date '2026-04-28', 29269, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Melissa Victoria Santos', date '2026-04-29', 28852, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Melissa Victoria Santos', date '2026-04-30', 29154, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (10609.0)
update payments p
set net_php = 10609.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa') and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 10609.00) > 0.01;

-- ============================================================
-- Contractor: Mery Angelyn Calpa Dunan  (db match: Mery / Dunan)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Mery Angelyn Calpa Dunan', date '2026-04-16', 28234, 14400, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Mery Angelyn Calpa Dunan', date '2026-04-17', 29298, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Mery Angelyn Calpa Dunan', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Mery Angelyn Calpa Dunan', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Mery Angelyn Calpa Dunan', date '2026-04-20', 29444, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Mery Angelyn Calpa Dunan', date '2026-04-21', 28736, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Mery Angelyn Calpa Dunan', date '2026-04-22', 28884, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Mery Angelyn Calpa Dunan', date '2026-04-23', 29782, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Mery Angelyn Calpa Dunan', date '2026-04-24', 27439, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Mery Angelyn Calpa Dunan', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Mery Angelyn Calpa Dunan', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Mery Angelyn Calpa Dunan', date '2026-04-27', 25948, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Mery Angelyn Calpa Dunan', date '2026-04-28', 21687, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Mery Angelyn Calpa Dunan', date '2026-04-29', 27932, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Mery Angelyn Calpa Dunan', date '2026-04-30', 29802, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (30340.435416666667)
update payments p
set net_php = 30340.44,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery') and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 30340.44) > 0.01;

-- ============================================================
-- Contractor: Montero Genel N.  (db match: Genel / Montero)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Montero Genel N.', date '2026-04-16', 29086, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Genel') and lower(w.last_name) = lower('Montero')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Montero Genel N.', date '2026-04-17', 29006, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Genel') and lower(w.last_name) = lower('Montero')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Montero Genel N.', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Genel') and lower(w.last_name) = lower('Montero')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Montero Genel N.', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Genel') and lower(w.last_name) = lower('Montero')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Montero Genel N.', date '2026-04-20', 29305, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Genel') and lower(w.last_name) = lower('Montero')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Montero Genel N.', date '2026-04-21', 28958, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Genel') and lower(w.last_name) = lower('Montero')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Montero Genel N.', date '2026-04-22', 29045, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Genel') and lower(w.last_name) = lower('Montero')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Montero Genel N.', date '2026-04-23', 29345, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Genel') and lower(w.last_name) = lower('Montero')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Montero Genel N.', date '2026-04-24', 29134, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Genel') and lower(w.last_name) = lower('Montero')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Montero Genel N.', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Genel') and lower(w.last_name) = lower('Montero')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Montero Genel N.', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Genel') and lower(w.last_name) = lower('Montero')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Montero Genel N.', date '2026-04-27', 28996, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Genel') and lower(w.last_name) = lower('Montero')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Montero Genel N.', date '2026-04-28', 29196, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Genel') and lower(w.last_name) = lower('Montero')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Montero Genel N.', date '2026-04-29', 29239, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Genel') and lower(w.last_name) = lower('Montero')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Montero Genel N.', date '2026-04-30', 31307, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Genel') and lower(w.last_name) = lower('Montero')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (8000.0)
update payments p
set net_php = 8000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Genel') and lower(w.last_name) = lower('Montero')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 8000.00) > 0.01;

-- ============================================================
-- Contractor: Stephanie Joy Gatchalian  (db match: Stephanie / Gatchalian)
-- ============================================================

-- Time entries (per-day tracked + PTO)
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Stephanie Joy Gatchalian', date '2026-04-16', 29547, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Stephanie Joy Gatchalian', date '2026-04-17', 29366, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Stephanie Joy Gatchalian', date '2026-04-18', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Stephanie Joy Gatchalian', date '2026-04-19', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Stephanie Joy Gatchalian', date '2026-04-20', 29078, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Stephanie Joy Gatchalian', date '2026-04-21', 28975, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Stephanie Joy Gatchalian', date '2026-04-22', 29266, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Stephanie Joy Gatchalian', date '2026-04-23', 29445, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Stephanie Joy Gatchalian', date '2026-04-24', 29254, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Stephanie Joy Gatchalian', date '2026-04-25', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Stephanie Joy Gatchalian', date '2026-04-26', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Stephanie Joy Gatchalian', date '2026-04-27', 29263, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Stephanie Joy Gatchalian', date '2026-04-28', 0, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Stephanie Joy Gatchalian', date '2026-04-29', 29072, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';
insert into time_entries (company_id, worker_id, source_name, work_date, tracked_seconds, pto_seconds, approval)
select c.id, w.id, 'Stephanie Joy Gatchalian', date '2026-04-30', 28992, 0, 'approved'
from workers w, companies c
where c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
on conflict (company_id, source_name, work_date) do update set
  tracked_seconds = excluded.tracked_seconds,
  pto_seconds = excluded.pto_seconds,
  worker_id = excluded.worker_id,
  approval = 'approved';

-- Payments: set net_php to Excel's Adjusted Disbursement (9225.315656565655)
update payments p
set net_php = 9225.32,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie') and lower(w.last_name) = lower('Gatchalian')
  and pp.period_start = date '2026-04-16'
  and pp.period_end = date '2026-04-30'
  and abs(p.net_php - 9225.32) > 0.01;

-- ============================================================
-- VERIFY
-- ============================================================

-- Summary: time entries for this period.
select w.first_name || ' ' || w.last_name as name,
  count(*) as days,
  to_char(interval '1 second' * sum(te.tracked_seconds), 'HH24:MI:SS') as tracked,
  to_char(interval '1 second' * sum(te.pto_seconds), 'HH24:MI:SS') as pto
from time_entries te
join workers w on w.id = te.worker_id
where te.company_id = (select id from companies where name = 'Ability Builders')
  and te.work_date >= '2026-04-16' and te.work_date <= '2026-04-30'
group by w.id, w.first_name, w.last_name order by w.last_name;

-- Payments comparison: original vs adjusted.
select w.first_name || ' ' || w.last_name as name,
       p.original_net_php as was, p.net_php as now, (p.net_php - p.original_net_php) as delta
from payments p
join workers w on w.id = p.worker_id
join pay_periods pp on pp.id = p.pay_period_id
where p.company_id = (select id from companies where name = 'Ability Builders')
  and pp.period_start = date '2026-04-16' and pp.period_end = date '2026-04-30'
order by w.last_name;