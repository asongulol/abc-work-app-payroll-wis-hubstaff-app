-- ============================================================================
-- Onboarding M0 · A4 — add HR-review columns to the existing documents table.
-- INERT: new columns are unused by the running app until the admin review UI
-- (M3) ships. Idempotent. APPLY TO PROD. Depends on: A1 enums (review_status).
--
-- OWNER DECISIONS BAKED IN (see implementation plan §7 — change here if you disagree):
--  * reviewed_by -> auth.users(id), NOT workers(id). Reviewers are ADMINS, and
--    admins live in admin_users.user_id -> auth.users(id); they are NOT rows in
--    workers. (The plan's `references workers(id)` would fail on insert.) The
--    portal-review edge fn fills this from the admin's auth.uid() server-side.
--  * Legacy-doc neutralize: existing documents are marked 'approved' so the new
--    "pending review" HR queue starts empty (pre-onboarding uploads aren't
--    onboarding submissions). New rows still default to 'pending'.
-- ============================================================================
alter table documents
  add column if not exists review_status   review_status not null default 'pending',
  add column if not exists review_reason   text,
  add column if not exists reviewed_by     uuid references auth.users(id) on delete set null,
  add column if not exists reviewed_at     timestamptz,
  add column if not exists issued_on       date,        -- e.g. NBI clearance issue date (6-month freshness)
  add column if not exists mime_type       text,
  add column if not exists file_size_bytes bigint;

create index if not exists documents_review_status_idx on documents (review_status);

-- Neutralize pre-existing documents so they don't appear as "pending" in the
-- onboarding review queue. Runs once at apply time; new uploads default 'pending'.
update documents set review_status = 'approved'
 where created_at < now() and review_status = 'pending';

-- VERIFY:
--   select review_status, count(*) from documents group by review_status;
--     -- expect existing docs under 'approved', none left 'pending'.
--   select column_name from information_schema.columns
--    where table_name='documents' and column_name in
--      ('review_status','review_reason','reviewed_by','reviewed_at','issued_on','mime_type','file_size_bytes');
--     -- expect 7 rows.
