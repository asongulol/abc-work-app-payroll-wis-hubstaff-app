# Design — Real Auth + RLS (the C1 rewrite)

> Status: **design only**. This document describes how to move the app from its
> current anon-key model to real Supabase Auth with scoped RLS. **It must be
> executed on a staging Supabase project first** — deploying it blind on the
> production payroll DB can lock the admin out. See §7.

Related work already in flight:
- **`feature/google-login`** — the *login gate* (Phase 1 below): Google sign-in
  in front of the app, real `audit_log.actor`, but data access still uses the
  anon key. Low risk; ships independently.
- This doc covers **Phase 2** (the actual security boundary: scoped RLS).

---

## 1. Why

Today (`app/index.html`):
- The app stores the Supabase **anon key** in `localStorage`
  (`sb_url` / `sb_anon`) and creates the client with it.
- **Every RLS policy is `using(true) with check(true)`** — so the anon key is a
  master key. Anyone with the key (or DevTools on a machine where the app has
  been used) can read or rewrite the entire payroll DB via the REST API.
- `audit_log.actor` is hardcoded `"admin"` — there is no identity, so the audit
  trail can't answer "who did this".

The goal: a real identity per user, and RLS that only lets **authorized** users
touch payroll data — without locking the admin out during the switch.

---

## 2. Target model

1. **Authentication:** Supabase Auth with the **Google** provider (magic-link or
   password as fallback). Sessions are managed by `supabase-js`
   (`persistSession`, `detectSessionInUrl`).
2. **Authorization:** an **allowlist** — Google sign-in lets *anyone* with a
   Google account authenticate, so access is granted by an `admin_users` table
   keyed on the authenticated user, not by the act of signing in.
3. **RLS:** replace the permissive policies with policies that grant access only
   to `auth.uid()`s present in `admin_users` (single-admin today; ready for more).
4. **Audit:** `audit_log.actor` is populated from `auth.email()` (DB default) or
   the session email (client), not a constant.

---

## 3. Schema additions

```sql
-- Who is allowed into the admin app. Seed your own row BEFORE enabling RLS (§7).
create table if not exists admin_users (
  user_id   uuid primary key references auth.users(id) on delete cascade,
  email     text unique not null,
  role      text not null default 'admin',     -- admin | viewer (future)
  added_at  timestamptz not null default now()
);

-- Helper: is the current caller an allowed admin?
create or replace function is_admin() returns boolean
  language sql stable security definer set search_path = public as $$
  select exists (select 1 from admin_users where user_id = auth.uid());
$$;

-- Audit actor defaults to the signed-in email when the client doesn't set it.
alter table audit_log alter column actor set default auth.email();
```

> `is_admin()` is `security definer` so the policy check can read `admin_users`
> regardless of that table's own RLS. Keep `admin_users` itself locked to
> `is_admin()` reads and service-role writes.

---

## 4. RLS policies (the boundary)

For **every** payroll table (`workers`, `worker_companies`, `rates`,
`pay_periods`, `time_entries`, `payments`, `documents`, `audit_log`, …):

```sql
-- 1. drop the permissive policy
drop policy if exists "<existing permissive policy>" on <table>;

-- 2. add an admin-scoped policy
create policy admin_all on <table>
  for all to authenticated
  using ( is_admin() )
  with check ( is_admin() );
```

Generate these programmatically from a table list rather than hand-writing each.
`audit_log` stays insert-allowed for admins; consider blocking `update`/`delete`
on it entirely (append-only) for tamper-evidence.

When the **contractor self-service portal** lands, add *narrow* per-contractor
read policies alongside (scoped to a `contractor_logins` mapping) — see the
review doc's self-service sketch.

---

## 5. App changes

1. **Login gate** (Phase 1, already on `feature/google-login`): after the client
   is created, require a Supabase Auth session; show a Google sign-in screen
   otherwise; set `sb_actor` from the session email; sign out on disconnect.
2. **Drop the anon-key reliance for data** (Phase 2): the same client, once the
   user has a session, sends the user JWT — so no client code changes are needed
   for queries; the *server* (RLS) is what changes. The anon key remains only as
   the `apikey` header (required by PostgREST); it's no longer a master key
   because `using(true)` is gone.
3. Remove the `|| "admin"` fallback in `logEvent` once `actor` is always set.

---

## 6. Migration sequence (staging → prod)

1. **Staging project**: clone schema + a data subset.
2. Enable Google provider (see `GOOGLE_LOGIN_SETUP.md`).
3. Apply §3 schema. **Seed `admin_users` with your own `auth.users` row first**
   (sign in once so the row exists, then insert into `admin_users`).
4. Apply §4 policies **one table at a time**, testing read/write after each.
5. Run the full payroll flow end-to-end as the signed-in admin.
6. Only then repeat on production, in a low-traffic window, with the rollback
   (§8) ready.

---

## 7. Lockout-avoidance (the critical risk)

- **Never** apply the §4 policies before your `admin_users` row exists and
  `is_admin()` returns true for your session — otherwise you lock yourself out of
  your own payroll DB.
- Keep the **service-role key** handy (server-side only) — it bypasses RLS and is
  your recovery path to fix `admin_users` if a policy is wrong.
- Apply per-table and verify between each, so a mistake is contained to one table.

## 8. Rollback

Each table's change is reversible:
```sql
drop policy if exists admin_all on <table>;
create policy temp_open on <table> for all using (true) with check (true);
```
Have this scripted for all tables before starting prod, so recovery is one paste.

---

## 9. Scope / non-goals

- This is the **admin** boundary only. Contractor self-service (read-only,
  per-contractor) is a later phase with its own narrow policies.
- TOTP / hardware-key 2FA for the admin login is optional polish on top of
  Google sign-in; not required for the boundary.
- Wise payout SCA is unrelated to this (that's Wise's own requirement for moving
  money via API — see the api-payouts work).

---

*Phase 1 (login gate) ships on its own and is low-risk. Phase 2 (this RLS
boundary) is the part that needs staging and care.*
