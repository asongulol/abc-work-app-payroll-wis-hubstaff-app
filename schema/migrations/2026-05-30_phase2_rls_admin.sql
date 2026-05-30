-- ============================================================================
-- Phase 2 (C1) — real authorization via RLS. APPLIED TO PROD 2026-05-30.
-- ----------------------------------------------------------------------------
-- Replaces the permissive anon/authenticated `using(true)` policies with an
-- allowlist model: only an AUTHENTICATED user whose auth.uid() is in
-- admin_users can touch payroll data. The anon key alone now grants nothing,
-- so it is safe to ship the URL + anon key in the (login-gated) client.
--
-- Auth is Supabase Auth + Google (Phase 1, already live). audit_log previously
-- had only an anon policy, so audit writes failed once login was required —
-- this restores them for the admin.
--
-- Recovery: the service-role key bypasses RLS. Rollback block at the bottom.
-- ============================================================================

-- ---- allowlist + helper ----------------------------------------------------
create table if not exists admin_users (
  user_id  uuid primary key references auth.users(id) on delete cascade,
  email    text unique not null,
  role     text not null default 'admin',
  added_at timestamptz not null default now()
);
alter table admin_users enable row level security;

create or replace function is_admin() returns boolean
  language sql stable security definer set search_path = public as $$
  select exists (select 1 from admin_users where user_id = auth.uid());
$$;

-- admins read the allowlist; writes are service-role-only (no write policy).
drop policy if exists admin_users_read on admin_users;
create policy admin_users_read on admin_users for select to authenticated using (is_admin());

-- seed the single admin (otrinidad@abckidsny.com)
insert into admin_users (user_id, email)
values ('1f4b9091-540c-4a2d-af15-d78611ddf8d7', 'otrinidad@abckidsny.com')
on conflict (user_id) do nothing;

-- ---- swap data-table policies to admin-only --------------------------------
do $$
declare t text;
begin
  foreach t in array array['companies','workers','worker_companies','rates',
                           'pay_periods','time_entries','payments','documents']
  loop
    execute format('drop policy if exists %I_admin_all on %I;', t, t);
    execute format('drop policy if exists %I_anon_all on %I;', t, t);
    execute format('create policy %I_admin_all on %I for all to authenticated using (is_admin()) with check (is_admin());', t, t);
  end loop;
end$$;

-- audit_log: was anon-only; give admin full access (fixes audit logging), drop anon.
drop policy if exists audit_log_anon_all on audit_log;
drop policy if exists audit_log_admin_all on audit_log;
create policy audit_log_admin_all on audit_log for all to authenticated using (is_admin()) with check (is_admin());

-- api_tokens intentionally left with RLS on and no policy => service-role only.

-- ============================================================================
-- ROLLBACK (restore the original permissive access):
-- begin;
-- do $$ declare t text; begin
--   foreach t in array array['companies','workers','worker_companies','rates',
--                            'pay_periods','time_entries','payments','documents'] loop
--     execute format('drop policy if exists %I_admin_all on %I;', t, t);
--     execute format('create policy %I_admin_all on %I for all to authenticated using (true) with check (true);', t, t);
--     execute format('create policy %I_anon_all on %I for all to anon using (true) with check (true);', t, t);
--   end loop; end$$;
-- drop policy if exists audit_log_admin_all on audit_log;
-- create policy audit_log_anon_all on audit_log for all to anon using (true) with check (true);
-- commit;
-- ============================================================================
