# Setup guide — HR & Payroll system (free tools only)

This stands up the whole thing on free tiers: **Supabase** (Postgres + auth +
auto REST API + file storage) and a **single-file React app** you open in a
browser. No paid services. ~20 minutes.

Everything that *would* need paid tooling is flagged with **[PAID-FLAG]** and a
free workaround.

---

## 0. What you'll end up with

```
Supabase project (cloud, free)         your computer
┌─────────────────────────────┐        ┌────────────────────────┐
│ Postgres DB (your schema)   │◄──────►│ index.html (React app) │
│ Auto REST API               │  HTTPS │ opened in a browser    │
│ Storage bucket (documents)  │        └────────────────────────┘
└─────────────────────────────┘
```

---

## 1. Create the Supabase project (free)

1. Go to **https://supabase.com** → sign up (free) → **New project**.
2. Name it (e.g. `hr-payroll`), choose a region near the Philippines
   (**Southeast Asia (Singapore)**), set a database password (save it).
3. Wait ~2 min for it to provision.

Free tier limits to know: 500 MB database, 1 GB file storage, 50,000 monthly
active auth users. Far more than enough here. **[PAID-FLAG]** Supabase pauses a
free project after ~1 week of *no activity*; just open the dashboard to wake it,
or log in to the app weekly. No cost.

---

## 2. Create the database tables

1. In the Supabase dashboard, open **SQL Editor** (left sidebar) → **New query**.
2. Open `schema/schema.sql` from this folder, copy all of it, paste, click **Run**.
   You should see "Success. No rows returned."
3. (Optional but recommended) Load real demo data: open `schema/seed.sql`,
   copy/paste into a new query, **Run**. This inserts your two companies and the
   contractors pulled from your Benefits file.

To re-seed from scratch later: run `truncate companies, workers,
worker_companies, rates, pay_periods, time_entries, payments, documents cascade;`
then re-run `seed.sql`.

---

## 3. Create the documents storage bucket

1. Dashboard → **Storage** → **New bucket** → name it `documents` → keep it
   **Private** → Create.
2. That's it. The app uploads IC agreements / W-8BENs here and stores the path
   in the `documents` table.

---

## 4. Get your API keys

Dashboard → **Project Settings** → **API**. You need two values:

- **Project URL** — looks like `https://abcdxyz.supabase.co`
- **anon public** key — a long string under "Project API keys"

> The **anon** key is safe to put in the frontend. Do **NOT** put the
> **service_role** key in the app — it bypasses all security. Keep it secret;
> we only use it server-side later (Phase 2 Wise payouts).

---

## 5. Run the app

The app is a single `app/index.html` file. Two ways to open it:

**Easiest:** double-click `app/index.html` — it opens in your browser.

**If your browser blocks it** (some block module scripts from `file://`), serve
it locally — you already have the tools:

```bash
cd app
python3 -m http.server 8000
```

Then open **http://localhost:8000** in your browser.

On first load the app asks for your **Project URL** and **anon key** (from step
4). It stores them in your browser only. Paste them in and you're connected.

---

## 6. Daily use

- **Company switcher** (top of the app) chooses which company you're working in.
- **Contractors** tab: directory + full profiles.
- **Time Import** tab: upload a Hubstaff daily-report CSV, review, approve.
- **Payroll** tab: pick a period, calculate, review pay statements, lock.
- **Documents** tab: upload/track IC agreements & W-8BENs, see expiry warnings.
- **Reports** tab: payouts by period (PHP & USD), utilization, unpaid — per
  company or consolidated.

---

## Phase 2 enhancements (later, still mostly free)

### Hubstaff API sync (built — needs one-time deploy)

Instead of exporting a CSV, the **Time Import → Option B** syncs directly from
Hubstaff. The Hubstaff token lives ONLY in a Supabase Edge Function (server
side); the browser never sees it. **[PAID-FLAG]** none — Edge Functions are free
up to 500K invocations/month.

One-time setup:

1. **Get a Hubstaff refresh token.** In Hubstaff: Account settings → Personal
   Access Tokens → create one → copy the *refresh token*.
2. **Install the Supabase CLI** (one line, free):
   ```
   brew install supabase/tap/supabase
   ```
3. **Link your project & deploy the function** (from the `hr_payroll_app` folder):
   ```
   supabase login
   supabase link --project-ref <your-project-ref>     # the xxxx in your URL
   supabase functions deploy hubstaff-sync --no-verify-jwt
   ```
   (The function file is in `supabase/functions/hubstaff-sync/index.ts`.)
4. **Set the secret token** (stays server-side, never in the app):
   ```
   supabase secrets set HUBSTAFF_REFRESH_TOKEN="paste-the-refresh-token"
   ```
5. **Find your Hubstaff org id** once — easiest is the Hubstaff URL, or ask me to
   add a one-click "list orgs" helper.

Then in the app: Time Import → Option B → enter the org id + dates → **Sync**.
It pulls the daily activity, matches contractors, and stages pending time exactly
like the CSV path. The org id is remembered in your browser.

> Security note: the function is deployed with `--no-verify-jwt` for simplicity
> in this admin-only setup, so treat its URL as semi-private. To lock it down
> later, drop that flag and the app's anon JWT will gate access.
### Wise payouts (built — drafts only, you fund in Wise)

For a **locked** pay period, the Payroll tab's **Wise payouts** panel creates
**draft transfers** in your Wise account and records Wise's locked FX rate +
transfer IDs back to each payment. **It never moves money** — by design the
function only calls quote/transfer endpoints, never the funding endpoint. You
review and **fund the batch in Wise yourself**. **[PAID-FLAG]** Wise charges its
normal transfer fees when *you* fund; the API itself is free.

How it's scoped: only contractors whose payout method is **wise** AND who have a
**Wise recipient ID** on their profile get drafted. The app references existing
Wise recipients by ID — it never handles bank account details. Add recipients in
Wise, then paste each one's numeric ID into the contractor's profile
(Contractors → click a person → "Wise recipient ID" → Save).

One-time setup:

1. **Add the database column** (SQL Editor → run):
   ```sql
   alter table workers add column if not exists wise_recipient_id bigint;
   ```
2. **Get a Wise personal API token**: Wise → Settings → API tokens → create one.
3. **Deploy the function & set the token** (from `hr_payroll_app`):
   ```
   supabase functions deploy wise-payouts --no-verify-jwt
   supabase secrets set WISE_API_TOKEN="paste-your-wise-token"
   ```
   To test against Wise's sandbox first (no real money), also:
   ```
   supabase secrets set WISE_API_BASE="https://api.sandbox.transferwise.tech"
   ```
   Remove that secret (or set it to `https://api.wise.com`) when going live.

Each pay period: lock the payroll → Payroll tab → **Wise payouts** → pick the
locked period → **Prepare drafts** → Confirm → then log into Wise to fund.

---

## Troubleshooting

- *"Failed to fetch" / blank lists* → check the Project URL and anon key; make
  sure you ran `schema.sql`.
- *Project won't connect after a week* → it auto-paused; open the Supabase
  dashboard to wake it.
- *CSV import matches nobody* → the contractor's `hubstaff_name` in
  `worker_companies` must match the name in the Hubstaff export. Edit it in the
  Contractors tab.
