-- ============================================================================
-- Onboarding M0 · A5 — add new document_kind enum values for Stage-3 uploads.
-- INERT: nothing references these until the upload UI (M2) ships. APPLY TO PROD.
--
-- ⚠️ RUN THIS FILE BY ITSELF, as its own statement(s) — do NOT paste it inside
-- the same SQL Editor run as other migrations. Postgres forbids USING a new
-- enum value in the same transaction that ADDs it; running this alone avoids
-- any "unsafe use of new value" error and keeps the add isolated.
--
-- FORWARD-ONLY: Postgres cannot drop an enum value. These additions are
-- effectively permanent (see plan §7.8). 'gov_id' already exists and is reused
-- for the government ID / passport (front + back stored as two documents rows).
-- ============================================================================
alter type document_kind add value if not exists 'resume';
alter type document_kind add value if not exists 'diploma';
alter type document_kind add value if not exists 'nbi_clearance';

-- VERIFY (run AFTER, in a separate execution):
--   select enumlabel from pg_enum e join pg_type t on t.oid=e.enumtypid
--    where t.typname='document_kind' order by e.enumsortorder;
--   -- expect: ic_agreement, w8ben, gov_id, other, resume, diploma, nbi_clearance
