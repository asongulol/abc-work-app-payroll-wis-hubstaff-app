-- Document review: add 'waived' (drops the requirement) and 'deferred'
-- (collect later — surfaces as a follow-up in Hiring & Onboarding).
-- Applied to production 2026-06-06 via MCP; this file is the repo record.
-- Additive enum values; portal-review treats both as clearing the requirement.

alter type public.review_status add value if not exists 'waived';
alter type public.review_status add value if not exists 'deferred';

-- Note: Postgres enum values cannot be dropped; to revert, recreate the enum
-- without these labels (only if no rows use them).
