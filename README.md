# ABC Kids — HR & Payroll App

Internal HR & payroll system for Philippine contractors of **Aaron Anderson E.H.S. LLC** (ABC Kids NY). Contractors track time in **Hubstaff**, are paid in **PHP via Wise**, and self-serve through a mobile portal. Everything runs on **Supabase** (Postgres + RLS + Deno edge functions) and deploys to **Cloudflare Workers**.

There is no build step and no framework CLI: each app is a single hand-edited HTML file with React loaded from a CDN.

---

## The two apps

| App | File | Who uses it | Auth |
|-----|------|-------------|------|
| **Admin app** | [`app/index.html`](app/index.html) (~12.7k lines) | Payroll / HR admins | Google sign-in + `admin_users` allowlist (owner / admin roles, per-company scoping) |
| **Contractor portal** | [`portal/index.html`](portal/index.html) (~2.1k lines) | Contractors (mobile-first) | Email + password + Cloudflare Turnstile; RLS-scoped to their own data |

Both are single-file React 18 apps transpiled in the browser by Babel-standalone — open the file and it runs. A frozen `app/legacy.html` is kept as a one-click rollback for the admin app (see [Design & rollback](#design--rollback)).

**Live URLs** (Cloudflare, git-connected to `main`):

- Admin: <https://payroll.abbilabs.com> (fallback `abc-work-app-payroll-wis-hubstaff-app.asongulol.workers.dev`)
- Portal: <https://portal.abbilabs.com> (fallback `abc-work-app-provider-portal-app.asongulol.workers.dev`)

---

## Architecture

```
Admin app  ─┐                        ┌─ Hubstaff API (time)
Portal app ─┼─ supabase-js (RLS) ──► Supabase Postgres + RLS
            │                        │
            └─ .functions.invoke ──► 10 Deno edge functions ─┼─ Wise API (PHP payouts — drafts only)
                                     (tokens kept server-side) └─ Gmail / Resend (emails)
pg_cron (04:00 Manila) ───────────► hubstaff-sync: cron_ingest
Portal also calls: open-meteo (weather), Cloudflare Turnstile (CAPTCHA)
```

- **Frontend**: React 18.2 (UMD from cdnjs) + Babel-standalone 7.23 + `@supabase/supabase-js` (from esm.sh). No Tailwind, no bundler — styling is a hand-rolled CSS design system (navy `#1F3A68` / gold `#D4A24C`, CSS custom properties, responsive tables-to-cards).
- **Backend**: Supabase project `cgsidolrauzsowqlllsz` ("asongulol's Project", **production**). Postgres with Row-Level Security on every table; privileged work runs in edge functions that hold the Wise/Hubstaff/email secrets.
- **Hosting**: Cloudflare Workers static assets. Two separate workers, both **git-connected to `main`** — pushing to `main` auto-deploys in ~15s. The admin worker serves `app/`, the portal worker serves `portal/` (config in [`portal/wrangler.jsonc`](portal/wrangler.jsonc)).
- **The anon key is shipped in the client** (hardcoded URL + anon key). That is safe: it grants nothing without (a) an allowlisted Google session for the admin app, or (b) a contractor login + RLS for the portal.

---

## Data model — employer vs. client

The single most important concept. There is **one employer** and several **clients**:

- **Employer** (`companies.kind = 'employer'`) — Aaron Anderson E.H.S. LLC. This is the payroll home for **every** contractor. All time lands here; all pay is calculated and paid here.
- **Clients** (`companies.kind = 'client'`) — Ability Builders, 123 Baby Talks, 1 World Realty, etc. A client is a **billing tag**: who you *invoice*, not who pays the contractor. A contractor can be assigned to one or more clients via the `worker_companies` junction (which also carries `bill_rate_usd` for invoicing).

In the admin UI the **top-bar switcher selects the employer (tenant)**; the **client picker lives inside Invoicing**. Payroll, time, reports, and reconciliation are always employer-scoped; clients only affect invoicing and per-client time attribution.

---

## Edge functions

Ten Deno functions under [`supabase/functions/`](supabase/functions/). All caller-authenticated (no bare-anon mutations):

| Function | Purpose | Auth posture |
|----------|---------|--------------|
| `wise-payouts` | Draft/batch Wise transfers, poll status, reconcile, FX rates | **Owner** for money-staging (draft/batch); admin **or** cron secret for read/poll/match. **Never funds** — drafts only |
| `hubstaff-sync` | Pull Hubstaff time; daily `cron_ingest`; activity backfill | Cron secret for ingest; admin **or** cron for the rest. Holds + rotates the Hubstaff token |
| `portal-admin` | Create/revoke/reset contractor logins; new-hire & tools emails | Admin JWT |
| `portal-self` | Contractor profile self-edit + onboarding stage completion | Contractor JWT; hard `SAFE_FIELDS` whitelist ∩ admin-allowed fields |
| `portal-sign` | Contractor e-signature capture (Stage 1 agreements) | Contractor JWT; captures IP/UA, immutable |
| `portal-countersign` | Admin countersignature on agreements | Admin JWT |
| `portal-review` | HR review of uploaded docs (approve / needs-replacement / waive / defer) | Admin JWT |
| `admin-manage` | Manage the admin allowlist (add/remove/set-role) | **Owner** JWT |
| `documents-expiry-check` | Email digest of expiring tracked documents | Cron secret **or** admin JWT |
| `hiring-docs-review-check` | Email digest of new-hire docs pending HR review | Cron secret **or** admin JWT |

Money/payment tables are mutated **only** by `wise-payouts` (`payments.wise_transfer_id`, `payments.status`). Everything else touches onboarding, profile, docs, or admin tables.

See [`docs/code-map.md`](docs/code-map.md) for the full action lists and a Mermaid architecture diagram.

---

## Local development

The apps need no build — open them directly or serve the folder:

```bash
open app/index.html         # admin (will prompt for Google sign-in against prod)
open portal/index.html      # portal
# or, to avoid file:// quirks:
python3 -m http.server 8000 # then visit http://localhost:8000/app/
```

Production URL + anon key are built in. (A dev-only Connect screen still lets you point at another Supabase project by entering a URL/key; production never uses it.)

### Editing conventions

- **Source of truth is the JSX in `app/`, `portal/`, `app/legacy.html`** — edit those directly. `dist/` is generated, never hand-edited.
- Some pure helpers (the agreement-merge engine: `mergeAgreement` / `agAddendum` / `monthlyFromPeriod`) are kept **byte-identical** across all three HTML files. A drift guard in [`tools/check-html-syntax.mjs`](tools/check-html-syntax.mjs) fails if they diverge.

### Tooling

```bash
npm run lint            # eslint + HTML/JSX syntax + merge-drift check
npm run build:check     # transpile both apps with esbuild, fail on any JSX error
npm run stamp           # rewrite the visible "Build …" footer + version.txt (run BEFORE every deploy)
npm run build           # stamp + precompile JSX into dist/ (optional perf build)
```

---

## Deploying

Deployment is **`git push origin main`** — both Cloudflare workers rebuild from the new commit automatically (~15s).

**Always `npm run stamp` before you push.** It refreshes the `const BUILD = "…"` footer and `version.txt`; if you skip it the footer freezes and looks like the deploy didn't land (it did). Verify a deploy via the `*.workers.dev` URL (the custom domains 403 a bare `curl`):

```bash
curl -s https://abc-work-app-payroll-wis-hubstaff-app.asongulol.workers.dev/ | grep 'const BUILD'
```

The apps **self-update**: on load they fetch `version.txt` (no-store); if a newer build is live they reload to it with a cache-busting `?_v=` param, so a normal refresh always lands on the latest — no hard refresh needed.

### Edge functions

Deployed with the Supabase CLI (they verify their own callers, so no `--no-verify-jwt` blanket needed for the secured ones):

```bash
supabase functions deploy wise-payouts
supabase functions deploy hubstaff-sync
# …etc
```

Secrets (set once, server-side — never committed):

```bash
supabase secrets set WISE_API_TOKEN=…           # Wise business API token
supabase secrets set HUBSTAFF_REFRESH_TOKEN=…   # rotated + persisted in api_tokens thereafter
supabase secrets set CRON_SECRET=…              # gates cron_ingest + cron report jobs
# email digests / new-hire mail:
supabase secrets set GMAIL_USER=…  GMAIL_APP_PASSWORD=…   # (or RESEND_API_KEY for documents-expiry-check)
```

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are auto-injected by Supabase — do not set them yourself.

---

## Database & schema

- Live schema: [`schema/schema.sql`](schema/schema.sql); seed data: `schema/seed.sql`; per-change migrations: [`schema/migrations/`](schema/migrations/).
- Migrations are applied **manually** via the Supabase SQL editor or DBeaver — nothing auto-applies them. (In DBeaver, `Ctrl+Enter` runs only the statement at the cursor; use *Execute SQL Script* for multi-statement files.)
- RLS is enforced through `SECURITY DEFINER` helpers: `is_admin` · `is_owner` · `is_company_admin(cid)` · `admin_can_see_worker(wid)` · `my_worker_id` · `is_onboarded`. **Any new company/worker-scoped table must use `is_company_admin()` / `admin_can_see_worker()`, not bare `is_admin()`**, or it will leak across the admin↔company scoping boundary.

---

## Conventions

- **Money never moves automatically.** The app drafts and prepares Wise payouts; a human funds the batch in Wise. Locked payments (`wise_locked_at IS NOT NULL`) are the source of truth — editing an amount after locking is flagged.
- **ID-first entity matching** for every external integration. Match imported people/recipients to local records by the provider's stable ID first (Hubstaff `user_id`, Wise recipient UUID), falling back to a hardened name match only when no ID is stored yet. **Match before create** — never insert without checking for an existing record. Persist the provider ID on first match so future syncs are ID-based.
- **Contractors are paid in PHP.** Any USD figure shown is reference only (Wise is USD-funded at a locked rate that differs from the stored market FX).
- **Admin company scoping**: owners see everything; admins see only their assigned companies; unassigned admins see nothing.

---

## What's NOT in the repo

- Excel/CSV exports with contractor PII (`payroll_history/`, `_select_*.csv`, etc.) — gitignored, stored separately.
- `.env`, tokens, secrets — only in Supabase env / `supabase secrets`.
- `node_modules/` — `npm install` only needed for the lint/build tooling, not the apps.

---

## Documentation index

| Doc | What it covers |
|-----|----------------|
| [`docs/code-map.md`](docs/code-map.md) | Architecture + component/data-flow diagrams (Mermaid), edge-function action lists |
| [`docs/ux-ui-improvements.md`](docs/ux-ui-improvements.md) | Catalog of every UX/UI improvement shipped, with where it lives |
| [`docs/ux-ui-guidelines.md`](docs/ux-ui-guidelines.md) | The owner's research-backed design guidelines (drives the redesign) |
| [`OPERATING_GUIDE.md`](OPERATING_GUIDE.md) | The per-period payroll routine, start to finish |
| [`MANUAL.md`](MANUAL.md) | Full feature reference (every tab) |
| [`docs/employer-client-model.md`](docs/employer-client-model.md) · [`docs/multiclient-pipeline-spec.md`](docs/multiclient-pipeline-spec.md) | Employer/client model + multi-client invoicing pipeline |
| [`docs/onboarding-workflow-design.md`](docs/onboarding-workflow-design.md) · [`docs/onboarding-implementation-plan.md`](docs/onboarding-implementation-plan.md) | Contractor onboarding (sign → profile → docs) design |
| [`docs/AUTH_RLS_DESIGN.md`](docs/AUTH_RLS_DESIGN.md) | Auth + RLS design |
| [`SETUP.md`](SETUP.md) · [`WISE_SETUP.md`](WISE_SETUP.md) · [`FINISH_SETUP.md`](FINISH_SETUP.md) · [`GOOGLE_LOGIN_SETUP.md`](GOOGLE_LOGIN_SETUP.md) | First-time setup walkthroughs |
| [`docs/precompile-build.md`](docs/precompile-build.md) · [`docs/optimization-plan.md`](docs/optimization-plan.md) | Build pipeline + performance work |
| [`AGENTS.md`](AGENTS.md) / [`CLAUDE.md`](CLAUDE.md) | Conventions for AI-assisted development |

---

## License

Private — internal use only.
