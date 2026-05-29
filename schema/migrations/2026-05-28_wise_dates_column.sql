-- 2026-05-28 — store Wise's real transfer timestamps on each payment
--
-- Background:
--   Today, payments.paid_at gets stamped to now() whenever the matcher/poll
--   flips a row to 'sent'. That's the moment the APP recorded the payment,
--   not the moment Wise actually sent the money. For a backfill ran today
--   on a payroll funded May 14, paid_at would read 2026-05-28 — misleading.
--
--   Wise's transfer record carries three relevant timestamps:
--     created      → the draft was made (~ batch CSV upload time)
--     dateFunded   → the user funded the batch in Wise
--     dateSent     → the money left Wise (terminal-success moment)
--
-- Fix:
--   Add a `wise_dates` jsonb column on payments. The matcher and the poll
--   action will populate it from the Wise transfer response, and the Pay
--   list will show dateSent as the primary "paid on" date (with tooltip
--   exposing created + funded). paid_at is also updated to dateSent so
--   existing reports that rely on paid_at become accurate.
--
-- Safety:
--   Nullable column, no default. Old rows simply have NULL and the UI
--   continues to fall back to paid_at. No backfill required up front —
--   the matcher will populate the field for any period it runs against.

alter table payments add column if not exists wise_dates jsonb;

-- Verify:
select column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'payments'
  and column_name = 'wise_dates';
