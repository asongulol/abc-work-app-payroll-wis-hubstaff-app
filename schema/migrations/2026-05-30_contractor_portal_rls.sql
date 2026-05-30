-- ============================================================================
-- Contractor self-service portal — Phase A foundation. APPLIED TO PROD 2026-05-30.
-- ----------------------------------------------------------------------------
-- Lets a contractor log in (email+password, Supabase Auth) and read ONLY their
-- own pay/time/documents. ADDITIVE: these read-only policies sit beside the
-- admin is_admin() policies, so admin access is unchanged. Verified by
-- simulation: a contractor session saw 38 of their own payment rows and
-- exactly 1 distinct worker (no cross-contractor leakage).
-- ============================================================================

create table if not exists contractor_logins (
  worker_id     uuid primary key references workers(id) on delete cascade,
  auth_user_id  uuid unique references auth.users(id) on delete set null,
  email         text,
  status        text not null default 'active',   -- active | revoked
  created_at    timestamptz not null default now(),
  last_login_at timestamptz
);
alter table contractor_logins enable row level security;

-- worker_id for the current contractor session (NULL for admins/anon).
create or replace function my_worker_id() returns uuid
  language sql stable security definer set search_path = public as $$
  select worker_id from contractor_logins
   where auth_user_id = auth.uid() and status = 'active' limit 1;
$$;

drop policy if exists contractor_logins_self on contractor_logins;
create policy contractor_logins_self on contractor_logins for select to authenticated
  using ( auth_user_id = auth.uid() or is_admin() );

-- read-only, self-scoped (beside the admin_all policies; permissive OR)
drop policy if exists payments_contractor_read on payments;
create policy payments_contractor_read on payments for select to authenticated
  using ( worker_id = my_worker_id() );

drop policy if exists time_entries_contractor_read on time_entries;
create policy time_entries_contractor_read on time_entries for select to authenticated
  using ( worker_id = my_worker_id() );

-- own docs, excluding internal 'other'
drop policy if exists documents_contractor_read on documents;
create policy documents_contractor_read on documents for select to authenticated
  using ( worker_id = my_worker_id() and kind <> 'other' );

drop policy if exists workers_contractor_read on workers;
create policy workers_contractor_read on workers for select to authenticated
  using ( id = my_worker_id() );

-- period dates aren't sensitive; needed when a pay slip shows its period.
drop policy if exists pay_periods_contractor_read on pay_periods;
create policy pay_periods_contractor_read on pay_periods for select to authenticated
  using ( my_worker_id() is not null );

-- Writes for contractors: NONE (no insert/update/delete policies). The portal
-- is read-only. contractor_logins is written only by the service role (the
-- portal-admin edge function) — no write policy here.
