-- 2026-06-06 — M1: hard-enforce the payment lock (was soft-warning only)
--
-- Background:
--   2026-05-28 added `wise_locked_at` + a SOFT trigger (`payments_lock_warn`)
--   that only LOGGED a warning to audit_log when a locked (Wise-confirmed) row
--   was edited — it never blocked the write. That was deliberate: observe first,
--   hard-enforce once we know which post-lock edits are legitimate.
--
--   We have now observed. Across 988 soft-warnings on 578 locked rows, the ONLY
--   columns that ever changed on a locked row were:
--       status (585x), fx_rate (386x), wise_transfer_id (17x)
--   i.e. the Reconcile / poll settlement flow. NO money-amount column
--   (net_php, gross_php, payout_amount, deductions, …) has EVER changed on a
--   locked row. So freezing the disbursed amounts will not break any real flow.
--
-- This migration:
--   1. Replaces `payments_lock_warn` (log-only) with `payments_lock_enforce`
--      (RAISE/block) — a BEFORE UPDATE trigger that, on a row whose
--      old.wise_locked_at is non-null, RAISEs if any PROTECTED column changed.
--   2. PROTECTED = the disbursed-amount snapshot + identity (frozen once paid).
--      PERMITTED-on-locked = note, wise_locked_at, wise_dates, status, fx_rate,
--      wise_transfer_id, paid_at — the settlement/reconcile columns prod
--      legitimately updates after lock (empirically verified above). payout_*,
--      net_php, original_net_php, misc_items etc. were never touched post-lock,
--      so they are frozen too (stricter than the old soft list, still safe).
--   3. Pins the function search_path (clears the `function_search_path_mutable`
--      security advisor that flagged the old payments_lock_warn).
--
-- UNLOCK PATH (how an admin legitimately edits a locked row):
--   The per-row Unlock action sets wise_locked_at = NULL in its OWN update.
--   After that, old.wise_locked_at is NULL and this trigger is a no-op, so the
--   amounts become editable again. Unlock → edit → (Reconcile re-locks). The
--   unlock itself is the audited decision point. A single UPDATE that BOTH
--   clears the lock AND changes an amount is still blocked (old is still
--   non-null at evaluation time) — clear the lock first, then edit.
--
-- Note: array elements are added with array_append() (NOT `arr || 'literal'`,
--   which is ambiguous in plpgsql and raises "malformed array literal") —
--   matching the deployed soft function.
--
-- Safety: pure trigger-logic swap, no data is modified. Fully reversible — the
--   rollback at the bottom restores the soft-warning behavior verbatim.
-- Dry-run (BEGIN…RAISE-to-rollback) on prod 2026-06-06 confirmed: net_php on a
--   locked row BLOCKED; fx_rate / wise_transfer_id on a locked row ALLOWED;
--   net_php on an unlocked row ALLOWED. Nothing persisted.

begin;

-- 1. The hard-enforce trigger function (search_path pinned).
create or replace function payments_lock_enforce() returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  changed_cols text[] := '{}';
begin
  -- Only enforce on rows that were locked at the time of update.
  if old.wise_locked_at is null then
    return new;
  end if;

  -- PROTECTED columns: the frozen pay snapshot + identity. (Everything NOT
  -- listed here — note, wise_locked_at, wise_dates, status, fx_rate,
  -- wise_transfer_id, paid_at — is editable while locked: the settlement flow.)
  if new.company_id           is distinct from old.company_id           then changed_cols := array_append(changed_cols,'company_id'); end if;
  if new.pay_period_id        is distinct from old.pay_period_id        then changed_cols := array_append(changed_cols,'pay_period_id'); end if;
  if new.worker_id            is distinct from old.worker_id            then changed_cols := array_append(changed_cols,'worker_id'); end if;
  if new.expected_hours       is distinct from old.expected_hours       then changed_cols := array_append(changed_cols,'expected_hours'); end if;
  if new.worked_hours         is distinct from old.worked_hours         then changed_cols := array_append(changed_cols,'worked_hours'); end if;
  if new.performance_ratio    is distinct from old.performance_ratio    then changed_cols := array_append(changed_cols,'performance_ratio'); end if;
  if new.rate_php             is distinct from old.rate_php             then changed_cols := array_append(changed_cols,'rate_php'); end if;
  if new.gross_php            is distinct from old.gross_php            then changed_cols := array_append(changed_cols,'gross_php'); end if;
  if new.health_allowance_php is distinct from old.health_allowance_php then changed_cols := array_append(changed_cols,'health_allowance_php'); end if;
  if new.pdd_lunch_php        is distinct from old.pdd_lunch_php        then changed_cols := array_append(changed_cols,'pdd_lunch_php'); end if;
  if new.bonus_php            is distinct from old.bonus_php            then changed_cols := array_append(changed_cols,'bonus_php'); end if;
  if new.thirteenth_month_php is distinct from old.thirteenth_month_php then changed_cols := array_append(changed_cols,'thirteenth_month_php'); end if;
  if new.deduction_php        is distinct from old.deduction_php        then changed_cols := array_append(changed_cols,'deduction_php'); end if;
  if new.net_php              is distinct from old.net_php              then changed_cols := array_append(changed_cols,'net_php'); end if;
  if new.original_net_php     is distinct from old.original_net_php     then changed_cols := array_append(changed_cols,'original_net_php'); end if;
  if new.payout_currency      is distinct from old.payout_currency      then changed_cols := array_append(changed_cols,'payout_currency'); end if;
  if new.payout_amount        is distinct from old.payout_amount        then changed_cols := array_append(changed_cols,'payout_amount'); end if;
  if new.payout_method        is distinct from old.payout_method        then changed_cols := array_append(changed_cols,'payout_method'); end if;
  if new.misc_items           is distinct from old.misc_items           then changed_cols := array_append(changed_cols,'misc_items'); end if;

  if array_length(changed_cols, 1) is not null then
    raise exception
      'payment % is locked (wise_locked_at=%); cannot change protected column(s): %',
      old.id, old.wise_locked_at, array_to_string(changed_cols, ', ')
      using errcode = 'check_violation',
            hint = 'Unlock the row first (clears wise_locked_at), then edit. '
                || 'Settlement columns (status, fx_rate, wise_transfer_id, '
                || 'wise_dates, paid_at, note) stay editable while locked.';
  end if;

  return new;
end;
$$;

-- 2. Repoint the trigger from the old soft function to the new hard one.
drop trigger if exists trg_payments_lock_warn    on payments;
drop trigger if exists trg_payments_lock_enforce on payments;
create trigger trg_payments_lock_enforce
before update on payments
for each row execute function payments_lock_enforce();

-- 3. Retire the old soft-warning function (also clears its search_path advisor).
drop function if exists payments_lock_warn();

commit;

-- 4. Verify (run after commit):
--   select tgname from pg_trigger where tgrelid = 'payments'::regclass and not tgisinternal;
--   select proname, proconfig from pg_proc where proname like 'payments_lock_%';

-- ============================================================================
-- ROLLBACK (restore the soft-warning behavior verbatim):
--
-- begin;
-- create or replace function payments_lock_warn() returns trigger
-- language plpgsql set search_path = public, pg_temp as $$
-- declare changed_cols text[] := '{}';
-- begin
--   if old.wise_locked_at is null then return new; end if;
--   if new.company_id is distinct from old.company_id then changed_cols := array_append(changed_cols,'company_id'); end if;
--   if new.pay_period_id is distinct from old.pay_period_id then changed_cols := array_append(changed_cols,'pay_period_id'); end if;
--   if new.worker_id is distinct from old.worker_id then changed_cols := array_append(changed_cols,'worker_id'); end if;
--   if new.expected_hours is distinct from old.expected_hours then changed_cols := array_append(changed_cols,'expected_hours'); end if;
--   if new.worked_hours is distinct from old.worked_hours then changed_cols := array_append(changed_cols,'worked_hours'); end if;
--   if new.performance_ratio is distinct from old.performance_ratio then changed_cols := array_append(changed_cols,'performance_ratio'); end if;
--   if new.rate_php is distinct from old.rate_php then changed_cols := array_append(changed_cols,'rate_php'); end if;
--   if new.gross_php is distinct from old.gross_php then changed_cols := array_append(changed_cols,'gross_php'); end if;
--   if new.health_allowance_php is distinct from old.health_allowance_php then changed_cols := array_append(changed_cols,'health_allowance_php'); end if;
--   if new.pdd_lunch_php is distinct from old.pdd_lunch_php then changed_cols := array_append(changed_cols,'pdd_lunch_php'); end if;
--   if new.bonus_php is distinct from old.bonus_php then changed_cols := array_append(changed_cols,'bonus_php'); end if;
--   if new.thirteenth_month_php is distinct from old.thirteenth_month_php then changed_cols := array_append(changed_cols,'thirteenth_month_php'); end if;
--   if new.deduction_php is distinct from old.deduction_php then changed_cols := array_append(changed_cols,'deduction_php'); end if;
--   if new.net_php is distinct from old.net_php then changed_cols := array_append(changed_cols,'net_php'); end if;
--   if new.fx_rate is distinct from old.fx_rate then changed_cols := array_append(changed_cols,'fx_rate'); end if;
--   if new.payout_currency is distinct from old.payout_currency then changed_cols := array_append(changed_cols,'payout_currency'); end if;
--   if new.payout_amount is distinct from old.payout_amount then changed_cols := array_append(changed_cols,'payout_amount'); end if;
--   if new.payout_method is distinct from old.payout_method then changed_cols := array_append(changed_cols,'payout_method'); end if;
--   if new.wise_transfer_id is distinct from old.wise_transfer_id then changed_cols := array_append(changed_cols,'wise_transfer_id'); end if;
--   if new.status is distinct from old.status then changed_cols := array_append(changed_cols,'status'); end if;
--   if new.paid_at is distinct from old.paid_at then changed_cols := array_append(changed_cols,'paid_at'); end if;
--   if array_length(changed_cols, 1) is not null then
--     insert into audit_log(company_id, action, entity, detail)
--     values (new.company_id, 'wise_lock_warning', 'payment ' || new.id::text,
--       jsonb_build_object('period_id', new.pay_period_id, 'worker_id', new.worker_id,
--         'changed_columns', to_jsonb(changed_cols), 'mode', 'soft_warning_only'));
--   end if;
--   return new;
-- end; $$;
-- drop trigger if exists trg_payments_lock_enforce on payments;
-- create trigger trg_payments_lock_warn before update on payments
--   for each row execute function payments_lock_warn();
-- drop function if exists payments_lock_enforce();
-- commit;
-- ============================================================================
