-- Admin-user management: tiered roles + guardrails + the admin-manage helpers.
-- Reflects the FINAL state applied to production 2026-06-06 (applied via MCP in
-- three steps: roles, lookup helper, guard hardening — consolidated here).
--   'owner' — can add / remove / re-role admins (manages the admin list)
--   'admin' — full app access, but cannot manage the admin list

alter table public.admin_users
  add column if not exists added_by uuid references auth.users(id) on delete set null;

-- bootstrap: promote the sole existing admin to owner (there was one)
update public.admin_users set role = 'owner' where lower(email) = 'otrinidad@abckidsny.com';

alter table public.admin_users drop constraint if exists admin_users_role_check;
alter table public.admin_users add constraint admin_users_role_check check (role in ('owner','admin'));

-- only owners manage admins (also re-checked server-side in admin-manage)
create or replace function public.is_owner() returns boolean
  language sql stable security definer set search_path to 'public'
as $$ select exists (select 1 from public.admin_users where user_id = auth.uid() and role = 'owner'); $$;

-- There must always be at least one owner. A per-row AFTER trigger checks the
-- POST-statement owner count, so it catches single- and multi-row UPDATE/DELETE
-- and cascade deletes (a per-row BEFORE trigger could be bypassed by a multi-row
-- demote). TRUNCATE is blocked separately (row triggers don't fire on TRUNCATE).
create or replace function public.admin_users_owner_check() returns trigger
  language plpgsql security definer set search_path to 'public'
as $$
begin
  if (select count(*) from public.admin_users where role = 'owner') = 0 then
    raise exception 'cannot remove or demote the last owner';
  end if;
  return null;
end;
$$;
drop trigger if exists admin_users_guard_trg on public.admin_users;     -- old per-row BEFORE guard
drop function if exists public.admin_users_guard();
create trigger admin_users_owner_check_trg
  after update or delete on public.admin_users
  for each row execute function public.admin_users_owner_check();

create or replace function public.admin_users_no_truncate() returns trigger
  language plpgsql as $$ begin raise exception 'truncate on admin_users is not allowed'; end; $$;
drop trigger if exists admin_users_no_truncate_trg on public.admin_users;
create trigger admin_users_no_truncate_trg
  before truncate on public.admin_users
  for each statement execute function public.admin_users_no_truncate();

-- Service-role-only helper: find an auth user's id by email (admin-manage's
-- sign-in-first add flow). Locked down so anon/authenticated can't call it
-- (prevents email enumeration); only the edge function (service_role) may.
create or replace function public.admin_lookup_auth_user(p_email text)
  returns uuid language sql security definer set search_path to 'public' stable
as $$ select id from auth.users where lower(email) = lower(p_email) limit 1; $$;
revoke all on function public.admin_lookup_auth_user(text) from public, anon, authenticated;
grant execute on function public.admin_lookup_auth_user(text) to service_role;

-- RLS unchanged: admin_users SELECT = is_admin(); no client write policy. Defense
-- in depth — revoke the default table write grants (writes go only through the
-- service-role admin-manage edge function, which bypasses grants/RLS).
revoke insert, update, delete, truncate, references on public.admin_users from anon, authenticated;
