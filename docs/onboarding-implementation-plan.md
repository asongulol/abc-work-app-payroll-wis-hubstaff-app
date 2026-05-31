# Onboarding Tasks — Master Implementation Plan

## 1. Summary

This plan assembles six workstreams (DB/RLS, Edge Functions, Portal UI, Admin UI, Notifications, Testing) into one dependency-ordered build for the 3-stage contractor onboarding gate defined in `docs/onboarding-workflow-design.md`: Stage 1 eSign 4 agreements (ICA, Non-Compete, NDA, BAA) with scroll-to-bottom + signature capture; Stage 2 complete 4 profile tabs (Contact / Personal / Payout / About Me); Stage 3 upload 4 docs (Resume/CV, Diploma/TOR, NBI clearance, Gov ID/Passport) reviewed by HR. The gate blocks all other portal features, enforced **both** client-side (boot fork in `portal/index.html` `App()`) and server-side (RLS `is_onboarded()` predicate on feature read policies). **Two operational realities shape everything below: (a) every DB migration is user-pasted SQL — the dev cannot run SQL programmatically, so each schema step is "hand this file to the user to paste in the Supabase SQL Editor"; (b) Cloudflare auto-deploys ONLY the `main` branch (~15s) for both single-file apps — so all work lands on a feature branch and merges to `main` only after its backing tables/edge fns are confirmed live in prod.** Edge functions deploy via CLI (`supabase functions deploy <name> --no-verify-jwt`).

**Cross-cutting type correction (overrides the design doc everywhere):** the doc's DDL (§3B/§3C/§3D) types `worker_id`/`reviewed_by` as `bigint`; the live schema is **`uuid`** throughout (`workers.id`, `documents.worker_id`, `contractor_logins.worker_id`, `my_worker_id()` all uuid). Every new table, FK, and column uses `uuid`. Treat the doc DDL as pseudo-code on type.

## 2. Current state → target

Today, `portal/index.html` `App()` (L461) resolves a session and renders the bottom-nav `<Portal/>` shell directly — there is no onboarding fork, no onboarding tables exist, and the five contractor read policies (`payments/time_entries/documents/workers/pay_periods_contractor_read`) gate only on `worker_id = my_worker_id()`. Reusable foundations already exist: `DocsView` Storage upload + signed-URL pattern, `ProfileView`/`FIELD_DEFS` (Contact/Personal/Payout/About Me sub-tabs), `portal-self`/`portal-admin` service-role edge-fn skeletons, the `documents-expiry-check` Resend+cron template, `logEvent()` audit writes, and `my_worker_id()`/`is_admin()` SECURITY DEFINER helpers. The target adds: `onboarding_progress` (gate state, `completed_at`), `onboarding_signatures` (eSign ledger), `documents` review columns + 3 new `document_kind` enum values, `portal_notifications` + `onboarding_reminders` tables, an `is_onboarded()` helper gating three feature read policies, new edge fns (`portal-sign`, `portal-review`, `onboarding-reminders`) plus extensions to `portal-self`/`portal-admin`, a full-screen `<OnboardingFlow/>` in the portal, an Onboarding review console in the admin app, and event-driven email + in-portal banners — all shipped behind a backfill that grandfathers every existing active contractor so the live app is never broken.

## 3. Milestone roadmap

| Milestone | Depends on | Deliverables | Ships to (branch) | Risk |
|---|---|---|---|---|
| **M0 — Schema (inert)** | — | A1 enums, A2 `onboarding_progress`, A3 `onboarding_signatures`, A4 `documents` review cols (+legacy neutralize), A5 `document_kind` ADD VALUE (own txn), A6 `onboarding_config`, E.2 `portal_notifications`, E.3 `onboarding_reminders`. All user-pasted SQL; no gate yet. | feature → applied to prod DB directly (SQL paste) | Low–Med (A4 not-null backfill; A5 enum-add must be its own txn) |
| **M1 — Edge fns + helper (inert)** | M0 | A7 `is_onboarded()` **+ grandfather backfill (atomic)**; E.1 `_shared/notify.ts`; `portal-sign`, `portal-review`, `onboarding-reminders` deployed; `portal-self` (complete_tab + guard + silent-drop fix); `portal-admin` provisioning hook. Helper exists but no policy uses it. | feature branch; fns deployed via CLI | Med (backfill correctness; fns live before gate — but change nothing yet) |
| **M2 — Portal flow (dark)** | M1 | C1 i18n, C2 boot gate read, C3 shell+header, C4–C6 Stage 1, C7 Stage 2, C8–C9 Stage 3, C10 completion, C11 + E.9 banner. Shipped **behind `onboarding_enabled=false`** feature flag. | feature → **main** (lands dark) | Med (large UI; flag-gated so invisible in prod) |
| **M3 — Admin review** | M1 | D0 scaffolding, D1 queue, D2 drill-down, D3 Stage-1 audit, D4 Stage-2 read-only, D5 review controls, D6 badges/refresh, D7 admin actions, D8 config (conditional). | feature → **main** | Low–Med (reads M0 tables; merge only after M0 applied) |
| **M4 — Notifications wiring** | M1, M2, M3 | E.4 N1 stage-complete, E.5 N2 upload→HR, E.6 N3/N4/N5/N7 review events, E.7 cron logic; secrets set; cron registered (user step). | feature branch; fns redeployed | Low (fire-and-log; never rolls back state) |
| **M5 — Gate cutover** | M0–M4 verified | **Backfill verify probe = 0**, then A8 enable `AND is_onboarded()` on 3 feature policies; F.3 REST probe before/after; flip `onboarding_enabled=true`. | user-pasted SQL (ordering-critical) + one-row flag update | **HIGH — lockout risk; see §6** |

## 4. Per-workstream steps (build order)

Legend: **[SQL-paste]** user pastes SQL in Supabase SQL Editor · **[code]** edit file + esbuild syntax-check + commit on feature branch · **[deploy]** `supabase functions deploy … --no-verify-jwt` · **[user-action]** dashboard/CLI step the user performs.

### A. Database & RLS (all [SQL-paste], authored as `schema/migrations/2026-05-31_*.sql`, committed individually)

Apply strictly in this order. **A7 must be applied and verified before A8.**

| # | File | Step | Notes |
|---|---|---|---|
| A1 | `…_onboarding_enums.sql` | Create enums `onboarding_stage`, `agreement_kind`, `signature_method`, `signature_status`, `review_status` (idempotent `do $$…duplicate_object$$` guards). | Low risk, additive. |
| A2 | `…_onboarding_progress.sql` | State table, **uuid PK** `worker_id references workers(id)`; cols `current_stage, stage1_last_kind, stage2_last_tab, stage{1,2,3}_complete, name_mismatch_flag, stalled, completed_at, started_at, updated_at`. RLS `for select … using (worker_id = my_worker_id() or is_admin())`. **No insert/update/delete policy** (service-role only). | Admin read added vs doc §3D (needed by admin queue). |
| A3 | `…_onboarding_signatures.sql` | eSign ledger, **uuid** `worker_id`; cols per §3B incl. `ip_address inet`, `user_agent`, `device_fingerprint`, `doc_version`, `doc_sha256`, `scrolled_to_end`, `status`. `unique (worker_id, agreement_kind, doc_version)`. RLS SELECT-own + `is_admin()`; **no contractor INSERT** (signing via `portal-sign` only). | Immutable/INSERT-only by design. |
| A4 | `…_documents_review_cols.sql` | `add column if not exists review_status review_status not null default 'pending', review_reason text, reviewed_by uuid references workers(id), reviewed_at timestamptz, issued_on date, mime_type text, file_size_bytes bigint`; index on `review_status`. **In the same file:** `update documents set review_status='approved' where created_at < now();` to neutralize legacy docs so they don't pollute the HR queue. | **Owner decision (§7):** confirm legacy-neutralize + `reviewed_by` FK target (workers vs auth.users). |
| A5 | `…_document_kind_values.sql` | `alter type document_kind add value if not exists 'resume'`/`'diploma'`/`'nbi_clearance'` only. | **Own migration, run alone** — enum value cannot be used in the txn that adds it. `gov_id` reused for ID/Passport. Irreversible-forward. |
| A6 | `…_onboarding_config.sql` | `alter table portal_settings add column if not exists onboarding_config jsonb not null default '{…agreements[],documents[]…}'`; guarded `insert … on conflict (id) do nothing` for id=1. | Data-driven "4 of 4"; `doc_sha256` filled by agreement-authoring step. |
| A7 | `…_is_onboarded_and_backfill.sql` ⚠️ | `create or replace function is_onboarded()` (SECURITY DEFINER, stable, checks `completed_at is not null`) **AND** grandfather backfill in **one file**: `insert into onboarding_progress(worker_id, current_stage, stage{1,2,3}_complete, completed_at, started_at, updated_at) select cl.worker_id,'complete',true,true,true,now(),now(),now() from contractor_logins cl where cl.status='active' on conflict do nothing`. | **HIGH.** Helper inert until A8. **Verify query** (hand to user): `select count(*) from contractor_logins where status='active' and worker_id not in (select worker_id from onboarding_progress where completed_at is not null);` must return **0** before A8. |
| A8 | `…_feature_rls_gate.sql` ⚠️ | Add `and is_onboarded()` to **only** `payments_contractor_read`, `time_entries_contractor_read`, `pay_periods_contractor_read`. **DO NOT gate** `workers_contractor_read` (Stage-2 reads own row) or `documents_contractor_read` (Stage-3 self-view). | **HIGH — the gate goes live here.** Keep the un-gate rollback SQL (the three policies without the predicate) in the same PR. Do not paste until A7 verify = 0. |

### B. Edge functions (build order)

**B.0 shared helpers** (land with first fn, copy-paste per fn or `_shared/onboarding.ts` if local imports deploy cleanly — verify with one deploy): `callerWorkerId(req)`, `callerAdminWorkerId(req)`, `clientIp(req)` (server-side `x-forwarded-for`), `reEvalProgress(worker_id)` (recompute stage flags from source tables, set `completed_at` on stage-3 done). **Sequencing guard in every finalizer:** reject `409 stage_out_of_order` if the prior stage's `*_complete` is not true.

1. **[code]+[deploy] `portal-sign` (NEW).** Stage-1 signature capture. Validates caller→active worker, agreement sign order (`ic_agreement→non_compete→confidentiality_nda→baa`), `scrolled_to_end===true`, version+sha256 present. Captures IP/UA **server-side**; `device_fingerprint` best-effort (null never fails, §6.8). Soft name-mismatch → `name_mismatch_flag=true` but succeeds. Idempotent insert keyed `(worker_id, agreement_kind, doc_version)` via `Prefer: resolution=merge-duplicates`. `audit_log agreement.signed`; `reEvalProgress` sets `stage1_complete` + `current_stage='stage2_profile'` on 4/4.
2. **[code]+[deploy] `portal-self` guard + silent-drop fix.** Add sequencing guard (`complete_tab` rejects if `stage1_complete` not true). Fix `editable_fields` allow-list silently dropping required onboarding fields — **decision (§7):** seed `editable_fields` with all Stage-2 columns (preferred if admin UI exposes them) OR bypass the allow-list for known onboarding fields while still enforcing `SAFE_FIELDS` (never accept `payout_method`/`work_*`/`email`).
3. **[code]+[deploy] `portal-self` `complete_tab` action.** Write fields, re-read `workers`, run §3A validators per tab server-side (contact: mobile `^(\+63|0)9\d{9}$`, postal `^\d{4}$`, DOB age≥18; personal: emergency fields + conditional course/year/school; payout: only the handle matching admin `payout_method`; about_me: no required fields, completes on explicit call). On pass set `stage2_last_tab`; when all 4 validate set `stage2_complete=true`, `current_stage='stage3_docs'`. On fail return `field_errors`, do not advance.
4. **[code]+[deploy] `portal-review` (NEW, admin-only) — approve/reject.** `callerAdminWorkerId` resolves `reviewed_by` server-side (never client-supplied). approve → `review_status='approved'`; needs_replacement → requires non-empty `review_reason`. NBI freshness guard at approval (§6.1). `reEvalProgress`: Stage-3 complete iff every required kind has an approved row (gov_id needs both front+back). Sets `completed_at` + `audit_log onboarding.completed` on full complete.
5. **[code]+[deploy] `portal-review` admin actions.** `reopen_stage` (flip `*_complete` / set doc(s) needs_replacement, require reason), `mark_stage_complete` (force, require reason, heavily audited). `approve_all_pending` loop (no bulk reject). Revoke stays in `portal-admin`.
6. **[code]+[deploy] `onboarding-reminders` cron (NEW).** See E.7.
7. **[code]+[deploy] `portal-admin` provisioning hook.** After `create_login` `contractor_logins` insert, also `insert into onboarding_progress(worker_id) … on conflict do nothing` (`current_stage='stage1_sign'`) so new hires are gated from session 1 (§1.5).

### C. Portal UI (`portal/index.html`, single babel block; esbuild syntax-check every commit)

C1–C3 are dependency-free and ship safely first (grandfathered contractors hit `<Portal/>` unchanged). All strings via `t()`; **no signature-pad library** (raw `<canvas>` for Draw, `<input>` for Type).

1. **C1 [code]** `STRINGS{en}` + `t(key,vars)` catalog (§2.6 keys).
2. **C2 [code]** Boot gate in `App()` (L461): after session, fetch `onboarding_progress.maybeSingle()`; `completed_at==null` (or no row) → `<OnboardingFlow/>`, else `<Portal/>`. **Gate branch reads `portal_settings.onboarding_enabled`; renders flow only when flag true (feature-flag dark launch).**
3. **C3 [code]** `<OnboardingFlow/>` shell + `<ProgressHeader/>` (Step X of 3 · N%, `role="status" aria-live="polite"`), `overallPct()` (§4.6), `<WelcomeIntro/>`.
4. **C4 [code]** `<Stage1Agreements/>` 4 locked cards in fixed order; reads signed set from `onboarding_signatures`.
5. **C5 [code]** `<AgreementViewer/>` modal: scroll region + `IntersectionObserver` bottom sentinel + accessible "I've reached the end" button; `AGREEMENTS` const holds text + `doc_version` + title.
6. **C6 [code]** `<SignaturePad/>` Type/Draw + legal name + consent + `device_fingerprint`/`client_nonce`; on Sign → `invoke('portal-sign', …)` (IP/UA NOT sent). Soft name-mismatch warning. *(needs `portal-sign`)*
7. **C7 [code]** `<Stage2Profile/>` reuses `FIELD_DEFS`; guided L→R tab unlock, per-field validation, `aria-invalid`/error summary, read-only fields as `readOnly` not `disabled`, localStorage draft. Saves via `portal-self` `complete_tab`. *(needs B step 2–3)*
8. **C8 [code]** `<Stage3Docs/>` 4 upload cards (Gov ID front+back = two rows), path `<auth.uid()>/<kind>/<uuid>-<name>`, idempotent insert keyed `(worker_id,kind,storage_path)`, `capture="environment"`, ≤10MB PDF/JPG/PNG guard, `downscaleImage()`. *(needs A4/A5)*
9. **C9 [code]** Review badges (Pending/Approved/Needs-replacement, icon+text), verbatim `review_reason`, Re-upload, signed-URL view, Finish disabled until all 4 (+both Gov ID sides) approved; refetch on focus.
10. **C10 [code]** `<OnboardingComplete/>` → "Go to my portal" tears down flow → `<Portal/>`. *(needs `completed_at` wiring)*
11. **C11 [code]** In-portal banner — see E.9.

### D. Admin UI (`app/index.html`; esbuild syntax-check every commit)

1. **D0 [code]** Scaffolding: `ONB_DOC_KINDS`, `ONB_AGREEMENTS`, `REVIEW_REASONS` (§6.9), `progressPct()` helper; add **Onboarding** tab to `tabGroups` (L8043) under "Review"; mount `<OnboardingAdmin/>` placeholder (no DB read — green before M0).
2. **D1 [code]** Queue: join `onboarding_progress`←`workers`←`contractor_logins` + `documents` counts (filtered to `ONB_DOC_KINDS`). Columns per §5.1; Status = Complete / Action needed (HR) / Stalled / In progress; default-sort "Action needed" top. Reuse `useSortFilter`/`useQuery`. *(needs M0)*
3. **D2 [code]** `OnboardingDrilldown` modal (reuse `modal-bg`/`modal`), 3 collapsible stage panels + `name_mismatch_flag` banner.
4. **D3 [code]** Stage-1 signature audit panel (read-only): legal name, signed time, IP, fingerprint, `doc_version`+`doc_sha256`, copy-to-clipboard; lazy signed-URL for drawn glyphs.
5. **D4 [code]** Stage-2 read-only render of the 4 tabs; label HR-set fields "Set by HR"; **no government enrollment numbers** (none exist — honor scope).
6. **D5 [code]** Stage-3 review controls: list `documents` (incl. gov_id front/back, full rejection history newest-first), signed-URL view (`createSignedUrl(path,60)`), Approve / Needs replacement (reason required) → `invoke('portal-review', …)`; Approve-all-pending loop; `logEvent document_review`. *(needs `portal-review`)*
7. **D6 [code]** Wire decisions back to queue refresh; top-of-queue "N contractors need HR review" banner.
8. **D7 [code]** Admin actions footer: Re-open stage, Mark complete (required reason + `window.confirm`), Revoke (reuse `portal-admin revoke_login`) → all via edge fn + `logEvent`.
9. **D8 [code] (conditional)** Extend `PortalSettingsModal` (L806) with onboarding config IF A6 added config keys; **skip if nothing admin-editable**.

### E. Notifications & Cron

Event→channel authoritative table (N1 stage-complete banner+email; N2 upload→HR email; N3 approve banner; N4 needs-replacement banner+email; N5 complete email to contractor+HR; N6 stalled email+banner; N7 3rd-rejection HR-lead email).

1. **E.1 [code]** `supabase/functions/_shared/notify.ts`: `sendEmail()` (Resend block cloned from `documents-expiry-check`, never throws), `insertBanner()`, `KIND_LABEL`. Secrets: reuse `RESEND_API_KEY`; new `ONB_EMAIL_FROM`, `ONB_HR_EMAIL_TO`, optional `ONB_HR_LEAD_EMAIL`, `PORTAL_URL`/`ADMIN_URL`.
2. **E.2 [SQL-paste]** `portal_notifications` table (**uuid** `worker_id`) + `portal_notification_kind` enum + RLS (select-own undismissed, update-own dismiss; inserts service-role only).
3. **E.3 [SQL-paste]** `onboarding_reminders` log table (**uuid** `worker_id`, `stage_at_send onboarding_stage`, `reminder_day int`); RLS enabled, service-role only.
4. **E.4 [code]+[deploy]** Wire N1 into `portal-sign` (stage 1 done) and `portal-self` (stage 2 done, fire once on false→true transition).
5. **E.5 [code]+[deploy]** Wire N2 (upload→HR) into the Stage-3 finalizing edge fn; idempotent on `(worker_id,kind,storage_path)`.
6. **E.6 [code]+[deploy]** Wire N3/N4/N5/N7 into `portal-review` (fire-and-log after the review write commits).
7. **E.7 [code]+[deploy]** `onboarding-reminders` cron (clone `documents-expiry-check`): select `completed_at is null and stalled=false`, skip non-active logins; cadence day 2/5/9/14 → weekly 21/28 → day-30 sets `stalled=true`; one reminder per bucket (check `onboarding_reminders`); email N6 + banner; log both channels.
8. **E.8 [deploy]+[user-action]** Deploy all fns; set secrets via CLI; register `onboarding-reminders` schedule (daily `0 1 * * *` = 09:00 Manila) — **user step** in Dashboard/pg_cron.
9. **E.9 [code]** Portal boot reads `portal_notifications` (undismissed, newest-first); dismissable banner stack (needs-replacement reason as visible text, not tooltip); dismiss writes `dismissed_at`. *(needs E.2)*

### F. Testing & rollout (the cutover owner)

1. **F.1 [user-action]** Safe-test setup on prod (no staging): disposable test contractor via `portal-admin create_login` (a Gmail you control); confirm Supabase PITR/backup on + record restore point; `onboarding_enabled` flag default false.
2. **F.2** Execute ship order = M0→M1→M2→M3→M4→M5 exactly (gate predicate dead last).
3. **F.3 [user-action]** RLS gate REST probe (raw PostgREST with test-contractor + live-contractor JWTs) **before AND after A8** — the live-contractor `/payments` row is the lockout canary; if it returns `[]` after A8, execute rollback immediately.
4. **F.4** Rollback ladder: gate lockout → re-paste 3 policies without `is_onboarded()` (seconds); broken UI → flip `onboarding_enabled=false` or git-revert app commit (~15s redeploy); bad fn → redeploy prior version; enum-add mistakes are forward-only (prevent, don't drop).
5. **F.5 [user-action]** Run the full acceptance checklist (§5) with the test contractor once flag on; sign-off gate = all server-gate (B) checks + live-contractor canary pass before flipping `onboarding_enabled=true` globally.
6. **F.6** Verification mechanics: esbuild syntax-check on both apps' babel blocks per commit; `deno check`/`supabase functions serve` + curl smoke-test per fn; user pastes confirmation SELECTs after each SQL block.

## 5. Consolidated acceptance criteria

**Client gate**
- [ ] Login with `completed_at IS NULL` mounts `<OnboardingFlow/>`, not the bottom-nav shell; nav unreachable until complete.
- [ ] Progress header shows correct Step X of 3 · N% (§4.6); reopening resumes at first incomplete step.

**Server gate (authoritative — via F.3 REST probe, not UI)**
- [ ] Un-onboarded contractor gets `[]` from `/payments`, `/time_entries`, `/pay_periods`.
- [ ] Same contractor still reads own `/workers` row and own `/documents` (un-gated by design).
- [ ] `PATCH /onboarding_progress.completed_at` denied to contractor JWT (no update policy).
- [ ] Out-of-order finalization (sign baa first; save tab 2 before 1; upload before Stage 2) rejected server-side (`409`).
- [ ] **Grandfathered live contractor still reads all feature tables (no regression) — the lockout canary.**

**Stage 1**
- [ ] Sign disabled until scroll-to-bottom + accessible end button satisfied.
- [ ] `onboarding_signatures` row has legal name, method, data, `signed_at`, **server-observed `ip_address`**, `user_agent`, `device_fingerprint` (or null), `doc_version`, `doc_sha256`, `scrolled_to_end=true`.
- [ ] 4th signature sets `stage1_complete=true`; signed in order ic→nc→nda→baa; replayed POST creates no duplicate (idempotent).

**Stage 2**
- [ ] Tabs unlock L→R; locked tab `aria-disabled`. Validation enforced **server-side** in `portal-self` (mobile, postal, DOB≥18, conditional education).
- [ ] Payout requires only the handle matching admin `payout_method`; read-only fields `readOnly` and rejected if submitted.
- [ ] All 4 valid → `stage2_complete=true`; name mismatch sets soft `name_mismatch_flag`.

**Stage 3 + HR review**
- [ ] Upload → `contractor-docs/<auth.uid()>/<kind>/<uuid>-<name>` + `documents` row `review_status='pending'`, `mime_type`, `file_size_bytes`; client rejects >10MB / non-PDF·JPG·PNG; Gov ID both sides as two rows.
- [ ] Admin queue lists contractor "Action needed (HR)"; signed-URL preview opens file.
- [ ] Approve writes `review_status='approved'`, server-derived `reviewed_by`, `reviewed_at` + `audit_log document_review`.
- [ ] Needs-replacement blocks empty reason; contractor sees verbatim reason + re-upload → new pending row, prior retained.
- [ ] All 4 (incl. both Gov ID sides) approved → `stage3_complete=true`, `current_stage='complete'`, `completed_at=now()`, `audit_log onboarding.completed`.

**Progress math / lifecycle**
- [ ] Stage-3 pending = 50%/doc, needs_replacement = 0%; `completed_at` set only when all 4 approved.
- [ ] Revoke blocks access but deletes no onboarding data; re-activation resumes.
- [ ] Cron sends day 2/5/9/14 → weekly → stops + `stalled=true` at day 30, logging each send.
- [ ] New login via `portal-admin` gets an `onboarding_progress` row at creation (gated from session 1).
- [ ] Notifications fire (banner+email) on stage-complete, approve, needs-replacement, complete, stalled, 3rd-rejection; mailer failure never rolls back state.

## 6. ⚠️ CRITICAL SEQUENCING RULE — grandfather BEFORE the gate

**This app is PRODUCTION with live, active contractors. The instant the RLS predicate `AND is_onboarded()` lands (migration A8 / ship step 8), every contractor whose `onboarding_progress.completed_at` is NULL loses access to pay slips, time, and pay periods.** Therefore:

1. **A7 (the `is_onboarded()` helper + grandfather backfill) MUST be applied and VERIFIED before A8 (the gate predicate).** They are separate pastes but the same session; A8 is never pasted until A7's verify query returns **0**:
   `select count(*) from contractor_logins where status='active' and worker_id not in (select worker_id from onboarding_progress where completed_at is not null);` → **must be 0.**
2. **Run the F.3 REST probe between A7 and A8**, and again after A8. The live-grandfathered-contractor `/payments` probe is the lockout canary — if it returns `[]` after A8, the backfill missed someone: **immediately re-paste the three feature policies WITHOUT `is_onboarded()`** (rollback SQL kept ready in the same PR), restore access, fix the backfill, re-probe, re-apply.
3. Defense in depth: `is_onboarded()` may additionally return true for any worker whose `contractor_logins` predates a `cutoff_at` constant (gate-by-cutoff) so a missed backfill row still doesn't lock anyone out — **owner decides** between pure backfill vs. cutoff-date (see §7).
4. Apply A8 during a low-traffic window with the un-gate rollback paste on hand.

## 7. Open decisions for the owner

1. **Grandfather scope** (blocks A7): mark **all** existing actives complete (recommended) vs. **gate only logins created after a cutoff date** (defense-in-depth via `cutoff_at` in `is_onboarded()`). Production money/access — owner sign-off required.
2. **Feature-flag vs. cutoff for client rollout**: ship the portal flow dark behind `portal_settings.onboarding_enabled` (recommended — lets UI land on `main` before the gate) and/or gate-by-cutoff date. Confirm the flag location/name (`portal_settings.onboarding_enabled` jsonb on id=1).
3. **A4 `reviewed_by` FK target**: are HR reviewers rows in `workers` (FK `references workers(id)`) or `auth.users`/admin email? If admins aren't workers, change the FK or store admin email instead.
4. **A4 legacy-doc neutralize**: confirm `update documents set review_status='approved' where created_at < <cutoff>` so pre-onboarding docs don't pollute the HR queue (recommended: yes).
5. **`portal-self` silent-drop fix**: seed `editable_fields` with all Stage-2 columns vs. bypass the allow-list for known onboarding fields (still enforcing `SAFE_FIELDS`). Pick (a) if the admin UI already exposes those fields.
6. **Signature library**: confirmed **none** — raw `<canvas>` for Draw, `<input>` for Type. Owner to confirm acceptable.
7. **Email provider**: confirmed **Resend** (reuses the `documents-expiry-check` mailer + `RESEND_API_KEY`). Confirm verified sender for `ONB_EMAIL_FROM` and the `ONB_HR_EMAIL_TO`/`ONB_HR_LEAD_EMAIL` inboxes.
8. **Signature/document retention**: `onboarding_signatures` is INSERT-only/immutable (legal evidence) and `document_kind` enum additions are forward-only (Postgres can't drop enum values) — confirm retention policy and that these are acceptably permanent.
9. **Staging rehearsal**: no staging environment exists. Confirm whether to stand up a throwaway Supabase project to rehearse A7+A8, or proceed on prod with the test-contractor + backup + canary discipline (per the staging-before-prod preference, rehearsal is advised for this DB/auth/money change).
