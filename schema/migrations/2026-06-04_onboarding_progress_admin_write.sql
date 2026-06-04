-- ============================================================================
-- Onboarding admin overrides: let ADMINS write onboarding_progress directly so
-- they can reopen a stage, force-complete, or revoke (reset) a contractor's
-- onboarding. Previously only the service-role portal functions could write it,
-- and they advance monotonically (never regress) — admin overrides need to
-- regress, so they get their own is_admin() write policy.
--
-- Contractors are unaffected: the predicate is is_admin(), and my_worker_id()
-- contractors are never admins. The portal functions use the service role and
-- bypass RLS regardless. Idempotent.
-- ============================================================================

drop policy if exists onboarding_progress_admin_write on onboarding_progress;
create policy onboarding_progress_admin_write on onboarding_progress
  for all to authenticated using (is_admin()) with check (is_admin());

-- ============================================================================
-- ROLLBACK:
--   drop policy if exists onboarding_progress_admin_write on onboarding_progress;
-- ============================================================================
