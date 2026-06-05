-- Per-hire onboarding overrides (Hiring & Onboarding, P1).
-- Applied to production 2026-06-06 via MCP; this file is the repo record.
-- Additive + reversible; rides existing RLS (admin-write / contractor-read-own).

-- IC addendum lives on the per-(worker, agreement_kind) row it modifies:
alter table public.onboarding_agreements add column if not exists addendum_type text;   -- 'scope_of_work' | 'other' | null
alter table public.onboarding_agreements add column if not exists addendum_text text;

-- This hire's additional required documents (same shape as the global documents[]):
alter table public.onboarding_progress add column if not exists extra_documents jsonb not null default '[]'::jsonb;

-- Rollback:
--   alter table public.onboarding_agreements drop column if exists addendum_type;
--   alter table public.onboarding_agreements drop column if exists addendum_text;
--   alter table public.onboarding_progress  drop column if exists extra_documents;
