-- Per-hour / per-session contract type ('PHS'). Unlike FT/PT it has NO expected
-- number of hours, so the FT/PT fixed-salary-prorated-by-worked/expected model
-- does not apply. Instead pay is purely transactional:
--   pay = (worked hours OR approved sessions in the period) × a PER-UNIT rate.
-- The PER-UNIT rate is rates.amount_php; the UNIT is set by worker_companies.pay_basis
-- (the SINGLE source of truth, kept next to .contract so the two can never drift):
--   pay_basis = 'hourly'      → pay = worked hours × amount_php
--   pay_basis = 'per_session' → pay = Σ approved session units × amount_php
-- This contract type is what ties a contractor to the per-session billing setup
-- (service_sessions / session_rate_usd — those are USD client billing, separate
--  from this PHP pay rate). Additive.
alter type public.contract_type add value if not exists 'PHS';

-- pay_basis lives on the engagement (next to contract) — NOT on the rate — so an
-- admin changing the contract type and the rate can never leave them inconsistent.
-- Nullable; only meaningful for contract='PHS' ('hourly' | 'per_session').
alter table public.worker_companies add column if not exists pay_basis text;

-- Snapshot the PHS pay shape onto the payment so a locked/draft period reloads
-- correctly (otherwise a per-session row reloads as a 0-hour row and the session
-- count is lost). contract/pay_basis are the engagement shape at calc time; units
-- is the count actually paid (session units for per_session; null for hourly,
-- where worked_hours already holds the hours).
alter table public.payments add column if not exists contract text;
alter table public.payments add column if not exists pay_basis text;
alter table public.payments add column if not exists units numeric(12,2);

-- Rollback:
--   alter table public.payments drop column if exists units;
--   alter table public.payments drop column if exists pay_basis;
--   alter table public.payments drop column if exists contract;
--   alter table public.worker_companies drop column if exists pay_basis;
--   -- (Postgres cannot DROP the 'PHS' enum value; leave it — inert if unused.)
