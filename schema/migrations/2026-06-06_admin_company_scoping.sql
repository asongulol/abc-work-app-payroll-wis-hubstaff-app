-- 2026-06-06 — Admin → company scoping (FULL RLS enforcement, incl. worker PII)
--
-- Owners can assign non-owner admins to one or more companies. A scoped admin
-- can only see/touch data for their assigned companies; the OWNER sees and does
-- everything. Secure default: a non-owner admin with NO assignment sees nothing.
--
-- Mechanism:
--   admin_companies(admin_email, company_id)  -- email-keyed so it also covers a
--                                                pending invite (carries over on
--                                                first sign-in)
--   is_company_admin(cid)      = is_owner() OR caller assigned to cid
--   admin_can_see_worker(wid)  = is_owner() OR caller assigned to a company that
--                                worker is linked to (worker_companies)
-- Then every ADMIN rls policy on a company- or worker-scoped table is rewritten
-- from is_admin() to the scoped helper. CONTRACTOR (my_worker_id) policies are
-- LEFT UNTOUCHED. The owner passes every check via is_owner() inside the helpers,
-- so the current owner + all contractors are unaffected (and there are no
-- non-owner admins yet, so nothing changes for anyone until one is assigned).
--
-- Global-config tables (agreement_templates, announcements, portal_settings,
-- admin_users, pending_admins) are NOT company data and stay is_admin()/is_owner().
--
-- Reversible: rollback at the bottom restores the is_admin() policies verbatim.

begin;

-- 1. Assignment table (email-keyed) -----------------------------------------
create table if not exists admin_companies (
  admin_email text not null,
  company_id  uuid not null references companies(id) on delete cascade,
  added_at    timestamptz not null default now(),
  added_by    uuid,
  primary key (admin_email, company_id)
);
create index if not exists admin_companies_email_idx on admin_companies (lower(admin_email));
alter table admin_companies enable row level security;
drop policy if exists admin_companies_owner_all on admin_companies;
create policy admin_companies_owner_all on admin_companies for all to authenticated
  using (is_owner()) with check (is_owner());
drop policy if exists admin_companies_read_self on admin_companies;
create policy admin_companies_read_self on admin_companies for select to authenticated
  using (lower(admin_email) = (select lower(email) from admin_users where user_id = auth.uid()));

-- 2. Helpers (SECURITY DEFINER, search_path pinned) -------------------------
create or replace function is_company_admin(cid uuid) returns boolean
  language sql stable security definer set search_path = public as $$
  select is_owner() or (cid is not null and exists (
    select 1 from admin_companies ac
    where ac.company_id = cid
      and lower(ac.admin_email) = (select lower(email) from admin_users where user_id = auth.uid())
  ));
$$;

create or replace function admin_can_see_worker(wid uuid) returns boolean
  language sql stable security definer set search_path = public as $$
  select is_owner() or (wid is not null and exists (
    select 1 from worker_companies wc
    where wc.worker_id = wid and is_company_admin(wc.company_id)
  ));
$$;

-- 3. workers.created_by — lets a scoped admin read back a worker they JUST
--    created (before it is linked to a company), so INSERT…RETURNING under RLS
--    doesn't break Add-Contractor / Bulk-Import. Defaults to the inserting admin.
alter table workers add column if not exists created_by uuid default auth.uid();

-- 4. company_id-scoped tables: is_admin() → is_company_admin(company_id) -----
drop policy if exists companies_admin_all on companies;
create policy companies_admin_all on companies for all to authenticated
  using (is_company_admin(id)) with check (is_company_admin(id));

drop policy if exists audit_log_admin_all on audit_log;
create policy audit_log_admin_all on audit_log for all to authenticated
  using (is_company_admin(company_id)) with check (is_company_admin(company_id));

drop policy if exists documents_admin_all on documents;
create policy documents_admin_all on documents for all to authenticated
  using (is_company_admin(company_id)) with check (is_company_admin(company_id));

drop policy if exists pay_periods_admin_all on pay_periods;
create policy pay_periods_admin_all on pay_periods for all to authenticated
  using (is_company_admin(company_id)) with check (is_company_admin(company_id));

drop policy if exists payments_admin_all on payments;
create policy payments_admin_all on payments for all to authenticated
  using (is_company_admin(company_id)) with check (is_company_admin(company_id));

drop policy if exists rates_admin_all on rates;
create policy rates_admin_all on rates for all to authenticated
  using (is_company_admin(company_id)) with check (is_company_admin(company_id));

drop policy if exists time_entries_admin_all on time_entries;
create policy time_entries_admin_all on time_entries for all to authenticated
  using (is_company_admin(company_id)) with check (is_company_admin(company_id));

drop policy if exists worker_companies_admin_all on worker_companies;
create policy worker_companies_admin_all on worker_companies for all to authenticated
  using (is_company_admin(company_id)) with check (is_company_admin(company_id));

-- 5. worker-scoped tables: is_admin() → admin_can_see_worker(worker_id) ------
-- workers: SPLIT so INSERT is allowed for any admin (they link to their company
-- in the very next statement); SELECT/UPDATE also allow the creator to see the
-- row they just inserted (created_by) so INSERT…RETURNING works.
drop policy if exists workers_admin_all on workers;
create policy workers_admin_select on workers for select to authenticated
  using (admin_can_see_worker(id) or created_by = auth.uid());
create policy workers_admin_insert on workers for insert to authenticated
  with check (is_admin());
create policy workers_admin_update on workers for update to authenticated
  using (admin_can_see_worker(id) or created_by = auth.uid())
  with check (admin_can_see_worker(id) or created_by = auth.uid());
create policy workers_admin_delete on workers for delete to authenticated
  using (admin_can_see_worker(id));

drop policy if exists contractor_logins_self on contractor_logins;
create policy contractor_logins_self on contractor_logins for select to authenticated
  using (auth_user_id = auth.uid() or admin_can_see_worker(worker_id));

drop policy if exists onboarding_progress_read on onboarding_progress;
create policy onboarding_progress_read on onboarding_progress for select to authenticated
  using (worker_id = my_worker_id() or admin_can_see_worker(worker_id));
drop policy if exists onboarding_progress_admin_write on onboarding_progress;
create policy onboarding_progress_admin_write on onboarding_progress for all to authenticated
  using (admin_can_see_worker(worker_id)) with check (admin_can_see_worker(worker_id));

drop policy if exists onboarding_agreements_admin_all on onboarding_agreements;
create policy onboarding_agreements_admin_all on onboarding_agreements for all to authenticated
  using (admin_can_see_worker(worker_id)) with check (admin_can_see_worker(worker_id));

drop policy if exists onboarding_signatures_read on onboarding_signatures;
create policy onboarding_signatures_read on onboarding_signatures for select to authenticated
  using (worker_id = my_worker_id() or admin_can_see_worker(worker_id));

drop policy if exists mood_self_read on mood_checkins;
create policy mood_self_read on mood_checkins for select to authenticated
  using (worker_id = my_worker_id() or admin_can_see_worker(worker_id));

drop policy if exists portal_notifications_read on portal_notifications;
create policy portal_notifications_read on portal_notifications for select to authenticated
  using (worker_id = my_worker_id() or admin_can_see_worker(worker_id));

commit;

-- ============================================================================
-- VERIFY (after commit): pick a scoped admin and confirm isolation in the app.
--   select proname, proconfig from pg_proc where proname in ('is_company_admin','admin_can_see_worker');
--   select tablename, policyname, qual from pg_policies where schemaname='public' order by 1,2;
--
-- ROLLBACK (restore the is_admin() policies verbatim):
-- begin;
--   drop policy if exists admin_companies_owner_all on admin_companies;
--   drop policy if exists admin_companies_read_self on admin_companies;
--   -- (leave admin_companies table in place, or: drop table admin_companies;)
--   create or replace function is_company_admin(uuid) returns boolean language sql stable security definer set search_path=public as $$ select is_admin() $$;
--   create or replace function admin_can_see_worker(uuid) returns boolean language sql stable security definer set search_path=public as $$ select is_admin() $$;
--   -- ^ neutralize helpers to is_admin() so all scoped policies revert to old behavior, OR restore each policy explicitly:
--   drop policy if exists companies_admin_all on companies;     create policy companies_admin_all on companies for all to authenticated using (is_admin()) with check (is_admin());
--   drop policy if exists audit_log_admin_all on audit_log;     create policy audit_log_admin_all on audit_log for all to authenticated using (is_admin()) with check (is_admin());
--   drop policy if exists documents_admin_all on documents;     create policy documents_admin_all on documents for all to authenticated using (is_admin()) with check (is_admin());
--   drop policy if exists pay_periods_admin_all on pay_periods; create policy pay_periods_admin_all on pay_periods for all to authenticated using (is_admin()) with check (is_admin());
--   drop policy if exists payments_admin_all on payments;       create policy payments_admin_all on payments for all to authenticated using (is_admin()) with check (is_admin());
--   drop policy if exists rates_admin_all on rates;             create policy rates_admin_all on rates for all to authenticated using (is_admin()) with check (is_admin());
--   drop policy if exists time_entries_admin_all on time_entries; create policy time_entries_admin_all on time_entries for all to authenticated using (is_admin()) with check (is_admin());
--   drop policy if exists worker_companies_admin_all on worker_companies; create policy worker_companies_admin_all on worker_companies for all to authenticated using (is_admin()) with check (is_admin());
--   drop policy if exists workers_admin_select on workers; drop policy if exists workers_admin_insert on workers; drop policy if exists workers_admin_update on workers; drop policy if exists workers_admin_delete on workers;
--   create policy workers_admin_all on workers for all to authenticated using (is_admin()) with check (is_admin());
--   drop policy if exists contractor_logins_self on contractor_logins; create policy contractor_logins_self on contractor_logins for select to authenticated using (auth_user_id = auth.uid() or is_admin());
--   drop policy if exists onboarding_progress_read on onboarding_progress; create policy onboarding_progress_read on onboarding_progress for select to authenticated using (worker_id = my_worker_id() or is_admin());
--   drop policy if exists onboarding_progress_admin_write on onboarding_progress; create policy onboarding_progress_admin_write on onboarding_progress for all to authenticated using (is_admin()) with check (is_admin());
--   drop policy if exists onboarding_agreements_admin_all on onboarding_agreements; create policy onboarding_agreements_admin_all on onboarding_agreements for all to authenticated using (is_admin()) with check (is_admin());
--   drop policy if exists onboarding_signatures_read on onboarding_signatures; create policy onboarding_signatures_read on onboarding_signatures for select to authenticated using (worker_id = my_worker_id() or is_admin());
--   drop policy if exists mood_self_read on mood_checkins; create policy mood_self_read on mood_checkins for select to authenticated using (worker_id = my_worker_id() or is_admin());
--   drop policy if exists portal_notifications_read on portal_notifications; create policy portal_notifications_read on portal_notifications for select to authenticated using (worker_id = my_worker_id() or is_admin());
-- commit;
-- ============================================================================
