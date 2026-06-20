-- Contractor self-service session logging. A contractor records their OWN service
-- sessions (as pending) for the clients they're engaged with, from the portal;
-- admins review/approve them in the Service Sessions tab. Builds on
-- 2026-06-20_per_session_billing.sql (service_sessions + admin RLS).

-- The caller's CLIENT engagements, id + name ONLY. Deliberately never returns the
-- bill_rate_usd / session_rate_usd on worker_companies — exposing those to a
-- contractor would leak the business margin. SECURITY DEFINER so it works without
-- granting contractors any read on worker_companies / companies.
create or replace function public.my_clients()
returns table(id uuid, name text)
language sql stable security definer set search_path = public as $$
  select c.id, c.name
  from worker_companies wc
  join companies c on c.id = wc.company_id
  where wc.worker_id = public.my_worker_id()
    and wc.status = 'active'
    and c.kind = 'client'
    and c.status = 'active'
  order by c.name;
$$;
grant execute on function public.my_clients() to authenticated;

-- Contractor RLS on service_sessions. These are PERMISSIVE and OR together with
-- the existing service_sessions_admin_all, so admins keep full access while a
-- contractor may ONLY: read their own sessions; insert a PENDING session for
-- themselves against one of THEIR clients; edit/delete their own still-PENDING
-- sessions. The WITH CHECK pins approval='pending' so a contractor can never
-- self-approve, and company_id ∈ my_clients() so they can never bill a client
-- they aren't engaged with or log for another worker.
drop policy if exists service_sessions_contractor_read on public.service_sessions;
create policy service_sessions_contractor_read on public.service_sessions for select to authenticated
  using ( worker_id = public.my_worker_id() );

drop policy if exists service_sessions_contractor_insert on public.service_sessions;
create policy service_sessions_contractor_insert on public.service_sessions for insert to authenticated
  with check ( worker_id = public.my_worker_id() and approval = 'pending'
               and company_id in (select id from public.my_clients()) );

drop policy if exists service_sessions_contractor_update on public.service_sessions;
create policy service_sessions_contractor_update on public.service_sessions for update to authenticated
  using ( worker_id = public.my_worker_id() and approval = 'pending' )
  with check ( worker_id = public.my_worker_id() and approval = 'pending'
               and company_id in (select id from public.my_clients()) );

drop policy if exists service_sessions_contractor_delete on public.service_sessions;
create policy service_sessions_contractor_delete on public.service_sessions for delete to authenticated
  using ( worker_id = public.my_worker_id() and approval = 'pending' );

-- Rollback:
--   drop policy if exists service_sessions_contractor_delete on public.service_sessions;
--   drop policy if exists service_sessions_contractor_update on public.service_sessions;
--   drop policy if exists service_sessions_contractor_insert on public.service_sessions;
--   drop policy if exists service_sessions_contractor_read on public.service_sessions;
--   drop function if exists public.my_clients();
