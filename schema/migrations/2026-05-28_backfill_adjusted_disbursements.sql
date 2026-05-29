-- 2026-05-28 — Stream C: Override payments.net_php with the ADJUSTED disbursement
--                       from /payroll_history Excel files.
--
-- Background:
--   The DB's payments.net_php was computed by the app's payroll calc; the Excel
--   files contain the ADJUSTED disbursement (what was actually paid). When the two
--   diverge, the Excel value is authoritative. This script overrides net_php to the
--   Excel value and preserves the previous DB value in original_net_php.
--
--   560 payment rows targeted across all paid historical periods.
--   Excludes Ramon Vizmonte (hourly contractor — per-period totals don't fit the model).
--
-- Safety:
--   - Only touches payments.net_php and payments.original_net_php.
--   - Does NOT touch tracked hours, wise IDs, or any other column.
--   - Idempotent: re-running asserts the same target value.
--   - Uses a CTE to look up worker_id by (first_name, last_name).
--
-- This script will trigger wise_lock_warning entries in audit_log for any locked
-- payment rows we touch. That is intentional and serves as the audit trail of which
-- previously-paid amounts were corrected.

begin;

update payments p
set net_php = 11503.85,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 11503.85) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Jam')
  and lower(w.last_name) = lower('Cruz')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 9000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 9000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-02-16'
  and pp.period_end = date '2025-02-28'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11587.50,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 11587.50) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 24649.48,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 24649.48) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Jam')
  and lower(w.last_name) = lower('Cruz')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 9000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 9000.00) > 0.01;
update payments p
set net_php = 10300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 10300.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-03-01'
  and pp.period_end = date '2025-03-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 7532.46,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 7532.46) > 0.01;
update payments p
set net_php = 12474.23,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 12474.23) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 24667.93,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 24667.93) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 9090.91,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Jam')
  and lower(w.last_name) = lower('Cruz')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 9090.91) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 9090.91,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 9090.91) > 0.01;
update payments p
set net_php = 9000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 9000.00) > 0.01;
update payments p
set net_php = 10222.75,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 10222.75) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-03-16'
  and pp.period_end = date '2025-03-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11587.50,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 11587.50) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 24365.45,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 24365.45) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 23836.88,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 23836.88) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Jam')
  and lower(w.last_name) = lower('Cruz')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 9000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 9000.00) > 0.01;
update payments p
set net_php = 10300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 10300.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-04-01'
  and pp.period_end = date '2025-04-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 8613.25,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-04-16'
  and pp.period_end = date '2025-04-30'
  and abs(p.net_php - 8613.25) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-04-16'
  and pp.period_end = date '2025-04-30'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-04-16'
  and pp.period_end = date '2025-04-30'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-04-16'
  and pp.period_end = date '2025-04-30'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-04-16'
  and pp.period_end = date '2025-04-30'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 22500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-04-16'
  and pp.period_end = date '2025-04-30'
  and abs(p.net_php - 22500.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-04-16'
  and pp.period_end = date '2025-04-30'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-04-16'
  and pp.period_end = date '2025-04-30'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-04-16'
  and pp.period_end = date '2025-04-30'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 13500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-04-16'
  and pp.period_end = date '2025-04-30'
  and abs(p.net_php - 13500.00) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-04-16'
  and pp.period_end = date '2025-04-30'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-04-16'
  and pp.period_end = date '2025-04-30'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 9000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-04-16'
  and pp.period_end = date '2025-04-30'
  and abs(p.net_php - 9000.00) > 0.01;
update payments p
set net_php = 10300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-04-16'
  and pp.period_end = date '2025-04-30'
  and abs(p.net_php - 10300.00) > 0.01;
update payments p
set net_php = 28373.08,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-04-16'
  and pp.period_end = date '2025-04-30'
  and abs(p.net_php - 28373.08) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-04-16'
  and pp.period_end = date '2025-04-30'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 3160.23,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-05-01'
  and pp.period_end = date '2025-05-15'
  and abs(p.net_php - 3160.23) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-05-01'
  and pp.period_end = date '2025-05-15'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 9090.91,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-05-01'
  and pp.period_end = date '2025-05-15'
  and abs(p.net_php - 9090.91) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-05-01'
  and pp.period_end = date '2025-05-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-05-01'
  and pp.period_end = date '2025-05-15'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-05-01'
  and pp.period_end = date '2025-05-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-05-01'
  and pp.period_end = date '2025-05-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-05-01'
  and pp.period_end = date '2025-05-15'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-05-01'
  and pp.period_end = date '2025-05-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-05-01'
  and pp.period_end = date '2025-05-15'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-05-01'
  and pp.period_end = date '2025-05-15'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-05-01'
  and pp.period_end = date '2025-05-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 9000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-05-01'
  and pp.period_end = date '2025-05-15'
  and abs(p.net_php - 9000.00) > 0.01;
update payments p
set net_php = 10300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-05-01'
  and pp.period_end = date '2025-05-15'
  and abs(p.net_php - 10300.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-05-01'
  and pp.period_end = date '2025-05-15'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 20454.55,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-05-01'
  and pp.period_end = date '2025-05-15'
  and abs(p.net_php - 20454.55) > 0.01;
update payments p
set net_php = 8917.95,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-05-16'
  and pp.period_end = date '2025-05-31'
  and abs(p.net_php - 8917.95) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-05-16'
  and pp.period_end = date '2025-05-31'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-05-16'
  and pp.period_end = date '2025-05-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-05-16'
  and pp.period_end = date '2025-05-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-05-16'
  and pp.period_end = date '2025-05-31'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-05-16'
  and pp.period_end = date '2025-05-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-05-16'
  and pp.period_end = date '2025-05-31'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-05-16'
  and pp.period_end = date '2025-05-31'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-05-16'
  and pp.period_end = date '2025-05-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-05-16'
  and pp.period_end = date '2025-05-31'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-05-16'
  and pp.period_end = date '2025-05-31'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-05-16'
  and pp.period_end = date '2025-05-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 9000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-05-16'
  and pp.period_end = date '2025-05-31'
  and abs(p.net_php - 9000.00) > 0.01;
update payments p
set net_php = 10205.91,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-05-16'
  and pp.period_end = date '2025-05-31'
  and abs(p.net_php - 10205.91) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-05-16'
  and pp.period_end = date '2025-05-31'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-05-16'
  and pp.period_end = date '2025-05-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 9832.92,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-06-01'
  and pp.period_end = date '2025-06-15'
  and abs(p.net_php - 9832.92) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-06-01'
  and pp.period_end = date '2025-06-15'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-06-01'
  and pp.period_end = date '2025-06-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-06-01'
  and pp.period_end = date '2025-06-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-06-01'
  and pp.period_end = date '2025-06-15'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-06-01'
  and pp.period_end = date '2025-06-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-06-01'
  and pp.period_end = date '2025-06-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-06-01'
  and pp.period_end = date '2025-06-15'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10600.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-06-01'
  and pp.period_end = date '2025-06-15'
  and abs(p.net_php - 10600.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-06-01'
  and pp.period_end = date '2025-06-15'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-06-01'
  and pp.period_end = date '2025-06-15'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-06-01'
  and pp.period_end = date '2025-06-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-06-01'
  and pp.period_end = date '2025-06-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10180.55,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-06-01'
  and pp.period_end = date '2025-06-15'
  and abs(p.net_php - 10180.55) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-06-01'
  and pp.period_end = date '2025-06-15'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-06-01'
  and pp.period_end = date '2025-06-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 10428.75,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-06-16'
  and pp.period_end = date '2025-06-30'
  and abs(p.net_php - 10428.75) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-06-16'
  and pp.period_end = date '2025-06-30'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-06-16'
  and pp.period_end = date '2025-06-30'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-06-16'
  and pp.period_end = date '2025-06-30'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-06-16'
  and pp.period_end = date '2025-06-30'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-06-16'
  and pp.period_end = date '2025-06-30'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-06-16'
  and pp.period_end = date '2025-06-30'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-06-16'
  and pp.period_end = date '2025-06-30'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10600.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-06-16'
  and pp.period_end = date '2025-06-30'
  and abs(p.net_php - 10600.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-06-16'
  and pp.period_end = date '2025-06-30'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-06-16'
  and pp.period_end = date '2025-06-30'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-06-16'
  and pp.period_end = date '2025-06-30'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-06-16'
  and pp.period_end = date '2025-06-30'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 9270.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-06-16'
  and pp.period_end = date '2025-06-30'
  and abs(p.net_php - 9270.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-06-16'
  and pp.period_end = date '2025-06-30'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-06-16'
  and pp.period_end = date '2025-06-30'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 10621.88,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 10621.88) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 7916.67,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 7916.67) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 24925.56,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 24925.56) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10600.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 10600.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 6198.89,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 6198.89) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 10300.00) > 0.01;
update payments p
set net_php = 30819.29,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 30819.29) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-07-16'
  and pp.period_end = date '2025-07-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 10534.09,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 10534.09) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10600.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 10600.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 6184.42,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 6184.42) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 9650.44,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 9650.44) > 0.01;
update payments p
set net_php = 10300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 10300.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-08-01'
  and pp.period_end = date '2025-08-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11587.50,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 11587.50) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 9000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 9000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10600.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 10600.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 9000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 9000.00) > 0.01;
update payments p
set net_php = 10300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 10300.00) > 0.01;
update payments p
set net_php = 30731.56,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 30731.56) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-09-01'
  and pp.period_end = date '2025-09-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 8181.82,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2025-09-16'
  and pp.period_end = date '2025-09-30'
  and abs(p.net_php - 8181.82) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-09-16'
  and pp.period_end = date '2025-09-30'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-09-16'
  and pp.period_end = date '2025-09-30'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-09-16'
  and pp.period_end = date '2025-09-30'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-09-16'
  and pp.period_end = date '2025-09-30'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 5113.64,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-09-16'
  and pp.period_end = date '2025-09-30'
  and abs(p.net_php - 5113.64) > 0.01;
update payments p
set net_php = 11363.64,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-09-16'
  and pp.period_end = date '2025-09-30'
  and abs(p.net_php - 11363.64) > 0.01;
update payments p
set net_php = 12426.53,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-09-16'
  and pp.period_end = date '2025-09-30'
  and abs(p.net_php - 12426.53) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-09-16'
  and pp.period_end = date '2025-09-30'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-09-16'
  and pp.period_end = date '2025-09-30'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-09-16'
  and pp.period_end = date '2025-09-30'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 10600.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-09-16'
  and pp.period_end = date '2025-09-30'
  and abs(p.net_php - 10600.00) > 0.01;
update payments p
set net_php = 9090.91,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-09-16'
  and pp.period_end = date '2025-09-30'
  and abs(p.net_php - 9090.91) > 0.01;
update payments p
set net_php = 1818.18,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-09-16'
  and pp.period_end = date '2025-09-30'
  and abs(p.net_php - 1818.18) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-09-16'
  and pp.period_end = date '2025-09-30'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 550.94,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 550.94) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10600.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 10600.00) > 0.01;
update payments p
set net_php = 14849.64,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 14849.64) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 600.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 600.00) > 0.01;
update payments p
set net_php = 31117.58,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 31117.58) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-10-01'
  and pp.period_end = date '2025-10-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11240.11,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 11240.11) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10600.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 10600.00) > 0.01;
update payments p
set net_php = 13750.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 13750.00) > 0.01;
update payments p
set net_php = 5647.71,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 5647.71) > 0.01;
update payments p
set net_php = 9166.67,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 9166.67) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 10300.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 22916.67,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-10-16'
  and pp.period_end = date '2025-10-31'
  and abs(p.net_php - 22916.67) > 0.01;
update payments p
set net_php = 8236.82,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 8236.82) > 0.01;
update payments p
set net_php = 8000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 8000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 33871.78,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 33871.78) > 0.01;
update payments p
set net_php = 13500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 13500.00) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 10600.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 10600.00) > 0.01;
update payments p
set net_php = 9000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 9000.00) > 0.01;
update payments p
set net_php = 8000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 8000.00) > 0.01;
update payments p
set net_php = 10300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 10300.00) > 0.01;
update payments p
set net_php = 30454.95,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-11-01'
  and pp.period_end = date '2025-11-15'
  and abs(p.net_php - 30454.95) > 0.01;
update payments p
set net_php = 11183.80,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 11183.80) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10600.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 10600.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 10300.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 24755.73,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-11-16'
  and pp.period_end = date '2025-11-30'
  and abs(p.net_php - 24755.73) > 0.01;
update payments p
set net_php = 11587.50,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 11587.50) > 0.01;
update payments p
set net_php = 12031.09,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 12031.09) > 0.01;
update payments p
set net_php = 9090.91,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 9090.91) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10600.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 10600.00) > 0.01;
update payments p
set net_php = 14506.96,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 14506.96) > 0.01;
update payments p
set net_php = 5681.82,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 5681.82) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 10300.00) > 0.01;
update payments p
set net_php = 30891.66,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 30891.66) > 0.01;
update payments p
set net_php = 22727.27,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-12-01'
  and pp.period_end = date '2025-12-15'
  and abs(p.net_php - 22727.27) > 0.01;
update payments p
set net_php = 9109.28,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 9109.28) > 0.01;
update payments p
set net_php = 10377.56,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 10377.56) > 0.01;
update payments p
set net_php = 9090.91,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 9090.91) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10600.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 10600.00) > 0.01;
update payments p
set net_php = 14883.29,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 14883.29) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 9090.91,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 9090.91) > 0.01;
update payments p
set net_php = 10300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 10300.00) > 0.01;
update payments p
set net_php = 25122.57,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 25122.57) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-12-16'
  and pp.period_end = date '2025-12-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11587.50,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 11587.50) > 0.01;
update payments p
set net_php = 10408.29,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 10408.29) > 0.01;
update payments p
set net_php = 9000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 9000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 23136.28,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 23136.28) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10600.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 10600.00) > 0.01;
update payments p
set net_php = 13500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 13500.00) > 0.01;
update payments p
set net_php = 4404.64,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 4404.64) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 9000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.')
  and lower(w.last_name) = lower('Marcelo')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 9000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 10300.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2026-01-01'
  and pp.period_end = date '2026-01-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11630.11,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2026-01-16'
  and pp.period_end = date '2026-01-31'
  and abs(p.net_php - 11630.11) > 0.01;
update payments p
set net_php = 9615.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2026-01-16'
  and pp.period_end = date '2026-01-31'
  and abs(p.net_php - 9615.00) > 0.01;
update payments p
set net_php = 9931.70,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2026-01-16'
  and pp.period_end = date '2026-01-31'
  and abs(p.net_php - 9931.70) > 0.01;
update payments p
set net_php = 25700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2026-01-16'
  and pp.period_end = date '2026-01-31'
  and abs(p.net_php - 25700.00) > 0.01;
update payments p
set net_php = 11695.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2026-01-16'
  and pp.period_end = date '2026-01-31'
  and abs(p.net_php - 11695.00) > 0.01;
update payments p
set net_php = 25700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2026-01-16'
  and pp.period_end = date '2026-01-31'
  and abs(p.net_php - 25700.00) > 0.01;
update payments p
set net_php = 18907.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2026-01-16'
  and pp.period_end = date '2026-01-31'
  and abs(p.net_php - 18907.00) > 0.01;
update payments p
set net_php = 10600.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2026-01-16'
  and pp.period_end = date '2026-01-31'
  and abs(p.net_php - 10600.00) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2026-01-16'
  and pp.period_end = date '2026-01-31'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 9000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2026-01-16'
  and pp.period_end = date '2026-01-31'
  and abs(p.net_php - 9000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.')
  and lower(w.last_name) = lower('Marcelo')
  and pp.period_start = date '2026-01-16'
  and pp.period_end = date '2026-01-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10516.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2026-01-16'
  and pp.period_end = date '2026-01-31'
  and abs(p.net_php - 10516.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2026-01-16'
  and pp.period_end = date '2026-01-31'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 30347.50,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2026-01-16'
  and pp.period_end = date '2026-01-31'
  and abs(p.net_php - 30347.50) > 0.01;
update payments p
set net_php = 2380.10,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2026-02-01'
  and pp.period_end = date '2026-02-15'
  and abs(p.net_php - 2380.10) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2026-02-01'
  and pp.period_end = date '2026-02-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2026-02-01'
  and pp.period_end = date '2026-02-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2026-02-01'
  and pp.period_end = date '2026-02-15'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 11477.06,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2026-02-01'
  and pp.period_end = date '2026-02-15'
  and abs(p.net_php - 11477.06) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2026-02-01'
  and pp.period_end = date '2026-02-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2026-02-01'
  and pp.period_end = date '2026-02-15'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2026-02-01'
  and pp.period_end = date '2026-02-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 19000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2026-02-01'
  and pp.period_end = date '2026-02-15'
  and abs(p.net_php - 19000.00) > 0.01;
update payments p
set net_php = 11723.23,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina')
  and lower(w.last_name) = lower('Lalosa')
  and pp.period_start = date '2026-02-01'
  and pp.period_end = date '2026-02-15'
  and abs(p.net_php - 11723.23) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2026-02-01'
  and pp.period_end = date '2026-02-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.')
  and lower(w.last_name) = lower('Marcelo')
  and pp.period_start = date '2026-02-01'
  and pp.period_end = date '2026-02-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2026-02-01'
  and pp.period_end = date '2026-02-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2026-02-01'
  and pp.period_end = date '2026-02-15'
  and abs(p.net_php - 10300.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2026-02-01'
  and pp.period_end = date '2026-02-15'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 5344.24,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy')
  and lower(w.last_name) = lower('Gino')
  and pp.period_start = date '2026-02-01'
  and pp.period_end = date '2026-02-15'
  and abs(p.net_php - 5344.24) > 0.01;
update payments p
set net_php = 9728.47,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2026-02-16'
  and pp.period_end = date '2026-02-28'
  and abs(p.net_php - 9728.47) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2026-02-16'
  and pp.period_end = date '2026-02-28'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2026-02-16'
  and pp.period_end = date '2026-02-28'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2026-02-16'
  and pp.period_end = date '2026-02-28'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2026-02-16'
  and pp.period_end = date '2026-02-28'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2026-02-16'
  and pp.period_end = date '2026-02-28'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2026-02-16'
  and pp.period_end = date '2026-02-28'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 4242.26,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy')
  and lower(w.last_name) = lower('Gino')
  and pp.period_start = date '2026-02-16'
  and pp.period_end = date '2026-02-28'
  and abs(p.net_php - 4242.26) > 0.01;
update payments p
set net_php = 19000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2026-02-16'
  and pp.period_end = date '2026-02-28'
  and abs(p.net_php - 19000.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina')
  and lower(w.last_name) = lower('Lalosa')
  and pp.period_start = date '2026-02-16'
  and pp.period_end = date '2026-02-28'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 4426.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2026-02-16'
  and pp.period_end = date '2026-02-28'
  and abs(p.net_php - 4426.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2026-02-16'
  and pp.period_end = date '2026-02-28'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.')
  and lower(w.last_name) = lower('Marcelo')
  and pp.period_start = date '2026-02-16'
  and pp.period_end = date '2026-02-28'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2026-02-16'
  and pp.period_end = date '2026-02-28'
  and abs(p.net_php - 10300.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2026-02-16'
  and pp.period_end = date '2026-02-28'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie')
  and lower(w.last_name) = lower('Gatchalian')
  and pp.period_start = date '2026-02-16'
  and pp.period_end = date '2026-02-28'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 11458.51,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2026-03-01'
  and pp.period_end = date '2026-03-15'
  and abs(p.net_php - 11458.51) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2026-03-01'
  and pp.period_end = date '2026-03-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2026-03-01'
  and pp.period_end = date '2026-03-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2026-03-01'
  and pp.period_end = date '2026-03-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2026-03-01'
  and pp.period_end = date '2026-03-15'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2026-03-01'
  and pp.period_end = date '2026-03-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2026-03-01'
  and pp.period_end = date '2026-03-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 4844.79,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy')
  and lower(w.last_name) = lower('Gino')
  and pp.period_start = date '2026-03-01'
  and pp.period_end = date '2026-03-15'
  and abs(p.net_php - 4844.79) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina')
  and lower(w.last_name) = lower('Lalosa')
  and pp.period_start = date '2026-03-01'
  and pp.period_end = date '2026-03-15'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 5688.98,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2026-03-01'
  and pp.period_end = date '2026-03-15'
  and abs(p.net_php - 5688.98) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2026-03-01'
  and pp.period_end = date '2026-03-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.')
  and lower(w.last_name) = lower('Marcelo')
  and pp.period_start = date '2026-03-01'
  and pp.period_end = date '2026-03-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10300.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2026-03-01'
  and pp.period_end = date '2026-03-15'
  and abs(p.net_php - 10300.00) > 0.01;
update payments p
set net_php = 31229.70,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2026-03-01'
  and pp.period_end = date '2026-03-15'
  and abs(p.net_php - 31229.70) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie')
  and lower(w.last_name) = lower('Gatchalian')
  and pp.period_start = date '2026-03-01'
  and pp.period_end = date '2026-03-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 11388.10,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2026-03-16'
  and pp.period_end = date '2026-03-31'
  and abs(p.net_php - 11388.10) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2026-03-16'
  and pp.period_end = date '2026-03-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2026-03-16'
  and pp.period_end = date '2026-03-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2026-03-16'
  and pp.period_end = date '2026-03-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2026-03-16'
  and pp.period_end = date '2026-03-31'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2026-03-16'
  and pp.period_end = date '2026-03-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 38207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2026-03-16'
  and pp.period_end = date '2026-03-31'
  and abs(p.net_php - 38207.00) > 0.01;
update payments p
set net_php = 4644.16,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy')
  and lower(w.last_name) = lower('Gino')
  and pp.period_start = date '2026-03-16'
  and pp.period_end = date '2026-03-31'
  and abs(p.net_php - 4644.16) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina')
  and lower(w.last_name) = lower('Lalosa')
  and pp.period_start = date '2026-03-16'
  and pp.period_end = date '2026-03-31'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 11250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2026-03-16'
  and pp.period_end = date '2026-03-31'
  and abs(p.net_php - 11250.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2026-03-16'
  and pp.period_end = date '2026-03-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.')
  and lower(w.last_name) = lower('Marcelo')
  and pp.period_start = date '2026-03-16'
  and pp.period_end = date '2026-03-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10609.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2026-03-16'
  and pp.period_end = date '2026-03-31'
  and abs(p.net_php - 10609.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2026-03-16'
  and pp.period_end = date '2026-03-31'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 8201.39,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie')
  and lower(w.last_name) = lower('Gatchalian')
  and pp.period_start = date '2026-03-16'
  and pp.period_end = date '2026-03-31'
  and abs(p.net_php - 8201.39) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelika')
  and lower(w.last_name) = lower('Alo')
  and pp.period_start = date '2026-04-01'
  and pp.period_end = date '2026-04-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2026-04-01'
  and pp.period_end = date '2026-04-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2026-04-01'
  and pp.period_end = date '2026-04-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 5000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ivy')
  and lower(w.last_name) = lower('Gino')
  and pp.period_start = date '2026-04-01'
  and pp.period_end = date '2026-04-15'
  and abs(p.net_php - 5000.00) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2026-04-01'
  and pp.period_end = date '2026-04-15'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 11935.12,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2026-04-01'
  and pp.period_end = date '2026-04-15'
  and abs(p.net_php - 11935.12) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2026-04-01'
  and pp.period_end = date '2026-04-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2026-04-01'
  and pp.period_end = date '2026-04-15'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2026-04-01'
  and pp.period_end = date '2026-04-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Justina')
  and lower(w.last_name) = lower('Lalosa')
  and pp.period_start = date '2026-04-01'
  and pp.period_end = date '2026-04-15'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2026-04-01'
  and pp.period_end = date '2026-04-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Ma.')
  and lower(w.last_name) = lower('Marcelo')
  and pp.period_start = date '2026-04-01'
  and pp.period_end = date '2026-04-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10609.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2026-04-01'
  and pp.period_end = date '2026-04-15'
  and abs(p.net_php - 10609.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2026-04-01'
  and pp.period_end = date '2026-04-15'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Stephanie')
  and lower(w.last_name) = lower('Gatchalian')
  and pp.period_start = date '2026-04-01'
  and pp.period_end = date '2026-04-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 9947.32,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2024-02-01'
  and pp.period_end = date '2024-02-15'
  and abs(p.net_php - 9947.32) > 0.01;
update payments p
set net_php = 22500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2024-02-01'
  and pp.period_end = date '2024-02-15'
  and abs(p.net_php - 22500.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2024-02-01'
  and pp.period_end = date '2024-02-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2024-02-01'
  and pp.period_end = date '2024-02-15'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2024-02-01'
  and pp.period_end = date '2024-02-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2024-02-01'
  and pp.period_end = date '2024-02-15'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 17500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Kristine')
  and lower(w.last_name) = lower('Mascardo')
  and pp.period_start = date '2024-02-01'
  and pp.period_end = date '2024-02-15'
  and abs(p.net_php - 17500.00) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2024-02-01'
  and pp.period_end = date '2024-02-15'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2024-02-01'
  and pp.period_end = date '2024-02-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2024-02-01'
  and pp.period_end = date '2024-02-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2024-02-01'
  and pp.period_end = date '2024-02-15'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2024-02-01'
  and pp.period_end = date '2024-02-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11249.86,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2024-04-16'
  and pp.period_end = date '2024-04-30'
  and abs(p.net_php - 11249.86) > 0.01;
update payments p
set net_php = 24205.10,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2024-04-16'
  and pp.period_end = date '2024-04-30'
  and abs(p.net_php - 24205.10) > 0.01;
update payments p
set net_php = 22500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2024-04-16'
  and pp.period_end = date '2024-04-30'
  and abs(p.net_php - 22500.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2024-04-16'
  and pp.period_end = date '2024-04-30'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 9187.14,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Jam')
  and lower(w.last_name) = lower('Cruz')
  and pp.period_start = date '2024-04-16'
  and pp.period_end = date '2024-04-30'
  and abs(p.net_php - 9187.14) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2024-04-16'
  and pp.period_end = date '2024-04-30'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2024-04-16'
  and pp.period_end = date '2024-04-30'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2024-04-16'
  and pp.period_end = date '2024-04-30'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 17426.42,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Kristine')
  and lower(w.last_name) = lower('Mascardo')
  and pp.period_start = date '2024-04-16'
  and pp.period_end = date '2024-04-30'
  and abs(p.net_php - 17426.42) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2024-04-16'
  and pp.period_end = date '2024-04-30'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2024-04-16'
  and pp.period_end = date '2024-04-30'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2024-04-16'
  and pp.period_end = date '2024-04-30'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2024-04-16'
  and pp.period_end = date '2024-04-30'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2024-04-16'
  and pp.period_end = date '2024-04-30'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2024-05-01'
  and pp.period_end = date '2024-05-15'
  and abs(p.net_php - 11250.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2024-05-01'
  and pp.period_end = date '2024-05-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 22500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2024-05-01'
  and pp.period_end = date '2024-05-15'
  and abs(p.net_php - 22500.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2024-05-01'
  and pp.period_end = date '2024-05-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 8020.66,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Jam')
  and lower(w.last_name) = lower('Cruz')
  and pp.period_start = date '2024-05-01'
  and pp.period_end = date '2024-05-15'
  and abs(p.net_php - 8020.66) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2024-05-01'
  and pp.period_end = date '2024-05-15'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 9978.57,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2024-05-01'
  and pp.period_end = date '2024-05-15'
  and abs(p.net_php - 9978.57) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2024-05-01'
  and pp.period_end = date '2024-05-15'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 17500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Kristine')
  and lower(w.last_name) = lower('Mascardo')
  and pp.period_start = date '2024-05-01'
  and pp.period_end = date '2024-05-15'
  and abs(p.net_php - 17500.00) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2024-05-01'
  and pp.period_end = date '2024-05-15'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 9219.63,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2024-05-01'
  and pp.period_end = date '2024-05-15'
  and abs(p.net_php - 9219.63) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2024-05-01'
  and pp.period_end = date '2024-05-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 28903.45,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2024-05-01'
  and pp.period_end = date '2024-05-15'
  and abs(p.net_php - 28903.45) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2024-05-01'
  and pp.period_end = date '2024-05-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 10973.30,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2024-05-16'
  and pp.period_end = date '2024-05-31'
  and abs(p.net_php - 10973.30) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2024-05-16'
  and pp.period_end = date '2024-05-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 22500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2024-05-16'
  and pp.period_end = date '2024-05-31'
  and abs(p.net_php - 22500.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2024-05-16'
  and pp.period_end = date '2024-05-31'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 9892.11,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Jam')
  and lower(w.last_name) = lower('Cruz')
  and pp.period_start = date '2024-05-16'
  and pp.period_end = date '2024-05-31'
  and abs(p.net_php - 9892.11) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2024-05-16'
  and pp.period_end = date '2024-05-31'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2024-05-16'
  and pp.period_end = date '2024-05-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2024-05-16'
  and pp.period_end = date '2024-05-31'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 16922.14,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Kristine')
  and lower(w.last_name) = lower('Mascardo')
  and pp.period_start = date '2024-05-16'
  and pp.period_end = date '2024-05-31'
  and abs(p.net_php - 16922.14) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2024-05-16'
  and pp.period_end = date '2024-05-31'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2024-05-16'
  and pp.period_end = date '2024-05-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 9329.48,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2024-05-16'
  and pp.period_end = date '2024-05-31'
  and abs(p.net_php - 9329.48) > 0.01;
update payments p
set net_php = 25971.19,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2024-05-16'
  and pp.period_end = date '2024-05-31'
  and abs(p.net_php - 25971.19) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2024-05-16'
  and pp.period_end = date '2024-05-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 9970.70,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2024-06-01'
  and pp.period_end = date '2024-06-15'
  and abs(p.net_php - 9970.70) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2024-06-01'
  and pp.period_end = date '2024-06-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 22500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2024-06-01'
  and pp.period_end = date '2024-06-15'
  and abs(p.net_php - 22500.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2024-06-01'
  and pp.period_end = date '2024-06-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 8626.74,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Jam')
  and lower(w.last_name) = lower('Cruz')
  and pp.period_start = date '2024-06-01'
  and pp.period_end = date '2024-06-15'
  and abs(p.net_php - 8626.74) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2024-06-01'
  and pp.period_end = date '2024-06-15'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2024-06-01'
  and pp.period_end = date '2024-06-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2024-06-01'
  and pp.period_end = date '2024-06-15'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 16381.82,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Kristine')
  and lower(w.last_name) = lower('Mascardo')
  and pp.period_start = date '2024-06-01'
  and pp.period_end = date '2024-06-15'
  and abs(p.net_php - 16381.82) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2024-06-01'
  and pp.period_end = date '2024-06-15'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2024-06-01'
  and pp.period_end = date '2024-06-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2024-06-01'
  and pp.period_end = date '2024-06-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 30287.31,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2024-06-01'
  and pp.period_end = date '2024-06-15'
  and abs(p.net_php - 30287.31) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2024-06-01'
  and pp.period_end = date '2024-06-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2024-07-01'
  and pp.period_end = date '2024-07-15'
  and abs(p.net_php - 11250.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2024-07-01'
  and pp.period_end = date '2024-07-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 22500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2024-07-01'
  and pp.period_end = date '2024-07-15'
  and abs(p.net_php - 22500.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2024-07-01'
  and pp.period_end = date '2024-07-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Jam')
  and lower(w.last_name) = lower('Cruz')
  and pp.period_start = date '2024-07-01'
  and pp.period_end = date '2024-07-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 31084.93,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2024-07-01'
  and pp.period_end = date '2024-07-15'
  and abs(p.net_php - 31084.93) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2024-07-01'
  and pp.period_end = date '2024-07-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 14253.70,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2024-07-01'
  and pp.period_end = date '2024-07-15'
  and abs(p.net_php - 14253.70) > 0.01;
update payments p
set net_php = 16130.44,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Kristine')
  and lower(w.last_name) = lower('Mascardo')
  and pp.period_start = date '2024-07-01'
  and pp.period_end = date '2024-07-15'
  and abs(p.net_php - 16130.44) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2024-07-01'
  and pp.period_end = date '2024-07-15'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2024-07-01'
  and pp.period_end = date '2024-07-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2024-07-01'
  and pp.period_end = date '2024-07-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2024-07-01'
  and pp.period_end = date '2024-07-15'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 18750.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2024-07-01'
  and pp.period_end = date '2024-07-15'
  and abs(p.net_php - 18750.00) > 0.01;
update payments p
set net_php = 9432.03,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 9432.03) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 20630.37,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 20630.37) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 22500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 22500.00) > 0.01;
update payments p
set net_php = 17111.65,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 17111.65) > 0.01;
update payments p
set net_php = 9636.81,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Jam')
  and lower(w.last_name) = lower('Cruz')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 9636.81) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 9176.39,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 9176.39) > 0.01;
update payments p
set net_php = 14303.22,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 14303.22) > 0.01;
update payments p
set net_php = 4611.15,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 4611.15) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 8514.12,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 8514.12) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 28501.65,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 28501.65) > 0.01;
update payments p
set net_php = 8819.06,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Nicole')
  and lower(w.last_name) = lower('Magada')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 8819.06) > 0.01;
update payments p
set net_php = 20000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2024-12-16'
  and pp.period_end = date '2024-12-31'
  and abs(p.net_php - 20000.00) > 0.01;
update payments p
set net_php = 10224.01,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 10224.01) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Jam')
  and lower(w.last_name) = lower('Cruz')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 5781.14,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 5781.14) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 8250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 8250.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 5075.77,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Nicole')
  and lower(w.last_name) = lower('Magada')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 5075.77) > 0.01;
update payments p
set net_php = 22916.67,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-01-16'
  and pp.period_end = date '2025-01-31'
  and abs(p.net_php - 22916.67) > 0.01;
update payments p
set net_php = 10204.14,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Althea')
  and lower(w.last_name) = lower('Dianalan')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 10204.14) > 0.01;
update payments p
set net_php = 12500.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Angelica')
  and lower(w.last_name) = lower('Conejos')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 12500.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Barrie')
  and lower(w.last_name) = lower('Deonaldo')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Beverly')
  and lower(w.last_name) = lower('Catalino')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 11000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Cecilia')
  and lower(w.last_name) = lower('Velante')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 11000.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Engelbert')
  and lower(w.last_name) = lower('Prim')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 25000.00) > 0.01;
update payments p
set net_php = 18207.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Giovanni')
  and lower(w.last_name) = lower('German')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 18207.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Jam')
  and lower(w.last_name) = lower('Cruz')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 34700.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Janice')
  and lower(w.last_name) = lower('Quiros')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 34700.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('John')
  and lower(w.last_name) = lower('Mistica')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 15000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Karlos')
  and lower(w.last_name) = lower('Sagun')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 15000.00) > 0.01;
update payments p
set net_php = 6250.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Leslie')
  and lower(w.last_name) = lower('Calandria')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 6250.00) > 0.01;
update payments p
set net_php = 10000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Loren')
  and lower(w.last_name) = lower('Zagado')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 10000.00) > 0.01;
update payments p
set net_php = 9000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Manuella')
  and lower(w.last_name) = lower('Gamboa')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 9000.00) > 0.01;
update payments p
set net_php = 9989.27,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Melissa')
  and lower(w.last_name) = lower('Santos')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 9989.27) > 0.01;
update payments p
set net_php = 31290.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Mery')
  and lower(w.last_name) = lower('Dunan')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 31290.00) > 0.01;
update payments p
set net_php = 25000.00,
    original_net_php = coalesce(original_net_php, net_php)
from workers w, companies c, pay_periods pp
where p.worker_id = w.id
  and p.company_id = c.id
  and p.pay_period_id = pp.id
  and c.name = 'Ability Builders'
  and lower(w.first_name) = lower('Valerie')
  and lower(w.last_name) = lower('Bantilan')
  and pp.period_start = date '2025-02-01'
  and pp.period_end = date '2025-02-15'
  and abs(p.net_php - 25000.00) > 0.01;

-- Verify: show every overridden payment with its before/after.
select w.first_name || ' ' || w.last_name as name,
       pp.period_start, pp.period_end,
       p.original_net_php as was_in_db, p.net_php as now_after_override,
       (p.net_php - p.original_net_php) as delta
from payments p
join workers w on w.id = p.worker_id
join pay_periods pp on pp.id = p.pay_period_id
where p.company_id = (select id from companies where name = 'Ability Builders')
  and p.original_net_php is not null
order by pp.period_start, w.last_name;

commit;