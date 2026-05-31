-- ============================================================================
-- Onboarding M0 · E.3 — onboarding_reminders (sent-reminder log, dedupe source).
-- INERT: written/read only by the onboarding-reminders cron (M4). Prevents
-- double-sending a reminder for the same cadence bucket. Idempotent.
-- APPLY TO PROD. Depends on: A1 enums (onboarding_stage), workers.
--
-- WRITE MODEL: service-role only. RLS is ENABLED with NO policy, so only the
-- service role (which bypasses RLS) can read/write — contractors and admins
-- have no access (this is an internal operational log).
-- ============================================================================
create table if not exists onboarding_reminders (
  id            uuid primary key default gen_random_uuid(),
  worker_id     uuid not null references workers(id) on delete cascade,
  stage_at_send onboarding_stage not null,   -- stage the contractor was on when nudged
  reminder_day  int not null,                -- cadence bucket (e.g. 2,5,9,14,21,28)
  channel       text,                        -- 'email' | 'banner'
  sent_at       timestamptz not null default now()
);

create index if not exists onboarding_reminders_worker_idx on onboarding_reminders (worker_id);

-- Lock it down: RLS on, no policy => service-role only.
alter table onboarding_reminders enable row level security;

-- VERIFY:
--   select count(*) from onboarding_reminders;           -- expect 0
--   select relrowsecurity from pg_class where relname='onboarding_reminders';  -- expect t
