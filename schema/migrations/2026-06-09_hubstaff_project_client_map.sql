-- Phase A of multi-client support: map Hubstaff PROJECTS → CLIENT companies, so
-- cron_ingest can attribute each worker's tracked time to the right client (the
-- employer org "Aaron Anderson" has one Hubstaff org; projects within it = clients).
-- Additive + reversible. RLS scopes rows to the admin's client companies (owner all),
-- reusing my_admin_company_ids() from 2026-06-08_rls_perf_money_tables.sql.

create table if not exists public.hubstaff_projects (
  hubstaff_project_id bigint primary key,           -- Hubstaff project id
  company_id          uuid not null references public.companies(id) on delete cascade,  -- the CLIENT
  name                text,                          -- project name snapshot (display)
  org_id              bigint,                        -- Hubstaff org the project belongs to
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);
create index if not exists hubstaff_projects_company_id_idx on public.hubstaff_projects(company_id);

alter table public.hubstaff_projects enable row level security;

drop policy if exists hubstaff_projects_admin_all on public.hubstaff_projects;
create policy hubstaff_projects_admin_all on public.hubstaff_projects for all to authenticated
  using       ((select is_owner()) or company_id in (select unnest(public.my_admin_company_ids())))
  with check  ((select is_owner()) or company_id in (select unnest(public.my_admin_company_ids())));

-- Rollback:
--   drop table if exists public.hubstaff_projects;
