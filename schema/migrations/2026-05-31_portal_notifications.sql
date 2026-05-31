-- ============================================================================
-- Onboarding M0 · E.2 — portal_notifications (in-portal banner stack).
-- INERT: written by edge fns (M4); read by the portal banner (M2/E.9). Nothing
-- surfaces until then. Idempotent. APPLY TO PROD. Depends on: workers.
--
-- WRITE MODEL: rows are INSERTed by service-role edge fns only (no contractor
-- INSERT policy). A contractor may read their own undismissed notifications and
-- UPDATE their own row to set dismissed_at.
--
-- Depends on: A1 enums (portal_notification_kind) — created in the enums file so
-- this file only USES the type. Run A1 (and let it commit) before this.
-- ============================================================================
create table if not exists portal_notifications (
  id           uuid primary key default gen_random_uuid(),
  worker_id    uuid not null references workers(id) on delete cascade,
  kind         portal_notification_kind not null,
  title        text not null,
  body         text,                       -- e.g. the verbatim needs_replacement reason
  created_at   timestamptz not null default now(),
  dismissed_at timestamptz
);

-- Partial index for the common read (own, undismissed, newest-first).
create index if not exists portal_notifications_open_idx
  on portal_notifications (worker_id, created_at desc) where dismissed_at is null;

alter table portal_notifications enable row level security;

-- Read own (or admin). No INSERT policy => service-role only.
drop policy if exists portal_notifications_read on portal_notifications;
create policy portal_notifications_read on portal_notifications
  for select to authenticated
  using ( worker_id = my_worker_id() or is_admin() );

-- Dismiss own: the app only ever sets dismissed_at; scoped to the caller's rows.
drop policy if exists portal_notifications_dismiss on portal_notifications;
create policy portal_notifications_dismiss on portal_notifications
  for update to authenticated
  using ( worker_id = my_worker_id() )
  with check ( worker_id = my_worker_id() );

-- VERIFY:
--   select count(*) from portal_notifications;           -- expect 0
--   select policyname, cmd from pg_policies where tablename='portal_notifications';
