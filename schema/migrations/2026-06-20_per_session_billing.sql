-- Phase 4 extension — per-SESSION (flat-fee per visit) client billing, alongside
-- the existing hourly path. A single client invoice may carry BOTH hourly lines
-- (worked hours × bill_rate_usd) and session lines (approved sessions ×
-- session_rate_usd; duration ignored). Markup applies ONCE to the combined
-- subtotal. Sessions attach DIRECTLY to the CLIENT company (unlike time_entries,
-- whose company_id is the EMPLOYER and which are re-attributed to a client via
-- worker_companies). Approval mirrors time_entries and reuses approval_status.
-- Additive + reversible.

-- 1. Per-worker-per-client flat session fee (mirrors bill_rate_usd: nullable,
--    null/0 ⇒ a $0 session line that the UI flags as "not set").
alter table public.worker_companies add column if not exists session_rate_usd numeric(12,2);

-- 2. service_sessions — one row per visit/session, recorded against the CLIENT.
--    worker_id is nullable + ON DELETE SET NULL so a session survives worker
--    deletion for audit (the same reason invoice_lines snapshots worker_name).
create table if not exists public.service_sessions (
  id              uuid primary key default gen_random_uuid(),
  company_id      uuid not null references public.companies(id) on delete cascade,  -- the CLIENT being billed
  worker_id       uuid references public.workers(id) on delete set null,
  session_date    date not null,
  session_type    text,
  units           integer not null default 1 check (units >= 0),
  case_ref        text,
  notes           text,
  approval        public.approval_status not null default 'pending',
  approved_by     uuid,
  approved_at     timestamptz,
  import_batch_id uuid,
  external_ref    text,
  created_by      uuid default auth.uid(),
  created_at      timestamptz not null default now()
);
create index if not exists service_sessions_company_date_idx on public.service_sessions (company_id, session_date);
create index if not exists service_sessions_worker_idx on public.service_sessions (worker_id);
create index if not exists service_sessions_import_batch_idx
  on public.service_sessions (import_batch_id) where import_batch_id is not null;
-- Idempotent CSV/API imports only; manual entry leaves external_ref null (multiple
-- visits per worker per day are legal, so there is no natural-key unique).
create unique index if not exists service_sessions_external_ref_unq
  on public.service_sessions (company_id, external_ref) where external_ref is not null;

-- RLS — owner, or an admin of the (CLIENT) company. Same shape as time_entries /
-- invoices; my_admin_company_ids() already returns client company ids.
alter table public.service_sessions enable row level security;
drop policy if exists service_sessions_admin_all on public.service_sessions;
create policy service_sessions_admin_all on public.service_sessions for all to authenticated
  using      ((select is_owner()) or company_id in (select unnest(public.my_admin_company_ids())))
  with check ((select is_owner()) or company_id in (select unnest(public.my_admin_company_ids())));

-- 3. Both line kinds on one invoice. amount_usd stays authoritative + snapshotted;
--    hourly lines keep worked_hours/bill_rate_usd (session cols null) and session
--    lines the reverse. Existing rows backfill to kind='hourly' via the default.
alter table public.invoice_lines add column if not exists kind text not null default 'hourly';
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'invoice_lines_kind_chk') then
    alter table public.invoice_lines add constraint invoice_lines_kind_chk check (kind in ('hourly','session'));
  end if;
end $$;
alter table public.invoice_lines add column if not exists sessions_count integer;
alter table public.invoice_lines add column if not exists session_rate_usd numeric(12,2);

-- Rollback:
--   drop policy if exists service_sessions_admin_all on public.service_sessions;
--   drop table if exists public.service_sessions;
--   alter table public.invoice_lines drop constraint if exists invoice_lines_kind_chk;
--   alter table public.invoice_lines drop column if exists session_rate_usd;
--   alter table public.invoice_lines drop column if exists sessions_count;
--   alter table public.invoice_lines drop column if exists kind;
--   alter table public.worker_companies drop column if exists session_rate_usd;
