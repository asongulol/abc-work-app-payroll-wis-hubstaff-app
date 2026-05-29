-- ============================================================================
-- HR & Payroll system for PH-based independent contractors
-- Target: Supabase (PostgreSQL 15+).  Admin-only for now; RLS-ready.
-- ----------------------------------------------------------------------------
-- DESIGN NOTES
--  * All workers are PH-based INDEPENDENT CONTRACTORS. No US payroll, no
--    withholding, no 1099. Per-worker US doc is a W-8BEN (in documents).
--  * Multi-company, many-to-many: a contractor may serve >1 company, with
--    role + PHP rate set PER company (worker_companies + rates).
--  * Everything operational is scoped by company_id so payroll runs and
--    reports are per-company, with a consolidated view available by union.
--  * Money: rates in PHP; payouts usually USD. Every payment records an FX
--    rate so PHP and USD reconcile. Phase 2 writes the real Wise FX back.
--  * All timestamps are stored UTC (timestamptz). Hubstaff day buckets are
--    normalized to PH time (Asia/Manila, UTC+8) on import; see time_entries.
--  * Compliance: we store the signed IC agreement + W-8BEN per worker and
--    deliberately AVOID employee-style supervision fields (no schedules to
--    enforce, no disciplinary tracking) to reduce PH misclassification risk
--    under the DOLE control test.
-- ============================================================================

create extension if not exists "pgcrypto";   -- gen_random_uuid()

-- ---------- enums -----------------------------------------------------------
create type company_status   as enum ('active', 'inactive');
create type worker_status     as enum ('active', 'inactive', 'ended');
create type contract_type     as enum ('FT', 'PT');
create type payout_method      as enum ('wise', 'bpi', 'gcash', 'paymaya', 'paypal');
create type approval_status     as enum ('pending', 'approved', 'rejected');
create type pay_period_state     as enum ('open', 'locked', 'paid');
create type payment_status        as enum ('draft', 'queued', 'sent', 'failed', 'reconciled');
create type document_kind          as enum ('ic_agreement', 'w8ben', 'gov_id', 'other');

-- ---------- companies -------------------------------------------------------
-- e.g. Ability Builders, Nightingale Process Management.
create table companies (
    id            uuid primary key default gen_random_uuid(),
    name          text not null unique,
    status        company_status not null default 'active',
    -- The Hubstaff organization this company's time comes from (one Hubstaff
    -- org may feed one company). Used to map imports -> company.
    hubstaff_org_id  bigint,
    created_at    timestamptz not null default now()
);

-- ---------- workers (the contractor, identity-level, company-agnostic) ------
create table workers (
    id              uuid primary key default gen_random_uuid(),
    first_name      text not null,
    last_name       text not null,
    -- normalized "first last" used to match Hubstaff display names on import
    match_key       text generated always as (
                        lower(trim(first_name)) || ' ' || lower(trim(last_name))
                    ) stored,
    status          worker_status not null default 'active',
    email           text,
    mobile          text,
    ph_address      text,                       -- PH home address
    date_of_birth   date,
    hire_date       date,                       -- engagement start (for tenure/HA/13th)
    -- payout details. NULL = not yet chosen (flagged in the app).
    -- Channels: wise | bpi | gcash | paymaya | paypal
    payout_method   payout_method,
    payout_account  jsonb,                       -- {wise_email, bank, acct_no, ...}
    -- Wise recipient identifiers (IDs only — NOT bank details). Recipients are
    -- created in Wise; the app just references them to draft transfers.
    -- wise_recipients: list of saved profiles e.g. [{"id":123,"label":"BPI peso","uuid":"33e5..."}]
    -- wise_recipient_id: the LAST-USED recipient numeric id (the payout default; API).
    -- wise_recipient_uuid: default recipient's Wise UUID — used by the manual
    --   Batch Payments CSV (recipientId). API gives the numeric id; only the
    --   "download all templates" export carries this UUID. Stable per account.
    wise_recipients      jsonb default '[]'::jsonb,
    wise_recipient_id    bigint,
    wise_recipient_uuid  text,
    -- backup local wallets (informational; from Benefits 201 file)
    gcash           text,
    paymaya         text,
    paypal          text,
    -- benefits flags
    health_allowance_eligible  boolean not null default true,
    thirteenth_month_eligible  boolean not null default true,
    -- optional contractor photo. Stored as a small (256px) center-cropped JPEG
    -- data URI, so no Storage bucket / RLS is required. NULL = use initials.
    photo_url       text,
    created_at      timestamptz not null default now()
);
create index on workers (match_key);

-- ---------- worker_companies (many-to-many; role + default scope per company)
create table worker_companies (
    id            uuid primary key default gen_random_uuid(),
    worker_id     uuid not null references workers(id) on delete cascade,
    company_id    uuid not null references companies(id) on delete cascade,
    role          text,                              -- e.g. "Billing Associate"
    contract      contract_type not null default 'FT',
    -- exact name as it appears in THIS company's Hubstaff export (for matching)
    hubstaff_name text,
    -- stable Hubstaff user id (preferred match key; immune to name changes)
    hubstaff_user_id bigint,
    status        worker_status not null default 'active',
    started_on    date,
    ended_on      date,
    unique (worker_id, company_id)
);
create index on worker_companies (company_id);
-- a Hubstaff user maps to at most one link per company (only where id is set)
create unique index if not exists worker_companies_company_hubstaff_user
  on worker_companies (company_id, hubstaff_user_id)
  where hubstaff_user_id is not null;

-- ---------- rates (effective-dated, PHP, per worker+company) ----------------
-- The PER-PERIOD (semi-monthly) PHP amount, matching the existing workbook's
-- "Rate" column. Monthly = rate * 2 (paid 15th and month-end).
create table rates (
    id            uuid primary key default gen_random_uuid(),
    worker_id     uuid not null references workers(id) on delete cascade,
    company_id    uuid not null references companies(id) on delete cascade,
    amount_php    numeric(12,2) not null,
    period_basis  text not null default 'semi_monthly',  -- semi_monthly | monthly | hourly
    effective_start date not null,
    effective_end   date,                                  -- null = current
    note          text,
    created_at    timestamptz not null default now(),
    check (effective_end is null or effective_end >= effective_start)
);
create index on rates (worker_id, company_id, effective_start);

-- ---------- pay_periods (scoped to one company; has a lock state) -----------
create table pay_periods (
    id            uuid primary key default gen_random_uuid(),
    company_id    uuid not null references companies(id) on delete cascade,
    period_start  date not null,            -- e.g. 2026-05-01
    period_end    date not null,            -- e.g. 2026-05-15
    pay_date      date,                      -- 15th or month-end
    state         pay_period_state not null default 'open',
    expected_hours_ft  numeric(6,2) not null default 80,
    expected_hours_pt  numeric(6,2) not null default 40,
    locked_at     timestamptz,
    created_at    timestamptz not null default now(),
    unique (company_id, period_start, period_end),
    check (period_end >= period_start)
);

-- ---------- time_entries (imported from Hubstaff; approval workflow) --------
-- One row per worker per day per company. Hubstaff day buckets are already
-- per-day; we keep the worked seconds and the PH-local date.
create table time_entries (
    id              uuid primary key default gen_random_uuid(),
    company_id      uuid not null references companies(id) on delete cascade,
    worker_id       uuid references workers(id) on delete set null,
    -- keep the raw Hubstaff name so unmatched rows are still importable/visible
    source_name     text not null,
    work_date       date not null,           -- PH-local (Asia/Manila) calendar day
    tracked_seconds integer not null default 0,
    -- Paid + approved PTO from Hubstaff time_off_requests, per day. Populated
    -- by hubstaff-sync alongside tracked. Counted toward worked_hours in
    -- payroll so PTO leave gets paid. CSV imports default to 0 (manual
    -- imports don't have a PTO source to pull from).
    pto_seconds     integer not null default 0,
    project         text,
    activity_pct    numeric(5,2),
    approval        approval_status not null default 'pending',
    approved_by     uuid,                     -- admin user id (auth.users) later
    approved_at     timestamptz,
    pay_period_id   uuid references pay_periods(id) on delete set null,
    import_batch_id uuid,                     -- groups one CSV/API import
    created_at      timestamptz not null default now(),
    unique (company_id, source_name, work_date)
);
create index on time_entries (company_id, work_date);
create index on time_entries (pay_period_id);
create index on time_entries (worker_id);

-- ---------- payments (one per worker per pay_period) ------------------------
-- Mirrors the existing pay-statement: gross PHP from rate * performance,
-- + health allowance + 13th-month component, then FX to the payout currency.
create table payments (
    id                uuid primary key default gen_random_uuid(),
    company_id        uuid not null references companies(id) on delete cascade,
    pay_period_id     uuid not null references pay_periods(id) on delete cascade,
    worker_id         uuid not null references workers(id) on delete cascade,
    -- computation snapshot (so a locked period is immutable & auditable)
    expected_hours    numeric(6,2),
    worked_hours      numeric(8,4),
    performance_ratio numeric(6,4),            -- min(worked/expected, cap)
    rate_php          numeric(12,2),           -- the rate applied
    gross_php         numeric(12,2) not null default 0,   -- expected disbursement
    health_allowance_php numeric(12,2) not null default 0,
    pdd_lunch_php     numeric(12,2) not null default 0,
    bonus_php         numeric(12,2) not null default 0,
    thirteenth_month_php  numeric(12,2) not null default 0,
    deduction_php     numeric(12,2) not null default 0,
    net_php           numeric(12,2) not null default 0,   -- adjusted disbursement
    -- When the Reconcile matcher finds a variance (DB ≠ Wise) and there's
    -- exactly one candidate transfer, it auto-overrides net_php with the
    -- amount Wise actually sent and preserves the old value here. Lets the
    -- UI show "was X, now Y" so the override is visible, not hidden.
    -- NULL = no override has happened. Non-NULL = net_php is the post-Wise
    -- amount, this column is the original pre-Wise DB amount.
    original_net_php  numeric(12,2),
    -- FX + payout
    fx_rate           numeric(14,6),           -- PHP per 1 unit payout currency
    payout_currency   text not null default 'USD',
    payout_amount     numeric(12,2),           -- net_php converted at fx_rate
    payout_method     payout_method,
    -- Wise (Phase 2)
    wise_transfer_id  text,
    -- All three Wise transfer timestamps, populated by matcher/poll from the
    -- /v1/transfers response: { created, dateFunded, dateSent }. Lets the UI
    -- show the real Wise pay date instead of "when we noticed it" (paid_at).
    wise_dates        jsonb,
    -- Lock timestamp: set by the smart Reconcile button when Wise confirms
    -- this row. When non-null the row is treated as locked — UI disables edit
    -- affordances, and a trigger logs warnings if anything tries to update
    -- non-allowed columns (everything except note / wise_locked_at / wise_dates).
    -- Unlock = clear this column via the per-row Unlock admin action.
    wise_locked_at    timestamptz,
    -- Free-form labeled pay add-ons that don't fit a single typed column.
    -- Each entry: { kind: "other_earns"|"other_hours", label, amount,
    -- hours?, hourly_rate? }. Sum of amount adds to net_php. Other Hours
    -- prices labeled hours at the contractor's effective hourly rate
    -- (rate * 24 / 2080) captured at entry time so historical periods are
    -- not retroactively repriced when rates change.
    misc_items        jsonb not null default '[]'::jsonb
                       check (jsonb_typeof(misc_items) = 'array'),
    status            payment_status not null default 'draft',
    paid_at           timestamptz,
    note              text,
    created_at        timestamptz not null default now(),
    unique (pay_period_id, worker_id)
);
create index on payments (company_id);
create index on payments (pay_period_id);

-- ---------- documents (IC agreement, W-8BEN, IDs; expiry reminders) ---------
create table documents (
    id            uuid primary key default gen_random_uuid(),
    worker_id     uuid not null references workers(id) on delete cascade,
    company_id    uuid references companies(id) on delete set null,  -- IC agreement is per-company
    kind          document_kind not null,
    title         text,
    storage_path  text,                       -- Supabase Storage object path
    signed_on     date,
    expires_on    date,                        -- drives reminders; null = no expiry
    created_at    timestamptz not null default now()
);
create index on documents (worker_id);
create index on documents (expires_on);

-- ---------- audit_log (who/what/when for overrides & key actions) -----------
create table audit_log (
    id            uuid primary key default gen_random_uuid(),
    company_id    uuid references companies(id) on delete set null,
    actor         text,                         -- admin identity (email) when available
    action        text not null,                -- e.g. 'override.gross','manual.hours','approve','lock','mark_paid','import','delete'
    entity        text,                         -- what it touched (contractor name, period, batch)
    detail        jsonb,                        -- { from, to, period, note, ... }
    created_at    timestamptz not null default now()
);
create index on audit_log (company_id, created_at);
create index on audit_log (action);

-- ---------- api_tokens (server-side rotating tokens, e.g. Hubstaff) ----------
-- Hubstaff rotates its refresh token on every exchange, so it can't live in a
-- static secret — the hubstaff-sync function reads & writes the current token here.
create table api_tokens (
    provider      text primary key,             -- 'hubstaff'
    refresh_token text not null,
    access_token  text,                          -- cached short-lived access token
    access_expires_at timestamptz,               -- when the access token expires
    updated_at    timestamptz not null default now()
);

-- ---------- a view for the consolidated (all-company) payout report ---------
-- SECURITY INVOKER is set EXPLICITLY here. Without it Supabase flags this view
-- as "Security Definer View — CRITICAL" because a definer-rights view executes
-- with the view-owner's permissions and silently bypasses row-level security
-- on the underlying tables. With SECURITY INVOKER the querying user's RLS
-- policies on payments / pay_periods / companies apply normally.
create view v_payouts_by_period
with (security_invoker = true) as
select
    p.company_id,
    c.name              as company_name,
    pp.period_start,
    pp.period_end,
    count(*)            as contractor_count,
    sum(p.net_php)      as total_net_php,
    sum(p.payout_amount) as total_payout,
    p.payout_currency
from payments p
join pay_periods pp on pp.id = p.pay_period_id
join companies   c  on c.id  = p.company_id
group by p.company_id, c.name, pp.period_start, pp.period_end, p.payout_currency;

-- ============================================================================
-- RLS SCAFFOLDING (kept permissive for admin-only Phase 1; ready to tighten)
-- ----------------------------------------------------------------------------
-- For now a single admin role uses the service key. When per-company logins
-- arrive, add a memberships table (user_id, company_id, role) and replace the
-- permissive policies below with company-scoped ones, e.g.:
--   using ( company_id in (select company_id from memberships
--                          where user_id = auth.uid()) )
-- ============================================================================
alter table companies        enable row level security;
alter table workers          enable row level security;
alter table worker_companies enable row level security;
alter table rates            enable row level security;
alter table pay_periods      enable row level security;
alter table time_entries     enable row level security;
alter table payments         enable row level security;
alter table documents        enable row level security;

-- Phase 1: authenticated admin can do everything. (Service role bypasses RLS.)
do $$
declare t text;
begin
  foreach t in array array['companies','workers','worker_companies','rates',
                           'pay_periods','time_entries','payments','documents']
  loop
    execute format(
      'create policy %I_admin_all on %I for all to authenticated using (true) with check (true);',
      t, t);
  end loop;
end$$;
