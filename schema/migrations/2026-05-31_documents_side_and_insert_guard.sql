-- ============================================================================
-- Onboarding M2 · Stage-3 support — documents.side + harden the contractor
-- INSERT policy so a contractor can NEVER self-insert an already-"approved" row.
-- APPLY TO PROD before flipping onboarding_enabled=true. Idempotent.
--
-- Why the policy change: documents_contractor_insert (from 2026-05-30_portal_doc_
-- upload.sql) only checked worker ownership + kind<>'other'. A tampered client
-- could POST review_status='approved' and self-satisfy Stage 3. We pin new
-- contractor inserts to review_status='pending' (HR approves via portal-review,
-- which runs as service role and bypasses RLS). The existing portal Docs upload
-- doesn't set review_status (defaults 'pending'), so it is unaffected.
-- ============================================================================

-- 1) side discriminator for multi-side uploads (gov_id front/back). Nullable;
--    only meaningful for kinds that declare `sides` in onboarding_config.
alter table documents add column if not exists side text;

-- 2) re-pin the contractor INSERT policy to pending-only.
drop policy if exists documents_contractor_insert on documents;
create policy documents_contractor_insert on documents for insert to authenticated
  with check (
    worker_id = my_worker_id()
    and kind <> 'other'
    and review_status = 'pending'        -- contractors can only submit, never self-approve
    and reviewed_by is null
    and reviewed_at is null
  );

-- (No contractor UPDATE/DELETE policy exists, so a submitted document can't be
--  edited by the contractor — a "replacement" is a NEW pending row, preserving
--  the rejected one for history. HR review goes through portal-review.)

-- VERIFY:
--   select column_name from information_schema.columns
--    where table_name='documents' and column_name='side';                 -- 1 row
--   select with_check from pg_policies
--    where tablename='documents' and policyname='documents_contractor_insert';
--    -- should mention review_status = 'pending'
