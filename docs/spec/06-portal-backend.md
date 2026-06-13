# Appendix 06 — Contractor portal & backend (edge functions, data model, RLS, cron)

> Granular build spec. Master overview: [../FEATURES.md](../FEATURES.md). Anchors are `portal/index.html` unless prefixed; backend in `supabase/functions/*` + `schema/*`.

## 0. Project facts
Single-file React SPA (~2,189 lines). Hosting: Cloudflare Workers static assets (`portal/wrangler.jsonc` → worker `contractor-portal`, assets `./`). `portal/_headers`: `/` and `/index.html` → **`Cache-Control: no-store`** (disables bfcache); other assets `no-cache`; + X-Frame-Options DENY, nosniff, no-referrer, noindex. **CSP enforcing** (script-src self+unsafe-inline+unsafe-eval+cdnjs+esm.sh+challenges.cloudflare.com; connect-src self+*.supabase.co+wss+api.open-meteo.com+esm.sh+challenges; frame-src challenges; img-src self data: https: blob:). Turnstile site key `0x4AAAAAADfnaW1d76MhtZAb` (public; empty disables). Title "Workspace — Contractor Portal".

# PART A — Portal

## A1. Boot, session, self-update, guard
- **`useClient()`** (637): polls `window.__createClient` every 50ms; creates client, `getSession`, `onAuthStateChange`. Returns `{client,session,ready}`.
- **`App()`** (2146): `!client||!ready`→loading; `!session`→`<Login/>`; `must_set_password`→`<SetPassword/>`; load onboarding_config + onboarding_progress → `ob`; `enabled && !done`→`<OnboardingFlow/>`; else `<Portal/>` + `<ToolsPopup/>`. Root render (2186): `<App/>` + `<UnsavedGuardModal/>`.
- **Self-update** (419): `BUILD` (420) vs `version.txt?_=<ts>` `no-store` on load + visibility/focus; reload to `?_v=<latest>` (loop-safe 436; skips OAuth callbacks 428).
- **Unsaved guard** (447): `_guards` Map; `useUnsavedGuard({dirty,label,save?,discard?})` (461); only savable blocks; `confirmUnsaved()` (467) → `<UnsavedGuardModal>` (485, **Stay/Discard/Save**); hooked into goTab/signOut/Close/beforeunload.
- Helpers: `peso` (525), `hrs` (526), `fullName` (527), `fnErr` (587), `ageManila(dob)` (594, 18+ via Asia/Manila), `sha256Hex` (611), `deviceFingerprint` (617).
- **i18n** (529): `STRINGS.en` + `t(key,vars)` (579); live Tagalog greetings hardcoded in Home (`greetTL` 1335).
- Shared inputs: `PhoneInput` (357) + `PHONE_COUNTRIES` (237, US+PH pinned); `EmailInput` (405) + `WORK_EMAIL_DOMAINS=["123babytalks.com","abckidsny.com"]` (391).

## A2. Login (661-729)
EmailInput + password + logo. **Turnstile** (667): explicit `window.turnstile.render` into a ref, polls api.js; single-use token; only when site key non-empty (718); `resetCaptcha` (687) after each attempt. `signIn` (690): `signInWithPassword({email lower, password, options:{captchaToken}})` — **never client-blocks on Turnstile** (Supabase Auth enforces). `reset` (698): `resetPasswordForEmail`; "Forgot / set password".

## A3. SetPassword (2054-2112)
Trigger (2177): `must_set_password===true`. Validate ≥8 + match. `submit` (2058): (1) email from session, fall back `getUser` (2065); (2) `portal-self {action:"set_password", password}` (2072, service-role self-update bypasses "current password required" + clears flag); (3) **always `signInWithPassword`** with the new pw (2078, recovers spent session); on failure show "Sign out and retry with temp password". Escape: "⏻ Sign out" (2104).

## A4. Onboarding flow
**`OnboardingFlow`** (1790): refresh onboarding_progress + signed kinds; `completed_at`→`onDone`. `WelcomeIntro` (1551, "Welcome to Ability Builders"); `ProgressHeader` (1538, "Step n of 3" + pct via `overallPct` 625); **"Finish later / Sign out"** (1811).
- **Stage 1 Agreements** (`Stage1Agreements` 1743): sequential (next unsigned unlocked, rest 🔒). `AgreementViewer` (1679): template body + onboarding_agreements prefill (IC fallback, hire_date) → `mergeAgreement` (1652, fills `{{contractor_name|rate|monthly_rate|company_name|employer_name|start_date|position|countersigner_name|schedule|employment_type|hours_per_week|addendum|today}}`, auto-appends engagement + DST note; employer default "Aaron Anderson E.H.S. LLC"). **Scroll-to-bottom gate** (1713, IntersectionObserver threshold .9 → `reached`). `SignaturePad` (1561): Type/Draw (per `signature_methods.contractor`), full legal name, editable signed date, consent → `portal-sign {action:"sign", agreement_kind, doc_version, doc_sha256, signed_legal_name, signature_method, signature_data, scrolled_to_end, signed_date, device_fingerprint}`. `advance_from_stage1` (1752) when stuck.
- **Stage 2 Profile** (`Stage2Profile` 1851): 4 sub-tabs (`STAGE2_SECTIONS` 1829) Contact/Personal/Payout/About; required (`REQUIRED_S2` 1830) incl. ≥1 payout (gcash/paymaya/paypal/wise_tag); editable = all `SAFE_FIELDS`; saves via `portal-self {action:"complete_tab", tab, fields}` (1879); advances after last tab when server reports `stage2_complete`. Wise referral link (1921).
- **Stage 3 Documents** (`Stage3Docs` 1990, `UploadSlot` 1936): `DEFAULT_DOCS` (1999) Resume/Diploma/NBI(6mo)/Gov ID front+back; one slot per kind+side. **`<input type=file accept="application/pdf,image/jpeg,image/png">` — NO `capture`** (1979) → mobile shows Take Photo/Library/Browse. NBI extra issued-date input. `doUpload` (1940): validate MIME+≤10MB → Storage `contractor-docs/${uid}/${kind}/${ts}-${side?}${name}` → `documents` row (review_status pending). Replace/defer. **Finish onboarding** (2018) when all required approved → `portal-self {action:"finish_onboarding"}`.

## A5. Home / portal (1489-1535)
`Portal`: sticky header ("{first}'s Workspace" + email + Sign out), 5 tabs Home/Pay slips/Time/Docs/Profile; **Docs red badge** (1526) = outstanding count; ≥900px restyles bottom bar → left sidebar + 2-col grid (CSS 167-225).
- **`Home`** (1327): PHT clock + bilingual greeting (`greetTL` 1335) + NY-time sun/moon; **"From New York" hero** `NyPanel` (1216): dual clocks (Manila+NYC), open-meteo weather (no key), daily NYC trivia (`NYC_TRIVIA` 1168), SVG skyline matching NY time-of-day (`skyPhase` 1194), animated weather FX (CSS 94-133, `wxCategory` 1202), reduced-motion aware; **"This pay period"** paycard (1440): next/last pay + day-of-period bar with sliding ☀️; **announcements** "Word from Your Mother"/"From New York" (1427); **activity chart** `ActivityChart` (1265, SVG bars + moving avg); **quick links** `QuickLinks` (1078, Hubstaff/Gmail/Providersoft/Wise); **daily mood check-in** (1369, start/end emoji within 2h of PHT shift → `mood_checkins`); **outstanding-docs popup** `DocReminder` (1141).
- **`PaySlips`** (731): own payments ⨝ pay_periods; rich breakdown (Worked/Expected, ratio %, rate, gross, health, 13th, lunch, bonus, misc_items, net, method, wise transfer id, date). Paid = sent|reconciled.
- **`TimeView`** (799): own time_entries by semi-monthly half; Worked+PTO+Total; daily expand.
- **`ProfileView`** (950): header + 4 sub-tabs; editable iff in `portal_settings.editable_fields` (961); save → `portal-self {action:"update_profile", fields}` (changed only, 970); About→profile_extras; Wise referral link; Sign out.
- **`DocsView`** (861): inline DocReminder + generic upload (IC/W-8BEN/Gov ID) + own docs list + View (120s signed URL).
- **`ToolsPopup`** (2116): `rpc("get_my_tools")` → one-time decrypted tool logins; "Got it" → `ack_my_tools`.

# PART B — Backend

## B5. Edge functions (`supabase/functions/*`, all `--no-verify-jwt`; in-code gate is the control)
Common: read Authorization JWT → `GET /auth/v1/user` → check admin_users (and role for owner) OR `x-cron-secret` vs `app_secrets.cron_secret`. Service-role key for DB writes.

| Function | Auth | Actions |
|---|---|---|
| **portal-admin** | admin | create_login (auth user + must_set_password + link + seed onboarding + email-taken guard via `admin_lookup_auth_user` 265 + welcome email), reset_password, resend_hire_emails, update_login_and_resend, withdraw_offer (revoke+ban 876000h+ended+email; refuses if payments/time), revoke_login, delete_contractor (block if payroll; force destroys signed/uploaded; delete worker+files+auth user), send_tools_email (decrypt_worker_tools 495). **Gmail SMTP** (`smtp.gmail.com:465`, denomailer); templates `DEFAULT_HIRE_EMAILS` (57: welcome/credentials/tools/withdraw) overridable at `onboarding_config.hire_emails`; HTML-escaped (`esc` 51). |
| **portal-self** | contractor (via contractor_logins 122) | update_profile (`editable_fields ∩ SAFE_FIELDS` 28), complete_tab (Stage-2 `validateTab` 77 + monotonic advance), advance_from_stage1, finish_onboarding (all required docs resolved), set_password (service-role self-update). `EXTRA_KEYS` → profile_extras. |
| **portal-sign** | contractor | sign — one immutable signature (ON CONFLICT DO NOTHING); enforces sign order (116) + scroll-to-end (422 if not, 90); drawn = bounded data:image base64 ≤1MB (99); typed ≤300; captures IP/UA; soft name-mismatch flag (126); monotonic advance; audit. |
| **portal-review** | admin | approve (NBI freshness + override), needs_replacement (reason), waive, defer, set_signed_date; `reEvalStage3` (47) finalizes onboarding. |
| **portal-countersign** | admin | countersign — requires contractor signed first + assigned countersigner; immutable; IP/UA. |
| **admin-manage** | owner | add_admin (sign-in-first via pending_admins; `ALLOWED_DOMAINS=["abckidsny.com","abbilabs.com"]`; blocks contractor emails), set_role (can't demote last owner), update_admin (name+can_countersign), remove_admin. |
| **hubstaff-sync** | admin OR cron-secret (121; cron_ingest/activity_backfill secret-gated) | refresh token rotated in api_tokens; default rollup, list_orgs/list_projects/get_user, **cron_ingest** (daily UPSERT, ID-first match, name fallback, protects approval≠pending, activity_pct, lands on EMPLOYER), sync_ingest, activity_backfill. PTO from time_off_requests. |
| **wise-payouts** | admin; OWNER for draft/batch; cron-secret for poll/match (184) | **never funds**; profile/draft/batch/status/rates/recipients/get_recipient/poll (mark sent+dates+lock)/match (backfill wise_transfer_id, auto-override variance keep original_net_php, ±₱1, ±window_days 7). |
| **documents-expiry-check** | cron-secret OR admin (66) | daily digest (Resend) of documents expiring/overdue. |
| **hiring-docs-review-check** | cron-secret OR admin (91) | daily digest (Gmail SMTP) of pending new-hire docs; honors `review_notify.frequency`/include_deferred. |

## B6. Data model (`schema/schema.sql` + migrations)
Employer/client (`company_kind` migration): `companies.kind ∈ {employer,client}`; employer `11111111…` (Aaron Anderson EHS LLC); clients carry `bill_rate_usd` for invoicing.
- **companies** (36): id, name unique, status, hubstaff_org_id, kind.
- **workers** (47): identity-level (company-agnostic): names, match_key (generated), status, email, work_email, mobile, work_number/extension, ph_address, permanent_address, address_landmark, postal_code, date_of_birth, hire_date, payout_method, payout_account jsonb, wise_recipients jsonb, wise_recipient_id/uuid, wise_tag, gcash/paymaya/paypal, emergency_*, marital_status, education_level/course/year_graduated/school, shift_start/end (time PHT), photo_url, profile_extras jsonb, health_allowance_eligible, thirteenth_month_eligible.
- **worker_companies** (90): worker↔company, role, contract(FT|PT), hubstaff_name, hubstaff_user_id, status, started/ended_on, bill_rate_usd, weekly_hours. unique (worker,company); partial-unique (company,hubstaff_user_id).
- **rates** (114): amount_php, period_basis(semi_monthly), effective_start/end.
- **pay_periods** (129): period_start/end, pay_date, state(open|locked|paid), expected_hours_ft/pt, locked_at.
- **time_entries** (147): source_name, work_date(PHT), tracked/pto_seconds, project, activity_pct, approval(pending|approved|rejected), pay_period_id?, import_batch_id?. unique (company,source_name,work_date).
- **payments** (177): per (pay_period_id,worker_id): expected/worked_hours, performance_ratio, rate_php, gross/health_allowance/pdd_lunch/bonus/thirteenth_month/deduction/net_php, original_net_php, fx_rate, payout_currency/amount/method, wise_transfer_id, wise_dates jsonb, wise_locked_at, misc_items jsonb, status(draft|queued|sent|failed|reconciled), paid_at, note. Hard-lock trigger once wise_locked_at set (355).
- **documents** (236): worker_id, company_id, kind(ic_agreement,w8ben,gov_id,other,resume,diploma,nbi_clearance), title, storage_path, signed_on, expires_on, issued_on, side, mime_type, file_size_bytes, review_status(pending|approved|needs_replacement|waived|deferred), review_reason, reviewed_by, reviewed_at.
- **contractor_logins**: worker_id PK, auth_user_id unique, email, status(active|revoked), last_login_at.
- **admin_users**: user_id PK, email unique, role(owner|admin), name, can_countersign. **pending_admins**: email PK, role (trigger promotes on first sign-in). **admin_companies**: (admin_email, company_id).
- **onboarding_progress**: worker_id PK, current_stage, stage1/2/3_complete, name_mismatch_flag, stalled, started_at, completed_at (the gate).
- **onboarding_signatures**: immutable ledger — agreement_kind, doc_version, doc_sha256, signed_legal_name, signature_method/data, signed_date, scrolled_to_end, ip_address, user_agent, device_fingerprint, status. unique (worker,kind,version).
- **onboarding_agreements**: worker+kind PK, f_rate/f_start_date/f_position/f_company_name/f_employment_type/f_hours_per_week/f_schedule, addendum_type/text, prepared_by/at, countersigner_user_id/name, countersign_*.
- **agreement_templates**: kind PK, title, version, body.
- **portal_settings**: id=1, editable_fields jsonb, onboarding_config jsonb (onboarding_enabled, agreements[], profile_tabs[], documents[], signature_methods, hire_emails, review_notify).
- **announcements** / **mood_checkins** (mood 1..5, kind start|end). **audit_log**. **api_tokens** (Hubstaff rotating). **app_secrets** (cron_secret, gmail creds — service-role read only). **worker_tools** + RPCs set_worker_tools/get_my_tools/ack_my_tools/decrypt_worker_tools (encrypted).

## B7. RLS & security
Helpers: `is_admin()`, `is_owner()`, `my_worker_id()`, `is_onboarded()` (A8 gate), `is_company_admin(cid)`, `admin_can_see_worker(wid)`. Admins **company-scoped** (owners all; admins only assigned companies; admin tables no client write policy → all via admin-manage; ≥1 owner enforced). Contractors read-only to own rows; pay-data reads also require `is_onboarded()`; only contractor writes = mood_checkins insert (self) + documents insert (own folder, forced review_status=pending). Storage `contractor-docs` private (per-uid folders, 120s signed URLs). Anon key in client safe (RLS grants nothing without session). Admin app = Google OAuth; portal = email+password.

## B8. Cron
- **Daily Hubstaff ingest** — pg_cron ~04:00 Manila → `hubstaff-sync cron_ingest` with x-cron-secret; ID-first/self-healing; lands on employer.
- **Email digests** — documents-expiry-check (Resend) + hiring-docs-review-check (Gmail SMTP), cron-secret gated.
- **Wise reconcile** poll/match may be cron-driven. Secret = `app_secrets.cron_secret`.

### Caveats for a recreator
1. **Not in `schema/migrations/`** (applied via SQL editor): `app_secrets`, `worker_tools` + tools RPCs, and `admin_users.name`/`can_countersign` columns — author their DDL.
2. **Agreement bodies are placeholders** — `AGREEMENT_TEXT` (603) and seeded `agreement_templates` are "[PLACEHOLDER — replace with executed legal text before go-live]".
