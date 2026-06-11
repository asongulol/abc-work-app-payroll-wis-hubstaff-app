-- 2026-06-11 — Fix: assigned admins couldn't see onboarding documents
-- ---------------------------------------------------------------------------
-- Bug: the `documents_admin_all` policy (from 2026-06-06_admin_company_scoping)
-- gated reads/writes on `is_company_admin(company_id)`. But onboarding documents
-- (resume / diploma / nbi_clearance / gov_id) are uploaded by the CONTRACTOR via
-- the portal, whose insert policy never sets company_id — so those rows have
-- company_id = NULL. `is_company_admin(NULL)` is false for a non-owner, so an
-- assigned admin saw NONE of a new hire's documents ("No document uploaded"),
-- while the owner (is_owner() short-circuit) saw everything.
--
-- Fix: documents are WORKER-scoped, so gate on whether the admin can see the
-- WORKER (admin_can_see_worker(worker_id) — owner, or assigned to any of the
-- worker's companies). OR-keep the company path so any company-tagged / future
-- company-level rows are unaffected. This only ADDS the missing access — every
-- branch still ultimately requires is_owner() or is_company_admin(assigned co),
-- so company scoping for non-owner admins is preserved.
--
-- Verified on prod (RLS-simulated): assigned admin went 0 -> 3 visible docs for a
-- pending new hire; owner unchanged.
alter policy documents_admin_all on public.documents
  using (admin_can_see_worker(worker_id) or is_company_admin(company_id))
  with check (admin_can_see_worker(worker_id) or is_company_admin(company_id));
