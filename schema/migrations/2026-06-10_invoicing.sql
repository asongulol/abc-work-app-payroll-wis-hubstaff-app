-- Phase 4 — client invoicing/billing. Clients are invoiced for WORKED hours per
-- client × a contracted USD bill rate (PTO is the employer's cost, never billed).
-- Additive + reversible. Verified via rolled-back dry-run on prod 2026-06-09:
-- 23.5 worked h × $12.50 = $293.75, PTO excluded.

-- USD/hour bill rate per contractor-client engagement (what Aaron Anderson charges
-- the client for this contractor's work). Distinct from the contractor's PHP pay rate.
alter table public.worker_companies add column if not exists bill_rate_usd numeric(12,2);

create table if not exists public.invoices (
  id            uuid primary key default gen_random_uuid(),
  company_id    uuid not null references public.companies(id) on delete cascade,  -- the CLIENT
  period_start  date not null,
  period_end    date not null,
  pay_date      date,
  invoice_no    text,
  status        text not null default 'draft',   -- draft | sent | paid | void
  subtotal_usd  numeric(14,2) not null default 0,
  total_usd     numeric(14,2) not null default 0,
  markup_pct    numeric(6,2) not null default 0,  -- hook; 0 = pass-through hours×rate
  currency      text not null default 'USD',
  notes         text,
  created_by    uuid,
  created_at    timestamptz not null default now()
);
create index if not exists invoices_company_period_idx on public.invoices (company_id, period_start, period_end);
-- one LIVE (non-void) invoice per client+period; void+regenerate allowed
create unique index if not exists invoices_one_live_per_period
  on public.invoices (company_id, period_start, period_end) where status <> 'void';

create table if not exists public.invoice_lines (
  id            uuid primary key default gen_random_uuid(),
  invoice_id    uuid not null references public.invoices(id) on delete cascade,
  worker_id     uuid references public.workers(id) on delete set null,
  worker_name   text,
  position      text,                                   -- the engagement role at invoice time
  worked_hours  numeric(10,2) not null default 0,
  bill_rate_usd numeric(12,2) not null default 0,
  amount_usd    numeric(14,2) not null default 0
);
create index if not exists invoice_lines_invoice_idx on public.invoice_lines (invoice_id);

alter table public.invoices      enable row level security;
alter table public.invoice_lines enable row level security;
drop policy if exists invoices_admin_all on public.invoices;
create policy invoices_admin_all on public.invoices for all to authenticated
  using      ((select is_owner()) or company_id in (select unnest(public.my_admin_company_ids())))
  with check ((select is_owner()) or company_id in (select unnest(public.my_admin_company_ids())));
drop policy if exists invoice_lines_admin_all on public.invoice_lines;
create policy invoice_lines_admin_all on public.invoice_lines for all to authenticated
  using      ((select is_owner()) or exists (select 1 from public.invoices i where i.id = invoice_id and ((select is_owner()) or i.company_id in (select unnest(public.my_admin_company_ids())))))
  with check ((select is_owner()) or exists (select 1 from public.invoices i where i.id = invoice_id and ((select is_owner()) or i.company_id in (select unnest(public.my_admin_company_ids())))));

-- sequential invoice numbers per year (race-safe)
create or replace function public.allocate_invoice_no(p_year int)
returns text language plpgsql security definer set search_path to 'public' as $$
declare n int;
begin
  select count(*) + 1 into n from public.invoices where extract(year from created_at) = p_year and status <> 'void';
  return p_year::text || '-' || lpad(n::text, 4, '0');
end $$;

-- Rollback:
--   drop table if exists public.invoice_lines;
--   drop table if exists public.invoices;
--   drop function if exists public.allocate_invoice_no(int);
--   alter table public.worker_companies drop column if exists bill_rate_usd;
