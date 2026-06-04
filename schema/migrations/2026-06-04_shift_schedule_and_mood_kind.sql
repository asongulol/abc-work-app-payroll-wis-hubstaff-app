-- ============================================================================
-- Shift schedule (admin-entered, single daily shift per contractor) + mood
-- check-in phase. The portal mood pop-up now shows only at the START of the
-- shift ("How are you feeling today?") and the END ("Tell me how your day
-- went?"), so we need:
--   workers.shift_start / shift_end  — wall-clock TIME, interpreted as PHT
--                                       (Asia/Manila). May be overnight
--                                       (end < start) for US-hours shifts.
--   mood_checkins.kind               — 'start' | 'end' (null = legacy / generic)
-- All additive + idempotent. Times are nullable; no schedule => the portal
-- falls back to a once-a-day generic check-in.
-- ============================================================================

alter table workers       add column if not exists shift_start time;
alter table workers       add column if not exists shift_end   time;
alter table mood_checkins add column if not exists kind        text;   -- 'start' | 'end'

-- ============================================================================
-- ROLLBACK:
--   alter table workers       drop column if exists shift_start;
--   alter table workers       drop column if exists shift_end;
--   alter table mood_checkins drop column if exists kind;
-- ============================================================================
