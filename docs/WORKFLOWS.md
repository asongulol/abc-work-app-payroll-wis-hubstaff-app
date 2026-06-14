# ABC HR & Payroll — End-to-End Workflows

How the system actually works, workflow by workflow: **hiring → onboarding → time → payroll → payout → invoicing**, plus the auth, reporting, configuration, and contractor-portal flows that surround them.

This is the *process* companion to [`FEATURES.md`](FEATURES.md) (which catalogs features) and the [`docs/spec/`](spec/) subsystem files (which detail UI/screens). Everything here is grounded in the live code — `app/index.html` (admin SPA), `portal/index.html` (contractor portal), `supabase/functions/*` (edge functions), `schema/schema.sql` + `schema/migrations/*`. Component/function names are durable; `app/index.html` **line anchors are approximate** (the file moves with edits).

> **Read [Appendix C — Known caveats](#appendix-c--known-caveats) first if you are recreating or auditing the system.** Several documented behaviors are *design-only / not wired* (`portal_notifications`, onboarding reminder cron) or live as *out-of-band schema drift* (columns applied via raw SQL, not in `schema/migrations/`).

---

## Contents

- [0. The big picture](#0-the-big-picture)
  - [0.1 The contractor lifecycle (the spine)](#01-the-contractor-lifecycle-the-spine)
  - [0.2 The employer/client model (load-bearing)](#02-the-employerclient-model-load-bearing)
  - [0.3 Access-control model (RLS)](#03-access-control-model-rls)
  - [0.4 Edge-function auth pattern](#04-edge-function-auth-pattern)
  - [0.5 State machines at a glance](#05-state-machines-at-a-glance)
- [1. Hiring & contractor management](#1-hiring--contractor-management)
- [2. Onboarding, agreements & document review](#2-onboarding-agreements--document-review)
- [3. Time tracking & Hubstaff sync](#3-time-tracking--hubstaff-sync)
- [4. Payroll calculation & the pay-period lifecycle](#4-payroll-calculation--the-pay-period-lifecycle)
- [5. Wise payouts & reconciliation](#5-wise-payouts--reconciliation)
- [6. Client invoicing](#6-client-invoicing)
- [7. Auth, admin & security](#7-auth-admin--security)
- [8. Dashboard, reports & configuration](#8-dashboard-reports--configuration)
- [9. Notifications & email](#9-notifications--email)
- [10. Contractor portal self-service](#10-contractor-portal-self-service)
- [Appendix A — Key tables, enums & helpers](#appendix-a--key-tables-enums--helpers)
- [Appendix B — Edge functions](#appendix-b--edge-functions)
- [Appendix C — Known caveats](#appendix-c--known-caveats)

---

## 0. The big picture

Two surfaces share one Supabase project (`cgsidolrauzsowqlllsz`, production):

- **Admin app** — `app/index.html`, single-file React, **Google OAuth**. Authorization is membership in `admin_users` (not merely signing in).
- **Contractor portal** — `portal/index.html`, single-file React, **email + password**. Each session resolves to exactly one `workers` row via `my_worker_id()`.

The browser ships the Supabase URL + **anon key** publicly; that is safe because **RLS grants nothing without an allow-listed session** (Phase 2, 2026-05-30).

### 0.1 The contractor lifecycle (the spine)

Every workflow in this document is a segment of one arc. Each box names the section that documents it.

```
  HIRE (§1)              ONBOARD (§2)            WORK (§3)             PAY (§4→§5)         BILL (§6)
  ┌──────────┐  invite   ┌───────────────┐  gate  ┌────────────┐ approve ┌──────────┐ pay  ┌──────────┐
  │ create   │ ───────▶  │ set password  │ ─────▶ │ Hubstaff   │ ──────▶ │ calc →   │ ───▶ │ Wise     │
  │ worker + │           │ → sign agrmts │ (A8)   │ sync →     │         │ lock →   │      │ draft →  │
  │ link +   │           │ → profile     │        │ approve    │         │ paid     │      │ poll →   │
  │ rate     │           │ → upload docs │        │ time       │         │ (period) │      │ reconcile│
  └──────────┘           │ → HR review   │        └────────────┘         └──────────┘      └──────────┘
       │                 └───────────────┘              │                      │                 │
       │                        │                       │                      │          client invoicing
       │                        │                       │                      │          (employer time ×
       │                        ▼                       │                      │           bill_rate_usd)
       │                 completed_at set ──────────────┼──────────────────────┘
       │                 ⇒ is_onboarded()=true          │
       │                 ⇒ A8 gate opens pay data        │
       │                                                 │
       └─── OFFBOARD (§1, §2): deactivate / withdraw offer (no payroll) / delete (no history) ───────────┘
```

The **gate** (`is_onboarded()`, §2) is the hinge: a contractor cannot see pay/time/period data until `onboarding_progress.completed_at` is set. **Approved time** (§3) is the only input to payroll (§4). A **locked** pay period freezes a `payments` snapshot; a Wise transfer hard-locks the row (§5). **Invoicing** (§6) reads employer time independently and never touches payroll.

### 0.2 The employer/client model (load-bearing)

This single decision shapes hiring, time, payroll, and invoicing — get it wrong and everything downstream is wrong.

- **Employer** — **one** `companies` row, `kind='employer'`, `id = 11111111-1111-1111-1111-111111111111` ("Aaron Anderson E.H.S. LLC", historically mislabeled "Ability Builders"). This is the **payroll home**: all `rates`, `pay_periods`, `payments`, and `time_entries` carry the **employer's** `company_id`. Hubstaff time always lands on the employer.
- **Clients** — `companies.kind='client'` (Ability Builders for Children LLC, 123 Baby Talks, 1 World Realty). A client is a **billing tag**, not a payroll axis. A contractor's `worker_companies` link to a client carries `bill_rate_usd`, used **only** for invoicing.
- The Contractors roster shows the **employer** link as the row; client links appear in a separate "Client" column.

Defined in `schema/migrations/2026-06-09_company_kind_employer_client.sql`; rationale and known gaps in [`docs/employer-client-model.md`](employer-client-model.md). **Known seam:** true multi-client assignment (per-client `payments` rows + a consolidated single Wise transfer) is *designed but not built* — see [Appendix C](#appendix-c--known-caveats).

### 0.3 Access-control model (RLS)

The entire boundary rests on six `SECURITY DEFINER` SQL helpers (all `stable`, `search_path=public`). A policy is the same shape everywhere: `for all to authenticated using(<helper>) with check(<helper>)`.

| Helper | True when… | Reads | Defined in |
|---|---|---|---|
| `is_admin()` | `auth.uid()` is in `admin_users` (any role) | `admin_users` | `schema.sql`, `2026-05-30_phase2_rls_admin.sql` |
| `is_owner()` | `auth.uid()` is in `admin_users` with `role='owner'` | `admin_users` | `2026-06-06_admin_users_roles.sql` |
| `is_company_admin(cid)` | `is_owner()` **OR** caller's email ∈ `admin_companies` for `cid` | `admin_companies`, `admin_users` | `2026-06-06_admin_company_scoping.sql` |
| `admin_can_see_worker(wid)` | `is_owner()` **OR** caller `is_company_admin` of any company `wid` is linked to | `worker_companies` → `is_company_admin` | `2026-06-06_admin_company_scoping.sql` |
| `my_worker_id()` | the `worker_id` of the **active** `contractor_logins` row for `auth.uid()` (NULL for admins/anon) | `contractor_logins` | `2026-05-30_contractor_portal_rls.sql` |
| `is_onboarded()` | the session's `my_worker_id()` has `onboarding_progress.completed_at` set | `onboarding_progress` | `2026-05-31_is_onboarded_and_backfill.sql` |

**Who can do what:**

- **Owner** — `is_owner()` short-circuits every scoped helper to `true`: sees/edits all companies, workers, payroll. Owner-exclusive: admin-list writes (`admin-manage`) and `admin_companies` writes.
- **Admin (non-owner)** — passes `is_admin()` but not `is_owner()`; company/worker tables are scoped to `admin_companies` assignments. **An unassigned admin sees nothing** (secure default). May still INSERT a `workers` row (`workers_admin_insert` checks only `is_admin()`), then must link it to one of their companies.
- **Contractor** — `my_worker_id()` non-NULL; read-only to **their own** rows; pay-data reads additionally require `is_onboarded()` (the A8 gate). No write policies — all contractor writes route through edge functions (the only exceptions are a `mood_checkins` insert and a `documents` insert into their own Storage folder, forced `review_status='pending'`).
- **Anon (key only)** — every helper false/NULL; grants nothing.
- **Service role** — bypasses RLS; the recovery path and the only writer of `admin_users` / `contractor_logins`.

### 0.4 Edge-function auth pattern

All edge functions are deployed `--no-verify-jwt`; **the in-code gate is the control.** Three gate styles appear:

- **Admin-bearer** — validate the caller's JWT via `/auth/v1/user`, then check `admin_users` (e.g. `portal-admin`, manual `sync_ingest`). Owner-only actions additionally require `role='owner'` (e.g. Wise `draft`/`batch`).
- **Cron-secret** — compare an `x-cron-secret` header against `app_secrets.cron_secret` (read with the service role). Used by scheduled jobs (`cron_ingest`, Wise `poll`/`match`, the two email digests).
- **Either** — the digests and some sync actions accept a valid cron secret **or** an admin JWT, never the bare anon key.

### 0.5 State machines at a glance

| Entity | Column / enum | States | Transition owner |
|---|---|---|---|
| Worker | `workers.status` (`active`/`inactive`/`ended`) | active ⇄ ended (deactivate writes **`ended`**, not `inactive`) | `setActive` (§1) |
| Engagement | `worker_companies.status` | active ⇄ ended (+ `ended_on`) | engagement panel (§1) |
| Onboarding | `onboarding_progress.current_stage` (`onboarding_stage`) | stage1_sign → stage2_profile → stage3_docs → complete (**monotonic**) | edge fns (§2) |
| Onboarding gate | `onboarding_progress.completed_at` | null → set (monotonic; never auto-cleared) | `portal-review` / admin (§2) |
| Agreement signature | `onboarding_signatures.status` (`signature_status`) | signed → superseded → disputed (only `signed` written by `portal-sign`) | §2 |
| Document | `documents.review_status` (`review_status`) | pending → approved / needs_replacement / waived / deferred | `portal-review` (§2) |
| Time entry | `time_entries.approval` | pending → approved / rejected | `TimeApproval` / cron (§3) |
| Pay period | `pay_periods.state` (`pay_period_state`) | open → locked → paid (unlock back to open w/ reason) | §4 |
| Payment | `payments.status` (`payment_status`) | draft → queued → sent → reconciled (or failed); **hard-locked once `wise_locked_at` set** | §4/§5 |
| Invoice | `invoices.status` | draft → sent → paid (or void; regenerate = void + new) | §6 |
| Admin | `admin_users.role` | admin ⇄ owner (last-owner protected) | `admin-manage` (§7) |
| Portal login | `contractor_logins.status` | active ⇄ revoked | `portal-admin` (§1/§7) |

---

## 1. Hiring & contractor management

All UI in `app/index.html`; server lifecycle actions in `supabase/functions/portal-admin/index.ts`.

### 1.1 Add a single contractor — Quick add

- **Actors:** Admin.
- **Trigger:** "Quick add" on the Contractors toolbar → `addContractor`.
- **Preconditions:** A single company selected (disabled in consolidated mode); RLS `workers_admin_insert` (`is_admin()`).
- **Steps:**
  1. Insert a placeholder `workers` row (`first_name:"New"`, `last_name:"Contractor"`, `status:'active'`, HA/13th eligible, shift defaulted 8–5 ET → PHT via `etToPhtHHMM`). If the insert errors on a legacy NOT-NULL `payout_method`, retry with `payout_method:'wise'`.
  2. Insert a `worker_companies` link `{worker_id, company_id, contract:'FT', status:'active'}` (no role/weekly_hours/started_on — differs from the wizard).
  3. `logEvent action:'add_contractor'` → `audit_log`; reopen the new row in **ProfileModal** to finish.
- **Data written:** `workers`, `worker_companies`, `audit_log`.
- **Edge cases:** the legacy "instant blank row" path — abandoning the modal leaves a "New Contractor" ghost (the reason a Delete action exists). No rollback on failure. The **wizard (§1.2) is the preferred replacement.**

### 1.2 Add a single contractor — Add Contractor Wizard

- **Actors:** Admin.
- **Trigger:** "+ Add contractor" (Contractors) or "+ Hire new contractor" (OnboardingAdmin) → `AddContractorWizard` → `create()`. **Creates nothing until "Create contractor."**
- **Steps (3 steps, per-step `validateStep`):**
  1. **Identity** — first/middle/last, personal email (required+valid if inviting), current/permanent address (+ "Same as current"), DOB.
  2. **Engagement / IC terms** — company, contract FT/PT (auto-sets hours 40/20), expected hours/week, role, rate (PHP/period), contract date, hire date, HA/13th, daily shift (two PHT inputs + "Reset to 8–5 ET"), **company countersigner** (admins with `can_countersign !== false`), IC addendum (none / scope_of_work / other + text), additional documents to request.
  3. **Portal & onboarding** — "Invite to the portal" (default on), tools to provision (Gmail / Providersoft / Hubstaff / Zoom + "Other"), summary.
  4. **Duplicate prevention (in order):** email hard-block vs `workers`; email hard-block vs `contractor_logins`; **name soft-warn** → typed `DUPLICATE` confirm → "Create anyway".
  5. **Ordered writes** (stop on first error): `workers` → `worker_companies` `{contract, role, weekly_hours, status:'active', started_on:hire_date}` → `rates` (only if rate>0) → **if invite:** `portal-admin create_login` (returns temp password) → **best-effort per-hire prep** (own try/catch, non-fatal): upsert `onboarding_agreements` (ic_agreement + non-IC kinds with engagement fields), `onboarding_progress.extra_documents`, `set_tools_requested` RPC → `logEvent add_contractor`.
  6. **Success screen** with the temp password (Copy).
- **States:** `workers.status='active'`; if invited, `create_login` seeds onboarding → appears in the OnboardingAdmin queue.
- **Data written:** `workers`, `worker_companies`, `rates` (conditional), `contractor_logins`+auth user (conditional), `onboarding_agreements`, `onboarding_progress`, tools, `audit_log`. Draft autosaved to `localStorage` (`eis_hire_draft_<companyId>`) with a resume banner.
- **Edge cases:** **Rollback** — on any throw before success, the just-created `workers` row is deleted (FK `ON DELETE CASCADE` clears links/rates/logins/onboarding); the best-effort prep block is excluded from rollback. The authoritative duplicate-email guard is the edge `create_login` (it sees all auth accounts).

### 1.3 Bulk CSV / TSV contractor import

- **Actors:** Admin. **Trigger:** "⇪ Bulk import" → `BulkImport` (input → preview → done); single company only.
- **Steps:**
  1. **Input** — paste or upload CSV; "Download CSV template"; "Prefer the Wise account name" toggle.
  2. **Parse** — auto delimiter, quote-aware; headers mapped via `BULK_COLMAP` after `normHdr` (Wise id/UUID, Hubstaff id, rate/effective/status/dates, emergency/education aliases).
  3. **Build rows** (`buildRow`) — **ID-first match order against the roster: Wise recipient id → Wise UUID → Hubstaff user id → strict name key → loose name key** (`via` records which matched). **Match-before-create**: no match + a name → create; no name → error. **Blanks never overwrite** existing values.
  4. **Preview** — "N new / N update / N skipped" + per-row table (matched-via, changes).
  5. **Commit** — **Update**: `workers.update(patch)` (+ merge `wise_recipients`), create the `worker_companies` link if missing, `upsertRate` if rate>0. **Create**: insert `workers` (+ link), with **23505 race recovery** (on unique-violation when `hubstaff_user_id` is set, look up the winner by `(company_id, hubstaff_user_id)`, delete the orphan, reuse the winner), `upsertRate` if rate>0. `logEvent` per row.
- **Data written:** `workers`, `worker_companies`, `rates`, `audit_log`.
- **Edge cases:** blanks never overwrite; object-valued fields skipped in the diff; nameless unmatched rows surface as errors, not silent creates.

### 1.4 Assign a contractor to a company / client (engagements)

- **Actors:** Admin. **Trigger:** ProfileModal → Profile → **Client engagements** (`addCompany`, `saveEngagement`, `toggleMembership`). RLS `admin_can_see_worker`.
- **Steps:** **Add company** — pick from assignable companies; if the worker already has ≥1 active link, a `confirm` warns Hubstaff hours aren't split per client and there's no consolidated Wise payout; insert `worker_companies {contract:'FT', status:'active', started_on}`. **Edit** — per-client `role` + **Bill rate (USD/hr)** (`bill_rate_usd`). **Deactivate/Reactivate** — `{status, ended_on}`.
- **Data written:** `worker_companies` (`role`, `bill_rate_usd`, `status`, `ended_on`), `audit_log`.
- **Edge cases:** `bill_rate_usd` is **invoicing-only** (client links); the employer link's pay is rate-driven. The multi-client path is latent-risky (double Hubstaff counting / double Wise payout) — see [Appendix C](#appendix-c--known-caveats).

### 1.5 Set pay rates & rate history (effective-dated)

- **Actors:** Admin. **Trigger:** ProfileModal → **Pay & payout** (`saveRate`, `saveRateEffectiveEdit`, `deleteRateRow`). Rate must be `>0`.
- **Steps:** **Same-day update** — if a `rates` row has `effective_start === effectiveFrom`, UPDATE it (preserves id). **New effective date** — close any strictly-earlier open rate (`effective_end = effectiveFrom`), then INSERT `{worker_id, company_id, amount_php, period_basis:'semi_monthly', effective_start}` (new `effective_end` null = current). **Edit date / Delete** recompute contiguity across all rows so the series stays gapless with exactly one open rate.
- **Data written:** `rates`, `audit_log` (`set_rate`). Fires `onBillingChange` so the next Calculate re-prompts.
- **Edge cases:** rate is per **(worker, company)**; `period_basis` defaults `semi_monthly` (monthly = ×2). A stale-rate banner flags drift during Calculate. *Inconsistency:* the wizard's initial `rates` insert omits `period_basis` (DB default), whereas `saveRate`/`upsertRate` set it explicitly.

### 1.6 ID-first entity matching (Hubstaff & Wise)

The convention — **match by stable provider ID first, persist it on first match, fall back to a hardened name match, never create without checking** — is applied in three places:

- **Hubstaff time sync** (`hubstaff-sync`): match order `hubstaff_user_id` → strict sorted-token `nameKey` → loose first+last `looseKey`, over both `worker_companies.hubstaff_name` and the real name. **Self-healing:** a name-matched row with `hubstaff_user_id IS NULL` gets the stable `uid` written back. Guarded by the partial unique index `worker_companies (company_id, hubstaff_user_id) WHERE hubstaff_user_id IS NOT NULL`.
- **Wise recipient pull** (`PullRecipients` → `wise-payouts {action:'recipients'}`, read-only): match Wise recipient id → strict → loose; append `{id,label}` to `workers.wise_recipients` and set `workers.wise_recipient_id` **only when null** (never clobbers an existing default).
- **Bulk import** (§1.3): Wise id → Wise UUID → Hubstaff id → strict → loose, with 23505 race recovery.

Name keys strip accents/suffixes and sort tokens, so first-ID-match wins and future syncs are immune to name changes.

### 1.7 Edit, activate/deactivate, delete

- **Edit (ProfileModal, `saveDetails`):** four tabs (Profile / Pay & payout / Personal-HR / Portal & login). Payout method **instant-saves** (`savePayMethod` → direct `workers.update`). Builds an `auditDiff` over worker + link + `profile_extras` fields → `edit_contractor`. No status change on edit.
- **Activate/Deactivate (`setActive`):** `workers.status` → `'active'` or **`'ended'`** (note: deactivate uses `ended`, not `inactive`), mirrors `worker_companies.status`/`ended_on`, fires `onBillingChange`. Recommended over deletion when payroll history exists.
- **Delete (`deleteContractor` → `portal-admin delete_contractor`):** counts `payments`/`time_entries`/`onboarding_signatures`/`documents` in parallel. **Hard block** if any payments/time exist ("Deactivate instead"). If signatures/documents exist, requires `force` + a **typed-name confirm**. The **server re-validates** (fail-closed 502/409 `has_history`, 409 `has_records`), then cascades `workers` → links/rates/logins/onboarding + Storage (`contractor-docs`) + auth user, and writes its own audit row. The server is the real authority.

### 1.8 Portal login lifecycle

All via `portal-admin`: `create_login` (provisions an auth user with `must_set_password`, inserts `contractor_logins`, seeds `onboarding_progress`, emails a temp password, returns it), `reset_password`, `revoke_login` (`status='revoked'`), `update_login_and_resend`, `withdraw_offer` (revoke + ban + `ended` + email; refuses if payroll exists), `send_tools_email`, `delete_contractor`. `requireOnboarding` is a **direct** `onboarding_progress` upsert (no edge fn). See §2.1 for the contractor-side first-login flow and §7.6 for RLS scoping.

---

## 2. Onboarding, agreements & document review

Edge fns: `portal-admin`, `portal-self`, `portal-sign`, `portal-review`, `portal-countersign`, `hiring-docs-review-check`. Admin UI in `app/index.html` (OnboardingAdmin / OnboardingDrilldown); portal UI in `portal/index.html`.

### 2.1 Portal invite + first-login password set

- **Actors:** Admin (invites); new-hire contractor.
- **Trigger:** `portal-admin create_login` (Contractors row / wizard Step 3).
- **Steps:**
  1. Verify admin → guard `contractor_logins` (409 if a login exists) → guard email-taken via RPC `admin_lookup_auth_user` (409 `email_taken`).
  2. Generate temp password (`"Abc-"+random`); create the auth user (`email_confirm:true`, `user_metadata.must_set_password:true`); insert `contractor_logins {worker_id, auth_user_id, email, status:"active"}`.
  3. **Provisioning hook:** insert `onboarding_progress {current_stage:"stage1_sign"}` (`ignore-duplicates`) — gates the hire from session 1.
  4. Best-effort welcome email (credentials folded in).
  5. **First sign-in:** `user_metadata.must_set_password===true` → **SetPassword** screen → `portal-self set_password` (service-role `PUT` sets the password and clears the flag, bypassing the "current password required" rule; min length 8) → signs in fresh (recovers a spent session) → lands in onboarding. A "⏻ Sign out" escape is present.
- **States:** `contractor_logins.status` active→revoked; `must_set_password` true→false.
- **Edge cases:** login exists → 409; email in an auth account → 409 `email_taken`; auth-create OK but `contractor_logins` insert fails → 500 (auth user orphaned, not auto-rolled-back). **Correct an in-flight hire:** `update_login_and_resend` (optionally change email, always new temp password). **Reset:** `reset_password` (audits `portal_login.reset_password`).

### 2.2 The onboarding wizard (the gate)

- **Trigger:** portal boot. After resolving the session + `my_worker_id()`, if `onboarding_progress.completed_at IS NULL` and `onboarding_config.onboarding_enabled` → mounts `<OnboardingFlow/>` full-screen (hides the shell); else `<Portal/>`.
- **Stages (strictly sequential):** Intro → **Stage 1 Agreements** (`portal-sign`) → **Stage 2 Profile** (`portal-self complete_tab`) → **Stage 3 Documents** (upload + `portal-review`) → Completion (`completed_at` set; "Go to my portal").
- **State machine (`onboarding_progress`):** `current_stage` `stage1_sign → stage2_profile → stage3_docs → complete` (**monotonic** — edge fns advance via a RANK map, never regress). Booleans `stage{1,2,3}_complete`. **Gate key:** `completed_at` non-null ⇔ `is_onboarded()` true (set once, never cleared by a later doc rejection). Resume pointers `stage1_last_kind`, `stage2_last_tab`. Progress math: per-stage 25%/task, overall = mean of three stages (Stage-3 submitted-pending-HR = 50%).
- **Sequencing guards (server-authoritative):** `complete_tab` → 409 `stage_out_of_order` if Stage 1 incomplete; `portal-sign` → 409 `out_of_order` if a prior agreement is unsigned; once `completed_at` set, `complete_tab` → 409 `stage_locked`.
- **Recovery paths:** `advance_from_stage1` (admin reopened to signing but all agreements already signed), `finish_onboarding` (no required docs configured → self-complete once Stages 1+2 done and required docs resolved).

### 2.3 The A8 onboarding gate (server enforcement)

- **What:** RLS appends `AND is_onboarded()` to exactly three contractor-read policies — `payments_contractor_read`, `time_entries_contractor_read`, `pay_periods_contractor_read`. **Deliberately NOT gated:** `workers_contractor_read` and `documents_contractor_read` (a contractor must read their own profile/docs *while* onboarding).
- **Mechanism:** `is_onboarded()` = `onboarding_progress.completed_at IS NOT NULL` for `my_worker_id()`. Two layers — the client boot fork is cosmetic; **RLS is the authority** (a hand-crafted PostgREST call by an un-onboarded contractor returns zero pay/time/period rows).
- **Rollout safety (critical ordering):** the A7 grandfather backfill (insert a `complete` `onboarding_progress` row for every active `contractor_logins`) must run, with a canary = 0, **before** A8 — otherwise an active contractor loses pay access. Rollback SQL is embedded in the A8 file. As of 2026-06-03: 2 logins grandfathered; only the test account is intentionally gated; 48 link-less workers are unaffected.

### 2.4 Agreement e-sign ledger (Stage 1)

- **Trigger:** contractor taps **Sign** after the scroll gate → `portal-sign sign`.
- **Steps:**
  1. Resolve caller → active worker (else 403). Load sign order from `onboarding_config.agreements` (fallback `ic_agreement, non_compete, confidentiality_nda, baa`).
  2. Validate `agreement_kind` ∈ order, `doc_version`, `signed_legal_name`, `signature_method` ∈ {typed,drawn}, **`scrolled_to_end===true`** (else 422). **Drawn-signature XSS guard:** must match `^data:image/(png|jpe?g|webp);base64,…` and be ≤ ~1 MB; typed capped at 300 chars.
  3. **Order enforcement** — any earlier-in-order unsigned kind → 409 `out_of_order`. **Soft name mismatch** — set `name_mismatch_flag=true` but **do not block**.
  4. **Insert the immutable ledger row** into `onboarding_signatures` (`ON CONFLICT (worker_id, agreement_kind, doc_version) DO NOTHING`): `doc_sha256`, `signature_data`, `scrolled_to_end`, **server-side `ip_address`/`user_agent`**, `device_fingerprint` (best-effort), `status:"signed"`, contractor-chosen `signed_date` (separate from immutable `signed_at`).
  5. Recompute `stage1_complete = order.every(signed)`; PATCH `onboarding_progress` (monotonic `current_stage`); `audit_log agreement.signed`.
- **Scroll gate (UI):** `AgreementViewer` uses an `IntersectionObserver` bottom sentinel; the Sign control is disabled until satisfied; the server re-checks.
- **Edge cases:** signature durable even if the progress PATCH fails (500 "retry"); replayed identical sign is a no-op. **Edit signed date later:** admin-only `portal-review set_signed_date` patches *only* `signed_date` (evidence untouched).

### 2.5 Agreement preparation + admin countersign

- **Trigger:** AgreementsPanel **Prepare/Edit prefill** (`savePrep`) then **Countersign** → `portal-countersign countersign`.
- **Steps:** verify admin; **contractor-signed-first guard** (409 `not_signed`); if `countersigned_at` set → 409 `already_countersigned` (immutable); if a `countersigner_user_id` was assigned and ≠ caller → 403 `not_assigned`; **upsert** `onboarding_agreements ON CONFLICT (worker_id, agreement_kind)` writing `countersigned_by/_name/_method/_data/_at` + **server-side `countersign_ip`**, preserving the prepared prefill; `audit_log agreement.countersigned`.
- **States:** unprepared/prepared → countersigned (terminal). Badges: Signed / Awaiting / Countersigned.
- **Edge cases:** rendering (`mergeAgreement`/`printDoc`) is XSS-safe (`safeSigImg` only emits `<img>` for bounded data-URIs, else an escaped name). Several prefill columns (`f_employment_type`/`f_hours_per_week`/`f_schedule`/`f_company_name`) are **schema drift** — see [Appendix C](#appendix-c--known-caveats).

### 2.6 Document upload (portal, Stage 3)

- **Trigger:** Stage-3 upload card — two file inputs, `accept=PDF/JPG/PNG`, **no `capture`** (mobile offers Take Photo / Library / Browse). File ≤ 10 MB; `downscaleImage()`.
- **Steps:** upload to private bucket `contractor-docs/<auth.uid()>/<kind>/<uuid>-<name>` (Storage RLS `contractor_docs_insert_own` restricts to the caller's own folder); insert a `documents` row. The contractor INSERT policy **pins** `worker_id=my_worker_id()`, `kind<>'other'`, `review_status='pending'`, `reviewed_by/at NULL` — a tampered client **cannot self-approve**. `gov_id` uses `side` (front/back) → two rows; NBI requires `issued_on`.
- **States:** `review_status` pending → approved / needs_replacement / waived / deferred. A "replacement" is a **new pending row** (no contractor UPDATE/DELETE policy); the rejected row is retained.

### 2.7 Admin document review (approve / needs-replacement / waive / defer; NBI freshness)

- **Trigger:** OnboardingDrilldown → **3 · Documents** → `review(d, action, reason, override)` → `portal-review`.
- **Steps:** verify admin; load doc. **Approve** — for `nbi_clearance` with `issued_on` and not `override`, day-accurate freshness vs `onboarding_config.documents[nbi].freshness_months` (default 6); stale → 422 `nbi_stale`. On approve: `review_status='approved'`, **`reviewed_by`=server-resolved admin id** (never client). **Needs replacement** — non-empty `reason` required (UI ReasonPicker presets). **Waive / Defer** — clear the whole-kind requirement. After every action, **`reEvalStage3`** recomputes `stage3_complete` from approved/waived/deferred docs (per-`side` for sided kinds); if all three stages complete and `completed_at` null → set it (monotonic), `current_stage='complete'`, `audit_log onboarding.completed`. A later rejection flips `stage3_complete` back to false but **never clears `completed_at`** (no silent access revocation).
- **View:** `view(d)` mints a 120 s signed URL on `contractor-docs`.
- **Enum drift:** committed `review_status` is `(pending, approved, needs_replacement)`; `waived`/`deferred` were added via in-app SQL — see [Appendix C](#appendix-c--known-caveats).

### 2.8 Hire / credential / welcome / tools emails

- **Transport:** **Gmail/Workspace SMTP** (`denomailer`), fresh `smtp.gmail.com:465` connection per message, **never throws** (mail must not break hiring). Secrets `gmail_user` + `gmail_app_password` (env or `app_secrets`); if absent → no-op `{email_configured:false}`.
- **Templates:** `onboarding_config.hire_emails` (welcome / credentials / tools / withdraw), merged via `{{name}} {{email}} {{password}} {{portal_url}} {{wise_referral_url}} {{tools_block}}`; contractor-derived values HTML-escaped, the generated password left exact.
- **Triggers:** `create_login` (welcome), `reset_password` (credentials), `update_login_and_resend`, `resend_hire_emails`, `send_tools_email` (Email 2 at completion — decrypts via `decrypt_worker_tools`, see §10.6), `withdraw_offer`.

### 2.9 Reminders (HR document-review digest)

- **Trigger:** daily cron POST (cron-secret) or admin JWT → `hiring-docs-review-check`.
- **Steps:** authorize → read `onboarding_config.review_notify {enabled, recipients[], frequency: daily|weekdays|weekly, include_deferred}` → **cadence gate** (weekdays = Mon–Fri, weekly = Mondays) → fetch `documents WHERE kind IN (resume, diploma, nbi_clearance, gov_id)` → latest per `worker|kind|side`, skip non-active workers → bucket `pending`/`deferred` → send digest via Gmail SMTP if anything waits.
- **Edge cases:** `dry_run` computes without sending; nothing waiting → `{emailed:false}`; bad cron secret → 401; non-admin JWT → 403. **The contractor-facing nudge cadence is design-only** — see [Appendix C](#appendix-c--known-caveats).

### 2.10 Admin onboarding overrides & hire lifecycle

OnboardingDrilldown stage controls: **↺ Reopen Stage 1/2/3** (`reopenTo` — clears downstream flags + `completed_at`, re-locks pay), **✓ Mark complete** (`markComplete` — all flags + `completed_at`, unlocks pay, auto-opens ToolsProvisionModal if tools pending), **↺ Reset** (`revoke`), **⊘ Withdraw offer** (`portal-admin withdraw_offer` — refuses 409 `has_history` if any payments/time exist), **🗑 Delete hire** (`delete_contractor force` — see §1.7). Writes go through the `onboarding_progress_admin_write` policy (`admin_can_see_worker`).

---

## 3. Time tracking & Hubstaff sync

Edge fn `hubstaff-sync`; admin UI `TimeImport` + `TimeApproval` in `app/index.html`. Time always lands on the **employer** company.

### 3.1 Hubstaff daily cron ingest (`cron_ingest`)

- **Actors:** Supabase **pg_cron** (no human), service role. **Schedule:** ~**04:00 Asia/Manila** (the literal pg_cron job — schedule expression, lookback, the `org_id`/`company_id` it passes — is configured in the Dashboard, **not in the repo**).
- **Auth:** secret-gated — reads `x-cron-secret` (or `body.secret`), matches `app_secrets.cron_secret` via the service role; 401 otherwise.
- **Steps:**
  1. Authorize → compute window (`lookback_days` clamped 0–31, default **3**, ending at `today`).
  2. `getAccessToken()` (reads/refreshes the Hubstaff token in `api_tokens`).
  3. Pull org **members** → user_ids → **names** (bulk `GET /v2/users?id[]=…` chunks of 50, per-id fallback).
  4. Pull **daily activities** → sum `tracked` + `overall` per user/day. Pull **PTO** (`time_off_requests`, approved only) → `pto` per user/day (failure here is non-fatal).
  5. Load all `worker_companies`; build match indexes `byId` / strict `nameKey` / loose `looseKey`. **Resolve** each member ID-first → strict → loose; unmatched → reported in `unmatched`, **never inserted**. Matched workers pinned to the employer (`EMPLOYER_COMPANY_ID` env or the employer UUID).
  6. Derive a canonical `source_name` per `(company, worker)` from existing rows (so the UPSERT hits the same key).
  7. Build `decidedSrc`/`decidedWrk` sets of rows with `approval != 'pending'`; **skip those days** (never revert a human decision).
  8. Per matched user/day where `tracked>0 || pto>0`: compute `activity_pct = round(overall/tracked*100)` (null if no tracked); **UPSERT** `time_entries` `on_conflict=company_id,source_name,work_date` (`merge-duplicates` → only payload columns update; `pay_period_id`/`import_batch_id`/`approved_*` preserved).
  9. **Self-heal:** backfill `worker_companies.hubstaff_user_id` on any name-matched link still null.
- **Data written:** `time_entries` (always `approval:'pending'`), `worker_companies.hubstaff_user_id`, `api_tokens` (on refresh).
- **Edge cases:** unmatched → reported, never auto-created; decided-row protection; dupes prevented by the unique key; PTO endpoint failure non-fatal. **Structural risk:** the org rollup has no project/client split, so running the ingest for two `company_id`s against one org would double-write — safe today only because there is effectively one client.

### 3.2 Manual "Sync now" (Hubstaff API import)

- **Trigger:** Time & Approval tab → **Import Time** → `syncFromHubstaff()`. Two server modes by the `consolidated` flag: **single client** (`{org_id, start, stop}` → rollup, returns per-member totals to the browser, which matches + **auto-commits, skipping preview**); **consolidated** (`{action:"sync_ingest", …}` → server writes directly like `cron_ingest`).
- **Auth:** `sync_ingest`/rollup run the **admin-bearer** gate (caller JWT → `admin_users`; 403 otherwise; `x-cron-secret` also accepted).
- **Edge cases:** empty members → "no activity"; unmatched names surfaced for setup (their time is **not** written — add the contractor then re-sync); errors point at "check the hubstaff-sync function / token."

### 3.3 CSV time import

- **Trigger:** `<input accept=".csv">` → `onFile()`; single company. `parseHubstaff` requires a Hubstaff **daily report** (header contains "Time off" + "Total worked"). CSV has **no `user_id`** → name-only matching.
- **Steps:** parse → `buildMatchTable` (ID-first → strict → loose) → preview (unmatched rows get **+ Add contractor**) → `commit` builds one row per matched contractor per date → **overlap detection** (existing rows in range → Overwrite / Skip / Cancel banner) → `writeRows` stamps one `import_batch_id` and **UPSERTs** `on_conflict=company_id,source_name,work_date` → backfill `hubstaff_user_id` (best effort).
- **Data written:** `time_entries` (shared `import_batch_id`, `approval:'pending'`), `audit_log action:'import'`. Enables "**Delete this import**" (`deleteCurrentImport` by `import_batch_id`).
- **Edge cases:** PTO always 0 on CSV. **+ Add contractor** is ID-first then strict/loose across all workers, insert only if no match, with 23505 race recovery. *Note:* the CSV Overwrite path does **not** apply decided-row protection (only the server ingest paths and the grid-delete do).

### 3.4 Worker attribution & ID persistence

Identical matching across all three paths: **ID-first** (`hubstaff_user_id`) → **strict** (`nameKey`: NFD accent-strip, drop `.`/`,`, `Ma`→`Maria`, drop suffixes, lowercase, **sorted** tokens) → **loose** (`looseKey`: first + last token). Keys derive from both `hubstaff_name` and the real name. On a name match carrying a `user_id`, write `hubstaff_user_id` to the link **only when null** → future syncs are ID-based, immune to name changes. Inactive/`ended` links are still indexed (so a final period imports) but flagged in the preview.

### 3.5 Time-entry approval (`TimeApproval`)

- **Trigger:** mounts when `revealApproval`; **auto-reveals** on mount if any `time_entries.approval != 'approved'` exist (so cron/sync-ingested pending time can't hide).
- **Steps:** load active rows (`approval != 'approved'`, unbounded to dodge the 1000-row cap) + approved history (limit 1000). Group by person; compute period span / working days (weekdays − weekday holidays). Edit **Tracked** total (`setContractorTotal` puts the period total on day-0), **Add hours**, **Add manual row**. **Approve/Reject** (`setApproval`, chunks of 100 ids; on approve navigates to Calculate via `openPeriodForEdit`); bulk **Approve all / Reject all pending**. **Delete** snapshots rows for **Undo** (re-inserts with same ids so payroll links survive).
- **States:** `approval` pending → approved / rejected (`approved_by`/`approved_at` columns exist but aren't written by this UI). Undo restores each row's captured prior value.
- **Edge cases:** **Delete is blocked** if any row's date falls in a `locked`/`paid` `pay_periods` window ("unlock on Calculate first") — checked by date overlap because lock writes `payments`, not `time_entries.pay_period_id`. PTO is read-only here.

### 3.6 How approved time feeds payroll

`calculate()` fetches **only** `time_entries WHERE approval='approved'` for the period; `worked = (Σ tracked_seconds + Σ pto_seconds)/3600` (**PTO is paid like worked time**). Null-`worker_id` rows resolve by `source_name`/`normName`; unresolved → `unattributed` banner; approved time with no link in this company → `noLink`. Lock writes `payments` + `pay_periods.state='locked'` (it does **not** stamp `time_entries.pay_period_id`). See §4.

---

## 4. Payroll calculation & the pay-period lifecycle

`Payroll` (Calculate) and `ProcessPayroll` (Process & Pay) in `app/index.html`; lock trigger in `schema.sql`. All on the **employer** company.

### 4.1 Pay-period lifecycle (open → locked → paid)

- **Steps:** a `pay_periods` row is upserted on first draft save (`saveDraft`, `state:"open"`, conflict key `(company_id, period_start, period_end)`). **Lock** (`lockAndSave`) re-upserts `state:"locked"`, `locked_at`, and writes the frozen `payments` snapshot. **Paid** is **derived, not manual** (`ProcessPayroll.load`): when every payment row is `sent`, the period auto-advances to `paid`. **Unlock** (`unlockPeriod`, typed reason) sets `state:"open"`, `locked_at:null`.
- **Transitions:** `open → locked → paid`; `locked → open` (reason); `paid → open` is **two-step** (Process "Mark all unpaid" → Calculate Unlock; `unlockPeriod` refuses a `paid` period directly).
- **Immutability:** a `payments` row is hard-immutable only once **`wise_locked_at`** is set (not merely when the *period* locks). The BEFORE-UPDATE trigger `payments_lock_enforce()` raises `check_violation` on changes to protected columns (`net_php`, `gross_php`, `worked_hours`, `rate_php`, all `*_php` components, `original_net_php`, `payout_amount`, `payout_method`, `misc_items`, identity) when `wise_locked_at` is set. Settlement columns stay writable: `note`, `wise_locked_at`, `wise_dates`, `status`, `fx_rate`, `wise_transfer_id`, `paid_at`.
- **Edge cases:** `saveDraft` no-ops on a non-open period; `deleteStatement`/`deleteAllStatements` refuse non-open periods and resolve the period by company+dates; TimeApproval delete refuses dates inside a locked/paid period.

### 4.2 Per-contractor payroll calculation (`calculate()`)

- **Period model (`periodFor`, arrears):** day ≤ 15 → `1st–15th`, payDate = last day of the month; day ≥ 16 → `16th–EOM`, payDate = 15th of next month. Constants: `HA_ANNUAL=20000`, `HA_ELIG_DAYS=180`, `PERIODS_PER_YEAR=24`, FT day = 8 h, PT day = 4 h.
- **Per contractor:**
  1. **Worked:** `(Σ tracked_seconds + Σ pto_seconds)/3600` (PTO paid).
  2. **Expected:** `expectedHours(contract,start,end)` = weekdays × dayH − weekday holidays × dayH (Sat/Sun holidays don't reduce expected). Holidays from `getHolidays()` (localStorage override else `defaultHolidays()`), editable via HolidayEditor.
  3. **Ratio:** `min(worked/expected, 5)` — **capped at 5**.
  4. **Gross:** `rate==null ? null : (ratio>=1 ? rate : round2(ratio*rate))` — **capped at the full rate**; pro-rated below.
  5. **Health allowance:** `0` until eligible (`hire + 180 d`); then **₱20 000 only in the period containing the hire anniversary** (clamped to day ≤ 28), else 0.
  6. **13th month:** `thirteenthAccrual(rate, hire, end)` = `(monthsWorkedInYear/12) × rate` = **half the full annual 13th** per payment.
  7. **PDD/Lunch & Bonus:** default 0, editable.
  8. **Performance shortfall (`deduction_php`):** `round2(rate − gross)` — the **"Perf short"** value, **informational, NOT subtracted from net**. (Real, user-entered deductions live in `misc_items`; the Reports UI tooltips disambiguate "Deductions — actually subtracted" vs "Perf. short — NOT subtracted." This column was renamed to `shortfall_php` in the `abc-helper-app` rewrite.)
  9. **Misc / net:** `miscTotal` adds `other_earns`/`other_hours`, subtracts `deduction` kind (stored positive); `net = gross + ha + t13 + pdd + bonus + miscSum`.
  10. **USD reference:** `net/fx` (reference only — **paid in PHP**; `fx` default ~58 from `open.er-api.com`).
  11. **Persist:** `saveDraft` upserts `pay_periods{open}` + `payments{status:'draft', payout_currency:'PHP', payout_amount=net, fx_rate}` on `(pay_period_id, worker_id)`.
- **Edge cases:** **Recalc guard** — if any row has overrides, `calculate()` fires a typed `RECALCULATE` confirm spelling out wiped Misc entries, with Undo. **Dropped time surfaced** (`unattributed`/`noLink` banners). **Rate-stale banner** — compares each snapshot `rate_php` vs the currently-effective rate. **Lock gate** — blocks rows with `net==null`; confirms on missing payout method / inactive worker.

---

## 5. Wise payouts & reconciliation

Edge fn `wise-payouts` (token only in the `WISE_API_TOKEN` secret). **It only creates quotes + draft transfers — it never funds.** Funding is always manual in Wise.

### 5.1 Authorization gate (all Wise actions)

`OWNER_ACTIONS={draft, batch}` (money-staging → **owner only**), `CRON_ACTIONS={poll, match}` (cron-secret path). User path validates the bearer → `admin_users.role` (403 if not admin; owner required for staging). Read-only actions (`recipients`, `status`, `rates`, `get_recipient`) are admin-gated.

### 5.2 Wise API draft batch (Path 3)

- **Trigger:** Process & Pay → "Pay via Wise API" → `WisePayouts` → **Create batch** (`createBatch`). Selects locked-period rows whose snapshot `payout_method='wise'`, with a recipient id, `amount>0`, and no existing `wise_transfer_id`.
- **Steps:** `wise-payouts batch` creates a **batch-group** (`sourceCurrency:"PHP"`), then per item a **quote** (PHP→PHP, `payOut:"BALANCE"`) + a **transfer** into the group (`targetAccount`=numeric recipient id, `quoteUuid`, `customerTransactionId=randomUUID`). Returns `{batch_group_id, results:[{worker_id, transfer_id, fx_rate, status:"drafted"}]}` — **group NOT completed or funded**. App writes back `payments {wise_transfer_id, fx_rate, status:"queued"}` and updates `workers.wise_recipient_id`.
- **States:** `draft → queued`.

### 5.3 Manual Wise batch file (Path 1)

`downloadWiseBatch` writes Wise's 10-column template using the recipient **UUID** (`recipient_uuid`); rows missing the UUID are surfaced and click-confirmed before drop. `guardedExport` stamps `localStorage` to warn against double-pay. *Note:* the Wise **API exposes only the numeric id, never the UUID** the CSV needs — so Path 3 is the API-native alternative.

### 5.4 Mark paid / unpaid (manual settlement)

`markPaid` → `payments {status:"sent", paid_at}` (BPI/Other arm an inline date input); `markUnpaid` reverses to `draft`. Both snapshot for Undo + log. `markAllUnpaid` operates only on `sent && !transfer_id` rows and **skips any row with a `wise_transfer_id`** (typed `UNPAID` confirm).

### 5.5 Poll Wise status

- **Trigger:** Process "Check Wise status" (`status`, read-only) or server `poll` (schedulable via cron-secret).
- **Steps (`poll`):** fetch `payments` with `wise_transfer_id`, GET each `/v1/transfers/{id}`; for **terminal-success** states (`outgoing_payment_sent`/`completed`/`sent`) PATCH `status:"sent"`, real `paid_at`, `wise_dates`, **and `wise_locked_at:now` (auto-lock)**. In-flight states are surfaced but not written. Idempotent. When all rows `sent`, the period auto-advances to `paid` (§4.1).

### 5.6 Reconcile / backfill missing transfer IDs (`match`)

- **Why:** CSV-uploaded and retro-imported periods have no `wise_transfer_id` (Wise generates them server-side).
- **CSV path:** `onReconcileFile` backfills `wise_transfer_id` **idempotently** by recipient UUID, flags amount variances, offers fuzzy name+amount suggestions, then polls.
- **`match` action:** fetch candidate `payments` (joined to recipient ids + period dates) → pull Wise transfer history for the union window (paged, padded ≥45 days) → **filter out `cancelled` ghost transfers** → index live transfers by numeric `targetAccount` + any UUID → **match per payment by recipient + amount (±₱1.00) + date window** (UI default 14 days). Outcomes: `matched_exact`, `matched_closest_date`, `ambiguous_exact`, `matched_with_variance[_overridden]`, `no_recipient`/`no_wise_transfer[_in_window]`/`unmatched`.
- **Variance auto-override (preserves `original_net_php`):** when recipient+window picks **exactly one** transfer with a differing amount and `original_net_php` is null, set `original_net_php = dbAmt` (pre-Wise) and `net_php = wiseAmt` (Wise's actual). Ambiguous (>1) writes the id but **never** auto-overrides the amount.
- **Orphan diagnostics:** unmatched payments get `candidate_orphan_transfers`; `linkOrphanRecipient` appends a "Historical recipient" to `workers.wise_recipients` (typed-confirm on name mismatch / ambiguity) so the next match links it.
- **Edge cases — FX drift:** `payments.fx_rate` at Calculate is the **market reference** (`open.er-api.com`); the batch is **PHP→PHP** so the contractor gets the exact PHP `net`, but the account is **USD-funded**, so Wise locks the **real USD→PHP rate** at conversion (re-readable via the `rates` action). The stored Calculate `fx_rate` ≠ the real locked rate. **Locked-row safety:** the variance-override writes `net_php`/`original_net_php` (protected columns), so it only succeeds *before* `wise_locked_at` is set (the override path itself sets it). Flagged as a money bug for *consolidated* multi-row transfers (not built) — single-client transfers are safe.

---

## 6. Client invoicing

`Invoicing` component; schema `schema/migrations/2026-06-10_invoicing.sql` (USD columns; **not** in core `schema.sql`). Read-only AR — never writes `payments`/`time_entries`.

- **Actors:** admin scoped to the client (`invoices_admin_all`: `is_owner() OR company_id in my_admin_company_ids()`).
- **Trigger:** Invoicing tab with its own **client** picker (the only tab not pinned to the employer).
- **Steps:**
  1. **Preview (`buildPreview`):** load the client's roster from `worker_companies` (`role`, `bill_rate_usd`, active) for `company_id=client`; load **employer** `time_entries` (`tracked_seconds` only — **PTO excluded**) for those workers in the window; per worker `hours = round(Σtracked/3600,2)`, `amount_usd = round(hours × bill_rate_usd,2)`; lines with `worked_hours>0`; `subtotal = Σ amount_usd`.
  2. **Generate (`generate`, only write path):** `allocate_invoice_no(year)` → `"{year}-{NNNN}"` (count of non-void invoices that year + 1) → insert `invoices` header (`status:'draft'`, `subtotal_usd`, `total_usd = round(subtotal × (1+markup/100),2)`, `markup_pct`, `currency:'USD'`) + `invoice_lines`; `audit_log invoice_generated`.
  3. **View/Print/Export read the snapshot:** standalone HTML invoice (From "Aaron Anderson E.H.S. LLC", Bill-to client, per-line table, footer "paid time off is not billed"), all values `escapeHtml`'d; CSV via `exportCsv`.
- **States:** `status` draft → sent → paid (or void). Lines immutable; **regenerate = void + new**.
- **Edge cases:** **double-invoice guard** — partial unique index `invoices_one_live_per_period on (company_id, period_start, period_end) where status<>'void'`; collision → "void it first to regenerate." Missing `bill_rate_usd` → `$0` lines + heads-up. `allocate_invoice_no` is count-based (not an atomic counter) — a theoretical concurrent-generate collision (`invoice_no` is not uniquely constrained). The shipped USD schema **diverges** from the PHP proposal in `multiclient-pipeline-spec.md` — the migration is authoritative.

---

## 7. Auth, admin & security

### 7.1 Admin Google-login gate

- **Steps:** `getSession()`/`onAuthStateChange` resolve a session (writing the email to `localStorage.sb_actor`, the audit actor). No session → `SignInScreen` → `signInWithOAuth({provider:"google"})`. With a session, the **allow-list check** `admin_users.select("role").eq("user_id", uid)` drives `myAdminRole` ∈ loading | owner | admin | null | error. Render gate: no session → SignInScreen; `null` → NotAuthorizedScreen; `error` → AccessErrorScreen; else the app.
- **Edge cases:** **fails closed** — a role-lookup network/5xx → AccessErrorScreen, never access. Google sign-in admits anyone; **authorization is `admin_users`** (the consent-screen test-user list is a soft pre-filter). The check re-runs only on real `user.id` change or explicit retry.

### 7.2 Admin vs owner roles

`admin_users.role ∈ (owner, admin)`. **owner** = full app + manages the admin list + company assignments; **admin** = full app minus admin-list, scoped to assigned companies. **Last-owner protection:** an `AFTER UPDATE OR DELETE … FOR EACH ROW` trigger raises `cannot remove or demote the last owner` when the post-statement owner count hits 0 (AFTER per-row specifically to catch multi-row/cascade demotes); `TRUNCATE` blocked by a separate trigger.

### 7.3 Inviting / binding a new admin (`pending_admins → admin_users`)

- **Trigger:** owner → AdminsModal "Add admin by email" → `admin-manage add_admin`.
- **Steps:** re-verify owner; `emailOk` (valid + allowed domain `abckidsny.com`/`abbilabs.com`); reject if the email is a contractor login (409); look up an auth user via service-role-only RPC `admin_lookup_auth_user` (locked down to prevent enumeration). **Never signed in** → upsert `pending_admins` (`{pending:true}`). **Auth user, already admin** → 409 `already_admin`. **Auth user, not admin** → insert `admin_users`. **First sign-in binding:** `bind_pending_admin_trg` (`AFTER INSERT ON auth.users`) inserts `admin_users` and deletes the pending row, wrapped in `exception when others then null` so binding **can never block a sign-in**.
- **Edge cases:** `pending_admins` RLS-locked (SELECT `is_owner()`, writes service-role only); cancel via `remove_admin {email}`. `admin_companies` is **email-keyed**, so company chips set on a pending invite carry over on binding.

### 7.4 Admin ↔ company scoping

- **Trigger:** owner toggles company chips → direct `admin_companies` writes under RLS (`is_owner()`).
- **Mechanism:** company-id-scoped tables swap `is_admin()` → `is_company_admin(company_id)` (`companies`, `audit_log`, `pay_periods`, `payments`, `rates`, `time_entries`, `worker_companies`); worker-scoped tables use `admin_can_see_worker(worker_id)` (`onboarding_*`, `contractor_logins`, `mood_checkins`, `portal_notifications`). **`workers` is split** into four policies (`workers_admin_insert` = any admin; select/update = `admin_can_see_worker(id) OR created_by = auth.uid()`; delete = `admin_can_see_worker` only) with `workers.created_by default auth.uid()` so an admin can read back a just-inserted unlinked row. **`documents`** gated on `admin_can_see_worker(worker_id) OR is_company_admin(company_id)` (onboarding uploads arrive with NULL `company_id`).
- **Edge cases:** **secure default** — an admin with no `admin_companies` rows sees nothing. Global-config tables (`admin_users`, `pending_admins`, `agreement_templates`, `announcements`, `portal_settings`) stay `is_admin()`/`is_owner()`. Ships a verbatim rollback.

### 7.5 Countersign permission (`admin_users.can_countersign`)

Owner sets it (and the display `name`) via `admin-manage update_admin`. Hiring flows filter the countersigner picker to `can_countersign !== false`; the wizard defaults to the current admin only if eligible. **The authoritative gate is server-side** `portal-countersign` (signer must be the assigned countersigner) — `can_countersign` is a UI/eligibility filter (absent/NULL counts as eligible). *Both `name` and `can_countersign` are schema drift* — see [Appendix C](#appendix-c--known-caveats).

### 7.6 Contractor portal auth (own-worker scoping)

Login = email + password + Cloudflare **Turnstile** (a soft challenge; Supabase Auth is the enforcer). `contractor_logins` links `auth_user_id` ↔ `workers.id` (`status='active'`), written only by the service role. Self-scoped **read** policies (additive, beside admin policies): `workers_contractor_read`, `payments/time_entries/pay_periods_contractor_read` (the last three also require `is_onboarded()`), `documents_contractor_read` (`kind<>'other'`). **No contractor write policies.** Verified by simulation: a contractor saw its own 38 payments and exactly 1 worker — no cross-contractor leakage. A revoked login drops out of `my_worker_id()`, severing access (onboarding data preserved).

### 7.7 Audit log

`audit_log(id, company_id → companies on-delete-set-null, actor, action, entity, detail jsonb, created_at)`. `logEvent` inserts with `actor = localStorage.sb_actor || "admin"` and **never throws**; `admin-manage` writes server-side with `actor: caller.email`. UI mutations build a **before→after diff** via `auditDiff(old, new, fields)`. The `AuditLog` tab shows newest-first (limit 500; date filters query past the cap) with humanized labels + CSV export. Logged actions include the `admin.*` family (server) and `add_contractor`/`edit_contractor`/`lock`/`mark_paid`/`import`/`override.gross`/etc. (UI). **Append-only is recommended but not enforced** — the live policy is `for all`, so a scoped admin can in principle update/delete their-company rows. `company_id` nullable so deleting a company preserves its trail.

---

## 8. Dashboard, reports & configuration

### 8.1 Admin overview dashboard

- **Trigger:** `overview` tab (default landing), mounted only when active (its own ErrorBoundary, re-queries on activate). No cron.
- **Steps:** **SWR paint** from `sessionStorage["eis_ov_"+scope]` (cold load → 6 skeleton tiles); one batched `Promise.allSettled` (each failure blanks only its tile): last-8 `pay_periods`+`payments`, pending time, locked-draft payments, failed payouts, setup gaps (`worker_companies`+`rates`), pending `documents`, open `onboarding_progress`. **THIS PAY CYCLE hero** — current period, state, **pay-day countdown**, Net = Σ`net_php`, **5-step pipeline** Time → Calc → Lock → Sent → Settled. **KPI tile grid** — each tile drills to a tab (current period → process, locked-not-sent → process, time pending → time, contractors needing setup → contractors, docs & onboarding → documents, payout issues → batches). **Net-pay sparkline** + delta pill. **Data-quality check** (`runDq`) flags `|tracked − paid| > 0.5 h`.
- **Edge cases:** per-tile isolation; motion disabled under `prefers-reduced-motion`. (The "From New York" weather is a *portal* feature, §10.)

### 8.2 Reports (CSV suite)

`reports` tab. **Payout by pay period** — `pageAll` `payments` (no 1000-row truncation) + summary cards + expandable per-period breakdown (Deductions vs Perf-short tooltips). **Contractor Pay Summary** (`PerContractorSummary`) — From/To + ContractorPicker; two CSVs (`contractor_summary_*.csv`, `contractor_statements_*.csv`). **Contractor pay & hours history** — per-period buckets, daily expand, `{name}_history.csv`. **Avg. Weekly Activity** (`UtilizationReport`) — per-ISO-week avg `activity_pct`. **Audit Log export** — §7.7. (`WiseReconciliation` lives in **Configuration**, not Reports.)

### 8.3 System configuration

`configuration` tab → `Configuration` hub (singleton `portal_settings` id=1). Six rows: **Employer/Clients** (`CompaniesModal` — add/edit, archive vs owner-only delete of an empty company via typed-name confirm; the employer can't be archived/deleted), **Hubstaff Projects → Clients** (`hubstaff_projects`, used by `cron_ingest` attribution), **Portal Fields** (`portal_settings.editable_fields`; payout destination is always admin-only), **Agreement Templates** (`agreement_templates`; seeded bodies are `[PLACEHOLDER]`), **Onboarding Configuration** (`portal_settings.onboarding_config`), and the **WiseReconciliation** card. `portal_settings`: read = any authenticated (the portal must know editable fields), write = `is_admin()`. **Rates** and **agreement templates** are the other config touchpoints (rates per-contractor in ProfileModal).

---

## 9. Notifications & email

Both digests are **cron-secret OR admin-JWT** gated (never bare anon) and **both compute + return JSON regardless**, sending only if their provider secrets are set.

- **Document-expiry digest (`documents-expiry-check`):** daily cron; `within_days` (default 30). Authorize → bound the query `expires_on lte today+(within+1)d` → join `workers`+`companies` → **skip non-active workers** → bucket overdue (`days<0`) / expiring_soon → if anything and **`RESEND_API_KEY`+`DOC_REMINDER_EMAIL_TO`+`DOC_REMINDER_EMAIL_FROM`** present, POST an HTML digest to Resend. **No DB writes.**
- **Hiring-docs review digest (`hiring-docs-review-check`):** §2.9; **Gmail SMTP** (`GMAIL_USER`+`GMAIL_APP_PASSWORD`).

> **Both are currently blocked on missing provider secrets in prod** (Resend keys for expiry; Gmail app-password for review) — each returns `emailed:false`/`email_configured:false` with the digest still in JSON. See [Appendix C](#appendix-c--known-caveats).

**In-portal notifications:** `portal_notifications` is **provisioned but inert** (zero references in either HTML app). What contractors actually see comes from the **announcements feed**, the **outstanding-docs reminder popup** (`DocReminder`), and the **Docs red badge**.

---

## 10. Contractor portal self-service

`portal/index.html` — 5 tabs (Home / Pay slips / Time / Docs / Profile); on ≥900 px the bottom bar becomes a left sidebar.

- **10.1 Pay statements (Pay slips):** own `payments ⨝ pay_periods` — full breakdown incl. `misc_items`, net, **Wise transfer id**, date. `is_onboarded()`-gated (RLS yields nothing until onboarded).
- **10.2 Time view:** own `time_entries` grouped by semi-monthly half (Worked + PTO + Total, daily expand). Read-only, gated.
- **10.3 Profile self-edit:** a field is editable **iff** in `portal_settings.editable_fields`; **Save** sends only changed fields via `portal-self update_profile`, which enforces `editable_fields ∩ SAFE_FIELDS` server-side (About fields → `profile_extras`). **Payout destination is always admin-only**; the contractor `wise_tag` is informational.
- **10.4 Documents:** §2.6 (upload, MIME/size guards, `contractor-docs/<uid>/…`, forced `pending`, 120 s signed-URL View).
- **10.5 Announcements & mood (Home):** admin posts via `AnnouncementsModal` → `announcements {title, body, author, active}` (Hide/Show flips `active`; RLS read = `active OR is_admin()`). Contractor **mood check-in** — within 2 h of the PHT shift start/end (`workers.shift_start/end`), an emoji Likert 1–5 → `mood_checkins {worker_id, mood, kind:'start'|'end'}` (self-insert RLS; admins read via `admin_can_see_worker`); guarded once/day/kind via `sessionStorage`.
- **10.6 Tools popup (one-time reveal):** `ToolsPopup` → `rpc("get_my_tools")` returns one-time **decrypted** tool logins → "Got it" → `rpc("ack_my_tools")`. Stored encrypted (`worker_tools` + RPCs `set_worker_tools`/`get_my_tools`/`ack_my_tools`/`decrypt_worker_tools`). *(In the `abc-helper-app` rewrite this was redesigned to one-time-reveal-then-purge — recoverable exactly once.)*

---

## Appendix A — Key tables, enums & helpers

| Object | Defined in | Notes |
|---|---|---|
| `workers` | `schema.sql` (+ migrations) | `status` (`active`/`inactive`/`ended`), `match_key`, `photo_url`, `wise_recipient_id`/`_uuid`/`wise_recipients`, `profile_extras`, `shift_start`/`_end`, `created_by` |
| `companies` | `2026-06-09_company_kind_employer_client.sql` | `kind` (`employer`/`client`), `contacts` jsonb, `tax_id` |
| `worker_companies` | `schema.sql` (+ drift) | `contract`, `role`, `weekly_hours` (drift), `bill_rate_usd`, `hubstaff_user_id`/`hubstaff_name`, `status`/`ended_on`; partial unique `(company_id, hubstaff_user_id)` |
| `rates` | `schema.sql` | effective-dated `amount_php`, `effective_start`/`_end`, `period_basis` (`semi_monthly`) |
| `time_entries` | `schema.sql` | `tracked_seconds`, `pto_seconds`, `activity_pct`, `source_name`, `import_batch_id`, `approval` (`pending`/`approved`/`rejected`); unique `(company_id, source_name, work_date)` |
| `pay_periods` | `schema.sql` | `state` (`open`/`locked`/`paid`), `locked_at`; conflict `(company_id, period_start, period_end)` |
| `payments` | `schema.sql` | `*_php` components, `deduction_php` (perf-shortfall, informational), `net_php`, `original_net_php`, `fx_rate`, `wise_transfer_id`/`wise_dates`/`wise_locked_at`, `misc_items`, `status` (`draft`/`queued`/`sent`/`failed`/`reconciled`); lock trigger `payments_lock_enforce()` |
| `invoices` / `invoice_lines` | `2026-06-10_invoicing.sql` | USD columns; `status` (`draft`/`sent`/`paid`/`void`); partial unique `invoices_one_live_per_period`; `allocate_invoice_no` |
| `onboarding_progress` | `2026-05-31_onboarding_progress.sql` | `current_stage`, `stage{1,2,3}_complete`, `completed_at` (**gate key**), `extra_documents`; admin-write policy `admin_can_see_worker` |
| `onboarding_signatures` | `2026-05-31_onboarding_signatures.sql` | immutable ledger; `doc_sha256`, `ip_address`, `user_agent`, `status` (`signed`/`superseded`/`disputed`), `signed_date`; UNIQUE `(worker_id, agreement_kind, doc_version)` |
| `onboarding_agreements` / `agreement_templates` | `2026-06-03_agreement_templates_and_countersign.sql` | per-hire prefill + countersign fields; templates keyed by `kind` |
| `documents` | `2026-05-31_documents_*` | `review_status` (`pending`/`approved`/`needs_replacement` + `waived`/`deferred` drift), `reviewed_by → auth.users`, `issued_on`, `side` |
| `admin_users` / `admin_companies` / `pending_admins` | `2026-06-06_*` | roles + email-keyed company scoping + invites; `name`/`can_countersign` drift |
| `audit_log` | `schema.sql` | `actor`, `action`, `entity`, `detail` jsonb |
| `announcements` / `mood_checkins` | `2026-05-30_announcements_mood.sql` (+ `…mood_kind`) | portal Home |
| `portal_notifications` / `onboarding_reminders` | `2026-05-31_*` | **inert / not wired** |
| `worker_tools` / `app_secrets` / `api_tokens` | runtime + migrations | encrypted tool creds; `cron_secret` & provider secrets; Hubstaff token |
| Helpers | see §0.3 | `is_admin`, `is_owner`, `is_company_admin`, `admin_can_see_worker`, `my_worker_id`, `is_onboarded` |

## Appendix B — Edge functions

All deployed `--no-verify-jwt` (in-code gate is the control).

| Function | Gate | Role |
|---|---|---|
| `hubstaff-sync` | cron-secret (`cron_ingest`) / admin-bearer (`sync_ingest`, `list_orgs`, `list_projects`) | Hubstaff time ingest + token rotation |
| `wise-payouts` | owner (`draft`/`batch`) / cron-secret (`poll`/`match`) / admin (read) | Wise draft + poll + reconcile (never funds) |
| `portal-admin` | admin-bearer | login lifecycle, tools email, withdraw, delete |
| `portal-self` | contractor session | set password, profile update, stage advance, finish |
| `portal-sign` | contractor session | agreement e-sign ledger |
| `portal-review` | admin-bearer | document review + signed-date edit |
| `portal-countersign` | admin-bearer (assigned countersigner) | agreement countersign |
| `admin-manage` | owner | admin allow-list management |
| `documents-expiry-check` | cron-secret / admin | document-expiry digest (Resend) |
| `hiring-docs-review-check` | cron-secret / admin | review digest (Gmail SMTP) |

## Appendix C — Known caveats

Read before recreating or auditing.

**Design-only / NOT wired (schema/design exists; no shipped code writes/reads it):**
- `portal_notifications` (the in-portal banner stack) — zero references in either HTML app.
- `onboarding_reminders` (dedupe log) + the contractor-facing onboarding nudge cron (day 2/5/9/14 → weekly → `stalled=true` at day 30) + `_shared/notify.ts` (Resend mailer in the design doc). `onboarding_progress.stalled` therefore stays `false` in prod. The **only** operational reminder is the HR digest `hiring-docs-review-check`.

**Out-of-band schema drift (applied via raw SQL, NOT in `schema/migrations/`):** `worker_companies.weekly_hours`; `onboarding_agreements.f_company_name`/`f_employment_type`/`f_hours_per_week`/`f_schedule`; `admin_users.name`/`can_countersign`; the `review_status` enum values `waived`/`deferred`; `app_secrets` DDL. Recreating the DB requires hand-authoring these. (`bill_rate_usd`, `companies.kind`, `shift_start/end` *are* in migrations.) The base `schema/schema.sql` predates the employer/client split and onboarding tables — the migrations are authoritative.

**Blocked on secrets (prod):** both email digests send nothing until their provider secrets are set — Resend (`RESEND_API_KEY`/`DOC_REMINDER_EMAIL_*`) for expiry, Gmail SMTP (`gmail_user`/`gmail_app_password`) for review and hire emails. (The app standardizes on Gmail SMTP for hiring/review; expiry still uses Resend.)

**Money / correctness:**
- `deduction_php` is the **informational performance shortfall** (`rate − gross`), **never subtracted** from net — distinct from real `misc_items` deductions. Renamed to `shortfall_php` in `abc-helper-app`.
- Wise `fx_rate` stored at Calculate is the **market reference**, not the **real USD-funded locked rate** Wise applies at conversion.
- The **multi-client seam is unbuilt:** per-client `payments` rows + a consolidated single Wise transfer (with the variance-override fix) are designed but not shipped; running time ingest for two `company_id`s against one Hubstaff org would double-count. Multi-client assignment is a hard blocker before going live (see [`docs/employer-client-model.md`](employer-client-model.md)).
- `allocate_invoice_no` is count-based (no atomic counter, `invoice_no` not uniquely constrained) — a theoretical concurrent-generate collision.

**Other:** `audit_log` append-only is recommended but **not enforced** (live policy is `for all`). Agreement template bodies ship as `[PLACEHOLDER — replace with executed legal text before go-live]`. The literal pg_cron job definitions (schedules, the `org_id`/`company_id` passed to `cron_ingest`) live in the Supabase Dashboard, not the repo.

---

*Generated by reading the live code across hiring, onboarding, time, payroll, payout, invoicing, auth, reporting, and portal subsystems. Component/function names are durable; `app/index.html` line anchors drift. When in doubt, the migration files and edge-function source are authoritative over `schema/schema.sql`.*
