-- ============================================================================
-- Onboarding M5 · A8 — TURN ON the onboarding read gate.
-- ----------------------------------------------------------------------------
-- Appends `and is_onboarded()` to the THREE contractor pay-data read policies so
-- a logged-in contractor can only see their pay/time/period rows AFTER they have
-- finished onboarding. documents_contractor_read and workers_contractor_read are
-- deliberately UNTOUCHED — a contractor must still read their own profile + docs
-- WHILE onboarding. Admin (is_admin()) policies are untouched, so admin access is
-- unchanged.
--
-- ⚠️ SAFETY KEYSTONE. Before applying, the A7 canary MUST be satisfied for every
-- REAL contractor. As of 2026-06-03 contractor_logins has 3 rows:
--   Leslie Mae Ann Calandria (active)  — grandfathered ✓
--   Abbie Lyzette Sol        (ended)   — grandfathered ✓
--   Oliver Trinidad / othgse@gmail.com — NOT grandfathered (intentional test acct)
-- So after A8, only the test account is gated into onboarding; the two real
-- logins keep pay access. The 48 workers without a contractor_logins row are
-- unaffected (gate keys off my_worker_id() → contractor_logins).
--
-- Depends on: A7 is_onboarded() helper + grandfather backfill (already applied).
-- Idempotent: drop-then-create each policy.
-- ============================================================================

drop policy if exists payments_contractor_read on payments;
create policy payments_contractor_read on payments for select to authenticated
  using ( worker_id = my_worker_id() and is_onboarded() );

drop policy if exists time_entries_contractor_read on time_entries;
create policy time_entries_contractor_read on time_entries for select to authenticated
  using ( worker_id = my_worker_id() and is_onboarded() );

drop policy if exists pay_periods_contractor_read on pay_periods;
create policy pay_periods_contractor_read on pay_periods for select to authenticated
  using ( my_worker_id() is not null and is_onboarded() );

-- ============================================================================
-- ROLLBACK (restores the pre-gate policies from 2026-05-30_contractor_portal_rls):
--
--   drop policy if exists payments_contractor_read on payments;
--   create policy payments_contractor_read on payments for select to authenticated
--     using ( worker_id = my_worker_id() );
--
--   drop policy if exists time_entries_contractor_read on time_entries;
--   create policy time_entries_contractor_read on time_entries for select to authenticated
--     using ( worker_id = my_worker_id() );
--
--   drop policy if exists pay_periods_contractor_read on pay_periods;
--   create policy pay_periods_contractor_read on pay_periods for select to authenticated
--     using ( my_worker_id() is not null );
-- ============================================================================
