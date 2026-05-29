-- 2026-05-29 — Misc-column pay statement add-ons
--
-- Background:
--   The Calculate tab's pay-statements table historically rendered four
--   adjustment columns inline for every row: PDD Lunch, 13th-month accrual,
--   Health Allowance, and Bonus. In practice most contractors have zero in
--   most of those columns, so the table got noisy. Worse, there was no
--   first-class place for two new patterns that started coming up:
--     * "Other Earns" — a labeled lump sum payment (e.g. "Christmas cash",
--       "referral bonus") that didn't fit the bonus column or felt distinct
--       enough to deserve its own label.
--     * "Other Hours" — extra labeled hours worked beyond the period's
--       expectation that should be priced at the contractor's effective
--       hourly rate ((rate * 24) / 2080) and added to net.
--
--   Both can repeat per pay period (multiple Other Earns, multiple Other
--   Hours entries), and each carries a user-typed label so the audit trail
--   stays readable.
--
-- This migration:
--   Adds payments.misc_items (jsonb, defaulted to '[]'::jsonb). Each entry
--   is an object with a small, free-form shape:
--
--     {
--       "kind":  "other_earns"  |  "other_hours",
--       "label": <string>,        -- user-typed; required, non-empty
--       "amount": <number>,       -- PHP amount; for other_hours, this is
--                                 --   the computed pay (hours * hourly_rate)
--       "hours": <number>?,       -- only for other_hours
--       "hourly_rate": <number>?  -- only for other_hours; captured at the
--                                 --   time the entry was added so it survives
--                                 --   later rate edits on the worker
--     }
--
--   The existing pdd_lunch_php, bonus_php, deduction_php, thirteenth_month_php,
--   and health_allowance_php columns ARE PRESERVED. The new "Misc" UI writes
--   Lunch → pdd_lunch_php, Bonus → bonus_php, Deductions → deduction_php
--   (same columns, just edited via a popup instead of inline cells). Only
--   "Other Earns" and "Other Hours" are stored in misc_items.
--
-- Net-pay impact:
--   Sum of misc_items[].amount adds to net_php (both kinds are positive —
--   "Other Earns" is a payment, "Other Hours" is hours × rate). Deductions
--   are NOT in misc_items; they continue to flow through deduction_php and
--   subtract from net in the existing calculator.
--
-- Rollback:
--   Drop the misc_items column. Frontend gracefully degrades — if the
--   column is missing, the misc-popup just hides Other Earns / Other Hours
--   sections and the existing PDD/Bonus/Deduction inputs keep working.

alter table payments
  add column if not exists misc_items jsonb not null default '[]'::jsonb;

-- Lightweight check that the column always holds a JSON array (never a
-- bare object or scalar). Caught by the upsert in lockAndSave / saveDraft.
alter table payments
  drop constraint if exists payments_misc_items_array;
alter table payments
  add constraint payments_misc_items_array
  check (jsonb_typeof(misc_items) = 'array');
