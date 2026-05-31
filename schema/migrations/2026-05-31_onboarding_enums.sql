-- ============================================================================
-- Onboarding M0 · A1 — enum types for the contractor onboarding feature.
-- INERT / ADDITIVE: creating types changes nothing in the running app until
-- later milestones reference them. Idempotent (safe to re-run).
-- Apply order: A1 FIRST (other M0 files depend on these types). APPLY TO PROD.
-- ============================================================================

-- Which stage the contractor is currently on (drives the portal gate).
do $$ begin
  create type onboarding_stage as enum ('stage1_sign','stage2_profile','stage3_docs','complete');
exception when duplicate_object then null; end $$;

-- The four Stage-1 agreements, in signing order.
do $$ begin
  create type agreement_kind as enum ('ic_agreement','non_compete','confidentiality_nda','baa');
exception when duplicate_object then null; end $$;

-- How a signature was captured.
do $$ begin
  create type signature_method as enum ('typed','drawn');
exception when duplicate_object then null; end $$;

-- Lifecycle of a captured signature. 'signed' on valid capture; 'superseded'
-- when a new doc_version is signed; 'disputed' when the contractor later
-- contests it (the original row is never deleted — see design §6.3).
do $$ begin
  create type signature_status as enum ('signed','superseded','disputed');
exception when duplicate_object then null; end $$;

-- HR review state for a Stage-3 uploaded document.
do $$ begin
  create type review_status as enum ('pending','approved','needs_replacement');
exception when duplicate_object then null; end $$;

-- VERIFY:
--   select typname from pg_type where typname in
--     ('onboarding_stage','agreement_kind','signature_method','signature_status','review_status');
--   -- expect 5 rows.
