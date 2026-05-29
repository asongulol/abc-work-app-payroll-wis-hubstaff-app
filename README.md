# HR & Payroll App

Single-file React app for managing PH-based contractors across multiple companies. Handles time tracking (via Hubstaff), payouts (via Wise), rate history, PTO, and reconciliation.

## Architecture

- **Frontend**: `app/index.html` — single-file React app using in-browser Babel (no build step). Tailwind via CDN.
- **Backend**: Supabase Postgres + Edge Functions.
- **Edge functions**: `supabase/functions/wise-payouts/` and `supabase/functions/hubstaff-sync/`. Hold the Wise and Hubstaff API tokens server-side so they never reach the browser.
- **Data flow**: Browser → Supabase (auth + DB reads/writes) → Edge functions (Wise / Hubstaff API calls when needed).

## Prerequisites

- A Supabase project (free tier works)
- A Wise business account with API token
- A Hubstaff account with API token (scopes: `openid profile email hubstaff:read hubstaff:write tasks:read tasks:write`)
- `supabase` CLI installed locally (for deploying edge functions)

## First-time setup

See the existing docs for the detailed walkthrough — they are the source of truth:

- `SETUP.md` — initial Supabase project setup, schema bootstrap
- `WISE_SETUP.md` — Wise API token, recipient setup, edge function secrets
- `FINISH_SETUP.md` — Hubstaff token, deploying edge functions
- `OPERATING_GUIDE.md` — day-to-day operations (time import, payroll, reconciliation)
- `CLAUDE.md` — conventions for AI-assisted development on this codebase
- `memory/` — accumulated context and project memory

## Running locally

The app is a single HTML file with no build step. Open it directly:

```bash
open app/index.html
```

On first launch, paste your Supabase project URL and anon key when prompted. The app stores them in `localStorage` under `sb_url` and `sb_anon`.

## Deploying edge functions

```bash
# From the repo root
supabase login                 # one-time
supabase link --project-ref <YOUR_PROJECT_REF>   # one-time

# Deploy
supabase functions deploy wise-payouts --no-verify-jwt
supabase functions deploy hubstaff-sync --no-verify-jwt
```

Note: `--no-verify-jwt` is required because the app uses the anon key (not user JWTs) for these calls.

### Edge function secrets

Set these once via `supabase secrets set`:

```bash
supabase secrets set WISE_API_TOKEN=<your-wise-token>
supabase secrets set HUBSTAFF_REFRESH_TOKEN=<your-hubstaff-refresh-token>
```

Optional:

```bash
# Override Wise API base (e.g. for sandbox testing)
supabase secrets set WISE_API_BASE=https://api.sandbox.transferwise.tech
```

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are auto-injected by Supabase — do NOT try to set them as secrets.

Wise profile ID is looked up dynamically by `wise-payouts` via `/v1/profiles`. Hubstaff org ID is hardcoded (see `hubstaff-sync/index.ts`).

## Schema

Live schema: `schema/schema.sql`. Per-change migrations: `schema/migrations/`. Migrations are applied via Supabase SQL Editor or DBeaver — they are not auto-applied by anything.

When using DBeaver, **note that Ctrl+Enter runs the statement at the cursor, not the entire script**. Use Alt+X or "Execute SQL Script" to run multi-statement files.

## Conventions

- **Money never moves automatically.** The app drafts/prepares Wise payouts but does not fund them — funding happens in the Wise UI.
- **ID-first entity matching** for all external API integrations (Hubstaff, Wise). Match on stable provider IDs first, name fallback only as last resort.
- **Multi-tenant** by `company_id`.
- **Locked payments** (`wise_locked_at IS NOT NULL`) are treated as the source of truth.

## What's NOT in this repo

- `payroll_history/` — Excel exports with contractor PII. Stored separately.
- `_select_*.csv`, `_All_*.csv` — ad-hoc query result exports. Stored separately.
- `.env`, secrets, tokens — never committed. All live in Supabase env or `supabase secrets`.
- `node_modules/` — install with `npm install` if you need it (only required for the supabase CLI dev loop, not the app itself).

## License

Private — internal use only.
