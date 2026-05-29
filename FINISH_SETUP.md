# Finish setup — one-time steps to make every feature live

These are the leftover setup steps that accumulated as features were added. Run
them once. Everything here is **safe to re-run** (idempotent) — `if not exists`
guards and additive changes only, no data loss.

Your Supabase project ref: `cgsidolrauzsowqlllsz`

---

## A. Database migrations (Supabase → SQL Editor → New query → paste → Run)

Paste this whole block and Run. It brings your live database in line with every
feature built (multi Wise recipients, PDD lunch, payment status, the 5 payout
channels). It won't touch existing data.

```sql
-- 1. payout channels enum -> wise/bpi/gcash/paymaya/paypal (skip if already done)
do $$
begin
  if not exists (select 1 from pg_type where typname='payout_method') then
    create type payout_method as enum ('wise','bpi','gcash','paymaya','paypal');
  end if;
end$$;

-- 2. workers: Wise recipient fields (IDs only, never bank details)
alter table workers add column if not exists wise_recipient_id bigint;
alter table workers add column if not exists wise_recipients   jsonb default '[]'::jsonb;
-- payout_method must be OPTIONAL (a new contractor has none until you choose).
alter table workers alter column payout_method drop not null;
alter table workers alter column payout_method drop default;

-- 3. payments: PDD lunch + bonus lines + ensure status/paid_at exist
alter table payments add column if not exists pdd_lunch_php numeric(12,2) not null default 0;
alter table payments add column if not exists bonus_php     numeric(12,2) not null default 0;
alter table payments add column if not exists paid_at       timestamptz;

-- 4. audit log table (who/what/when for overrides & key actions)
create table if not exists audit_log (
    id         uuid primary key default gen_random_uuid(),
    company_id uuid references companies(id) on delete set null,
    actor      text, action text not null, entity text, detail jsonb,
    created_at timestamptz not null default now()
);
create index if not exists audit_log_company_idx on audit_log (company_id, created_at);
alter table audit_log enable row level security;

-- 4b. api_tokens: holds the Hubstaff refresh token (it ROTATES on every use, so
-- it can't stay in a static secret). The hubstaff-sync function reads/writes here
-- with the service-role key (which bypasses RLS), so no anon policy is needed.
create table if not exists api_tokens (
    provider text primary key, refresh_token text not null,
    updated_at timestamptz not null default now()
);
-- access-token cache columns (v6 reuses the access token instead of refreshing
-- on every call — Hubstaff rate-limits refreshes).
alter table api_tokens add column if not exists access_token text;
alter table api_tokens add column if not exists access_expires_at timestamptz;
alter table api_tokens enable row level security;   -- service role bypasses; anon has no access (good — keep tokens private)

-- 5. anon access for the app (Phase 1, admin-only). Skip if you ran BLOCK 3 earlier.
do $$
declare t text;
begin
  foreach t in array array['companies','workers','worker_companies','rates',
                           'pay_periods','time_entries','payments','documents','audit_log']
  loop
    if not exists (select 1 from pg_policies where tablename=t and policyname=t||'_anon_all') then
      execute format('create policy %I_anon_all on %I for all to anon using (true) with check (true);', t, t);
    end if;
  end loop;
end$$;

-- confirm
select 'workers cols' as check, string_agg(column_name,', ') from information_schema.columns
  where table_name='workers' and column_name in ('wise_recipient_id','wise_recipients','payout_method')
union all
select 'payments cols', string_agg(column_name,', ') from information_schema.columns
  where table_name='payments' and column_name in ('pdd_lunch_php','paid_at','status');
```

The final `select` should list the new columns — if it does, the DB is ready.

> Already ran some of these in earlier sessions? Fine — the `if not exists`
> guards make re-running harmless.

---

## B. Set contractor payout methods from your payroll sheet (optional)

If payout methods aren't set, this matches your "Through" column (5 BPI, rest Wise):

```sql
update workers set payout_method='bpi'
where (lower(first_name) like 'angelika%' and lower(last_name) like '%alo%')
   or (lower(first_name) like 'barrie%'   and lower(last_name) like '%deonaldo%')
   or (lower(first_name) like 'engelbert%' and lower(last_name) like '%prim%')
   or (lower(first_name) like 'ivy%'      and lower(last_name) like '%gino%')
   or (lower(first_name) like 'leslie%'   and lower(last_name) like '%calandria%');
```

(Everyone else stays Wise. You can also set this per-contractor in the app.)

---

## C. Deploy the Edge Functions (Terminal, in `hr_payroll_app/`)

Both functions hold their API tokens server-side. The Hubstaff one you've already
deployed and tested; redeploy if you changed it. The Wise one needs deploying for
the Process Payroll batch + status features.

```bash
# Hubstaff time sync — REDEPLOY (v5 fixes the token-rotation timeout)
supabase functions deploy hubstaff-sync --no-verify-jwt

# Wise payouts (drafts only — never moves money)
supabase functions deploy wise-payouts --no-verify-jwt
supabase secrets set WISE_API_TOKEN="your-wise-personal-api-token"

# Optional: test Wise against the sandbox first (no real money). Remove to go live.
supabase secrets set WISE_API_BASE="https://api.sandbox.transferwise.tech"
```

### IMPORTANT — seed the Hubstaff token (fixes the "times out after 2 uses" bug)

Hubstaff issues a NEW refresh token every time it's used and kills the old one,
so a static secret goes stale fast. v5 of the function stores the token in the
`api_tokens` table and writes the rotated one back each call. To start it off,
seed the table once with a FRESH token (create a new Personal Access Token at
developer.hubstaff.com — the old one is dead) — run in the SQL Editor:

```sql
insert into api_tokens (provider, refresh_token)
values ('hubstaff', 'PASTE_A_FRESH_REFRESH_TOKEN_HERE')
on conflict (provider) do update set refresh_token = excluded.refresh_token, updated_at = now();
```

From then on the function self-maintains the token. (`HUBSTAFF_REFRESH_TOKEN`
secret is only a first-run fallback now — the table is the source of truth.)

---

## D. Done check

After A + C, refresh the app (Cmd+R) and you should be able to:
- Sync time from Hubstaff (Time & Approval → Option B)
- Calculate + lock a payroll period
- On Process Payroll: download the Wise batch CSV, create a Wise API draft,
  mark paid, and print the pay list

If anything errors, the function logs are at
`https://supabase.com/dashboard/project/cgsidolrauzsowqlllsz/functions`.
