-- 2026-05-28 — diagnose why Manuella's 2025-04-01→04-15 payment is unreconciled
--
-- Schema notes (verified against schema.sql):
--   - workers: first_name, last_name (no middle_name), wise_recipient_id (bigint),
--     wise_recipient_uuid (text), wise_recipients (jsonb), payout_method, status, email.
--     hubstaff_user_id lives on worker_companies, not workers.
--   - payments: pay_period_id (join through pay_periods), worker_id, net_php,
--     original_net_php, rate_php, worked_hours, expected_hours, payout_method,
--     wise_transfer_id, wise_dates, wise_locked_at, paid_at, status.
--
-- Run each block separately.

-- ============================================================
-- BLOCK 1: Find Manuella's worker record
-- ============================================================
select id, first_name, last_name,
       wise_recipient_id, wise_recipient_uuid, wise_recipients,
       payout_method, status, email
from workers
where first_name ilike 'manuella%' or last_name ilike '%gamboa%'
order by last_name, first_name;

-- ============================================================
-- BLOCK 2: Her payment row for 2025-04-01 → 2025-04-15
-- ============================================================
select p.id, p.worker_id, w.first_name || ' ' || w.last_name as name,
       pp.period_start, pp.period_end, pp.pay_date,
       p.net_php, p.original_net_php,
       p.rate_php, p.worked_hours, p.expected_hours,
       p.payout_method,
       p.wise_transfer_id, p.wise_dates, p.wise_locked_at, p.paid_at,
       p.status
from payments p
join workers w on w.id = p.worker_id
join pay_periods pp on pp.id = p.pay_period_id
where pp.period_start = '2025-04-01'
  and pp.period_end = '2025-04-15'
  and (w.first_name ilike 'manuella%' or w.last_name ilike '%gamboa%');

-- ============================================================
-- BLOCK 3: Compare her row to everyone reconciled in the same period
-- ============================================================
select w.first_name || ' ' || w.last_name as name,
       w.wise_recipient_id,
       p.net_php, p.payout_method,
       p.wise_transfer_id, p.paid_at,
       case
         when p.payout_method::text != 'wise' then 'not_wise (' || coalesce(p.payout_method::text,'null') || ')'
         when w.wise_recipient_id is null then 'no_recipient_id_on_worker'
         when p.wise_transfer_id is not null then 'matched'
         else 'unmatched'
       end as recon_state
from payments p
join workers w on w.id = p.worker_id
join pay_periods pp on pp.id = p.pay_period_id
where pp.period_start = '2025-04-01'
  and pp.period_end = '2025-04-15'
order by recon_state, w.last_name;
