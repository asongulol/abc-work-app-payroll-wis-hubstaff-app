-- 2026-05-28 — surface paid PTO from Hubstaff alongside tracked time
--
-- Background:
--   Hubstaff exposes paid time off via /v2/organizations/{org}/time_off_requests
--   (not on activities/daily — confirmed 2026-05-28 probe). Until today the
--   sync only pulled `tracked` seconds and PTO was silently lost. That meant
--   payroll under-paid anyone who took PTO during a pay period.
--
-- Fix:
--   Add pto_seconds column to time_entries. The hubstaff-sync function now
--   pulls time_off_requests and writes per-day paid+approved PTO seconds.
--   The payroll calc treats worked_hours = (tracked + pto) / 3600 so PTO
--   counts toward the period's hours.
--
-- Safety:
--   Default 0, NOT NULL. Existing rows keep tracked_seconds unchanged and
--   simply have pto_seconds = 0 (which is what they would have been had
--   the column existed). Historical periods aren't retroactively backfilled
--   — re-importing those periods would do it, but you'd then need to re-run
--   payroll for those periods. The migration deliberately does not auto-
--   backfill to keep already-locked periods stable.

alter table time_entries add column if not exists pto_seconds integer not null default 0;

-- Verify
select column_name, data_type, column_default, is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name   = 'time_entries'
  and column_name  = 'pto_seconds';
