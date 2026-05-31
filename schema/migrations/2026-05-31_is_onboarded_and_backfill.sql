-- ============================================================================
-- Onboarding M1 · A7 — is_onboarded() gate helper + GRANDFATHER BACKFILL.
-- ----------------------------------------------------------------------------
-- ⚠️ This is the safety keystone. The helper is created here but is INERT: NO
-- RLS policy references it until A8 (the M5 cutover). What matters NOW is the
-- backfill — it marks every currently-active contractor as fully onboarded so
-- that when the gate finally turns on, none of them are locked out of their pay.
--
-- Idempotent: the helper is CREATE OR REPLACE; the backfill is INSERT … ON
-- CONFLICT DO NOTHING, so re-running adds only newly-active contractors and
-- never disturbs anyone already grandfathered. SAFE to apply now and to re-run
-- again immediately before the M5 cutover as the final canary.
-- Depends on: A2 onboarding_progress, my_worker_id(), contractor_logins.
-- ============================================================================

-- Gate helper: true only when THIS session's worker has finished onboarding.
-- Admins have my_worker_id() = null, so this returns false for them — that's
-- fine: admin access flows through the separate is_admin() admin_all policies,
-- never through this predicate.
create or replace function is_onboarded() returns boolean
  language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from onboarding_progress
     where worker_id = my_worker_id()
       and completed_at is not null
  );
$$;

-- Grandfather every active contractor as already-onboarded (gate is still off).
insert into onboarding_progress
  (worker_id, current_stage, stage1_complete, stage2_complete, stage3_complete,
   started_at, completed_at, updated_at)
select cl.worker_id, 'complete', true, true, true, now(), now(), now()
  from contractor_logins cl
 where cl.status = 'active'
on conflict (worker_id) do nothing;

-- ============================================================================
-- CANARY (hand-run; MUST return 0 before A8 is ever pasted at M5):
--   select count(*) as ungrandfathered
--     from contractor_logins
--    where status = 'active'
--      and worker_id not in (
--        select worker_id from onboarding_progress where completed_at is not null);
--   -- expect 0. If > 0, DO NOT enable the gate — re-run this file first.
--
-- Also confirm the helper exists:
--   select proname from pg_proc where proname = 'is_onboarded';   -- 1 row
-- ============================================================================
