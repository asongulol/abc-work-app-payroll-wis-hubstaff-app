-- Bulk-set activity_pct on existing time_entries by id, for the hubstaff-sync
-- `activity_backfill` action. Updates ONLY activity_pct — never touches hours,
-- approval, pay_period, or anything else; never inserts a row (a PostgREST upsert
-- can't do this, as its INSERT branch violates NOT NULL on the omitted columns).
-- Service-role only (the edge function). Applied to production 2026-06-06 via MCP.
create or replace function public.set_time_entry_activity(p jsonb)
  returns integer language plpgsql security definer set search_path to 'public'
as $$
declare n integer;
begin
  update public.time_entries t
     set activity_pct = (u->>'activity_pct')::numeric
    from jsonb_array_elements(p) u
   where t.id = (u->>'id')::uuid;
  get diagnostics n = row_count;
  return n;
end;
$$;
revoke all on function public.set_time_entry_activity(jsonb) from public, anon, authenticated;
grant execute on function public.set_time_entry_activity(jsonb) to service_role;
