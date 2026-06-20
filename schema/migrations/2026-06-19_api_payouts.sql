-- 2026-06-19 — API-based payout (gated behind per-company flag)
-- (Re-applied onto current main from feature/api-payouts-integration; the
--  original was authored 2026-05-29. Idempotent — safe to run once here.)
--
-- Background:
--   Payments today are funded via Wise's Batch Payments UI: the app generates
--   a CSV, the user uploads it on wise.com, and clicks Fund in Wise's UI.
--   The existing API draft path (action: "draft" → /v3/profiles/{id}/quotes +
--   /v1/transfers) creates a Wise transfer but stops short of funding —
--   money does not move until someone funds the batch in the Wise UI.
--
-- This migration adds the schema needed to take the next step: have the app
-- call POST /v3/profiles/{id}/transfers/{transferId}/payments after each
-- draft, which IS the funding call. After that endpoint succeeds, the money
-- has actually left the Wise balance.
--
-- Because that's a real-money action, it's gated:
--   1. Per-company flag (companies.api_payouts_enabled) — default FALSE.
--      The UI only shows the "Create + Fund batch" affordance when this
--      is TRUE for the currently-selected company. Flip it via SQL when
--      you're ready to enable for a company; flip back to FALSE to revert
--      to draft-only behaviour.
--   2. Per-payment funded_at timestamp — set when the fund endpoint
--      returns success. Used as a defensive idempotency check (refuse to
--      fund a row that already has funded_at). Wise's own API rejects
--      double-funding, but storing it locally lets the UI render the
--      "funded" pill without an extra API roundtrip.
--   3. Per-payment funded_by — captures the authenticated admin (email
--      or auth user id) at fund time. Nullable for back-compat.
--   4. Per-payment fund_error — last error string from the Wise fund call,
--      so the UI can render a per-row failure reason without a fresh probe.
--
-- Rollback:
--   Drop the four columns. Flag flip to FALSE on every company is a softer
--   rollback that keeps history intact while turning off the affordance.
--
-- Notes:
--   `wise_locked_at` already exists; we deliberately do NOT auto-set it
--   on fund. The lock is set by the Reconcile button when Wise has
--   confirmed the transfer's status. Funded != confirmed, so this stays
--   separated. A row can be funded but not yet locked (Wise still
--   processing); Reconcile will lock it on its next run.

alter table companies
  add column if not exists api_payouts_enabled boolean not null default false;

alter table payments
  add column if not exists funded_at  timestamptz,
  add column if not exists funded_by  text,
  add column if not exists fund_error text;

-- Partial index so the API-payout UI can quickly count "drafted but not
-- yet funded" rows per period without a sequential scan as the table
-- grows.  Matches the WHERE clause the UI uses.
create index if not exists payments_unfunded_drafts
  on payments (pay_period_id)
  where wise_transfer_id is not null
    and funded_at is null
    and status <> 'reconciled';
