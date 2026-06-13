# ABBI HR & Payroll — Full Feature Spec (recreation guide)

A complete, feature-by-feature description of this app so it can be **recreated in another similar app**. Covers UI/UX, website design, field dropdowns, data-entry helpers, menu structure, workflows, and the backend.

> Two apps in one repo, plus a Supabase backend:
> - **Admin app** — `app/index.html` (~13,000 lines, single-file React 18 via in-browser Babel). Desktop-first.
> - **Contractor portal** — `portal/index.html` (~2,200 lines, same stack). Mobile-first.
> - **Legacy fallback** — `app/legacy.html` (frozen older admin UI, reachable via a kill switch).
> - **Backend** — Supabase Postgres + 10 edge functions. Schema in `schema/schema.sql` + `schema/migrations/*`.
>
> Hosting: Cloudflare Workers static assets (admin worker + separate portal worker), git-connected to `main` (auto-deploy). Pays Philippine contractors in **PHP**; time from **Hubstaff**; payouts via **Wise**.
>
> **Deeper detail:** this file is the organized overview. For exact `file:line` anchors, every dropdown option, validation rule, and formula, see the six subsystem appendices in **[`docs/spec/`](spec/README.md)**.

---

## Table of contents
1. [Architecture & key concepts](#1-architecture--key-concepts)
2. [Design system (colors, type, components)](#2-design-system)
3. [Global UX systems (helpers, guards, drafts, confirms, a11y, cache)](#3-global-ux-systems)
4. [Navigation & menu structure](#4-navigation--menu-structure)
5. [Admin app — feature by feature](#5-admin-app--feature-by-feature)
6. [Contractor portal — feature by feature](#6-contractor-portal--feature-by-feature)
7. [Backend — edge functions, data model, RLS, cron](#7-backend)
8. [Reproduction checklist](#8-reproduction-checklist)

---

## 1. Architecture & key concepts

- **Single-file SPA, no build step.** Each app is one HTML file: React 18 + ReactDOM UMD + Babel-standalone (from cdnjs) + `@supabase/supabase-js@2` as an ESM module exposing `window.__createClient`. A `<script type="text/babel" data-type="module">` holds the entire app; Babel transpiles it in the browser. The root render is the last statement, e.g. `ReactDOM.createRoot(...).render(<><ErrorBoundary><App/></ErrorBoundary><Toaster/><UnsavedChangesModal/></>)`.
- **Auth.** Admin app = Google OAuth (Supabase Auth + Google provider); only allow-listed emails in `admin_users` get in. Portal = email + password (+ Cloudflare Turnstile). The anon key is shipped in the client — safe because RLS grants nothing without an allow-listed session.
- **The employer/client model (load-bearing).** `companies.kind ∈ {employer, client}`.
  - **Aaron Anderson E.H.S. LLC** = the single **employer** (UUID `11111111-1111-1111-1111-111111111111`; historically mislabeled "Ability Builders"). All payroll — rates, pay periods, payments, time — lives at the **employer** level.
  - **Ability Builders for Children / 123 Baby Talks / 1 World Realty** = **clients** (billing tags only). A contractor's `worker_companies` link to a client carries a `bill_rate_usd` used only for invoicing.
  - Hubstaff time always lands on the employer; the client attribution is derived separately for invoices.
- **Self-hosting caching strategy.** The shell HTML is served `Cache-Control: no-store` (always fresh + disables bfcache). A `BUILD` constant + a `version.txt` poll auto-reloads open tabs to the latest deploy. See §3.7.

---

## 2. Design system

**Brand:** navy + gold. `--navy #1F3A68`, `--gold #D4A24C`. Logo assets: `mark-light.png` (top bar), `logo.png` (auth/print), inline-SVG favicon. Aesthetic: restrained enterprise — soft gray page, white cards with hairline borders + subtle shadows, tabular-numeric money, instant (.16s) easing, fully responsive, strong a11y.

### 2.1 Tokens (CSS custom properties)
```
--navy #1F3A68  --navy-700 #162a4d  --navy-50 #eef2f8
--gold #D4A24C  --gold-soft #f7edd8
--bg #f4f6f9  --card #fff  --surface-2 #f8fafc
--border #e4e8ee  --border-strong #ccd3dd
--text #15233b  --muted #5c6677  --subtle #677083   (subtle darkened to hit WCAG AA)
--good #0a7d3c / --good-soft #dcfce7
--warn #b45309 / --warn-soft #fef3c7
--bad  #b91c1c / --bad-soft  #fee2e2
--accent → var(--navy)  --accent-soft → var(--navy-50)   ← single re-skin hook
--radius-sm 7  --radius 11  --radius-lg 16 (px)
--shadow-sm/--shadow/--shadow-lg ; --ring 0 0 0 3px rgba(31,58,104,.22)
--dur .16s  --ease cubic-bezier(.2,.6,.2,1)   (all motion disabled under prefers-reduced-motion)
```
**Typography:** `Inter, system-ui, …`; base 14px/1.5; money uses `font-variant-numeric:tabular-nums`. `h2` 19/700, `h3` 15, table `th` 11px uppercase letter-spacing .04em muted.

### 2.2 Global components & their classes
- **Buttons** `.btn` (solid navy/white), `.btn.ghost` (white/navy outline), `.btn.danger` (red), `.btn.danger-outline`, `.btn.sm`. Mobile: 44px min height.
- **Modals** `.modal-bg` (fixed, dim backdrop, `z-index:20`, top-aligned, scroll) + `.modal` (white, radius-lg, max-width ~680 often overridden). On ≤640px modals become **bottom sheets** (full-width, 92dvh, rounded top, sticky bottom action bar, 16px fonts to stop iOS zoom).
- **Tables** `.table-scroll` wrapper; on ≤767px any `.table-scroll:not(.keep-table)` table **CSS-transforms into stacked cards** — `thead` hidden, each `<td>` becomes a `[label][value]` row where the label = the cell's **`data-label="…"`** attribute. Cell helpers: `.card-title` (full-width heading), `.card-action` (stacked buttons), `.card-skip` (hide on mobile). Opt out with `.keep-table`.
- **Pill** `.pill` (rounded chip 11px/600) with variants `.ft` (navy), `.pt` (pink #fce7f3/#9d174d), `.active` (green), `.inactive` (gray), `.warn`, `.bad`, `.info`. Used for every status; usually paired with a `title=codeHint(...)` tooltip.
- **Badge** `<Badge s={{color,bg,txt}}/>` — dynamic-color version of a pill (document/signature statuses).
- **Banner / Alert** `.banner` (prominent message, left accent bar, auto icon) with `.success/.error/.info` (info is blue, deliberately not green). `<Banner msg/>` auto-detects tone from the text; `<Alert>` is a persistent tab-scoped toast.
- **Skeleton** `<Skeleton rows/>` shimmer bars; `<ProgressSteps>` checklist + live elapsed timer for >10s ops.
- **Empty/stub** `.empty` (centered muted) and `.stub` (dashed placeholder).
- **FilterBox** single text input bound to `q`/`setQ`.
- **Tooltips** custom `.tip-wrap`/`.tip-body` for multiline; coded values use native `title=codeHint(kind,val)`.
- **Toasts** fixed top-center `.toaster` stack via `notify(content,{type,ms,persistent,actions})`.
- **Command palette (⌘K)** `CommandPalette` — opened by Cmd/Ctrl-K or the top-bar "🔎 Find"; searches **sections** (nav), **contractors** (👤), and **pay periods** (📅); ↑/↓/↵/Esc; routes via `go()/openContractor()/openPeriodForEdit()`.

---

## 3. Global UX systems

### 3.1 Data-entry helpers (reused everywhere)
- **`EmailInput`** — `<input type=email>` + native `<datalist>` of common domains; `work` prop pins `["123babytalks.com","abckidsny.com"]`; `pin=[…]` for custom (e.g. AdminsModal pins `["abckidsny.com","abbilabs.com"]`).
- **`PhoneInput`** — country `<select>` (US & PH pinned at top, then ~200 A–Z, flags from ISO codepoints) + `type=tel`; formats on blur (US `+1 (AAA) BBB-CCCC`, PH `+63 AAA-BBB-CCCC`); emits one canonical string.
- **`ContractorPicker`** — searchable multi-select popover over `[{id,name}]`, `value` is a `Set`; "Select all (N)" / "Clear" / checkboxes; closes on outside-click/Esc.
- **`Avatar`** — round photo or initials circle; `fileToAvatarDataUri` center-crops uploads to a ~256px JPEG data-URI (stored in a text column; no bucket for avatars).
- **Date/time** — native `<input type=date|time>` styled globally; PHT shift times via `etToPhtHHMM`/`phtToEtHHMM`/`fmt12`/`phtShiftToEtLabel` (Eastern↔Philippine, DST-aware).
- **Money/name** — `money(n,cur)` (`"PHP "` default, `"$"` USD, null→"—", 2dp), `fullName(w)`, `methodLabel(m)` (BPI uppercased else capitalized), `codeHint(kind,val)` tooltips.
- **`useSortFilter(rows, accessors, searchFields)`** → `{rows, Th, q, setQ}`; `<Th k="name">` clickable sort header (▲/▼/⇅); text filter scans `searchFields`.
- **`useQuery(client, runner, deps, opts)`** → `{data,error,loading,reload}`; `opts.enabled:false` defers (used to gate hidden-but-mounted tabs).
- **`pageAll(countQuery, rangeQuery, 1000)`** — works around PostgREST's 1000-row cap by counting then firing all `range()` pages concurrently (used wherever totals must not truncate, e.g. Reports).
- **`downloadCSV(filename, rowsOfArrays)`** — RFC-4180 escaping, `\r\n`, Blob download.
- **`logEvent(client,{company_id,action,entity,detail})`** — writes `audit_log`; never throws.

### 3.2 Unsaved-changes guard
A registry-based guard so any dirty surface blocks navigation with one prompt.
- `useUnsavedGuard({dirty,label,save,discard})` registers each render. Only surfaces with a `save` fn block; a dirty-but-unsavable surface (e.g. an in-progress signature) just lets you leave.
- `confirmUnsaved()` → Promise<bool>; opens the single `<UnsavedChangesModal>` (**Save / Discard / Stay**). "Save" runs each guard's `save()` (commit OR write a draft); keeps the modal open if a Save fails.
- Hooked into every navigation choke point: tab switch (`go()`), cross-tab jumps, Sign out, and a `beforeunload` backstop. `guardedClose(onClose)` wraps any modal close.

### 3.3 Draft autosave + resume (localStorage; never the DB)
- `draftSave(key,value)` (synchronous, used by the guard's Save), `draftLoad`, `draftClear`, and `useAutoDraft(key,value,hasContent,doneRef)` (debounced 500 ms).
- Resume patterns: `<DraftNotice>` ("↩ Resumed your saved draft." + Start fresh) inside a reopened form; **`<HireDraftBanner>`** — a discoverable amber banner on the Contractors and Hiring screens ("📝 Unfinished hire draft for {name} · saved {time}" + **Resume** / **Discard**) so "Save"-on-leave isn't a dead end.

### 3.4 Risk-proportional confirm
`confirmDanger({title, message, consequence, confirmWord, confirmLabel})` → Promise<bool>. Renders `<DangerConfirm>` above any modal (z-index 1000). When `confirmWord` is set, a **typed-confirm input** appears ("Type **WORD** to confirm") and Confirm stays disabled until it matches. Used for LOCK / DELETE / WITHDRAW / RECALCULATE / typed entity names.

### 3.5 Modal accessibility
`useModalA11y(onClose, {escClose, dep})` → a ref for the inner `.modal`. Pushes onto `_modalStack` (only the top modal handles keys → nested dialogs nest correctly), focus-traps Tab/Shift-Tab, restores focus on close. `escClose` is **off** for data-entry forms so a stray Escape never drops edits.

### 3.6 Toasts + error boundary
`notify()`/`<Toaster/>` (top-center). `<ErrorBoundary>` wraps the app + each conditionally-mounted tab → on a render error shows a recovery card ("Something went wrong / Your data is safe", Reload, "Switch to classic view") instead of a blank page.

### 3.7 Legacy kill switch + self-update/cache
- **Kill switch** (head `<script>` before React): reads `?ui=classic|new`, a global `var FORCE_CLASSIC=false` lever, and `localStorage["eis_ui"]`. Classic → `location.replace("/legacy.html"+search+hash)`. A discreet "↩ Classic view" pill lives outside `#root`.
- **Self-update** (`BUILD` constant + `version.txt`): on load and on tab refocus, fetch `version.txt?_=<ts>` `no-store`; if the deployed build ≠ `BUILD`, reload to `?_v=<latest>` (loop-safe; skips during OAuth callbacks). The shell is served `no-store` so a normal refresh always lands on the latest — no hard refresh.

---

## 4. Navigation & menu structure

**Top bar** (sticky, navy, 3px gold top border): logo + **"HR & Payroll"** / "PH independent contractors", **🔎 Find** (⌘K), the **Employer switcher** dropdown (only global context selector; disabled if ≤1 employer), signed-in email, **Admins** (owner-only), **Sign out**. Footer everywhere: `Build {date · sha}`.

**Left sidebar** (desktop) / **bottom tab bar + "More" sheet** (mobile). Sections and items (icon · tab id · label):

| Section | Tab | Label | Icon |
|---|---|---|---|
| **Home** | overview | Overview | 🏠 |
| **Manage Team** | contractors | Contractors | 👥 |
| | onboarding | Hiring & Onboarding | 🧭 |
| | documents | Documents (legacy expiry tracker) | 📄 |
| **Run payroll** | time | Time & Approval | ⏱ |
| | payroll | Calculate | 🧮 |
| | process | Process and Pay | 💸 |
| **Review** | batches | Review & Recon Batches | 📦 |
| | reports | Reports | 📊 |
| | invoicing | Invoicing | 🧾 |
| | imports | Imports | 🗂 |
| | audit | Audit Log | 📝 |
| **Configuration** | configuration | Configuration | ⚙ |

**Routing:** a single `tab` string in `App` state (persisted to localStorage). `overview` and `configuration` mount only while active; every other tab lazy-mounts on first visit then stays mounted hidden (`display:none`) so its in-memory state survives switches. Every tab is pinned to the selected **employer**; Invoicing is the only tab with its own (client) picker. Cross-tab jumps: `openContractor(workerId)`, `openPeriodForEdit({start,end})`, `goTab(id)`.

---

## 5. Admin app — feature by feature

### 5.1 Overview (dashboard / Home)
Attention-first dashboard, stale-while-revalidate from `sessionStorage`. One batched query (`Promise.allSettled`, each failure blanks only its tile).
- **THIS PAY CYCLE hero:** current semi-monthly period, state, **pay-day countdown**, contractor count, **Net this period** (Σ `payments.net_php`), and a 5-step **pipeline** Time → Calc → Lock → Sent → Settled (each done/active/todo).
- **KPI tile grid** (each tile is a button that drills to a tab): Current pay period → process; **Locked, not yet sent** (+ ₱ ready) → process; **Time pending approval** → time; **Contractors needing setup** (no payout method OR no current rate) → contractors; **Docs & onboarding** (pending docs + open onboarding) → documents; **Payout issues** (failed payouts) → batches.
- **Net-pay sparkline** (inline SVG, last N periods + delta pill). **Data-quality check** ("Run check") flags contractors where |tracked − paid| > 0.5 h for the latest period.
- Motion: a subtle staggered fade-up entrance only (no weather animation here — the "From New York" weather visuals live in the **portal** home).

### 5.2 Contractors
List of `worker_companies` rows joined to `workers` + client engagements, scoped to the employer.
- **Toolbar:** "Show inactive" toggle, "⤓ Pull IDs from Wise", "⇪ Bulk import", "📣 Announcements", "Quick add" (creates a blank worker + opens its profile), "+ Add contractor" (wizard), and the `HireDraftBanner`.
- **Columns** (sortable `<Th>` + FilterBox over name/client/role): **Name** (avatar + clickable → profile), **Client** (joined client names or "—"), **Role**, **Contract** (pill FT navy / PT pink), **Payout** (`methodLabel` or amber **"not set"** pill), **Status** (active/inactive). Inactive rows at opacity .6; row key `worker.id|company_id`.
- **Row actions:** **Edit** (ProfileModal), **Deactivate/Reactivate** (`setActive`: `workers.status` → `active`/`ended`, link status + `ended_on`, triggers a billing-dirty acknowledgment), **Delete** (`deleteContractor`): client-side payroll-history guard (any payments/time → block, "deactivate instead"), then **typed-confirm via prompt** (type the name/email), then `portal-admin {action:"delete_contractor", force: hasRecords}`. The server re-validates and is the authority (cascades worker → links/rates/logins/onboarding, deletes Storage files + auth user).

### 5.3 ProfileModal (contractor editor)
Header: avatar 64px + Upload/Change/Remove photo. **Four tabs:**

**Profile** — First/Middle/Last; **Contract** `<select> FT|PT`; Role; **Expected hours/week** (number 1–60, default 40/20); **Payout method** `<select>` (— not set —, Wise/BPI/GCash/PayMaya/PayPal, **instant-save**); Personal email (EmailInput); Work email (EmailInput work); Mobile / Work number (PhoneInput PH) + Ext; Hire date / DOB; **ShiftEditor** (two PHT time inputs + Save + "Reset to 8–5 ET"); PH address; Hubstaff name; Health allowance + 13th-month checkboxes; **Save details**. Plus a **Client engagements** sub-panel: per-client `worker_companies` card (active/ended + Deactivate/Reactivate, **Position**, **Bill rate (USD/hr)**, Save) and an **Add company** select (multi-client guardrail warning).

**Pay & payout** — **Rate (PHP per period)** + "Effective from" + Save (effective-dated `rates`; new rate closes the prior); **Rate history** table (Edit date / Delete with contiguity recompute); **Wise recipients** (id+label list, Make default / Remove / Add) + separate **Wise recipient UUID** (for the manual batch CSV); `ExternalSourcesPanel` (on-demand pull vs Wise/Hubstaff with ⚠ mismatch flags).

**Personal / HR** — Emergency contact + **Relationship** `<select>` (Parent/Spouse/Sibling/Child/Grandparent/Relative/Friend/Partner/Guardian/Other) + Emergency mobile; Permanent address (+ "Same as current" mirror); Landmark; Postal; **Marital** `<select>` (Single/Married/Widowed/Separated/Annulled/Divorced); Education level; Course; **Year graduated** `<select>` (current → −60); School; About/culture (Favorite color/food/Personal motto → `profile_extras` jsonb).

**Portal & login** — Create portal login / Reset password / Revoke / Require onboarding (each confirms → the matching `portal-admin` action); temp-password banner; Wise Tag banner.

Saving: `saveDetails` builds an `auditDiff`, updates `workers` + the company link, logs `edit_contractor`. Unsaved guard active; `refreshLocal` re-syncs after sub-saves but won't clobber in-progress typing.

### 5.4 AddContractorWizard (hire)
3 steps; **creates nothing until "Create contractor"**; per-company draft autosave + resume.

- **Step 1 — Identity:** First */Middle/Last *; Personal email * (EmailInput); Current address; Permanent address (+ "Same as current"); DOB.
- **Step 2 — Engagement (IC terms):** **Company *** `<select>`; **Contract *** `<select> FT|PT` (changing it auto-sets hours 40/20); **Expected hours/week *** (number 1–60); **Role/position ***; Rate (PHP/period); Contract date; **Hire date ***; Health + 13th checkboxes; **Daily shift *** (two PHT inputs + "Reset to 8–5 ET"); **Company countersigner *** `<select>` (admins filtered by `can_countersign`, labeled "{name} ({email})") + a free-text name-on-document field; **IC addendum** `<select>` (No addendum / Scope of Work / Other) + textarea; **Additional documents to request** (dynamic list).
- **Step 3 — Portal & onboarding:** **Invite to the portal** checkbox; **Tools to provision** (Gmail/Providersoft/Hubstaff/Zoom checkboxes + "Other tools" text); **Summary** card.
- **Validation** per step (`validateStep`): step 1 names + valid email (when inviting); step 2 company, role, rate>0, hours>0, hire date, countersigner, shift.
- **Duplicate prevention:** email hard-block on existing **worker** AND existing **contractor_login**; **name** soft-warn via `confirmDanger` requiring you to type `DUPLICATE`. (The edge `create_login` is the authoritative guard via `admin_lookup_auth_user`.)
- **On Create** writes: `workers` → `worker_companies` → `rates` (if rate>0) → `portal-admin create_login` (if invite) → prefill `onboarding_agreements` (IC + the others, snapshotting employment type/hours/ET shift label) → `extra_documents` → `set_tools_requested` RPC; logs `add_contractor`. **Rollback** deletes the just-created worker on any later failure. Success screen shows the temp password + Copy.

### 5.5 BulkImport
Paste/upload a CSV/TSV roster; **ID-first matching** (Wise recipient id → Wise UUID → Hubstaff id → strict name key → loose name key); **match-before-create**. Stages: input → preview → done. Flexible header aliases (`BULK_COLMAP`), blanks never overwrite, "Prefer the Wise account name" option, CSV template download. Preview table shows per-row action (create/update/skip) + matched-via + changes/notes. Commit updates/creates `workers`+`worker_companies`+`rates`; logs each row. Draft autosave.

### 5.6 Hiring & Onboarding (admin)
- **OnboardingAdmin list:** `onboarding_progress` + workers, columns **Contractor / Stage / Progress% / Status / Updated**, a `Badge` from `onbStatus` (Action needed / Complete / Stalled / In progress), pending-doc and deferred-doc counts (+ Alerts), "Show completed" toggle, **+ Hire new contractor**, **📄 Agreement templates**, **⚙ Onboarding config**, `HireDraftBanner`, and a **Review** button per row.
- **OnboardingDrilldown (Review modal):**
  - **Stage overrides:** ↺ Stage 1/2/3 reopen, ✓ Mark complete, 🔑 Tool access, ↺ Reset (all via `applyProg` with a confirm + audit; reopening re-locks pay-data access, completing unlocks it).
  - **Hire-management row:** **✎ Edit details** (opens ProfileModal with a synthesized row); **✉ Update login & resend** (modal to correct the login email + always issue a fresh temp password + resend welcome → `update_login_and_resend`); **⊘ Withdraw offer** (confirm `WITHDRAW` → `withdraw_offer`: revoke login, ban auth user, mark ended, withdrawal email; refuses if payroll exists); **🗑 Delete hire** (confirm `DELETE` → `delete_contractor force`).
  - Sections: **1 · Agreements** (signature ledger table + AgreementsPanel), **2 · Profile** (read-only), **3 · Documents** (review).
- **AgreementsPanel** — per kind (IC / Non-Compete / NDA / BAA): **Prepare/Edit prefill** form (Position, Rate, Start date, **Engagement** `<select> full_time|part_time`, **Expected hours/week**, **Shift/schedule**, **Countersigner** `<select>` filtered by `can_countersign`, **IC addendum** `<select>` for IC only). Non-IC rows **auto-fill from the IC row**. **`mergeAgreement`** merges tokens `{{contractor_name|rate|monthly_rate|company_name|client_name|employer_name|start_date|position|contractor_address|countersigner_name|today|employment_type|hours_per_week|schedule|addendum}}`; if the template omits the engagement tokens it **auto-appends** an "Engagement: Full-time (40 hours/week). Work schedule: … " clause + a **DST note** (Eastern observes DST, Philippines doesn't → local PH time shifts an hour at spring-forward/fall-back). `printDoc` renders a print window with logo + merged `<pre>` + a two-column signature block (XSS-safe signature image rendering). Countersign via `portal-countersign`; edit the signed date via `portal-review set_signed_date`.
- **AgreementTemplatesModal** — per-kind legal-text editor (`agreement_templates` table) with a documented merge-field legend.
- **Document review** (in the drilldown): per doc — **View** (120s signed URL), **Approve** / **Approve anyway** (NBI 6-month freshness override), **Needs replacement** (ReasonPicker preset reasons + Other), **Waive**, **Defer** → all via `portal-review`. Statuses: pending/approved/waived/deferred/needs_replacement; counts only the latest version per kind+side.
- **ToolsProvisionModal** — enter Gmail/Providersoft/Hubstaff/Zoom/Other logins → `set_worker_tools` RPC (encrypted at rest) → `send_tools_email`.
- **AdminsModal (owner-only)** — add admin by email (pinned domains) + role `<select> Admin|Owner`; per-admin **Name** input + **Can countersign** checkbox (`update_admin`); company-scoping chips (`admin_companies`); Make owner/admin; Remove; pending invites (`pending_admins`). All writes via `admin-manage`.
- **OnboardingConfigModal** — `portal_settings.onboarding_config`: Onboarding-enabled toggle; **Documents to collect** (reorderable, Required/Front&back/Expires-after-N-months); **Agreements to sign** (reorderable = sign order); **Signature methods** per party (Typed or drawn / Typed only / Drawn only); **Onboarding emails** (auto-send toggle, portal + Wise links, editable Welcome / Tool-access / Password-reset templates with merge-field hints); **Document-review reminders** (enable, frequency daily/weekdays/weekly, include-deferred, recipients). A raw-JSON escape hatch preserves unknown keys (e.g. `editable_fields`).

### 5.7 Time & Approval (`TimeImport` + `TimeApproval`)
- **Option A — CSV:** upload the Hubstaff daily report; `parseHubstaff` validates Member/Time-off/Total columns; **name matching** is ID-first (`hubstaff_user_id`) then strict (sorted-token) then loose (first+last) keys. Preview table (matched/unmatched, days, tracked/PTO/total/activity) → **Import N → pending**.
- **Option B — Hubstaff API:** Organization (List my orgs / id), Start (auto-fills Stop to the period end), **Import Time** → `hubstaff-sync` (single-client skips the preview; consolidated writes per-client server-side).
- **Pending vs approved** (`time_entries.approval`): imports stage as `pending`. The approval grid **auto-reveals** when any non-approved rows exist (so cron-ingested time can't hide). Overlap detection offers Overwrite / Skip / Cancel; commit stamps an `import_batch_id` and backfills `hubstaff_user_id` on first name-match.
- **TimeApproval grid:** per-contractor **Days in period / Working days / Days worked / Tracked (editable) / PTO / Total / Status**, with **Approve**, **Add hours** (period-total or day-by-day), **Reject all**, **Delete** (Undo; blocked if dates fall in a locked/paid period), and a "Create Manual Time Entry" path. **Approving navigates forward** to Calculate for that period.

### 5.8 Calculate (`Payroll`)
Builds pay statements from approved time for a chosen semi-monthly period.
- **Period model** `periodFor`: day ≤15 → 1st–15th, pays month-end; day ≥16 → 16th–end, pays the 15th next month (arrears).
- **Batch list** "Pay periods ready for calculation": status badges paid / locked·ready / calculated(draft) / not calculated; **Calculate** / **View** / **Delete** + "Clean up empty drafts".
- **`calculate()` formulas** per contractor: `worked = (tracked+pto)/3600`; `exp = expectedHours(contract,start,end)` (weekdays × 8h FT/4h PT − weekday holidays); `ratio = min(worked/exp, 5)`; **gross** = full rate if ratio≥1 else `ratio×rate`; **health allowance** (₱20000, eligibility = hired+180d AND the period contains the hire anniversary); **13th** = `(monthsWorkedInYear/12)×rate` (half-annual, paid across two periods); **lunch (pdd)** + **bonus** (editable, default 0); **misc_items** (earns/hours add, deduction subtracts); **deduction_php** = `rate − gross` = the **"Perf short"** performance shortfall (informational, NOT subtracted); **net** = gross + ha + 13th + lunch + bonus + miscSum. Recalc guard (type `RECALCULATE`) protects manual overrides; rate-stale banner flags drift vs the effective rate.
- **Pay-statement table:** Contractor / Worked / Exp / Ratio / Rate / **Gross (editable)** / [HA] / [13th] / [Lunch] / [Bonus] / Misc / **Net** / ≈USD ref / **Via** (payout `<select>`) / Delete. **MiscModal** (+ Misc) edits HA/13th/Lunch/Bonus + Other earns / Other hours (×hourly rate) / Deductions with a live "Net impact" footer.
- **Lock** (type to confirm) saves `pay_periods.state='locked'` + `payments` (draft), blocks rows with no rate, warns on no-payout-method/inactive, then offers to go to Process. **Unlock** requires a typed reason. Draft autosave (debounced) upserts `pay_periods` + `payments`.

### 5.9 Process and Pay (`ProcessPayroll`)
- **Empty state** lists "Waiting upstream: N pending time entries" with jump buttons. Locked-period list → **Open & pay** / **Unlock**.
- **Summary + three payout paths:** (1) **Manual Wise batch file** — `downloadWiseBatch` writes Wise's exact 10-column template (USD→PHP), only rows with a recipient UUID, with a re-download guard; (2) **Individual payment files** — a per-row CSV for all methods; (3) **Automatic Wise API draft** (`WisePayouts` → `wise-payouts {action:"batch"}`) which creates a batch group + transfers and **never funds** ("NO money has moved — open Wise to review and FUND").
- **Statuses** `draft|queued|sent|failed|reconciled`. **Mark paid/unpaid** (Wise rows take the API date; BPI/other arm an inline date input), **Check Wise status** (`poll`), and per-row unlock-with-reason. When all rows are `sent`, the period auto-advances to `paid`.
- **FX:** `payments.fx_rate` is the market rate stored at Calculate (reference). The Wise batch is PHP→PHP so Wise locks the **real USD-funded rate** at conversion time; the `rates` action reads back the locked quote per transfer.

### 5.10 Review & Recon Batches
Same `ProcessPayroll` component in `reconcileOnly` mode. Pick any locked/paid batch (read-only table) → **Import processed Wise CSV** (backfills `wise_transfer_id` idempotently, flags amount variances, suggests fuzzy matches) and **Reconcile with Wise** (`match`/`poll` — links missing transfers, auto-overrides single-candidate variances preserving `original_net_php`, finalizes to `reconciled`). `ReconcileOverview` + the Configuration-tab `WiseReconciliation` card (backfill all paid periods, email cross-check, cross-system drift scan) round it out. (Single-statement / whole-batch delete live on Calculate and require unlock first.)

### 5.11 Reports
One `pageAll` payments query (so totals don't truncate). Four summary cards (Total net, Total ≈ USD ref, Unpaid, Period count), then:
- **Payout by pay period** — year/month multi-select filter; expandable per-period breakdown (full component columns; clarifies real deductions vs the perf-shortfall `deduction_php`).
- **PerContractorSummary ("Contractor Pay Summary")** — From/To + This-year/Last-year + ContractorPicker; per-contractor totals (Periods/Hours/Gross/Misc/Net/Paid) with **expandable per-period statement rows**; **Summary CSV** and **Statements CSV** exports.
- **ContractorHistory** — pick one contractor → every period stacked (worked/PTO + pay components, expandable to daily), CSV export.
- **UtilizationReport ("Avg. Weekly Activity")** — ContractorPicker; per ISO week avg `activity_pct` + hours.

### 5.12 Invoicing (`Invoicing`)
Bills a **client** for worked hours × each contractor's USD bill rate (PTO not billed). Client `<select>` (+ "all clients" history), From/To, Markup %, Preview. Build pulls the client roster's `bill_rate_usd` × employer time. Generate → `allocate_invoice_no` RPC + `invoices`/`invoice_lines` (one live invoice per client+period; Void to regenerate). Print = standalone HTML ("INVOICE", From "Aaron Anderson E.H.S. LLC", Bill to, lines, subtotal/markup/total). Status flow draft → sent → paid (+ void); CSV export.

### 5.13 Imports (`DeleteImports`)
Cleanup tool (importing happens in Time & Approval). **Delete by date range** (dry-run preview per contractor; normal one-click confirm, or type `DELETE` when the range overlaps locked/paid periods) and **Delete by import batch** (recent batches list with View + guarded Delete). Both also clear draft payments for open overlapping periods.

### 5.14 Audit Log (`AuditLog`)
`audit_log` newest-first (limit 500; date filters query the server past the cap). Columns **When / Action (human label via `AUDIT_LABELS`) / Item / Detail (`summarizeDetail` renders before→after diffs) / By**. Date presets (7d/30d/year), FilterBox, sortable headers, CSV export.

### 5.15 Configuration
Six rows opening modals:
- **Employer** / **Clients** → `CompaniesModal` (add/edit with Tax ID, Hubstaff org ID, address, phone, website, repeatable contacts; **Archive** keeps history vs **Delete** which is owner-only and only for a genuinely empty company via typed-name confirm; the employer can't be archived/deleted).
- **Hubstaff Projects → Clients** → `HubstaffProjectsModal` (map each Hubstaff project to a client; `cron_ingest` uses it for attribution).
- **Portal Fields** → `PortalSettingsModal` (checklist of 27 self-editable fields; payout destination always admin-only).
- **Agreement Templates** → `AgreementTemplatesModal`.
- **Onboarding Configuration** → `OnboardingConfigModal`.
- Embedded **WiseReconciliation** maintenance card. (No in-app secrets/connection-status panel — connectivity surfaces through action error messages; tokens live in Supabase secrets.)

---

## 6. Contractor portal — feature by feature

Mobile-first SPA (`portal/index.html`). On ≥900px the bottom tab bar restyles into a left sidebar + 2-column dashboard. Shipped `Cache-Control: no-store` + the same self-update poll. i18n via `STRINGS.en` + `t(key,vars)` (Tagalog greetings are live; legal text stays authoritative).

- **Login** — EmailInput + password + **Cloudflare Turnstile** (graceful no-op if the site key is empty; never client-blocks — Supabase Auth is the enforcer). "Forgot / set password" sends a reset email.
- **SetPassword (forced first login)** — triggered by `user_metadata.must_set_password`. Submits a new password (≥8, confirmed) through `portal-self {action:"set_password"}` (service-role update of the caller's own auth user → bypasses the project's "current password required" rule + clears the flag), then **always signs in fresh** with the new password (recovers from a spent/invalidated session) → lands straight in onboarding. A "⏻ Sign out" escape is on the screen.
- **Onboarding flow (the gate)** — blocks the portal until complete. Intro ("Welcome to Ability Builders"), ProgressHeader ("Step n of 3 · pct%"), "Finish later / Sign out".
  - **Stage 1 — Agreements:** sequential (next unsigned unlocked, rest locked). `AgreementViewer` renders the merged template; a **scroll-to-bottom** IntersectionObserver gate enables signing; `SignaturePad` (Type/Draw per `signature_methods`) + full legal name + editable signed date + consent → `portal-sign` (captures sha256, IP/UA server-side, immutable ledger).
  - **Stage 2 — Profile:** 4 sub-tabs (Contact/Personal/Payout/About); required fields enforced (incl. ≥1 payout destination); saved per tab via `portal-self {action:"complete_tab"}`; advances only after the last tab when the server reports complete.
  - **Stage 3 — Documents:** one slot per kind+side. **Two file inputs, `accept=PDF/JPG/PNG`, NO `capture`** → on mobile the OS shows **Take Photo / Photo Library / Browse** (camera + existing files/PDF). NBI requires an issued date. Upload → Storage `contractor-docs/{uid}/{kind}/…` + a `documents` row (`review_status=pending`). Replace/defer supported; **Finish** enabled only when all required docs approved.
- **Home (post-onboarding):** PHT clock + bilingual greeting; **"From New York" hero** (dual live clocks, open-meteo NYC weather, daily trivia, an SVG skyline whose sky matches NY time-of-day, animated weather FX, reduced-motion aware); **"This pay period"** paycard (next/last pay, day-of-period progress with a sliding ☀️); **announcements** feed ("Word from Your Mother" / "From New York"); **activity chart** (SVG bars + moving average); **quick links** (Hubstaff/Gmail/Providersoft/Wise); **daily mood check-in** (start/end emoji within 2h of the PHT shift → `mood_checkins`); **outstanding-docs reminder** popup. Tabs: **Home / Pay slips / Time / Docs / Profile**. **Pay slips** = rich breakdowns (hours/ratio/rate/components/Wise transfer id). **Profile** = self-edit limited to `portal_settings.editable_fields` (payout destination admin-only). **ToolsPopup** = one-time decrypted tool logins via `get_my_tools`/`ack_my_tools`.

---

## 7. Backend

### 7.1 Edge functions (`supabase/functions/*`, all deployed `--no-verify-jwt`; in-code gate is the control)
| Function | Auth | Purpose / actions |
|---|---|---|
| **portal-admin** | admin-verified | Contractor login lifecycle: `create_login` (auth user + `must_set_password` + link + seed onboarding + **email-taken guard** + welcome email), `reset_password`, `resend_hire_emails`, `update_login_and_resend`, `withdraw_offer` (revoke+ban+ended+email; refuses if payroll), `revoke_login`, `delete_contractor` (payroll-history hard-block; force destroys signed/uploaded; deletes worker+files+auth user), `send_tools_email`. **Email = Gmail/Workspace SMTP**; templates in `onboarding_config.hire_emails` (welcome/credentials/tools/withdraw); all values HTML-escaped. |
| **portal-self** | contractor (via `contractor_logins`) | `update_profile` (writes `editable_fields ∩ SAFE_FIELDS`), `complete_tab` (Stage-2 validation + monotonic advance), `advance_from_stage1`, `finish_onboarding` (requires stages + all required docs resolved), `set_password` (service-role self-update bypassing the current-password rule). |
| **portal-sign** | contractor | `sign` — one immutable Stage-1 signature: enforces sign order + scroll-to-end; drawn signature must be a bounded `data:image/...;base64` ≤1MB (anti-XSS); captures IP/UA; soft legal-name-mismatch flag. |
| **portal-review** | admin | `approve` (NBI freshness + override), `needs_replacement` (reason), `waive`, `defer`, `set_signed_date`; `reEvalStage3` recomputes completion and finalizes onboarding. |
| **portal-countersign** | admin | `countersign` — admin countersignature; requires contractor signed first + the assigned countersigner; immutable; captures IP/UA. |
| **admin-manage** | owner-only | `add_admin` (sign-in-first via `pending_admins`; domain/contractor guards), `set_role` (can't demote last owner), `update_admin` (name, can_countersign), `remove_admin`. |
| **hubstaff-sync** | admin OR cron-secret | Pull Hubstaff time (rotating refresh token in `api_tokens`). `list_orgs`/`list_projects`/`get_user`, default rollup, **`cron_ingest`** (daily UPSERT, ID-first + name fallback, protects approved rows, lands on the EMPLOYER), `sync_ingest`, `activity_backfill`. PTO from `time_off_requests`. |
| **wise-payouts** | admin; OWNER for draft/batch; cron-secret for poll/match | **Drafts only — never funds.** `profile/draft/batch/status/rates/recipients/get_recipient`, `poll` (mark sent + dates + lock), `match` (backfill `wise_transfer_id`, auto-override single-candidate variances preserving `original_net_php`). |
| **documents-expiry-check** | cron-secret OR admin | Daily digest (via **Resend**) of `documents` expiring/overdue. |
| **hiring-docs-review-check** | cron-secret OR admin | Daily digest (via **Gmail SMTP**) of pending new-hire docs, honoring `review_notify.frequency`/`include_deferred`. |

### 7.2 Data model (key tables)
`companies (kind employer|client, hubstaff_org_id)` · `workers (identity + contact + HR + payout + profile_extras jsonb + shift_start/end PHT + eligibility flags)` · `worker_companies (worker↔company M2M: role, contract FT|PT, hubstaff_name/user_id, status, started/ended_on, bill_rate_usd, weekly_hours)` · `rates (effective-dated amount_php)` · `pay_periods (period_start/end, pay_date, state open|locked|paid)` · `time_entries (source_name, work_date PHT, tracked/pto_seconds, activity_pct, approval, import_batch_id)` · `payments (one per period×worker: all *_php component columns, net_php, original_net_php, fx_rate, payout_method, wise_transfer_id, wise_dates, status draft|queued|sent|failed|reconciled, misc_items jsonb; hard-lock trigger once wise_locked_at set)` · `documents (kind, storage_path, side, issued_on, review_status, review_reason)` · `contractor_logins (worker_id PK, auth_user_id, email, status)` · `admin_users (user_id, email, role owner|admin, name, can_countersign)` + `pending_admins` + `admin_companies (admin_email, company_id scoping)` · `onboarding_progress (worker_id PK, current_stage, stage flags, completed_at = the gate)` · `onboarding_signatures (immutable eSign ledger: sha256, method, data, signed_date, ip, ua, fingerprint)` · `onboarding_agreements (per-hire prefill + countersignature: f_rate/f_position/f_start_date/f_company_name/f_employment_type/f_hours_per_week/f_schedule, addendum, countersign_*)` · `agreement_templates (kind PK, body merge-field text)` · `portal_settings (id=1: editable_fields jsonb, onboarding_config jsonb)` · `announcements` · `mood_checkins` · `audit_log` · `api_tokens (Hubstaff rotating token)` · `app_secrets (cron_secret, gmail creds…)` · `worker_tools` + tools RPCs (encrypted).

### 7.3 RLS & security
Helpers `is_admin()`, `is_owner()`, `my_worker_id()`, `is_onboarded()`, `is_company_admin(cid)`, `admin_can_see_worker(wid)`. Admins are **company-scoped** (owners see all; admins only assigned companies; admin tables have no client write policy → all via `admin-manage`). Contractors are read-only to **their own** rows; pay-data reads also require `is_onboarded()` (the A8 gate); the only contractor writes are `mood_checkins` insert + `documents` insert into their own Storage folder (forced `review_status=pending`) — everything else routes through `portal-self`/`portal-sign`. Storage bucket `contractor-docs` is private (per-uid folders; 120s signed URLs). Anon key in the client is safe because RLS grants nothing without a session.

### 7.4 Cron / automation
- **Daily Hubstaff ingest** — pg_cron (~04:00 Manila) → `hubstaff-sync cron_ingest` with `x-cron-secret`; ID-first/self-healing; lands time on the employer.
- **Email digests** — `documents-expiry-check` (Resend) + `hiring-docs-review-check` (Gmail SMTP), both cron-secret gated.
- **Wise reconcile** (`poll`/`match`) may be cron-driven. Every secret-gated action checks `x-cron-secret` against `app_secrets.cron_secret` (service-role readable only).

---

## 8. Reproduction checklist

1. **Shell** — one HTML file: load React/ReactDOM/Babel + supabase-js (ESM → `window.__createClient`); copy the `:root` token block + component CSS (navy `#1F3A68` / gold `#D4A24C`); mount the three global hosts (`Toaster`, `UnsavedChangesModal`, `DangerConfirm`) + the four imperative helpers (`notify`, `confirmUnsaved`/`useUnsavedGuard`, `confirmDanger`, `useModalA11y`); add the kill-switch + `version.txt` self-update + `no-store` headers.
2. **Helpers first** — `EmailInput`, `PhoneInput`, `ContractorPicker`, `useSortFilter`, `useQuery`, `pageAll`, `money`/`fullName`/`methodLabel`/`codeHint`, `periodFor`, draft helpers. Everything else builds on these.
3. **Backend** — create the tables in §7.2 with RLS in §7.3; deploy the 10 edge functions (`--no-verify-jwt`, in-code gate); set Supabase secrets (`SUPABASE_SERVICE_ROLE_KEY` auto-injected; add Gmail SMTP / Resend / Wise / Hubstaff / `cron_secret`); schedule the pg_cron jobs.
4. **Admin app tabs** — build in dependency order: Contractors + ProfileModal → AddContractorWizard/BulkImport → Onboarding (drilldown/agreements/docs/admins/config) → Time & Approval → Calculate → Process & Pay → Review/Recon → Reports/Invoicing/Imports/Audit/Configuration → Overview last (it reads everything).
5. **Portal** — Login (+Turnstile) → SetPassword → OnboardingFlow (3 stages) → Home + the 5 tabs.
6. **Gotchas worth copying:** the employer/client split (all payroll at the employer, clients are billing tags); ID-first matching + match-before-create for every external sync; the semi-monthly arrears period model + the pay-component formulas (gross pro-ration, HA anniversary, half-annual 13th, perf-shortfall `deduction_php` that is NOT subtracted); Wise drafts never fund; `no-store` shell + version poll for cache freshness; typed-confirm for every destructive action; agreement merge tokens + auto-appended engagement/DST clause; document uploads without `capture` so mobile keeps camera + files.

> **Placeholders to replace before go-live:** the legal text in `agreement_templates` / portal `AGREEMENT_TEXT` is marked "[PLACEHOLDER]". The `app_secrets`, `worker_tools` (+ tools RPCs), and the `admin_users.name`/`can_countersign` columns were applied directly via SQL (not in `schema/migrations/`) — author their DDL when recreating.
