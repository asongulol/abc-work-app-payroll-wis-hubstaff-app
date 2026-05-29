-- 2026-05-28 — lock payment rows once Wise has confirmed them
--
-- Background:
--   Yesterday's investigation surfaced a real failure mode: when a paid period
--   gets re-calculated or re-imported, the stored amounts can silently change
--   on rows where the money has ALREADY been disbursed. (Ferdinand/Melissa/Mery
--   are the recorded example.) Once Wise has confirmed a payment, the DB row
--   is a record of what was paid, not an editable calculation.
--
-- Fix:
--   Add `wise_locked_at` (timestamptz, nullable). When non-null, the row is
--   treated as locked: the UI disables edit affordances, and a database
--   trigger logs any attempted update of locked rows to audit_log so we can
--   see what flows would have been blocked before flipping to hard-enforce.
--
--   The smart Reconcile button sets wise_locked_at = now() whenever it
--   confirms a row from Wise (either by matching a transfer_id for the first
--   time, or by polling and discovering an outgoing_payment_sent status with
--   wise_dates populated).
--
-- Retroactive lock:
--   This migration ALSO sets wise_locked_at = now() on every existing row
--   that's already `sent` AND has wise_dates populated. Those are rows Wise
--   has already confirmed at some point — locking them is the right starting
--   state. Rows without wise_dates stay unlocked (the smart button will lock
--   them once it has Wise data to base the lock on).
--
-- Safety:
--   Nullable column, no default. Old rows simply have NULL (unlocked).
--   The trigger logs WARNINGS to audit_log; it does NOT block updates.
--   Hard enforcement is a separate decision once we've observed what edits
--   were happening that would have been blocked.

-- 1. Add the column
alter table payments add column if not exists wise_locked_at timestamptz;

-- 2. Retroactively lock rows that are already paid AND have Wise dates
update payments
   set wise_locked_at = now()
 where status = 'sent'
   and wise_dates is not null
   and wise_locked_at is null;

-- 3. Soft-warning trigger: when someone updates a locked row, log a warning
--    to audit_log. Does NOT block the update. The trigger ignores updates that
--    only touch `note`, `wise_locked_at`, or `wise_dates` (those are always
--    allowed on locked rows).
create or replace function payments_lock_warn() returns trigger
language plpgsql as $$
declare
  changed_cols text[] := '{}';
begin
  -- Only consider rows that were locked at the time of update
  if old.wise_locked_at is null then
    return new;
  end if;
  -- Build a list of columns whose value changed, excluding allowed-on-locked ones
  if new.company_id            is distinct from old.company_id            then changed_cols := changed_cols || 'company_id'; end if;
  if new.pay_period_id         is distinct from old.pay_period_id         then changed_cols := changed_cols || 'pay_period_id'; end if;
  if new.worker_id             is distinct from old.worker_id             then changed_cols := changed_cols || 'worker_id'; end if;
  if new.expected_hours        is distinct from old.expected_hours        then changed_cols := changed_cols || 'expected_hours'; end if;
  if new.worked_hours          is distinct from old.worked_hours          then changed_cols := changed_cols || 'worked_hours'; end if;
  if new.performance_ratio     is distinct from old.performance_ratio     then changed_cols := changed_cols || 'performance_ratio'; end if;
  if new.rate_php              is distinct from old.rate_php              then changed_cols := changed_cols || 'rate_php'; end if;
  if new.gross_php             is distinct from old.gross_php             then changed_cols := changed_cols || 'gross_php'; end if;
  if new.health_allowance_php  is distinct from old.health_allowance_php  then changed_cols := changed_cols || 'health_allowance_php'; end if;
  if new.pdd_lunch_php         is distinct from old.pdd_lunch_php         then changed_cols := changed_cols || 'pdd_lunch_php'; end if;
  if new.bonus_php             is distinct from old.bonus_php             then changed_cols := changed_cols || 'bonus_php'; end if;
  if new.thirteenth_month_php  is distinct from old.thirteenth_month_php  then changed_cols := changed_cols || 'thirteenth_month_php'; end if;
  if new.deduction_php         is distinct from old.deduction_php         then changed_cols := changed_cols || 'deduction_php'; end if;
  if new.net_php               is distinct from old.net_php               then changed_cols := changed_cols || 'net_php'; end if;
  if new.fx_rate               is distinct from old.fx_rate               then changed_cols := changed_cols || 'fx_rate'; end if;
  if new.payout_currency       is distinct from old.payout_currency       then changed_cols := changed_cols || 'payout_currency'; end if;
  if new.payout_amount         is distinct from old.payout_amount         then changed_cols := changed_cols || 'payout_amount'; end if;
  if new.payout_method         is distinct from old.payout_method         then changed_cols := changed_cols || 'payout_method'; end if;
  if new.wise_transfer_id      is distinct from old.wise_transfer_id      then changed_cols := changed_cols || 'wise_transfer_id'; end if;
  if new.status                is distinct from old.status                then changed_cols := changed_cols || 'status'; end if;
  if new.paid_at               is distinct from old.paid_at               then changed_cols := changed_cols || 'paid_at'; end if;
  -- If any non-allowed column was changed, log a warning (does NOT block)
  if array_length(changed_cols, 1) is not null then
    insert into audit_log(company_id, action, entity, detail)
    values (
      new.company_id,
      'wise_lock_warning',
      'payment ' || new.id::text,
      jsonb_build_object(
        'period_id', new.pay_period_id,
        'worker_id', new.worker_id,
        'changed_columns', to_jsonb(changed_cols),
        'mode', 'soft_warning_only'
      )
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_payments_lock_warn on payments;
create trigger trg_payments_lock_warn
before update on payments
for each row execute function payments_lock_warn();

-- 4. Verify
select
  (select count(*) from payments where wise_locked_at is not null) as locked_rows,
  (select count(*) from payments where status = 'sent')             as total_sent_rows,
  (select count(*) from payments where wise_dates is not null)      as rows_with_wise_dates;
