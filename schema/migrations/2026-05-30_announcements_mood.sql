-- ============================================================================
-- Contractor portal — welcome page: announcements + mood check-in. APPLY TO PROD.
-- ----------------------------------------------------------------------------
-- announcements: admin posts; every contractor reads (global feed).
-- mood_checkins: contractor logs a daily mood (1–5); admin can review.
-- ============================================================================

create table if not exists announcements (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  body         text,
  author       text,
  active       boolean not null default true,
  published_at timestamptz not null default now()
);
alter table announcements enable row level security;
drop policy if exists announcements_read on announcements;
create policy announcements_read on announcements for select to authenticated
  using ( active or is_admin() );
drop policy if exists announcements_admin_write on announcements;
create policy announcements_admin_write on announcements for all to authenticated
  using ( is_admin() ) with check ( is_admin() );

create table if not exists mood_checkins (
  id         uuid primary key default gen_random_uuid(),
  worker_id  uuid references workers(id) on delete cascade,
  mood       int,                       -- 1 (rough) .. 5 (great)
  note       text,
  created_at timestamptz not null default now()
);
alter table mood_checkins enable row level security;
drop policy if exists mood_self_insert on mood_checkins;
create policy mood_self_insert on mood_checkins for insert to authenticated
  with check ( worker_id = my_worker_id() );
drop policy if exists mood_self_read on mood_checkins;
create policy mood_self_read on mood_checkins for select to authenticated
  using ( worker_id = my_worker_id() or is_admin() );
