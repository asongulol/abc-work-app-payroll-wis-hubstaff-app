-- RLS performance: make helper evaluation once-per-query (InitPlan) and the admin
-- branch index-eligible on the heavy money/time tables (time_entries ~10.5k,
-- payments ~1.1k, pay_periods). Behavior-preserving — every rewritten predicate is
-- logically equivalent to the original; verified by per-role (owner / non-owner
-- scoped admin / onboarded contractor) row-predicate diff = 0 on live data, and by
-- EXPLAIN (owner time_entries read 1,297 ms -> ~3 ms).
--
-- Equivalence:
--   is_company_admin(cid)            == is_owner() OR exists(admin_companies match)
--   (select is_owner()) OR cid in (select unnest(my_admin_company_ids()))   -- same set
-- The (select ...) wrapping turns the column-less helpers (is_owner, is_onboarded,
-- my_worker_id) into cached InitPlans; the company-id set lets the admin branch use
-- an index instead of a per-row SubPlan (helps the non-owner scoped admins too).
--
-- Rollback: restore the original quals (kept verbatim at the bottom of this file).

-- 1. The calling admin's company set (once-per-query; ORed with owner = all).
create or replace function public.my_admin_company_ids()
returns uuid[] language sql stable security definer set search_path to 'public' as $$
  select coalesce(array(
    select ac.company_id from admin_companies ac
    where lower(ac.admin_email) = (select lower(email) from admin_users where user_id = auth.uid())
  ), '{}'::uuid[]);
$$;

-- 2. time_entries
drop policy if exists time_entries_admin_all on public.time_entries;
create policy time_entries_admin_all on public.time_entries for all to authenticated
  using       ((select is_owner()) or company_id in (select unnest(public.my_admin_company_ids())))
  with check  ((select is_owner()) or company_id in (select unnest(public.my_admin_company_ids())));
drop policy if exists time_entries_contractor_read on public.time_entries;
create policy time_entries_contractor_read on public.time_entries for select to authenticated
  using ((worker_id = (select my_worker_id())) and (select is_onboarded()));

-- 3. payments
drop policy if exists payments_admin_all on public.payments;
create policy payments_admin_all on public.payments for all to authenticated
  using       ((select is_owner()) or company_id in (select unnest(public.my_admin_company_ids())))
  with check  ((select is_owner()) or company_id in (select unnest(public.my_admin_company_ids())));
drop policy if exists payments_contractor_read on public.payments;
create policy payments_contractor_read on public.payments for select to authenticated
  using ((worker_id = (select my_worker_id())) and (select is_onboarded()));

-- 4. pay_periods
drop policy if exists pay_periods_admin_all on public.pay_periods;
create policy pay_periods_admin_all on public.pay_periods for all to authenticated
  using       ((select is_owner()) or company_id in (select unnest(public.my_admin_company_ids())))
  with check  ((select is_owner()) or company_id in (select unnest(public.my_admin_company_ids())));
drop policy if exists pay_periods_contractor_read on public.pay_periods;
create policy pay_periods_contractor_read on public.pay_periods for select to authenticated
  using (((select my_worker_id()) is not null) and (select is_onboarded()));

-- ---------------------------------------------------------------------------
-- ROLLBACK (run to revert):
--   drop policy if exists time_entries_admin_all on public.time_entries;
--   create policy time_entries_admin_all on public.time_entries for all to authenticated
--     using (is_company_admin(company_id)) with check (is_company_admin(company_id));
--   drop policy if exists time_entries_contractor_read on public.time_entries;
--   create policy time_entries_contractor_read on public.time_entries for select to authenticated
--     using ((worker_id = my_worker_id()) and is_onboarded());
--   drop policy if exists payments_admin_all on public.payments;
--   create policy payments_admin_all on public.payments for all to authenticated
--     using (is_company_admin(company_id)) with check (is_company_admin(company_id));
--   drop policy if exists payments_contractor_read on public.payments;
--   create policy payments_contractor_read on public.payments for select to authenticated
--     using ((worker_id = my_worker_id()) and is_onboarded());
--   drop policy if exists pay_periods_admin_all on public.pay_periods;
--   create policy pay_periods_admin_all on public.pay_periods for all to authenticated
--     using (is_company_admin(company_id)) with check (is_company_admin(company_id));
--   drop policy if exists pay_periods_contractor_read on public.pay_periods;
--   create policy pay_periods_contractor_read on public.pay_periods for select to authenticated
--     using ((my_worker_id() is not null) and is_onboarded());
--   -- drop function if exists public.my_admin_company_ids();
