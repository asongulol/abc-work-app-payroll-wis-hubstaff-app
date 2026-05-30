-- ============================================================================
-- Contractor portal — profile self-edit (Phase: refinements). APPLY TO PROD.
-- ----------------------------------------------------------------------------
-- Contractors edit a WHITELISTED set of their own profile fields from the
-- portal. Writes go through the portal-self edge function (service role), which
-- enforces the whitelist server-side — contractors get NO direct write RLS on
-- workers. Admin picks which fields are editable via portal_settings.
-- Adds wise_tag (informational handle the contractor supplies; admin still sets
-- the actual Wise recipient — payout destination stays admin-only).
-- ============================================================================

-- informational Wise @tag the contractor provides (admin uses it to set up the
-- real recipient; NOT the payout destination itself)
alter table workers add column if not exists wise_tag text;

-- which profile fields contractors may edit (admin-controlled, single row)
create table if not exists portal_settings (
  id              int primary key default 1,
  editable_fields jsonb not null default '[]'::jsonb,
  updated_at      timestamptz not null default now(),
  constraint portal_settings_singleton check (id = 1)
);
alter table portal_settings enable row level security;

-- any signed-in user may READ the setting (the portal needs to know which
-- fields to show as editable); only admins may WRITE it.
drop policy if exists portal_settings_read on portal_settings;
create policy portal_settings_read on portal_settings for select to authenticated using (true);
drop policy if exists portal_settings_admin_write on portal_settings;
create policy portal_settings_admin_write on portal_settings for all to authenticated
  using (is_admin()) with check (is_admin());

-- seed the admin's chosen default set (contact + name + wallets + wise_tag)
insert into portal_settings (id, editable_fields)
values (1, '["first_name","middle_name","last_name","mobile","ph_address","date_of_birth","gcash","paymaya","paypal","wise_tag"]'::jsonb)
on conflict (id) do nothing;
