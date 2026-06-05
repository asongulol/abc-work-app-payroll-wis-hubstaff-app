-- Pre-add admins by email (before they've ever signed in). An owner adds an
-- email to pending_admins; a trigger on auth.users promotes them into
-- admin_users with the chosen role the moment they first sign in with Google.
-- This avoids depending on OAuth identity auto-linking (unreliable). Applied to
-- production 2026-06-06 via MCP.

create table if not exists public.pending_admins (
  email      text primary key,
  role       text not null default 'admin' check (role in ('owner','admin')),
  added_by   uuid references auth.users(id) on delete set null,
  added_at   timestamptz not null default now()
);
alter table public.pending_admins enable row level security;
drop policy if exists pending_admins_read on public.pending_admins;
create policy pending_admins_read on public.pending_admins for select using (public.is_owner());
revoke insert, update, delete, truncate on public.pending_admins from anon, authenticated;

-- Bind a pending admin to their auth user on first sign-in (OAuth INSERTs the
-- auth.users row). Wrapped so it can never block a sign-in.
create or replace function public.bind_pending_admin() returns trigger
  language plpgsql security definer set search_path to 'public'
as $$
declare p record;
begin
  begin
    select * into p from public.pending_admins where lower(email) = lower(new.email) limit 1;
    if found then
      insert into public.admin_users (user_id, email, role, added_by)
        values (new.id, lower(new.email), p.role, p.added_by)
        on conflict do nothing;
      delete from public.pending_admins where lower(email) = lower(new.email);
    end if;
  exception when others then
    null;   -- never block a sign-in because of admin binding
  end;
  return new;
end;
$$;
drop trigger if exists bind_pending_admin_trg on auth.users;
create trigger bind_pending_admin_trg after insert on auth.users
  for each row execute function public.bind_pending_admin();
