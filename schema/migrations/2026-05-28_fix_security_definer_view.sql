-- 2026-05-28 — fix "Security Definer View" critical advisor on v_payouts_by_period
--
-- Background:
--   Supabase Advisor flagged public.v_payouts_by_period as SECURITY DEFINER,
--   meaning it ran with the view owner's privileges and silently bypassed RLS
--   on the underlying tables (payments / pay_periods / companies). Any caller
--   with read access to the view could see across all companies regardless of
--   their RLS scope.
--
-- Fix:
--   Set security_invoker = true so the view executes with the caller's
--   privileges and RLS policies apply normally.
--
-- Safety:
--   The view is read-only and is currently NOT queried by the front-end
--   (verified — no references in app/index.html). Flipping this flag won't
--   break any user-facing feature; it only tightens who can read what.
--
-- Run this in: Supabase dashboard → SQL Editor → New query → paste → Run.
-- Idempotent — safe to run more than once.

alter view public.v_payouts_by_period set (security_invoker = true);

-- Verify (returns one row; "security_invoker" should be true):
select
  c.relname            as view_name,
  c.reloptions         as view_options
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname  = 'v_payouts_by_period';
