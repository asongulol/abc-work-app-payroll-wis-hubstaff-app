-- ============================================================================
-- Onboarding M0 · A2 — onboarding_progress (per-contractor gate state).
-- INERT: no app reads this until M2; the RLS gate that depends on it (A7/A8)
-- ships in later milestones. One row per worker. Idempotent. APPLY TO PROD.
-- Depends on: A1 enums. Apply AFTER A1.
--
-- WRITE MODEL: mutated ONLY by service-role edge functions (portal-sign,
-- portal-self complete_tab, portal-review). There is deliberately NO
-- insert/update/delete RLS policy, so a contractor session can never flip its
-- own completed_at and skip the gate. Contractors (and admins) may only SELECT.
-- ============================================================================
create table if not exists onboarding_progress (
  worker_id          uuid primary key references workers(id) on delete cascade,
  current_stage      onboarding_stage not null default 'stage1_sign',
  stage1_last_kind   agreement_kind,            -- resume point within Stage 1
  stage2_last_tab    text,                      -- resume point within Stage 2
  stage1_complete    boolean not null default false,
  stage2_complete    boolean not null default false,
  stage3_complete    boolean not null default false,
  name_mismatch_flag boolean not null default false,  -- signed name vs profile name
  stalled            boolean not null default false,   -- set by the reminder cron at day 30
  started_at         timestamptz not null default now(),
  completed_at       timestamptz,               -- non-null == fully onboarded (the gate key)
  updated_at         timestamptz not null default now()
);

alter table onboarding_progress enable row level security;

-- Read-only for the owning contractor and for admins. No write policy on purpose.
drop policy if exists onboarding_progress_read on onboarding_progress;
create policy onboarding_progress_read on onboarding_progress
  for select to authenticated
  using ( worker_id = my_worker_id() or is_admin() );

-- VERIFY:
--   select count(*) from onboarding_progress;            -- expect 0 (no backfill yet — that's A7/M1)
--   select policyname, cmd from pg_policies where tablename='onboarding_progress';
