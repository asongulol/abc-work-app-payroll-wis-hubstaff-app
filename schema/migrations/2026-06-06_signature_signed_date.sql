-- Editable "date signed" on e-signatures, separate from signed_at (the immutable
-- cryptographic timestamp). Auto-filled to "today" (Asia/Manila) at signing and
-- shown on the agreement. Applied to production 2026-06-06 via MCP.

alter table public.onboarding_signatures add column if not exists signed_date date;

-- Captured by portal-sign at signing (contractor may override the auto "today").
-- onboarding_signatures has no UPDATE RLS policy (signatures are insert-only
-- legal evidence), so any "edit after" must go through a service-role function.

-- Rollback:
--   alter table public.onboarding_signatures drop column if exists signed_date;
