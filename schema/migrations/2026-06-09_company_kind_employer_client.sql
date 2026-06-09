-- Employer/client model — Phase A data foundation.
-- Aaron Anderson E.H.S. LLC (company 11111111) is the EMPLOYER (payroll home for
-- every contractor). Ability Builders / 123 Baby Talks / 1 World Realty are CLIENTS
-- (billing tags). Adds a `kind` discriminator, (re)creates the Ability client that
-- the employer-rename consumed, and gives the active employer roster (those not
-- already on another client) an Ability billing link. Additive + reversible.
-- PAY stays employer-level; client links carry bill_rate_usd for invoicing only.

-- 1) kind discriminator (default 'client' is safe: 11111111 is the only employer)
alter table public.companies add column if not exists kind text not null default 'client';
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'companies_kind_chk') then
    alter table public.companies add constraint companies_kind_chk check (kind in ('employer','client'));
  end if;
end $$;
update public.companies set kind = 'employer'
  where id = '11111111-1111-1111-1111-111111111111' and kind <> 'employer';

-- 2) re-create the Ability Builders CLIENT (the rename turned the original row into
--    the employer; this is a fresh client row, NOT a reuse of id 11111111)
insert into public.companies (name, kind)
select 'Ability Builders for Children, LLC', 'client'
where not exists (select 1 from public.companies where name = 'Ability Builders for Children, LLC');

-- 3) billing links: every ACTIVE employer-roster contractor not already on another
--    client gets an Ability client link (bill_rate_usd left null — set in Clients UI).
--    contract/role copied from their employer link. on conflict = idempotent.
insert into public.worker_companies (worker_id, company_id, contract, role, status)
select wc.worker_id,
       (select id from public.companies where name = 'Ability Builders for Children, LLC' limit 1),
       coalesce(wc.contract, 'FT'), wc.role, 'active'
from public.worker_companies wc
join public.workers w on w.id = wc.worker_id
where wc.company_id = '11111111-1111-1111-1111-111111111111'
  and wc.status = 'active' and w.status = 'active'
  and wc.worker_id not in (
    select worker_id from public.worker_companies
    where company_id in ('f7c3025e-b014-4fea-a314-eca00841a533','68f62aa4-4049-4403-863b-a5a1da7cb4ac')
      and status = 'active')
on conflict (worker_id, company_id) do nothing;

-- Rollback:
--   delete from worker_companies wc using companies c
--     where wc.company_id=c.id and c.name='Ability Builders for Children, LLC';
--   delete from companies where name='Ability Builders for Children, LLC';
--   alter table companies drop constraint if exists companies_kind_chk;
--   alter table companies drop column if exists kind;
