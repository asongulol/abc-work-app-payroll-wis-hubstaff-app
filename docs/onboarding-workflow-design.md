# Contractor Onboarding Tasks — Design Document

**Context.** This document specifies the one-time "Onboarding Tasks" workflow for Philippine independent contractors of **Aaron Anderson E.H.S. LLC** (a NY-based BPO; named **"Ability Builders"** in-app — both names refer to the same entity). It runs in the mobile-first contractor portal (`portal/index.html`, `portal.abbilabs.com`) and the desktop admin app (`app/index.html`, `payroll.abbilabs.com`), backed by Supabase (Postgres + RLS + Auth + Storage + Edge Functions, project `cgsidolrauzsowqlllsz`, PRODUCTION). No build step exists; both apps are single-file in-browser-Babel React.

> **Status: DRAFT.** This is a working design for owner review; it is not yet approved for implementation. Open questions are collected at the end. Compliance content is engineering-to-control mapping, **not legal advice** — licensed PH and US/NY counsel must review before go-live.

---

## Table of Contents

1. [Overview, Architecture & Gating Model](#1-overview-architecture--gating-model)
2. [User-Facing Flow & Microcopy](#2-user-facing-flow--microcopy)
3. [Data Model](#3-data-model)
4. [Status Model & State Transitions](#4-status-model--state-transitions)
5. [HR / Admin View & Notifications](#5-hr--admin-view--notifications)
6. [Edge Cases](#6-edge-cases)
7. [Accessibility & Localization](#7-accessibility--localization)
8. [Compliance — PH DPA 2012 & US/NY Record-Keeping](#8-compliance--ph-dpa-2012--usny-record-keeping)
9. [Open Questions / Decisions for the Owner](#9-open-questions--decisions-for-the-owner)

> **Canonical naming used throughout (contradictions resolved).** The onboarding state table is **`onboarding_progress`** (keyed by `worker_id`, one row per worker; see §3D); references to a "`contractor_onboarding`" table in early drafts mean this same table. The Stage-1 signature ledger is **`onboarding_signatures`** (see §3B); references to "`agreement_signatures`" mean this same table. Document review status lives on the existing **`documents`** table in the **`review_status`** column with enum values **`pending` / `approved` / `needs_replacement`** (see §3C). The five abstract workflow statuses (`not_started` / `in_progress` / `submitted` / `approved` / `rejected`, §4) are the *task-level* vocabulary; for Stage-3 uploads they map onto `documents.review_status` as `submitted→pending`, `approved→approved`, `rejected→needs_replacement`. The server-side gate helper is **`is_onboarded()`**.

---

## 1. Overview, Architecture & Gating Model

### 1.1 Purpose & placement

The **Onboarding Tasks** flow is a one-time, mandatory gate that runs the first time a contractor authenticates to the portal. Until onboarding is complete, the portal does **not** render its normal bottom-nav shell (Home, Pay slips, Time, Docs, Profile). Instead it renders the onboarding flow full-screen. This guarantees that every active contractor has, in order: (1) e-signed the four legal agreements, (2) filled and validated their four profile tabs, and (3) uploaded the four required identity/credential documents for HR review — before they can see pay slips, time, or any other feature.

Onboarding sits *after* Supabase Auth and `my_worker_id()` resolution but *before* the tab shell. It does not introduce a new identity concept; it keys entirely off the existing `worker_id`.

### 1.2 Two-layer gating (client cannot bypass via REST)

Gating is enforced in **two independent layers**. The client layer is for UX; the server layer is the real enforcement, because the portal talks to Supabase directly over the REST/RPC API and a determined user could call those endpoints without ever loading our JS.

**Layer 1 — Client (UX only).** On boot the portal reads the onboarding state row for the session's worker (`select … from onboarding_progress where worker_id = my_worker_id()`). If `completed_at is null` (equivalently, `current_stage <> 'complete'`), the app mounts `<OnboardingFlow/>` and never mounts the tab shell. The flow computes the current stage from the state row and refuses to render a later stage until the earlier one's stage-completion timestamp is set.

**Layer 2 — Server (authoritative).** Bypassing the client must fail:

| Surface | Enforcement |
|---|---|
| Profile writes (Stage 2) | `portal-self` already validates `SAFE_FIELDS` server-side. It additionally records per-tab completion and **must not** be the thing that unlocks features by itself — feature data stays gated by the checks below. |
| Document uploads (Stage 3) | Storage RLS already confines a contractor to their own `auth.uid()` folder; the `documents` insert is allowed, but the row lands as `review_status = 'pending'` and does not satisfy the gate until HR approves. |
| Feature reads (Pay slips, Time, etc.) | RLS policies on the feature tables add a predicate: rows are visible only when the caller has finished onboarding. Concretely, gate on a `SECURITY DEFINER` helper `is_onboarded()` that returns `true` when `onboarding_progress.completed_at is not null` for `my_worker_id()`. Existing per-worker policies become `USING ( worker_id = my_worker_id() AND is_onboarded() )`. |
| Stage ordering | The edge functions that finalize a stage (agreement sign, tab save, upload) reject the write if the *previous* stage is not yet complete, so the REST API cannot be used to complete stages out of order. |

This means even a hand-crafted `curl` against PostgREST returns **zero feature rows** for a contractor who hasn't finished onboarding. The client gate is purely cosmetic on top of that.

> **Note:** agreement signing and the Stage-3 approval transitions are written by **edge functions using the service role** (signing must capture IP/device server-side; approvals are HR-only). Contractor sessions never get direct write access to `onboarding_progress` — RLS on that table is `SELECT`-own-row only; all mutations go through edge functions. This removes the "contractor flips their own `completed_at`" attack entirely.

### 1.3 Stage / sub-step model & progress math

Three sequential stages, each with a fixed set of equally-weighted tasks:

| Stage | Tasks (in order) | Task count |
|---|---|---|
| **1 — Agreements** | IC Agreement, Non-Compete, Confidentiality/NDA, BAA | 4 |
| **2 — Profile** | Contact, Personal, Payout, About Me | 4 |
| **3 — Documents** | Resume/CV, Diploma/TOR, NBI Clearance, Gov ID/Passport | 4 |

**Weighting.** Each stage is worth **1/3 of overall progress**; within a stage, each task is worth `1/3 ÷ tasks_in_stage`. With 4 tasks per stage that is `100/3/4 ≈ 8.33%` per task. Overall percent:

```
overall% = round( 100/3 * Σ_stages ( credited_tasks_in_stage / tasks_in_stage ) )
```

The **"Step X of 3 · N%"** label uses the *current* stage as X (the first stage not yet complete; 3 if all done) and `overall%` as N. The per-task credit rules (including the Stage-3 "50% while pending HR review" nuance) are defined canonically in §4.6; the worked example "Step 2 of 3 · ~58%" lives there.

**Stage-3 nuance.** A document task counts as fully complete only when its `documents.review_status = 'approved'`. A `pending` upload earns partial bar credit (§4.6) but does not satisfy the gate; a `needs_replacement` upload earns nothing. `completed_at` is therefore set only when all three stages' tasks are satisfied, which for Stage 3 means all four docs approved.

### 1.4 Pause & resume (what persists, and exactly when)

Nothing is held in volatile client state across sessions; every atomic task is durably persisted the moment it succeeds, so closing the tab or app mid-flow loses nothing.

| Event | Persisted by | What is written |
|---|---|---|
| Agreement signed | `portal-sign` edge fn (service role) | A row in `onboarding_signatures` (signature, full legal name, date, **IP, device fingerprint, doc version/hash**) + bump of `onboarding_progress`; when the 4th agreement is signed, `stage1_complete = true`. |
| Profile tab validated & saved | `portal-self` | Whitelisted field writes to `workers` / `profile_extras` (existing behavior). On a tab passing required-field validation, the tab is marked complete; when all 4 tabs are complete, `stage2_complete = true`. |
| Document uploaded | Storage insert + `documents` insert | File in `contractor-docs/<auth.uid()>/…`, `documents` row with `review_status='pending'`. |
| Document approved | `portal-admin`/HR edge fn (service role) | `documents.review_status='approved'`, `reviewed_by`, `reviewed_at`; when all 4 docs approved, `stage3_complete = true`, `current_stage='complete'`, and `completed_at = now()`. |

On resume, the portal recomputes current stage and per-task completion from `onboarding_progress` (cached pointers) reconciled against `onboarding_signatures` + `documents` — there is no separate "draft" blob. Stage-2 in-progress field values live in `workers`/`profile_extras` already, so a half-filled tab repopulates naturally on reload.

### 1.5 State-model decision — dedicated table, not columns on `contractor_logins`

**Decision: a dedicated onboarding-state table (`onboarding_progress`), keyed by `worker_id`, rather than columns on `contractor_logins`.** Rationale:

1. `contractor_logins` is an **auth/identity** table (login lifecycle, revocation). Onboarding is workflow state with a different lifecycle and different RLS needs — mixing them muddies the auth table and its policies.
2. The table needs richer per-stage timestamps and per-task pointers; bolting that onto the auth table invites churn on a security-sensitive table.
3. Clean foreign-key target for `onboarding_signatures` and for the `is_onboarded()` gate helper.

The full DDL for `onboarding_progress`, plus the RLS policy and the `is_onboarded()` helper, lives in **§3D** (single source of truth — not repeated here). A row is created (by `portal-admin`) at the same time the login is provisioned, so the gate is "on" from the contractor's very first session.

### 1.6 Stage diagram

```
  [Login + my_worker_id()]
            │
            ▼
   completed_at IS NULL? ──no──► render tab shell (Home/Pay/Time/Docs/Profile)
            │ yes
            ▼
 ┌─────────────────────────── ONBOARDING (full-screen, blocks shell) ───────────────────────────┐
 │                                                                                               │
 │  STAGE 1  Agreements          STAGE 2  Profile             STAGE 3  Documents                 │
 │  IC ▸ NonCompete ▸ NDA ▸ BAA  Contact ▸ Personal ▸         Resume ▸ Diploma ▸ NBI ▸ GovID     │
 │  (scroll-to-bottom, sign)     Payout ▸ AboutMe             (upload → pending → HR review)      │
 │        │ 4/4 signed                 │ 4/4 valid                  │ 4/4 approved                │
 │        ▼                            ▼                            ▼                             │
 │  stage1_complete  ───unlocks───► stage2_complete ───unlocks───► stage3_complete                │
 │                                                                          │                    │
 └──────────────────────────────────────────────────────────────────────── │ ───────────────────┘
                                                                             ▼
                                                                   completed_at = now()
                                                                             │
                                                                             ▼
                                                              is_onboarded() = true → shell unlocks
```

Stages are strictly sequential: the flow will not render Stage *N+1* until Stage *N* is complete, and the finalizing edge functions reject any out-of-order write — so neither the UI nor the REST API can jump ahead.

---

## 2. User-Facing Flow & Microcopy

> **Audience note:** all copy below is mobile-first (single column, thumb-reachable primary buttons pinned to the bottom). English ships now; every string is a candidate for a `t('key')` lookup later (see §7.3 for the `t()` helper) — the **Microcopy Table** at the end of this section is the source-of-truth string catalog, and the **TL** column is reserved for Tagalog (left blank now, filled in the localization pass). Do not hardcode strings outside the catalog.

### 2.0 Onboarding gate (what the contractor lands on)

On first login (`contractor_logins.last_login_at` was null, or onboarding is incomplete), the portal renders the **Onboarding** shell full-screen and keeps the bottom nav hidden/locked until all three stages are complete. If the contractor closes the app mid-flow, they resume exactly where they left off (server-side progress; no data loss) — see §1.4 and §3 for the persistence model.

A persistent **progress header** sits at the top of every onboarding screen:

```
Welcome, {first_name}
Step 2 of 3 · 60% complete
[●━━━━━━━━○━━━━━━━━○]   ← Agreements · Profile · Documents
```

The three step labels are tappable only for **completed** stages (to review), never to skip ahead.

### 2.1 Welcome / intro screen

Shown once, before Stage 1. Sets expectations, time, and pause-ability.

- **Title:** "Welcome to Ability Builders 👋"
- **Body:** "Before you start working, we need to get you set up. This takes about **10–15 minutes** and has 3 steps:"
- **Checklist preview (non-interactive):**
  1. ✍️ Sign 4 agreements
  2. 📝 Complete your profile
  3. 📎 Upload 4 documents
- **Reassurance line:** "You can stop anytime — we'll save your progress and bring you right back here."
- **Primary button:** "Let's get started"

> A consent/privacy-notice acknowledgement is presented at or before this point — see §8.1.2; it is captured as its own signed record.

### 2.2 Stage 1 — eSign agreements

#### Document list

A vertical list of 4 cards, **in fixed order**. Exactly one is "active" at a time; the rest below it are locked.

| State | Card appearance | Right-side icon |
|-------|-----------------|-----------------|
| Signed | Title + "Signed {date}" in muted green | ✓ (green check) |
| Active (next to sign) | Title + "Tap to review & sign", highlighted border | › (chevron) |
| Locked | Title greyed out, subtext "Complete the step above first" | 🔒 (lock) |

Order: (1) Independent Contractor Agreement → (2) Non-Compete → (3) Confidentiality / NDA → (4) Business Associate Agreement (BAA).

Tapping the **active** card opens the viewer. Tapping a **locked** card does nothing but briefly shake + show toast: "Finish the agreement above first."

#### In-viewer scroll-to-bottom gate

- Full document renders in a scrollable pane. A thin progress bar at the top of the viewer fills as they scroll.
- A pinned footer shows the **Sign** affordance but it is **disabled** until the contractor scrolls to the very bottom (within a small tolerance).
- Helper text under the disabled control: "Please scroll to the end to continue."
- Once the bottom is reached, the helper text disappears and the signature area expands/enables.

(Keyboard/screen-reader equivalents for this gate — an explicit "I've reached the end" button and a live-region announcement — are specified in §7.1.2.)

#### Signature capture UI

Two tabs inside the signature sheet — **Type** (default) and **Draw**:

- **Type:** a single text input "Type your full legal name" rendered in a script-style preview below. This typed string is the legal signature.
- **Draw:** a canvas pad "Sign with your finger" + a "Clear" link. Drawn signature is captured as an image.
- **Full legal name field** (always required, even in Draw mode): "Full legal name (as it appears on your ID)". This is matched against `workers.first_name` + `last_name` (case-insensitive, trimmed); a soft mismatch warns but does not hard-block (see §6.5 for the name-mismatch handling).
- **Date:** auto-filled with today (PHT; see §7.3.3), read-only: "Signed on {today}".
- **Consent checkbox** (required, unchecked by default): "I have read and agree to the **{Document Title}**, and I understand that typing or drawing my name is my legal electronic signature."
- Captured silently alongside the above: IP address, device fingerprint, document version/hash (see §3B — not shown to the contractor, but the privacy line below acknowledges it).
- Fine print under the button: "Your signature, name, date, and device details are recorded for legal purposes."

#### Sign button states

| State | Label | When |
|-------|-------|------|
| Disabled (not scrolled) | "Sign" (greyed) | Bottom not reached |
| Disabled (incomplete) | "Sign" (greyed) | Scrolled, but name empty / signature empty / consent unchecked |
| Active | "Sign agreement" | Scrolled + name + signature + consent all present |
| Signing | "Signing…" (spinner, disabled) | Request in flight |
| Signed | "Signed ✓" (then auto-advances) | Success |

#### Per-document success state

On success: a brief inline confirmation sheet — "✅ Agreement signed. 1 of 4 done." — auto-dismisses after ~1.5s and returns to the document list with the next card now **active**. After the 4th: "All agreements signed!" then auto-advance to Stage 2.

### 2.3 Stage 2 — Complete your profile

Re-uses the existing Profile screen's 4 sub-tabs, but in **guided/sequential mode**: tabs unlock left-to-right. Writes go through the existing **`portal-self`** edge function (SAFE_FIELDS allow-list); About Me writes merge into `profile_extras`.

**Tab order & lock behavior** — identical pattern to Stage 1: completed tabs show ✓, the active tab is highlighted, locked tabs show 🔒 and a tooltip "Complete {previous tab} first."

| Tab | Heading | Required fields (must be filled + valid to complete) | Optional |
|-----|---------|------------------------------------------------------|----------|
| **Contact** | "Your contact details" | first_name, last_name, mobile, ph_address, permanent_address, postal_code, date_of_birth | middle_name, address_landmark |
| **Personal** | "Personal & emergency info" | emergency_name, emergency_relationship, emergency_mobile, marital_status, education_level | course, year_graduated, school (conditionally required — see §3A) |
| **Payout** | "How you'll get paid" | the one payout handle matching the admin-set `payout_method` (gcash / paymaya / paypal / wise_tag) | the other three |
| **About Me** | "A little about you" | — (no required fields) | favorite_color, favorite_food, motto |

> **Required-field reconciliation:** the authoritative per-field requirement and validation rules are in **§3A**. In particular: Payout requires the single handle matching the admin-set `payout_method` (not "any one of four"); About Me has **no** required fields and is marked complete on an explicit "Save & continue" (Stage 2 still demands a deliberate action on the last tab). `course`/`year_graduated`/`school` are conditionally required when `education_level` is tertiary/college.

Notes shown read-only on the relevant tabs:
- Contact: "Email (login): {email}" and "Work email / number set by ABC Kids" — both greyed, non-editable (`email`, `work_email`, `work_number`, `work_extension`).
- Payout: "Payout method ({payout_method}) is set by ABC Kids." greyed.

**Field markers & validation:**
- Required fields show a red asterisk `*` and a label "Required".
- Validation is **inline on blur** (per field) and again **on "Save & continue"**. Errors render in red under the field; the field border turns red. (Accessible error wiring — `aria-invalid`, `role="alert"`, error summary — is in §7.1.4 / §7.1.7.)
- The bottom button is "Save & continue", disabled until all required fields on the tab are valid.
- On tap: save via `portal-self`, mark tab ✓, unlock the next tab, auto-scroll to it. Toast: "{Tab} saved."
- After **About Me** saves: "Profile complete!" → auto-advance to Stage 3.

**Validation rules surfaced to the user** (formats; full rules in §3A):
- Mobile: PH format, accepts `09XXXXXXXXX` or `+639XXXXXXXXX`. Error if not.
- Postal code: 4 digits.
- date_of_birth: must be a real date and age ≥ 18.
- Email shown is read-only (login-tied) so it is not validated here.

### 2.4 Stage 3 — Upload documents

Four **upload cards**, each independent (no fixed order — contractor can do them in any sequence, but **all four must reach Approved** to finish). Files: PDF/JPG/PNG, max 10MB each. Uploads land in the private `contractor-docs` bucket under the contractor's own `auth.uid()` folder; a `documents` row is created with `review_status = pending`.

**Card anatomy (per document):**

```
[icon]  Resume / CV                 *Required
        PDF, JPG or PNG · max 10MB
        ─────────────────────────────
        [ 📷 Take photo ]  [ 📁 Choose file ]
```

Required documents:
1. **Resume / CV**
2. **Diploma or Transcript of Records**
3. **NBI Clearance** — helper: "Must be issued within the last 6 months."
4. **Government ID or Passport** — helper: "Upload a clear photo of **both** the front and back." (two slots: Front, Back; each is its own file and its own `documents` row so HR can approve/reject each side independently — see §7.2.1.)

**Mobile picker:** "Take photo" opens the camera (`capture` on a file input); "Choose file" opens the OS file/gallery picker. After selection, an inline **preview** thumbnail (image) or a file chip (PDF, with name + size) appears, with a "Remove" link, then an "Upload" button. On large screens, drag-and-drop is also accepted. Large camera images are downscaled client-side before upload (§7.2.3).

**Per-card review states the contractor sees** (`documents.review_status`):

| `review_status` | Badge shown | Card copy | Actions available |
|-----------------|-------------|-----------|-------------------|
| (none yet) | — | "Not uploaded yet" | Take photo / Choose file |
| `pending` | 🟡 Pending review | "Uploaded {date} · We're reviewing this." | View, Replace |
| `approved` | 🟢 Approved | "Approved on {reviewed_at}." | View only |
| `needs_replacement` | 🔴 Needs replacement | "Needs replacement: {review_reason}" (reason from HR shown verbatim) | View, **Re-upload** |

**Re-upload flow:** tapping **Re-upload** on a `needs_replacement` card opens the same picker; on upload it creates a fresh `documents` row with `review_status = pending` (the prior row/reason is retained for audit — see §3C, §6.2), badge flips to 🟡, copy resets to "Uploaded {date} · We're reviewing this." HR re-reviews. This loops until Approved.

**Stage-3 footer:** a status line "Documents approved: 2 of 4" and a disabled "Finish" — the Finish button only enables when **all four** are 🟢 Approved. (If HR hasn't reviewed yet, the contractor sees the pending state and can close the app; an email/in-portal nudge — §5.5 — tells them when a doc is approved or needs replacement.)

### 2.5 Completion screen — "You're all set"

Triggered only when all 4 documents are Approved (the last gate). Full-screen success:

- **Title:** "🎉 You're all set, {first_name}!"
- **Body:** "Your onboarding is complete. You now have full access to your portal."
- **What unlocks (listed):** "Home, Pay slips, Time tracking, Documents, and Profile are now available."
- **Primary button:** "Go to my portal" → tears down the onboarding shell, enables the bottom nav, routes to **Home**.
- The onboarding gate never shows again for this worker (`completed_at` persisted — see §1.4 / §3D).

### 2.6 Microcopy Table (string catalog)

> `key` = i18n lookup key · `EN` = ships now · **TL** (Tagalog) intentionally left blank for the localization pass. Interpolations in `{braces}`.

| key | Element | EN copy | TL |
|-----|---------|---------|----|
| `onb.welcome.title` | Welcome title | Welcome to Ability Builders 👋 | |
| `onb.welcome.body` | Welcome body | Before you start working, we need to get you set up. This takes about 10–15 minutes and has 3 steps: | |
| `onb.welcome.reassure` | Pause reassurance | You can stop anytime — we'll save your progress and bring you right back here. | |
| `onb.welcome.cta` | Welcome button | Let's get started | |
| `onb.progress` | Progress header | Step {n} of 3 · {pct}% complete | |
| **Buttons** | | | |
| `btn.signOpen` | Open agreement | Tap to review & sign | |
| `btn.sign.idle` | Sign (disabled) | Sign | |
| `btn.sign.active` | Sign (active) | Sign agreement | |
| `btn.sign.busy` | Signing | Signing… | |
| `btn.sign.done` | Signed | Signed ✓ | |
| `btn.saveContinue` | Stage 2 save | Save & continue | |
| `btn.takePhoto` | Camera | Take photo | |
| `btn.chooseFile` | File picker | Choose file | |
| `btn.upload` | Upload | Upload | |
| `btn.reupload` | Re-upload | Re-upload | |
| `btn.remove` | Remove selection | Remove | |
| `btn.view` | View doc | View | |
| `btn.finish` | Finish onboarding | Finish | |
| `btn.goPortal` | Enter portal | Go to my portal | |
| **Labels / helpers** | | | |
| `sign.scrollHint` | Scroll gate hint | Please scroll to the end to continue. | |
| `sign.nameLabel` | Legal name field | Full legal name (as it appears on your ID) | |
| `sign.date` | Signed date | Signed on {today} | |
| `sign.consent` | Consent checkbox | I have read and agree to the {docTitle}, and I understand that typing or drawing my name is my legal electronic signature. | |
| `sign.finePrint` | Capture notice | Your signature, name, date, and device details are recorded for legal purposes. | |
| `doc.nbi.help` | NBI helper | Must be issued within the last 6 months. | |
| `doc.govid.help` | Gov ID helper | Upload a clear photo of both the front and back. | |
| `lock.tab` | Locked tab tip | Complete {prevTab} first. | |
| `field.required` | Required marker | Required | |
| **Success toasts** | | | |
| `toast.signed` | Per-doc signed | ✅ Agreement signed. {x} of 4 done. | |
| `toast.allSigned` | All signed | All agreements signed! | |
| `toast.tabSaved` | Tab saved | {Tab} saved. | |
| `toast.profileDone` | Profile done | Profile complete! | |
| `toast.uploaded` | Upload ok | Uploaded — we're reviewing this. | |
| `toast.approved` | Doc approved | {docTitle} approved. | |
| **Status badges** | | | |
| `status.pending` | Pending | 🟡 Pending review | |
| `status.approved` | Approved | 🟢 Approved | |
| `status.needsReplace` | Needs replacement | 🔴 Needs replacement | |
| `status.docCount` | Approved count | Documents approved: {x} of 4 | |
| **Error states** | | | |
| `err.scroll` | Scroll not complete | Please read to the end of the document before signing. | |
| `err.lockedDoc` | Locked agreement tapped | Finish the agreement above first. | |
| `err.nameMismatch` | Name ≠ profile name | This doesn't match the name on your profile ({fullName}). Please enter your full legal name. | |
| `err.consentRequired` | Consent unchecked | Please check the box to confirm your electronic signature. | |
| `err.signatureEmpty` | No signature drawn/typed | Please type or draw your signature. | |
| `err.required` | Required field empty | This field is required. | |
| `err.mobile` | Invalid mobile | Enter a valid PH mobile number (e.g. 09171234567). | |
| `err.email` | Invalid email | Enter a valid email address. | |
| `err.postal` | Invalid postal | Postal code must be 4 digits. | |
| `err.dobAge` | Under 18 / bad date | Enter a valid date of birth (you must be at least 18). | |
| `err.fileTooBig` | File > 10MB | File is too large. Maximum size is 10MB. | |
| `err.fileType` | Wrong type | Unsupported file. Please use PDF, JPG, or PNG. | |
| `err.uploadFailed` | Upload error | Upload failed. Please check your connection and try again. | |
| `err.nbiOld` | NBI > 6 months | This NBI Clearance looks older than 6 months. Please upload one issued within the last 6 months. | |
| `err.govidBothSides` | Missing a side | Please upload both the front and back of your ID. | |
| `err.needsReplace` | HR rejection display | Needs replacement: {review_reason} | |

> Note on `err.nbiOld`: this is a soft, client-side advisory. The hard gate for NBI recency is HR's review decision (`needs_replacement` with reason), cross-checked against the `documents.issued_on` date (§3C). The advisory simply nudges the contractor before they waste an upload.

---

## 3. Data Model

This section defines the storage backing each onboarding stage. It assumes the existing schema in the kernel and only specifies new columns/tables and validation. All new tables live in the same Postgres database, scoped by `worker_id` and protected by RLS (a contractor sees/writes only rows where `worker_id = my_worker_id()`).

### (A) Stage-2 captured fields

All columns already exist on `workers`, except About Me keys which live in `workers.profile_extras` (jsonb). "Editable" = contractor may write via the `portal-self` edge function (field must also be in `portal_settings.editable_fields` allow-list). "Read-only" = displayed but never accepted from the contractor (admin-set; rejected server-side by `SAFE_FIELDS`).

| Field | Stage-2 Tab | Column / Source | Type | Required? | Validation rules |
|-------|-------------|-----------------|------|-----------|------------------|
| First name | Contact | `workers.first_name` | text | Required | non-empty, trimmed, ≤ 60 chars |
| Middle name | Contact | `workers.middle_name` | text | Optional | ≤ 60 chars |
| Last name | Contact | `workers.last_name` | text | Required | non-empty, trimmed, ≤ 60 chars |
| Mobile (personal) | Contact | `workers.mobile` | text | Required | PH mobile: `^(\+63|0)9\d{9}$` (e.g. `+639171234567` or `09171234567`); normalize to `+63` on save |
| Current PH address | Contact | `workers.ph_address` | text | Required | non-empty, ≤ 250 chars |
| Permanent address | Contact | `workers.permanent_address` | text | Required | non-empty, ≤ 250 chars |
| Address landmark | Contact | `workers.address_landmark` | text | Optional | ≤ 120 chars |
| Postal code | Contact | `workers.postal_code` | text | Required | PH ZIP: exactly 4 digits `^\d{4}$` |
| Date of birth | Contact | `workers.date_of_birth` | date | Required | valid date; age ≥ 18y as of today; not in future |
| Personal email (login) | Contact | `workers.email` | text | **Read-only** | login-tied; displayed only; valid email format (informational) |
| Work email | Contact | `workers.work_email` | text | **Read-only** | admin-set (`@abckidsny.com`) |
| Work number | Contact | `workers.work_number` | text | **Read-only** | admin-set |
| Work extension | Contact | `workers.work_extension` | text | **Read-only** | admin-set |
| Emergency contact name | Personal | `workers.emergency_name` | text | Required | non-empty, ≤ 120 chars |
| Emergency relationship | Personal | `workers.emergency_relationship` | text | Required | non-empty, ≤ 60 chars |
| Emergency mobile | Personal | `workers.emergency_mobile` | text | Required | PH mobile `^(\+63|0)9\d{9}$`; normalize to `+63` |
| Marital status | Personal | `workers.marital_status` | text | Required | one of: single, married, widowed, separated, divorced |
| Education level | Personal | `workers.education_level` | text | Required | non-empty (from lookup list) |
| Course | Personal | `workers.course` | text | Optional* | ≤ 120 chars (*required if education_level is tertiary/college) |
| Year graduated | Personal | `workers.year_graduated` | int / smallint | Optional* | 4-digit year, 1950 ≤ y ≤ current year (*required if course set) |
| School | Personal | `workers.school` | text | Optional* | ≤ 150 chars (*required if course set) |
| GCash | Payout | `workers.gcash` | text | Conditional | required if `payout_method = gcash`; PH mobile format |
| PayMaya | Payout | `workers.paymaya` | text | Conditional | required if `payout_method = paymaya`; PH mobile format |
| PayPal | Payout | `workers.paypal` | text | Conditional | required if `payout_method = paypal`; valid email format |
| Wise tag | Payout | `workers.wise_tag` | text | Conditional | required if `payout_method = wise`; `^@?[A-Za-z0-9_]{3,}$` |
| Payout method | Payout | `workers.payout_method` | text/enum | **Read-only** | admin-set; drives which Payout field above is required |
| Favorite color | About Me | `profile_extras->>'favorite_color'` | jsonb (text) | Optional | ≤ 40 chars |
| Favorite food | About Me | `profile_extras->>'favorite_food'` | jsonb (text) | Optional | ≤ 80 chars |
| Motto | About Me | `profile_extras->>'motto'` | jsonb (text) | Optional | ≤ 200 chars |

**Tab-completion rule for the flow:** Contact, Personal, Payout each require all their *Required*/satisfied-*Conditional* fields before the tab is marked complete. **About Me has no required fields** — it is marked complete on explicit "Save & continue" (so Stage 2 still requires a deliberate action on the last tab). Payout requires exactly the one field matching the admin-set `payout_method`.

### (B) Stage-1 eSign capture — new table `onboarding_signatures`

One row per agreement signed. The four `agreement_kind` values are signed **in order**: `ic_agreement` → `non_compete` → `confidentiality_nda` → `baa`. A `(worker_id, agreement_kind, doc_version)` unique constraint enforces one signature per agreement version; re-issuing a new `doc_version` is handled by versioned re-sign (insert with new version, supersede prior).

```sql
create type agreement_kind   as enum ('ic_agreement','non_compete','confidentiality_nda','baa');
create type signature_method as enum ('typed','drawn');
create type signature_status as enum ('signed','superseded','voided');

create table onboarding_signatures (
  id                 uuid primary key default gen_random_uuid(),
  worker_id          bigint not null references workers(id) on delete cascade,
  agreement_kind     agreement_kind   not null,
  doc_version        text   not null,                 -- e.g. 'ica-v2026.01'
  doc_sha256         text   not null,                 -- hash of the exact rendered document bytes
  signed_legal_name  text   not null,                 -- full legal name as typed by signer
  signature_method   signature_method not null,       -- typed | drawn
  signature_data     text   not null,                 -- typed string, or storage path / data-URL of drawn glyph
  scrolled_to_end    boolean not null default false,  -- scroll-to-bottom gate satisfied
  signed_at          timestamptz not null default now(),
  ip_address         inet   not null,
  user_agent         text   not null,
  device_fingerprint text,                            -- client-computed fingerprint hash (may be null; see §6.8)
  status             signature_status not null default 'signed',
  created_at         timestamptz not null default now(),
  unique (worker_id, agreement_kind, doc_version)
);
create index on onboarding_signatures (worker_id, agreement_kind);
```

**Notes:** `signed_at`, `ip_address`, `user_agent`, `device_fingerprint` are captured/validated **server-side** in the signing edge function (do not trust client-supplied timestamps/IP). `doc_sha256` + `doc_version` together prove *which* text was agreed to, satisfying e-signature evidentiary needs. RLS: contractor may `insert`/`select` own rows; `update`/supersede is service-role only. This table also stores the privacy-notice consent signature (§8.1.2) as a distinct artifact (a dedicated `agreement_kind`/notice variant, owner to confirm — see Open Questions).

### (C) Stage-3 uploads — `documents` table + review columns

The `documents` table exists today: `(id, worker_id, company_id, kind document_kind, title, storage_path, signed_on, expires_on, created_at)`. Add the HR-review columns below and extend the `document_kind` enum.

**Columns to ADD to `documents`:**

```sql
create type review_status as enum ('pending','approved','needs_replacement');

alter table documents add column review_status review_status not null default 'pending';
alter table documents add column review_reason text;          -- required when needs_replacement
alter table documents add column reviewed_by   bigint references workers(id);  -- admin/HR worker_id
alter table documents add column reviewed_at   timestamptz;
alter table documents add column issued_on     date;          -- issuance date (NBI freshness rule)
alter table documents add column mime_type     text;
alter table documents add column file_size_bytes bigint;
```

**`document_kind` enum values to ADD** (existing: `ic_agreement`, `w8ben`, `gov_id`, `other`):

```sql
alter type document_kind add value 'resume';
alter type document_kind add value 'diploma';        -- diploma OR transcript of records
alter type document_kind add value 'nbi_clearance';
-- 'gov_id' already exists → reused for Government-issued ID / Passport (both sides)
```

| Stage-3 required doc | `kind` | Extra rule |
|----------------------|--------|------------|
| Resume / CV | `resume` | — |
| Diploma / Transcript of Records | `diploma` | — |
| NBI Clearance | `nbi_clearance` | **`issued_on` required**, must be ≥ today − 6 months (freshness) |
| Government ID / Passport (both sides) | `gov_id` | clear photo of BOTH sides; two files (Front, Back), each its own row |

**Upload constraints (enforced client-side + in storage RLS / edge validation):**

| Constraint | Value |
|------------|-------|
| Accepted MIME types | `application/pdf`, `image/jpeg`, `image/png` |
| Max size | 10 MB per file (`file_size_bytes <= 10485760`) |
| Storage bucket | private `contractor-docs` |
| Storage path convention | `<auth.uid()>/<kind>/<uuid>-<original-filename>` |
| Review lifecycle | insert → `review_status = pending`; HR sets `approved` or `needs_replacement` (+`review_reason`); `needs_replacement` requires re-upload (new row) |

**Notes:** Stage-3 is complete when every required `kind` has a row with `review_status = approved` (and for `gov_id`, both Front and Back approved). A `needs_replacement` row does not block re-upload; the contractor uploads a fresh file (new `id`) which returns to `pending`. The full rejection history is preserved (one row per attempt) to feed the escalation counter in §6.2. `reviewed_by`/`reviewed_at` are written service-role only.

### (D) Onboarding progress — `onboarding_progress` (the canonical state table)

One row per worker tracking resumable position. This is the single onboarding-state table the portal reads on login (§1.5); the `is_onboarded()` gate helper (§1.2) reads `completed_at` from here.

```sql
create type onboarding_stage as enum ('stage1_sign','stage2_profile','stage3_docs','complete');

create table onboarding_progress (
  worker_id          bigint primary key references workers(id) on delete cascade,
  current_stage      onboarding_stage not null default 'stage1_sign',
  -- granular sub-step pointers for pause/resume:
  stage1_last_kind   agreement_kind,        -- last agreement signed (null = none yet)
  stage2_last_tab    text,                  -- 'contact'|'personal'|'payout'|'about_me'
  stage1_complete    boolean not null default false,
  stage2_complete    boolean not null default false,
  stage3_complete    boolean not null default false,
  name_mismatch_flag boolean not null default false,  -- raised in §6.5 for HR review
  stalled            boolean not null default false,  -- set by reminder cron after day 30 (§6.1)
  completed_at       timestamptz,           -- set when current_stage -> 'complete'; null = still gated
  started_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

-- RLS: contractor may read only their own row; no client writes.
alter table onboarding_progress enable row level security;
create policy onb_select_own on onboarding_progress
  for select using ( worker_id = my_worker_id() );
-- (no insert/update/delete policies for the anon/auth role → all mutations via service-role edge fns)

-- Gate helper used by feature-table RLS:
create function is_onboarded() returns boolean
  language sql security definer stable as $$
    select exists (
      select 1 from onboarding_progress
      where worker_id = my_worker_id() and completed_at is not null
    );
$$;
```

**Notes:** `current_stage` is the source of truth the portal reads on login to decide whether to launch the blocking onboarding flow (`current_stage <> 'complete'`) and where to resume. The `*_complete` booleans and `*_last_*` pointers are derived/maintained as the contractor advances and exist purely to restore position without recomputing from `onboarding_signatures`/`workers`/`documents` on every load; the edge functions re-verify completion against the source tables before advancing `current_stage`. RLS: contractor `select`s own row; all writes go through service-role edge functions.

> **Rehire note (§6.6):** when a previously off-boarded contractor returns, match by stable `worker_id` (ID-first; never create a duplicate worker) and start a new onboarding cycle. If multiple historical cycles must be retained distinctly, add an `onboarding_cycle_id` and promote the PK accordingly — flagged in Open Questions.

---

## 4. Status Model & State Transitions

This section defines the canonical status vocabulary for the workflow and the exact rules that move a task between statuses. All five statuses persist server-side (in `onboarding_progress` for stage/aggregate state and in `documents.review_status` for Stage-3 items) so that pause/resume restores the contractor to the precise point of progress.

### 4.1 The five canonical statuses

| Status | Meaning (generic) | Counts toward "done"? |
|--------|-------------------|------------------------|
| `not_started` | The contractor has not yet engaged with this task. | No |
| `in_progress` | Engaged but incomplete (partial form, doc opened but not signed, replacement requested). | No |
| `submitted` | Contractor has finished their part; awaiting either automatic validation or HR review. | No |
| `approved` | Task is satisfied. For auto-approved types this is set on valid submission; for uploads it requires HR sign-off. | **Yes** |
| `rejected` | Task failed review and must be redone. **Stage-3 uploads only** (surfaced in the UI as "Needs replacement" with a reason). | No |

> **Mapping to storage:** these are the *abstract task statuses*. For Stage-3 documents they map onto the `documents.review_status` enum: `submitted ⇔ pending`, `approved ⇔ approved`, `rejected ⇔ needs_replacement`. For Stages 1–2 there is no separate review column — the status is derived from the presence of an `onboarding_signatures` row / the per-tab completion pointer.

### 4.2 The review asymmetry (read this first)

Not all tasks are reviewed by a human. This is the single most important rule in the model:

| Task type | Reviewed by | `submitted` lifetime | Can ever be `rejected`? |
|-----------|-------------|----------------------|--------------------------|
| Stage-1 eSign agreement | **System only** | Transient — collapses to `approved` in the same transaction as a valid signature capture | No |
| Stage-2 profile tab | **System only** | Transient — collapses to `approved` in the same transaction as successful validation | No |
| Stage-3 document upload | **HR (human)** | **Durable** — a real "Pending review" queue state that an HR user must resolve | **Yes** |

So: **Stage 1 and Stage 2 are auto-approved on valid submission; only Stage 3 has a true `submitted` → (`approved` | `rejected`) human decision.** For agreements and tabs, `submitted` is essentially an internal instant before `approved` and is never shown as a lingering state to the contractor — they see the task flip straight to a completed checkmark. For uploads, `submitted` is a meaningful, possibly long-lived state ("Pending review") that the contractor sees and waits on.

### 4.3 Which statuses apply, per task type

#### Stage-1 — eSign agreement (ICA, Non-Compete, NDA, BAA)

| Status | Applies? | Meaning for this type |
|--------|:-------:|------------------------|
| `not_started` | yes | Agreement not yet opened. |
| `in_progress` | yes | Viewer opened; scroll-to-bottom not yet satisfied, or Sign not yet tapped. |
| `submitted` | yes (transient) | Valid signature capture received (signature + full legal name + date + IP + device fingerprint + doc version/hash). Immediately promoted to `approved`. |
| `approved` | yes | Signed and captured. No HR action. This is the terminal success state. |
| `rejected` | **no** | Agreements are never human-reviewed; a malformed capture simply fails and stays `in_progress`. |

#### Stage-2 — profile tab (Contact, Personal, Payout, About Me)

| Status | Applies? | Meaning for this type |
|--------|:-------:|------------------------|
| `not_started` | yes | Tab not yet opened/edited. |
| `in_progress` | yes | Some fields filled but at least one REQUIRED field missing or failing validation. |
| `submitted` | yes (transient) | All required fields present and valid on save (via `portal-self`, SAFE_FIELDS-enforced). Immediately promoted to `approved`. |
| `approved` | yes | Tab fully valid. No HR action. Terminal success. |
| `rejected` | **no** | Tabs are never human-reviewed; invalid input just keeps the tab `in_progress`. |

> About Me persists to `workers.profile_extras` jsonb (favorite_color, favorite_food, motto); the other three tabs write their mapped `workers` columns. "Required" is governed per-field (§3A) and intersected with `portal_settings.editable_fields`.

#### Stage-3 — document upload (Resume/CV, Diploma/TOR, NBI Clearance, Gov ID/Passport)

| Status | Applies? | `documents.review_status` | Meaning for this type |
|--------|:-------:|---------------------------|------------------------|
| `not_started` | yes | (no row) | No file uploaded for this required kind. |
| `in_progress` | yes | (no live row) | Upload started/failed, or a prior submission was `rejected` and the contractor must replace it. |
| `submitted` | yes (**durable**) | `pending` | File stored in `contractor-docs/<auth.uid>/...`, `documents` row inserted. Sitting in HR's queue. |
| `approved` | yes | `approved` | HR approved. Terminal success. |
| `rejected` | yes | `needs_replacement` | HR rejected with `review_reason`. Contractor must re-upload → returns to `in_progress`. |

#### Stage (1, 2, 3) — container/aggregate

| Status | Applies? | Meaning for this type |
|--------|:-------:|------------------------|
| `not_started` | yes | None of the stage's child tasks have left `not_started`. |
| `in_progress` | yes | At least one child task started; not all children `approved`. |
| `submitted` | yes (Stage 3 only, meaningful) | All Stage-3 uploads `submitted` but ≥1 still awaiting HR. (For Stages 1–2 this is transient/unused since children auto-approve.) |
| `approved` | yes | **All** child tasks `approved`. Auto-computed; unlocks the next stage. |
| `rejected` | **no** | A stage is never itself rejected; rejection lives on the individual upload. |

#### Overall onboarding

| Status | Applies? | Meaning for this type |
|--------|:-------:|------------------------|
| `not_started` | yes | Stage 1 not yet begun (first login, nothing touched). |
| `in_progress` | yes | Somewhere between first action and full completion. |
| `submitted` | yes | Stages 1 & 2 `approved` and all Stage-3 docs `submitted`, but HR review still pending. ("Everything's in, waiting on HR.") |
| `approved` | yes | Stage 3 `approved` ⇒ all three stages `approved`. Onboarding complete (`completed_at` set); portal unblocks. |
| `rejected` | **no** | Never rejected as a whole; a rejected upload pulls overall back to `in_progress`. |

### 4.4 Transition table

Notation: a transition fires only when its trigger occurs **and** any sequencing rule holds (no skipping ahead — a Stage-N child can only leave `not_started` once Stage-(N-1) is `approved`).

| # | Task type | From → To | Trigger | Caused by | Side effects |
|---|-----------|-----------|---------|-----------|--------------|
| T1 | Agreement | `not_started` → `in_progress` | Viewer opened | Contractor | audit_log `agreement.opened` (doc id + version/hash). |
| T2 | Agreement | `in_progress` → `in_progress` | Scrolled to bottom | Contractor (UI gate) | Enables the Sign control. No status change. |
| T3 | Agreement | `in_progress` → `submitted` → `approved` (same txn) | Valid signature capture (signature + legal name + date + IP + device fingerprint + doc version/hash all present) | Contractor; validated server-side | Persist `onboarding_signatures` row; audit_log `agreement.signed`; unlock **next agreement** in order; if last agreement, re-evaluate Stage 1 (→ T11). |
| T3a | Agreement | `in_progress` → `in_progress` | Signature capture malformed/incomplete | System (validation fail) | No promotion; surface inline error. Optional `agreement.sign_failed` audit row. |
| T4 | Profile tab | `not_started` → `in_progress` | First edit of any field on the tab | Contractor | None (autosave of draft allowed). |
| T5 | Profile tab | `in_progress` → `submitted` → `approved` (same txn) | Save with **all required fields valid** | Contractor via `portal-self`; validated server-side against SAFE_FIELDS + required set | Write mapped `workers` columns / `profile_extras`; audit_log `profile_tab.completed`; unlock **next tab** in order; if last tab, re-evaluate Stage 2 (→ T11). |
| T5a | Profile tab | `in_progress` → `in_progress` | Save with missing/invalid required field | System (validation fail) | Persist valid fields as draft; return field errors; no promotion. |
| T6 | Upload | `not_started` / `in_progress` → `submitted` | File inserted (PDF/JPG/PNG ≤10MB) into own Storage folder + `documents` row created | Contractor | Set `documents.review_status = pending`; audit_log `document.submitted`; **notify HR** (review queue); re-evaluate Stage 3 (→ T11a). |
| T6a | Upload | `not_started` → `in_progress` | Upload started but failed (size/type/storage error) | System | No `documents` row (or marked failed); surface error. |
| T7 | Upload | `submitted` → `approved` | HR approves | HR user (admin app) | `review_status = approved`, `reviewed_by`, `reviewed_at`; audit_log `document.approved`; re-evaluate Stage 3 (→ T11); **notify contractor**. |
| T8 | Upload | `submitted` → `rejected` | HR rejects with reason | HR user | `review_status = needs_replacement`, `review_reason`, `reviewed_by`, `reviewed_at`; audit_log `document.rejected`; **notify contractor** with reason; Stage 3 cannot complete. |
| T9 | Upload | `rejected` → `in_progress` | Contractor opens the task to replace | Contractor | UI re-enables upload for that kind; prior reason retained in history. |
| T10 | Upload | `rejected` → `submitted` | Replacement file inserted | Contractor | New `documents` row, `review_status = pending`; audit_log `document.resubmitted`; **notify HR**; re-evaluate Stage 3. |
| T11 | Stage | `in_progress` → `approved` | **All** child tasks reached `approved` | System (aggregate recompute, fired by T3/T5/T7) | audit_log `stage.completed`; set the relevant `onboarding_progress.stageN_complete`; **unlock next stage**; re-evaluate overall (→ T13). |
| T11a | Stage 3 | `in_progress` → `submitted` | All uploads `submitted`, ≥1 still `pending` | System | Reflects "waiting on HR"; sets overall → `submitted` (T13). |
| T12 | Stage 3 | `approved`/`submitted` → `in_progress` | Any approved/pending upload flipped to `rejected` (T8) | System | Stage re-opens; overall recomputed back to `in_progress`. |
| T13 | Overall | `*` → recomputed | Any stage status change | System | If Stage 3 `approved` → overall `approved`, set `current_stage='complete'` + `completed_at=now()` + audit_log `onboarding.completed` + **remove portal block**. If all docs in but pending → `submitted`. Otherwise `in_progress`. |

Sequencing guard (applies to T1, T4, T6): the transition is rejected server-side if the prior stage is not `approved`. RLS + the `onboarding_progress` pointers enforce this; the UI also greys out locked stages.

### 4.5 State machine — Stage-3 upload (the only human-reviewed task)

```
                 ┌─────────────┐
   (stage 3      │ not_started │
    unlocked)    └──────┬──────┘
                        │ contractor selects a file (T6/T6a)
                        ▼
                 ┌─────────────┐   upload fails (size/type/net)
            ┌───▶│ in_progress │◀────────────────────┐
            │    └──────┬──────┘                      │
            │           │ file stored + documents row │
            │           │ inserted (review_status=    │
            │           │ pending)            (T6)    │
            │           ▼                             │
            │    ┌─────────────┐                      │
   contractor   │  submitted  │  ("Pending review"   │
   opens to     │ (HR queue,  │   — durable)         │
   replace      │  =pending)  │                      │
   (T9)         └──┬───────┬──┘                      │
            │      │       │                          │
            │      │ HR    │ HR approves (T7)         │
            │      │ rejects                          │
            │      │ +reason(T8)      ▼               │
            │      │           ┌─────────────┐        │
            │      │           │  approved   │ (terminal,
            │      │           └─────────────┘  counts done)
            │      ▼                                   │
            │  ┌─────────────┐  replacement file      │
            └──┤  rejected   ├──inserted (T10)────────┘
               │("Needs      │   → back to submitted
               │ replacement"│   (=needs_replacement)
               │  +reason)   │
               └─────────────┘
```

Agreements and profile tabs collapse to the trivial machine `not_started → in_progress → approved` (the `submitted` node exists but is never observable), which is why only the upload machine is drawn in full.

### 4.6 Progress % mapping (canonical)

Progress is derived from status, never stored as a free-floating number, so pause/resume and recomputes stay consistent. This is the single source of truth for the "Step X of 3 · N%" indicator referenced in §1.3 and §2.0.

**Weighting.** Each of the 3 stages is worth one-third of overall (≈33.3%). Within a stage, each of the 4 child tasks contributes equally (25% of that stage).

**Per-task contribution to its stage's fraction:**

| Task status | Credit |
|-------------|:------:|
| `not_started` | 0% |
| `in_progress` | 0% (no partial credit — keeps the bar honest) |
| `submitted` | Stage 1 & 2: 100% (auto-approves instantly). **Stage 3: 50%** (work done, awaiting HR). |
| `approved` | 100% |
| `rejected` | 0% (must be replaced) |

**Overall %** = average of the three stage fractions, each capped at 100%:

```
overall% = round( (stage1% + stage2% + stage3%) / 3 )
```

The step label X is the lowest stage not yet fully `approved` (3 once all are done).

**Worked example** (matches a "Step 2 of 3 · ~58%" indicator): Stage 1 fully `approved` (100%), Stage 2 with 3 of 4 tabs `approved` and the 4th `in_progress` (75%), Stage 3 `not_started` (0%) → (100 + 75 + 0) / 3 = 58% ≈ "Step 2 of 3". When Stage 3 has uploads sitting in `submitted` (`pending`), the bar shows partial (50%-per-doc) credit so the contractor sees that HR — not they — now hold the next action.

---

## 5. HR / Admin View & Notifications

This section covers the desktop admin app (`app/index.html`). Stage-1/2/3 producers (signatures, profile writes, uploads) are defined in their own sections; here we consume and act on them.

### 5.1 New admin "Onboarding" view

Add a top-level **Onboarding** entry to the admin nav (alongside the existing Workers / Pay / Documents views). It renders a queue table backed by a single read query that joins `workers`, the per-stage progress (`onboarding_progress` + derived counts from `documents`), and `contractor_logins` (to show login state).

**Queue columns:**

| Column | Source | Notes |
|--------|--------|-------|
| Contractor | `workers.first_name … last_name` | links to drill-down |
| Company | org→company mapping | always "Ability Builders" today |
| Login | `contractor_logins.status`, `last_login_at` | active / revoked / never logged in |
| Stage | `onboarding_progress.current_stage` | `1 eSign` / `2 Profile` / `3 Docs` / `Complete` |
| % complete | derived (§4.6) | overall across 3 stages (e.g. "Step 2 of 3 — 60%") |
| Stage detail | derived | e.g. "Payout tab pending", "2 of 4 docs approved" |
| Docs awaiting review | count of `documents` where `review_status='pending'` and `kind` in the Stage-3 set | drives the review badge |
| Last activity | max of signed/updated/uploaded timestamps | feeds the stalled-reminder logic |
| Status | derived | In progress / **Action needed (HR)** / Complete / Stalled |

Sort/filter by Status so "Action needed (HR)" (pending uploads) floats to the top. A simple search box filters by name/email client-side, matching the existing Workers view UX.

**Per-contractor drill-down** (modal or detail pane) shows three collapsible panels, one per stage, each rendering the read-only audit/state described below, plus the per-item Stage-3 review controls and the stage-level admin actions (re-open / mark complete / revoke).

### 5.2 Stage-3 upload review workflow

For each required Stage-3 doc (Resume/CV, Diploma/TOR, NBI Clearance, Gov ID/Passport front+back), the drill-down lists the submitted `documents` row(s) with their current `review_status`.

**Opening a file.** The `contractor-docs` bucket is private. The admin app requests a short-lived signed URL via `supabase.storage.from('contractor-docs').createSignedUrl(storage_path, 60)` (60s TTL) and opens it in a new tab / inline preview. No file is ever made public; the URL expires quickly and is generated on demand per click.

**Decision controls** (per item):

- **Approve** → writes `review_status='approved'`, clears `review_reason`, sets `reviewed_by` (the verified admin's worker id), `reviewed_at = now()`.
- **Needs replacement** → opens a small form with a **required** `review_reason` (reject is blocked if empty; HR may pick from the suggested-reason list in §6.9); writes `review_status='needs_replacement'`, `review_reason`, `reviewed_by`, `reviewed_at`. The contractor's Stage-3 then re-surfaces only that item for re-upload.

Both decisions write an `audit_log` entry (`action='document_review'`, target = `documents.id`, before/after `review_status`, reason). Writes go through an edge function (or RLS policy) that requires an admin role — `reviewed_by` is taken from the verified admin session, never client-supplied.

**Bulk vs per-item.** Review is **per-item** by design (each doc needs an individual judgement and, on rejection, a specific reason). The only bulk affordance is a convenience **"Approve all pending for this contractor"** button that loops the same per-item approve write (no bulk reject — rejections always require a typed reason).

### 5.3 Read-only audit views

**Stage-1 signatures.** A read-only panel lists each signed agreement (IC Agreement, Non-Compete, NDA, BAA) from `onboarding_signatures` with: full legal name, signed date/time, captured IP address, device fingerprint, and document version/hash. These are immutable audit records — no edit controls, copy-to-clipboard only. This is the evidence trail for contractor-classification defense (§8.2), so it must show the exact doc version/hash that was signed.

**Stage-2 profile.** A read-only render of the four tabs' submitted values (Contact, Personal, Payout, About Me) using the real `workers` columns and `profile_extras` keys. Admin-set/read-only fields (`work_email`, `work_number`, `payout_method`) are clearly labelled as admin-set. No government enrollment numbers appear here — by design there are none to show (§8.1.3).

### 5.4 Admin stage actions

All actions write `audit_log` (actor = admin, timestamp, reason where applicable) and run via an admin-scoped edge function / RLS policy:

| Action | Effect |
|--------|--------|
| **Re-open stage / request changes** | Marks a completed stage incomplete (and for Stage 3, sets the relevant doc(s) back to `needs_replacement` with a reason). Unblocks that stage for the contractor; portal re-gates to it. Fires a "changes requested" notification. (See §6.6.) |
| **Manually mark complete** | Force-completes a stage without the normal gate (e.g. agreement signed out-of-band). Requires a reason; heavily audited. Use sparingly. |
| **Revoke** | Sets `contractor_logins.status='revoked'`, ending portal access. Audited. Does not delete submitted data (§6.4). |

### 5.5 Notifications

Two channels: **email** (sent from an edge function using the same mailer the existing `documents-expiry-check` cron uses) and **in-portal banner** (a persisted row the portal reads on load). New scheduled jobs (stalled-reminder) are modeled on the existing `documents-expiry-check` cron-style function.

| Event | Channel | Recipient | Copy summary |
|-------|---------|-----------|--------------|
| Contractor completes a stage | In-portal banner + email | Contractor | "Stage N complete — Step N+1 of 3 unlocked." Confirms progress, nudges to continue. |
| Stage-3 upload submitted | Email | HR/admin | "{Name} submitted {doc kind} for review." Links to the Onboarding drill-down. |
| HR approves an item | In-portal banner | Contractor | "Your {doc kind} was approved." |
| HR requests replacement | In-portal banner + email | Contractor | "Your {doc kind} needs replacement: {review_reason}. Please re-upload." Includes the required reason verbatim. |
| Onboarding complete (all 3 stages) | Email | HR/admin **and** contractor | To contractor: "Onboarding complete — full portal access unlocked." To HR: "{Name} finished onboarding." |
| Stalled (no activity ≥ N days) | Email + in-portal banner | Contractor | "You have unfinished onboarding — pick up at Stage N." Reminder cron, capped to avoid spam (cadence in §6.1). |

**Implementation notes.** Per-event email sends fire from the same edge functions that perform the underlying write (e.g. the Stage-3 review function emails the contractor on approve/reject; the upload-submit path emails HR). The **stalled-reminder** is the only scheduled job: a cron edge function patterned on `documents-expiry-check` that selects onboarding-incomplete workers whose last-activity timestamp is older than N days and below the reminder cap, then emails them and writes an in-portal banner row. In-portal banners are persisted (e.g. a `portal_notifications` row keyed by `worker_id`, read on portal load and dismissable) so they survive reload and work without the contractor being online when the event fired. (The exact reminder cadence/cap is defined once in §6.1.)

---

## 6. Edge Cases

The onboarding flow must survive interruption, ambiguity, and adversarial input without losing data or producing a non-defensible signature record. All edge-case handling below assumes the per-worker state model (`onboarding_progress` keyed by `worker_id`, §3D) and the immutable `onboarding_signatures` ledger (§3B). RLS scopes every read/write to `my_worker_id()`.

### 6.1 Abandons mid-flow for days/weeks

**Trigger:** Contractor closes the tab/app at any point and returns later (minutes to weeks).

**System behavior:**
- On every login the portal reads `onboarding_progress`. If `completed_at` is not set, the gate re-renders and routes the contractor to the **first incomplete step** — never the start. Stage-1 signed agreements, Stage-2 saved tabs, and Stage-3 uploaded-and-approved docs all persist independently, so resume is exact.
- Stage-2 partial input: profile writes go through `portal-self` per tab on each "Save & continue", so a half-finished tab persists its saved fields. In-progress unsaved keystrokes are not persisted server-side (acceptable — a tab is short; a debounced `localStorage` mirror also exists, §7.2.4). A tab only flips to `complete` when all required fields validate.
- **Reminder cadence** (driven by an edge function on a Supabase scheduled cron, e.g. `onboarding-reminders` daily): send at **day 2, day 5, day 9, day 14** after `started_at` while incomplete; then weekly to day 30; after **day 30** stop auto-reminders and set `onboarding_progress.stalled = true` for HR follow-up. Reminders go to the personal login `email`. Each send is logged (`onboarding_reminders(worker_id, sent_at, channel, stage_at_send)`); a paused state is never counted as completion. **This is the canonical cadence referenced by §5.5.**

**Copy (reminder email):** "You're almost there — Step 2 of 3, 60% complete. Pick up right where you left off: [Resume onboarding]. Your progress is saved."

**Data/audit effect:** No state mutation on resume beyond `last_login_at`. Reminder sends appended to `onboarding_reminders`. At day 30, `stalled` flag set (idempotent).

**Sub-case — agreement `doc_version` changed since they started:** If a contractor signed agreement (a) at one `doc_version` and the master template is bumped before they finish onboarding, the **already-signed** signature stays valid against the version they saw (it is immutable and legally bound to the hash). On next entry to the gate, the Stage-1 step for that agreement is re-flagged `needs_resign` **only if** policy marks the new version as materially changed (`agreement_versions.requires_resign = true`); cosmetic versions do not force re-sign. If re-sign is required, that single step reopens, the new version is presented, and a **new** `onboarding_signatures` row is appended (the old one is retained). Other completed stages are untouched.

**Copy (re-sign banner):** "The Independent Contractor Agreement has been updated. Please review and sign the current version to continue. Your previous signature remains on file."

**Sub-case — NBI Clearance goes stale while waiting:** NBI must be "issued within the last 6 months." The rule is evaluated against `documents.issued_on` at **two moments**: at upload, and at the moment HR approves. If HR approval happens after the 6-month window lapses, HR sets `review_status = needs_replacement` with `review_reason = "NBI clearance is older than 6 months at time of review; please upload a current one."` A scheduled job also re-checks `pending` NBI rows daily and surfaces staleness to HR. If a contractor delays so long that an **already-approved** NBI ages out before completion, it is **not** retroactively revoked — approval is a point-in-time HR decision and stage completion is preserved.

**Data/audit effect:** `documents.review_status/review_reason/reviewed_by/reviewed_at` updated; staleness re-check is read-only until HR acts.

### 6.2 Upload fails HR review 3 times

**Trigger:** The same Stage-3 document `kind` reaches its 3rd `needs_replacement` rejection.

**System behavior:**
- **Every** rejection is preserved as its own `documents` row (we never overwrite the prior reason — §3C), so the full rejection history is auditable. A `rejection_count` per `(worker_id, kind)` is derived from that history.
- On the 3rd rejection the system **escalates**: notifies the HR lead (edge function → email), and switches the contractor's UI from a plain re-upload to a **guided/manual-assist** path.
- The contractor is **not** hard-blocked by default — they may keep uploading — but HR gains a "manual assist" action (HR can approve the doc after an out-of-band check, e.g. a video call, with `review_reason` documenting the basis). An optional admin-toggled hard block (`portal_settings`) can freeze that single document step pending HR contact.

**Copy (contractor, on 3rd rejection):** "We've had trouble verifying this document. An HR team member has been notified and may reach out to help. You can try one more upload using the tips below, or wait for HR to contact you at [work_email]."

**Copy (HR notification):** "Escalation: {worker} has had 3 rejected uploads for {kind}. Last reason: '{review_reason}'. Review or start manual assist."

**Data/audit effect:** One `documents` row per rejection (history preserved); HR notification logged. Manual approval records `reviewed_by` = HR lead + reason.

### 6.3 Signs an agreement then later disputes it

**Trigger:** Contractor (or their counsel) later claims they did not sign, signed under a different version, or wishes to repudiate.

**System behavior:**
- The original `onboarding_signatures` row is **immutable and never deleted or edited** (enforced by RLS: contractors have INSERT-only, no UPDATE/DELETE; admins have no DELETE on this table — only service-role migrations could, and policy forbids it). It carries signature, full legal name, date, captured IP, device fingerprint, `doc_version`, and `doc_sha256`.
- A dispute is recorded **additively** in `agreement_disputes(id, signature_id FK, worker_id, raised_by, raised_at, reason, status open|resolved|withdrawn, resolution_note, legal_hold bool)`. The original signature is annotated by reference, not mutated.
- If the resolution is to re-sign a corrected/new version, the contractor signs again → a **new** `onboarding_signatures` row (new `doc_version`/`doc_sha256`); both old and new coexist, giving a complete chain of who signed what, when.
- Setting `legal_hold = true` on the dispute (or a worker-level hold flag) **suppresses any purge/retention deletion** of the related signature and documents until the hold clears — referenced by the data-retention job (§8.1.5) so held records are skipped.

**Copy (user-facing):** Generally none in-portal (disputes are handled by HR/legal out-of-band). If HR opens a dispute that requires re-sign, reuse the re-sign banner from §6.1.

**Data/audit effect:** New `agreement_disputes` row; zero mutation of the original signature; optional new signature row on re-sign; `legal_hold` gates the retention job.

### 6.4 Login revoked mid-onboarding

**Trigger:** Admin sets `contractor_logins.status = revoked` while onboarding is incomplete.

**System behavior:** `my_worker_id()`/RLS and the portal gate check `status = active` on load and on each privileged write. A revoked session can read nothing and write nothing; the portal shows a neutral locked state. Partial progress in `onboarding_progress`, signatures, and uploaded docs **all remain intact** — revocation never deletes onboarding data. Re-activation (`status = active`) drops the contractor back at their first incomplete step.

**Copy:** "Your access is currently paused. Please contact your ABC Kids NY administrator." (No data-loss language; no onboarding detail leaked.)

**Data/audit effect:** No onboarding rows touched; `contractor_logins.status` change is the only mutation (logged with `revoked_by`/timestamp).

### 6.5 Legal name changes between Stage 1 (signed) and Stage 2 (profile)

**Trigger:** Contractor types legal name "Juan P. Dela Cruz" when signing Stage 1, then in the Stage-2 Contact tab enters `first_name/middle_name/last_name` that compose to a different name (married name change, typo, or transliteration difference).

**System behavior:**
- The signed `signed_legal_name` on each `onboarding_signatures` row is **frozen** — it reflects what they attested to at signing and is never back-edited from the profile.
- On Stage-2 completion the system computes a normalized comparison (case/diacritics/whitespace-insensitive) between the composed profile name and the most recent signed name. A meaningful mismatch sets `onboarding_progress.name_mismatch_flag = true` and surfaces a **soft** confirmation to the contractor (does not hard-block, since legitimate name changes happen). This is the same soft-warning behavior referenced at sign time in §2.2.

**Copy (contractor confirm):** "The name on your signed agreements is '{signed_name}', but your profile name is '{profile_name}'. If you recently changed your legal name, that's fine — confirm to continue. HR may follow up."

**Data/audit effect:** `name_mismatch_flag` raised for HR review; no automatic mutation of either name. If HR requires the agreements to match the new legal name, that becomes a re-sign (§6.3 path) — never an edit of the historical signature.

### 6.6 Re-onboarding (rehire) or admin re-opens a completed stage

**Trigger (rehire):** A previously off-boarded person returns. **Trigger (re-open):** Admin needs a contractor to redo a stage (e.g. updated agreement, stale docs).

**System behavior:**
- **Rehire — ID-first (per engineering convention):** match the returning person to the existing `workers` row by stable `worker_id`, never create a duplicate worker. Their old onboarding artifacts are preserved. Admin chooses, per stage, whether prior completion still counts or must be redone (agreements almost always require re-sign at the current `doc_version`; About-Me can carry over). An `onboarding_cycle_id` (Open Question, §3D) would distinguish this engagement's progress from the previous one so history is not co-mingled.
- **Admin re-open:** Admin action flips a specific `onboarding_progress` stage flag back to incomplete (and Stage-1 to `needs_resign` if applicable). The gate reactivates for **only** the reopened step; already-valid stages stay complete. The re-open is recorded with `reopened_by`/`reopened_at`/`reason`.

**Copy (contractor, on re-open):** "HR has asked you to update one onboarding step: {step}. Please complete it to keep your access."

**Data/audit effect:** Rehire creates a new onboarding cycle without duplicating the worker or destroying prior signatures/docs; re-open writes an audit trail and reverts only the targeted step's status.

### 6.7 Network drop during signature or upload

**Trigger:** Connection lost mid-write while signing or uploading.

**System behavior:**
- **Signature:** the client sends an **idempotency key** (`worker_id + agreement_kind + doc_sha256 + client_nonce`); the signing edge function upserts on that key so a retried request after a dropped response does not create a duplicate signature row. If the client never got a success ack, on reconnect the gate re-queries Stage-1 state and shows the step as either signed (write landed) or unsigned (it did not) — no phantom half-signed state.
- **Upload:** Storage upload to the private `contractor-docs/{auth.uid}/` folder is a two-step (object PUT, then `documents` row insert). The `documents` insert is keyed by `(worker_id, kind, storage_path)` so a retry is idempotent. If the object PUT succeeded but the row insert failed, the orphan object is harmless and overwritten on retry (same deterministic path); a periodic cleanup reconciles objects with no `documents` row. The UI shows the doc as "not received" until the row exists, so the contractor simply re-uploads.

**Copy:** "Your connection dropped before we finished. Nothing was lost — please tap Sign/Upload again."

**Data/audit effect:** No duplicate signatures or document rows (idempotency keys); possible orphan storage object reconciled by cleanup, never surfaced as a valid doc.

### 6.8 Fingerprinting blocked / IP via VPN

**Trigger:** Browser blocks the fingerprinting script (privacy extension, Brave shields), or the contractor connects through a VPN (very common for PH-based remote contractors).

**System behavior:** Signature capture is **best-effort and must never hard-fail** on missing telemetry. The signing edge function reads the IP **server-side** from the request (`x-forwarded-for` / connection) rather than trusting the client; device fingerprint is captured client-side if available, else stored as `null`/`"unavailable"`. A VPN IP is recorded **as observed** — we store what we saw and do not attempt to defeat the VPN. The legally load-bearing capture is signature + full legal name + timestamp + `doc_sha256`; IP and fingerprint are corroborating, not gating.

**Copy:** None — signing proceeds silently. (No accusatory "VPN detected" messaging.)

**Data/audit effect:** `onboarding_signatures.ip_address` = server-observed value (may be VPN egress); `device_fingerprint` may be `null`/`unavailable`. A `capture_quality` note (e.g. `fingerprint_missing`) may be stored for transparency, but never blocks the signature.

### 6.9 Valid image but illegible

**Trigger:** Contractor uploads a real PDF/JPG/PNG under 10MB that passes type/size validation but is blurry, glare-washed, cropped, low-resolution, or only one side of a two-sided ID.

**System behavior:** Type/size checks pass at upload (no OCR-gating client-side). HR reviews and, if unreadable, sets `review_status = needs_replacement` with a **specific** `review_reason` from a suggested list so the contractor knows exactly what to fix. The step stays incomplete; the rejection is preserved as its own `documents` row (feeds the §6.2 escalation counter).

**Suggested `review_reason` values (HR-selectable):**

| Reason | When |
|--------|------|
| `Image is blurry / out of focus` | Text not sharp enough to read |
| `Glare or reflection obscures text` | Flash/light washout |
| `Document is cropped — edges cut off` | Corners/fields missing |
| `Resolution too low to read` | Tiny/over-compressed |
| `Only one side provided — both sides required` | Government ID front+back |
| `Wrong document type for this slot` | e.g. NBI uploaded under Diploma |
| `Expired or out-of-date document` | NBI > 6 months, etc. |

**Copy (contractor):** "Your {document} couldn't be approved: {review_reason}. Please re-upload a clear, complete photo or scan. Tips: good lighting, no glare, all four corners visible, both sides for IDs."

**Data/audit effect:** New `documents` row on re-upload; `documents.review_status = needs_replacement` on the rejected one; step remains blocking until an approved replacement lands.

---

## 7. Accessibility & Localization

This section defines how the flow meets WCAG 2.1 AA, behaves on a PH contractor's phone over mobile data, and is built English-now / Tagalog-later inside the single-file in-browser-Babel React app (`portal/index.html`). No build step exists, so everything below is plain ES + JSX patterns — no extra libraries beyond what the portal already loads.

### 7.1 WCAG 2.1 AA for this flow

The flow has three a11y-hostile patterns by nature: things that **lock/unlock**, a **scroll-to-bottom gate**, and a **signature pad**. These get explicit treatment.

#### 7.1.1 Focus management on lock/unlock

Because stages and tabs gate each other, focus must follow the unlock — a keyboard or screen-reader user must not be dumped at the top of a re-rendered page with no idea what changed.

| Transition | Focus + announcement behavior |
|---|---|
| Stage N completes → Stage N+1 unlocks | Move focus (`ref.focus()` in a `useEffect` keyed on stage) to the new stage's `<h2>` heading (heading has `tabIndex={-1}`). Announce via the live region (7.1.6). |
| Tab N complete → Tab N+1 unlocks (Stage 2) | Focus the newly enabled tab button; do not auto-advance the panel silently. |
| Locked control receives focus | Locked steps render as `<button disabled>` **or** `aria-disabled="true"` with an `aria-describedby` pointing to a "Complete previous step to unlock" hint — never a click-dead `<div>`. |
| Modal viewer / signature dialog opens | Trap focus inside the dialog (`role="dialog"` `aria-modal="true"`, focus first control on open, restore focus to the trigger on close, `Esc` closes). |

A locked step must be **perceivable as locked** to AT: use `aria-disabled` + visible lock icon + text, not a greyed color alone.

#### 7.1.2 Scroll-to-bottom gate (keyboard + SR path)

The Sign button stays disabled until the agreement is read to the end. This must not be mouse-/touch-scroll-only.

- The scroll container is `tabIndex={0}` `role="region"` `aria-label="Agreement text"` so it is keyboard-focusable and PageDown/arrow/Space scrollable.
- Provide an explicit **"Jump to end / I've reached the end"** affordance that is itself a real `<button>` — keyboard and screen-reader users who navigate by structure (not pixels) need a non-scroll way to satisfy the gate. (The viewer still records that the bottom sentinel became visible via `IntersectionObserver`; the button is the accessible equivalent that sets the same `reachedEnd` state.)
- When `reachedEnd` flips true: (1) the Sign button's `disabled` is removed, (2) a polite live-region message fires: **"You can now sign this agreement."** (3) optionally move focus to the Sign button.
- The gate state is exposed on the Sign button via `aria-disabled` mirroring `disabled`, and an `aria-describedby` hint reads "Read to the end of the document to enable signing" while locked.

#### 7.1.3 Accessible signature alternative

A canvas signature pad is invisible to AT and impossible for keyboard-only users. The flow already captures **full legal name + date + IP + fingerprint** as the binding record, so a drawn squiggle is not legally load-bearing on its own.

- Offer **two equivalent signing methods**, toggled by a radio group ("Draw signature" / "Type my name"):
  - **Type-to-sign** (default for keyboard/AT, always available): a text `<input>` for full legal name; submitting it sets the signature payload with `signature_method: 'typed'`.
  - **Draw** (`<canvas>`): the canvas has `role="img"` `aria-label="Signature drawing area"`, with the typed alternative always present as the fallback, never hidden.
- The Sign action is a real `<button type="submit">`, operable with Enter/Space, not a canvas mouseup.

#### 7.1.4 Form labels, errors, and required fields (Stage 2)

Every field in the 4 profile tabs (Contact / Personal / Payout / About Me) follows one pattern:

```jsx
<label htmlFor="mobile">{t('field.mobile')} <span aria-hidden="true">*</span></label>
<input id="mobile" name="mobile"
       required aria-required="true"
       aria-invalid={!!errors.mobile}
       aria-describedby={errors.mobile ? 'mobile-err' : 'mobile-hint'} />
<p id="mobile-hint" className="hint">{t('hint.mobile')}</p>
{errors.mobile && <p id="mobile-err" role="alert" className="err">{t(errors.mobile)}</p>}
```

- Labels are real `<label htmlFor>` — never placeholder-as-label.
- Required is signalled three ways: visible `*`, `aria-required`, and stated in the field hint ("Required").
- Errors set `aria-invalid="true"` and are wired with `aria-describedby`; each error node has `role="alert"` so it is announced on appearance.
- Read-only admin-set fields (`work_email`, `work_number`, `payout_method`, `email`) render as `readOnly` inputs (not `disabled`, so they stay in tab order and are SR-readable) with a "Set by HR" hint.

#### 7.1.5 State color-contrast & non-color cues

The lifecycle states must never be conveyed by color alone (WCAG 1.4.1). Every state = **icon + text label**, with text meeting 4.5:1 contrast.

| State | Icon | Text | Color (AA on white) |
|---|---|---|---|
| Locked | 🔒 lock | "Locked" | grey #595959 (7.0:1) |
| In progress | ◐ half | "In progress" | amber text #8a6d00 (4.6:1) |
| Complete / Approved | ✓ check | "Complete" / "Approved" | green #1b7a3d (4.8:1) |
| Pending review | ⏳ clock | "Pending review" | blue #1f5fbf (4.7:1) |
| Needs replacement | ⚠ warning | "Needs replacement" | red #c0392b (4.6:1) + reason text |

`documents.review_status` maps directly onto the last three rows; "Needs replacement" always renders `review_reason` as visible text, not a tooltip.

#### 7.1.6 Progress indicator as live region

"Step 2 of 3 — 60% complete" is both a visual `<progress>`/bar and an `aria-live="polite"` region so SR users hear progress change as stages complete.

```jsx
<div role="status" aria-live="polite" aria-atomic="true">
  {t('progress.stepOf', { current: 2, total: 3, pct: 60 })}
</div>
```

Use `aria-live="polite"` (not assertive) so it queues behind, e.g., the "you can now sign" message rather than interrupting.

#### 7.1.7 Touch targets & error summaries

- All interactive controls (tab buttons, Sign, Next, upload, camera) are **≥ 44×44 CSS px** (WCAG 2.5.5 / 2.5.8 AA min 24px — we exceed it for mobile comfort), with ≥ 8px spacing so fat-finger taps don't hit the wrong control.
- On a failed tab/stage submit, render an **error summary** at the top of the panel: a `role="alert"` `tabIndex={-1}` box that is focused on submit, listing each error as an in-page anchor (`<a href="#mobile">`) that moves focus to the offending field. This satisfies the "errors identified + suggestion" SC and is far better than hunting fields on a phone.

### 7.2 Mobile-first

Contractors complete onboarding on a phone, frequently on metered mobile data. The portal is already mobile-first; the onboarding additions must stay that way.

#### 7.2.1 Camera capture for IDs — both sides as two files

Stage 3 "Government-issued ID or Passport (BOTH sides)" is two separate uploads, each its own row with its own `review_status`.

```jsx
<input type="file" accept="image/*,application/pdf"
       capture="environment"           /* opens rear camera on mobile */
       onChange={onPickFront} />
```

- Two distinct inputs labelled **"Front side"** and **"Back side"**; each writes a separate file into the contractor's own Storage folder (`{auth.uid()}/gov_id/<uuid>-front.jpg`, `.../<uuid>-back.jpg`) and a separate `documents` row (`kind = gov_id`), so HR can approve/reject each side independently.
- `accept="image/*,application/pdf"` + `capture="environment"` → camera on phones, file picker on desktop. Omitting `capture` on the other doc kinds lets users pick from Photos/Files; we set `capture` only where live capture is the expected path (the ID).
- Client-side guard: reject > 10MB and non PDF/JPG/PNG before upload, with a clear `role="alert"` message (matches server/RLS limits).

#### 7.2.2 Document viewer + scroll gate on small screens

- The agreement viewer is a full-height scroll `region` (`max-height` ≈ `100dvh` minus header/footer; use `dvh` not `vh` so the mobile URL bar doesn't clip the Sign button).
- Sign / I've-reached-the-end controls live in a **sticky footer** within safe-area insets (`env(safe-area-inset-bottom)`) so they're reachable one-thumb and never hidden behind the home indicator.
- Pinch-zoom is **not** disabled (no `user-scalable=no`) — legal text must be zoomable.

#### 7.2.3 Upload from photos & client-side image downsizing

- For non-ID docs (Resume, Diploma, NBI), no `capture` attribute → the OS sheet offers Camera / Photos / Files.
- Before upload, downscale large camera images client-side via a `<canvas>` (e.g. cap longest edge ~2000px, re-encode JPEG ~0.8) to cut a 6MB phone photo to a few hundred KB. This saves the contractor's mobile data and keeps uploads under the 10MB cap. PDFs are passed through untouched.

#### 7.2.4 Low-bandwidth & resumability on flaky connections

PH mobile data is metered and drops; onboarding must pause/resume without data loss.

- **Stage 2 (forms):** autosave each tab's fields on blur/change to the server via the existing `portal-self` edge function (whitelisted `SAFE_FIELDS` + `profile_extras` merge), plus a debounced mirror to `localStorage` keyed by `worker_id`. On reload, hydrate from server first, fall back to local draft — so a dropped connection mid-tab loses nothing.
- **Stage 1 (signatures):** a signature is one atomic POST; if it fails, keep the captured payload in component state and show **Retry** (don't force re-reading the agreement). Mark the stage done only on server ack.
- **Stage 3 (uploads):** upload one file at a time with a visible per-file progress + Retry; a failed file leaves the others intact. Resume = re-open Stage 3 and see which rows are still missing/`Needs replacement`.
- Lazy-load the onboarding bundle/strings; don't ship heavy agreement PDFs until the user opens that specific agreement. Show skeleton/placeholder, not spinners that hide whether anything is loading.

### 7.3 Bilingual-ready (English now, Tagalog later)

The portal already ships a **PHT-aware Tagalog greeting on Home** ("Magandang umaga", time-zoned to Asia/Manila). That establishes the precedent: UI chrome can localize, and we generalize it into a tiny catalog rather than scattering ternaries.

#### 7.3.1 Minimal `t()` + string catalog (no i18n library)

A single-file app can't pull in i18next cleanly, so use a ~30-line helper:

```jsx
const STRINGS = {
  en: {
    'progress.stepOf': 'Step {current} of {total} — {pct}% complete',
    'field.mobile': 'Mobile number',
    'hint.mobile': 'Required. PH mobile, e.g. 0917 123 4567',
    'sign.enabled': 'You can now sign this agreement.',
    'state.needsReplacement': 'Needs replacement',
    // ...
  },
  tl: {
    // 'progress.stepOf': 'Hakbang {current} ng {total} — {pct}% kumpleto',
    // filled in when Tagalog copy is approved
  },
};
const LOCALE = (localStorage.getItem('portal.locale') || 'en'); // later: a Profile toggle
function t(key, vars) {
  const tbl = STRINGS[LOCALE] || STRINGS.en;
  let s = (tbl[key] ?? STRINGS.en[key] ?? key);
  return vars ? s.replace(/\{(\w+)\}/g, (_, k) => vars[k] ?? '') : s;
}
```

- `tl` falls back to `en` per-key, so we can ship Tagalog incrementally — a missing key never blanks the UI.
- Locale persists in `localStorage`; a future Profile language toggle (and/or a default seeded from the existing Home greeting logic) flips `LOCALE`. Set `<html lang>` accordingly so AT switches voice.
- **Migration rule:** all NEW onboarding copy goes through `t()` from day one (this is the same catalog as the §2.6 Microcopy Table). Existing hardcoded English is migrated opportunistically; the Home Tagalog greeting is the reference implementation to copy.

#### 7.3.2 User-facing vs legal strings — what does NOT get translated

| Category | Localize? | Why |
|---|---|---|
| UI chrome: buttons, tab names, hints, progress, status labels, error messages | **Yes** (`t()`) | Comprehension + accessibility |
| Field labels for the 4 Stage-2 tabs | **Yes** | Same |
| **Agreement bodies** (ICA, Non-Compete, NDA, BAA) | **No — authoritative language only** | These are legal instruments. The signed/hashed text must remain the executed English version; translating the binding text changes its legal meaning. Provide a **non-binding reading aid** translation if ever needed, clearly labelled "For understanding only — the English text governs," and **always hash/sign the English version** (`doc_version`/`doc_sha256` captured in §3B). |
| Document kind names HR sees, audit/log text | **No** (keep canonical English) | Operational consistency for HR + audit integrity. |

So `t()` localizes the *shell* around an agreement (Sign button, scroll hint, "I agree"), never the agreement clauses themselves.

#### 7.3.3 Date / number / locale formatting

- Format dates and numbers with `Intl`, not hand-built strings, driven by the same `LOCALE`:
  ```js
  new Intl.DateTimeFormat(LOCALE === 'tl' ? 'fil-PH' : 'en-PH',
    { dateStyle: 'long', timeZone: 'Asia/Manila' }).format(d);
  ```
- **All contractor-facing dates use `timeZone: 'Asia/Manila'` (PHT)** — consistent with the existing Home greeting — so the signature date, "issued within last 6 months" NBI check, and document expiry read in the contractor's own timezone. Store timestamps as UTC (`timestamptz`); format at render.
- Use `en-PH` even in English mode for local conventions (peso, PH date order), so switching `en`→`tl` changes language but not number/date habits.
- The Stage-1 signature **date stamp recorded for legal purposes** is captured server-side in UTC (`onboarding_signatures.signed_at`) alongside IP/fingerprint; the PHT display is presentation only and must not be the source of truth.

#### 7.3.4 RTL / future-proofing

Tagalog is LTR, so no bidi work is needed now. Avoid hard-coding `left/right` in styles where `start/end` (logical properties) are cheap to use, so the catalog approach isn't blocked if a RTL language is ever added.

---

## 8. Compliance — PH DPA 2012 & US/NY Record-Keeping

> **Not legal advice.** This section documents how the onboarding workflow is *engineered* to align with two overlapping regimes. It flags where licensed counsel (PH National Privacy Commission-savvy data-privacy counsel, and US/NY employment + tax counsel) must review before go-live. Treat the tables as a design-to-control map, not a legal opinion.

This workflow collects personal data from Philippine residents into infrastructure hosted in the United States (Supabase, US region, project `cgsidolrauzsowqlllsz`). It therefore sits inside **both** the Philippine **Data Privacy Act of 2012 (RA 10173)** and the **US/New York** contractor record-keeping regime. The two are reconciled by a single deliberate posture: collect the *minimum* needed to engage and pay an **independent contractor**, store it under least-privilege RLS, and prove consent + provenance via signature and audit records.

### 8.1 Philippine Data Privacy Act of 2012 (RA 10173)

#### 8.1.1 What we collect, and how the DPA classifies it

The DPA distinguishes ordinary **Personal Information (PI)** from **Sensitive Personal Information (SPI)**, which carries a higher consent and protection bar.

| App data | DPA class | Where it lives |
|---|---|---|
| Name, mobile, addresses, postal code, work email/number | PI | `workers` (Stage-2 Contact) |
| Emergency contact (name/relationship/mobile) | PI (third-party) | `workers` (Stage-2 Personal) |
| Payout handles (gcash, paymaya, paypal, wise_tag) | PI (financial) | `workers` (Stage-2 Payout) |
| About-Me fun facts | PI (low-risk) | `profile_extras` jsonb |
| **Marital / civil status** | **SPI** (§3(l)) | `workers.marital_status` |
| **Education** (level, course, school, year) | **SPI** (§3(l)) | `workers` (Stage-2 Personal) |
| **NBI Clearance** (reveals criminal-history status) | **SPI** (§3(l)) | `documents` + `contractor-docs` bucket |
| **Government-issued ID / Passport** (gov-issued identifier) | **SPI** (§3(l)) | `documents` + `contractor-docs` bucket |
| Date of birth | PI (treated with SPI-level care) | `workers.date_of_birth` |

#### 8.1.2 Lawful basis & consent capture

Because SPI is in scope, we rely on **explicit, documented consent** (DPA §13) rather than only contractual necessity. Consent is captured **inside the onboarding flow, before any Stage-2/Stage-3 data is written**:

- A dedicated **consent/privacy-notice screen** (rendered ahead of Stage 1, or bundled as the first eSign artifact — see §2.1) states: who the controller is ("Aaron Anderson E.H.S. LLC" / in-app "Ability Builders"), the **purposes** (engagement, payment, identity verification, statutory/contractual record-keeping), the categories of PI/SPI, the **US cross-border transfer**, retention period, and the data-subject rights below.
- Consent is recorded as a **signature record** — the same capture mechanism used for the Stage-1 agreements (an `onboarding_signatures` artifact): signature image, full legal name, timestamp, **IP address, device fingerprint, and the privacy-notice version/hash**. This gives a non-repudiable, versioned proof of *what notice was consented to*.
- A separate **consent flag** is persisted (e.g. a `consent_*` row keyed to `worker_id` with `consented_at`, notice version) so consent state is queryable independent of the signed image.
- **Granularity:** consent to the privacy notice is logically distinct from the IC/Non-Compete/NDA/BAA agreements; the notice covers *data processing*, the agreements cover the *engagement*.

#### 8.1.3 Purpose limitation, proportionality & data minimization (DPA §11)

Data minimization is a **design decision, not an afterthought**, and is the hinge that also keeps the US classification posture clean (see §8.2):

- **No government enrollment numbers are collected** — no TIN, SSS, PhilHealth, or Pag-IBIG fields exist anywhere in `workers` or `profile_extras`. These are employee-style statutory enrollment identifiers; collecting them would be both *disproportionate* to engaging a contractor (DPA proportionality) and an *employment indicium* under US/NY law.
- A government ID is collected **only as an uploaded identity document** (Stage 3), for one-time identity verification — not parsed into structured number fields. The image is SPI and protected as a document, but no durable government identifier column is created.
- Each Stage-2 field maps to a stated purpose: Contact/Payout → engage & pay; Personal (emergency contact) → welfare; education/civil status → contractually/role relevant only. About-Me is explicitly low-stakes.
- **Purpose limitation** is enforced operationally: collected data is used for engagement, payment (Wise/Hubstaff pipeline), and record-keeping only — not repurposed.

#### 8.1.4 Data-subject rights (DPA §16) — mapped to mechanisms

| Right | Mechanism in this app |
|---|---|
| **Right to be informed** | Privacy-notice screen + versioned signed consent record (§8.1.2) |
| **Right to access** | The portal *is* the access surface — Profile tabs render the contractor's own rows; RLS (`my_worker_id()`) guarantees they see only their own data |
| **Right to correction** | `portal-self` edge function lets the contractor edit the whitelisted `SAFE_FIELDS` + `profile_extras` keys directly; admin corrects admin-set fields |
| **Right to erasure / blocking** | Soft-delete via `contractor_logins.status = revoked` (cuts access); hard data/document erasure executed by admin (service role) on request — see retention/disposal |
| **Right to object / withdraw consent** | Withdrawal request handled out-of-band by DPO/admin; revoking consent triggers the erasure/disposal path, subject to the legal-retention holds in §8.2 |
| **Right to data portability** | Contractor's structured data is exportable from `workers`/`documents` on request (admin-assisted) |
| **Right to damages / complaint** | Contact path to the DPO published in the privacy notice |

#### 8.1.5 Retention & secure disposal

- **Active engagement:** all PI/SPI retained for the duration of the engagement under least-privilege access.
- **Post-termination:** retain only what US/NY tax & contract record-keeping requires (see §8.2 — notably W-8BEN and signed agreements); SPI **not** needed for those holds (e.g., NBI clearance, About-Me, emergency contact) should be disposed once its purpose ends.
- **Secure disposal:** structured fields nulled/row-deleted in Postgres; documents deleted from the private `contractor-docs` bucket. Each disposal is recorded in `audit_log` (who/when/what), giving an auditable disposal trail. The disposal job skips any record under a `legal_hold` (§6.3).
- A documented **retention schedule** (per data category) should be authored and reviewed by counsel before first contractor offboarding.

#### 8.1.6 Data Protection Officer (DPO)

RA 10173 / NPC issuances require a designated **DPO**. For this small operation the DPO is a named role (initially the admin/Bronxon, ideally formalized) responsible for: the privacy notice, handling data-subject requests, the retention schedule, and breach response. The DPO's contact is published in the privacy notice (§8.1.2). (Who is formally named DPO is an Open Question.)

#### 8.1.7 Breach notification

- The **NPC and affected data subjects must be notified within 72 hours** of knowledge of a breach involving SPI or data that may enable identity fraud (NPC breach rules).
- Supporting mechanisms: `audit_log` provides the forensic timeline (access/changes); Supabase auth & storage logs scope the blast radius; private bucket + RLS limit exposure. A short written **incident-response runbook** (detect → assess → notify NPC + subjects → remediate) should accompany this design.

#### 8.1.8 Cross-border transfer (US-hosted Supabase)

Data is transferred to and processed on **US infrastructure**. Under the DPA the PH controller remains accountable for data sent abroad. Safeguards:

- **Consent**: the privacy notice explicitly discloses US hosting and the contractor consents (§8.1.2).
- **Contractual safeguards**: a Supabase **Data Processing Agreement / processor terms** binds the processor; encryption in transit (TLS) and at rest; access constrained by RLS and folder-scoped storage policies.
- **Accountability**: the controller ("Ability Builders" / Aaron Anderson E.H.S. LLC) documents this transfer as part of its DPA records.

### 8.2 US / New York Independent-Contractor Record-Keeping

This is an **independent-contractor engagement, not employment.** The design is deliberately built to *avoid employment indicia*, because misclassification (IRS, NY DOL) is the dominant legal risk for a US entity engaging offshore contractors.

#### 8.2.1 How the design avoids employment indicia

- **No government enrollment numbers** (TIN/SSS/PhilHealth/Pag-IBIG) — these are hallmarks of payroll/employment onboarding, not a contractor relationship (also satisfies DPA minimization, §8.1.3).
- **No payroll-style tax withholding form** (no W-4/I-9 equivalent). US tax status is captured **out-of-band via a W-8BEN document** (foreign-person, no US-source-effectively-connected income) — uploaded/signed as a `documents` artifact (`kind = w8ben`), not a portal form.
- **Signed independent-contractor instruments** in Stage 1 establish the relationship in writing: **IC Agreement** (defines contractor status, control, deliverables), **Non-Compete**, **Confidentiality/NDA**, and **BAA**. Each is eSigned with full legal name, date, IP, device fingerprint, and doc version/hash — a durable, non-repudiable contract record (§3B).
- **Caution:** *labels don't control.* Even a signed IC Agreement does not by itself defeat misclassification if behavioral/financial control indicia exist. Worker-classification facts (degree of control, integration, exclusivity) should be **reviewed by US/NY counsel** — flagged here, not resolved.

#### 8.2.2 Record retention norms

| Record | Why retained | Note |
|---|---|---|
| **W-8BEN** | Establishes foreign-person status / withholding posture; IRS guidance treats it as **valid ~3 years + must be retained while relied upon** | Stored as a `documents` artifact; keep current copy + history |
| **Signed IC / Non-Compete / NDA / BAA** | Proof of engagement terms; enforce/defend the relationship | Signature records + doc version/hash retained for the limitations period (counsel to set) |
| **Payment records** (Wise/Hubstaff-derived) | Tax/accounting substantiation of contractor payments | Outside this onboarding module but part of the same retention policy |

Retention windows above are **norms/illustrations, not adjudicated periods** — counsel should set the firm schedule, which then feeds the DPA retention schedule (§8.1.5).

#### 8.2.3 The BAA's role (HIPAA)

The Business Associate Agreement is collected because the contractor may touch **HIPAA-covered (PHI) data** in the course of work for the BPO's clients. The BAA contractually binds the contractor to HIPAA safeguards. If, in fact, **no PHI is ever accessed**, the BAA is precautionary; if PHI *is* accessed, the BAA is **mandatory** and its presence (signed, versioned) is the compliance artifact. Whether PHI is in scope is a **factual/legal determination for counsel.**

#### 8.2.4 IRS / NY classification caution

Engaging an offshore contractor does not exempt the US entity from classification scrutiny. The design reduces *form-level* employment signals, but the **substance** (who controls the work, exclusivity, integration into operations) governs. **This document does not opine on classification** — US/NY employment + international-tax counsel must review before scaling the engagement.

### 8.3 Requirement → How this workflow satisfies it

**PH Data Privacy Act of 2012 (RA 10173)**

| Requirement | How this workflow satisfies it |
|---|---|
| Lawful basis / explicit consent for PI & SPI (§§12–13) | Privacy-notice screen + versioned **signed consent record** (signature, name, date, IP, device fingerprint, notice hash) + persisted consent flag, captured before Stage-2/3 writes |
| SPI handled with heightened care (civil status, education, NBI, gov ID) | Identified as SPI; stored under RLS / in private `contractor-docs` bucket; consent is explicit |
| Purpose limitation (§11) | Data used only for engage/pay/verify/record-keeping; not repurposed |
| Proportionality / minimization (§11) | **No TIN/SSS/PhilHealth/Pag-IBIG fields**; gov ID only as an upload, never a structured number |
| Right to access | Portal renders contractor's own rows; `my_worker_id()` RLS scoping |
| Right to correction | `portal-self` edge function over whitelisted `SAFE_FIELDS` + `profile_extras` |
| Right to erasure / object / withdraw | Admin (service role) data/document deletion + `contractor_logins.status=revoked`; logged in `audit_log` |
| Retention & secure disposal | Category-based retention schedule; Postgres null/delete + bucket delete; disposal logged to `audit_log`; `legal_hold` respected |
| Data Protection Officer | Named DPO role; contact published in privacy notice |
| Breach notification (72h) | `audit_log` + Supabase logs for forensics; incident-response runbook |
| Cross-border transfer to US | Disclosed + consented in notice; Supabase DPA/processor terms; TLS + at-rest encryption; RLS |

**US / New York Independent-Contractor Record-Keeping**

| Requirement | How this workflow satisfies it |
|---|---|
| Maintain IC relationship in writing | Stage-1 eSigned **IC Agreement + Non-Compete + NDA + BAA**, each with name/date/IP/fingerprint/version+hash |
| Avoid employment indicia | No gov enrollment numbers; no W-4/I-9; payment via Wise as a contractor, not payroll |
| Foreign-person tax status | **W-8BEN as an uploaded document** (not a portal form); retained while relied upon (~3 yr norm) |
| Retain contractor agreements & tax docs | Signature records + `documents` artifacts retained per counsel-set schedule |
| HIPAA exposure (if PHI touched) | Signed **BAA** on file (mandatory if PHI accessed; precautionary otherwise) |
| Worker-classification risk (IRS / NY DOL) | Form-level signals minimized; **substance flagged for counsel** — design does not adjudicate classification |
| Provenance / non-repudiation of signed docs | IP + device fingerprint + doc version/hash captured at signing; immutable signature records |

> **Counsel-review flags:** (1) firm retention periods for W-8BEN, signed agreements, and SPI; (2) whether PHI is actually in scope (BAA necessity); (3) worker-classification substance under IRS / NY DOL tests; (4) sufficiency of the Supabase DPA + cross-border consent language under current NPC issuances. Resolve these before onboarding the first contractor at scale.

---

## 9. Open Questions / Decisions for the Owner

1. **Signature pad library.** Confirm the drawn-signature implementation — a small dependency (e.g. `signature_pad`) vs. a hand-rolled `<canvas>` handler. Must work in single-file in-browser-Babel with no build step. (Type-to-sign is the always-available accessible default regardless.)
2. **Device fingerprinting approach.** Which fingerprint source (a lightweight hand-rolled hash vs. a library), given it must be best-effort and never block signing (§6.8). Confirm this is acceptable for the legal evidence posture.
3. **Privacy-notice consent representation.** Confirm whether the DPA consent record is a distinct `agreement_kind` value in `onboarding_signatures` (e.g. `privacy_notice`) plus a `consent_*` flag table, or a separate mechanism (§8.1.2 / §3B).
4. **`onboarding_cycle_id` for rehires.** Decide whether to add a cycle id now (promoting the `onboarding_progress` PK) to keep rehire history distinct, or defer until the first rehire (§3D / §6.6).
5. **Exact retention periods.** Counsel to set firm windows for W-8BEN, the four signed agreements, and each SPI category; these then drive the disposal job and the DPA retention schedule (§8.1.5 / §8.2.2).
6. **Who is DPO.** Formally name the Data Protection Officer (default: Bronxon) and publish contact in the privacy notice (§8.1.6).
7. **Email provider for notifications.** Confirm the mailer used by the existing `documents-expiry-check` cron is the one to reuse for onboarding emails, and verify deliverability to PH inboxes (§5.5).
8. **Stalled-reminder cadence & cap.** Confirm the day-2/5/9/14 → weekly → stop-at-30 schedule and the per-contractor reminder cap (§6.1).
9. **Manual-assist / hard-block policy after 3 rejections.** Decide whether the optional hard block (§6.2) is on by default or admin-toggled per `portal_settings`.
10. **`requires_resign` versioning source.** Confirm where agreement version metadata + the `requires_resign` flag live (a new `agreement_versions` table vs. config), since §6.1 depends on it.
11. **NBI freshness enforcement point.** Confirm the "issued within 6 months" check is HR-decision-driven against `documents.issued_on` (with a soft client advisory), and who captures `issued_on` at review.
