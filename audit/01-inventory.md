# Track 1 — Feature & Navigation Inventory

READ-ONLY audit of the ABC Kids HR & Payroll app. Scope = both front-end apps (`app/index.html` admin, `portal/index.html` contractor portal). Every row cites evidence as `file:line` (or route / state value / edge-fn action). Each claim is labelled **OBSERVED** (read in code) or **INFERRED** (reasoning). Things expected but missing are marked **ABSENT**; ambiguous intent is **ASSUMPTION**. `app/legacy.html` is the frozen `?ui=classic` rollback copy and is noted only — not deep-audited.

Counts: **Admin top-level tabs = 14** · **Admin screens/features (incl. sub-views) = 28** · **Portal screens = 12** (6 nav tabs + auth/onboarding screens) · **Modals & drawers ≈ 30** (admin ~26, portal ~4) · **Edge-function-backed UI actions = 33 invoke call-sites**.

---

## Method & routing mechanism

Neither app uses a router library or URL routes — both are single hand-edited HTML files with React (CDN) + in-browser Babel. Navigation is a **top-level `tab` state variable** + conditional render switch in each app's root `App`/`Portal` component. There is no hash/path routing; deep-linking is in-memory only (cross-tab "jump" callbacks).

### Admin app — routing (`app/index.html`)
- Root component `App` `app/index.html:13359`. **OBSERVED.**
- Tab state: `const [tab,setTab]=useState(...)` `app/index.html:13363`, restored from `localStorage["eis_tab"]` and validated against a hard-coded id list `app/index.html:13365`. **OBSERVED.**
- **Enumerated tab set (14)** `app/index.html:13365` + grouped labels `tabGroups` `app/index.html:13563-13568`:

  | tab id | Sidebar label | Group | Component rendered (router line) |
  |---|---|---|---|
  | `overview` | Overview | Home | `Overview` `app/index.html:13623` |
  | `contractors` | Contractors | Manage Team | `Contractors` `app/index.html:13630` |
  | `onboarding` | Hiring & Onboarding | Manage Team | `OnboardingAdmin` `app/index.html:13641` |
  | `documents` | Documents | Manage Team | `Documents` `app/index.html:13635` |
  | `time` | Time & Approval | Run payroll | `TimeImport` `app/index.html:13631` |
  | `payroll` | Calculate | Run payroll | `Payroll` `app/index.html:13633` |
  | `process` | Process and Pay | Run payroll | `ProcessPayroll` `app/index.html:13634` |
  | `batches` | Review & Recon Batches | Review | `ProcessPayroll` (reconcileOnly) `app/index.html:13636` |
  | `reports` | Reports | Review | `Reports` `app/index.html:13637` |
  | `invoicing` | Invoicing | Review | `Invoicing` `app/index.html:13638` |
  | `sessions` | Service Sessions | Review | `SessionsApproval` `app/index.html:13639` |
  | `imports` | Imports | Review | `DeleteImports` `app/index.html:13632` |
  | `audit` | Audit Log | Review | `AuditLog` `app/index.html:13640` |
  | `configuration` | Configuration | Configuration | `Configuration` `app/index.html:13642` |

- **Lazy-mount + keep-mounted**: a tab isn't mounted until first visited (`seenTabs` `app/index.html:13374`); once seen it stays mounted via `display:none` toggling `app/index.html:13630-13641`, preserving in-tab state. `overview` and `configuration` are the exception — fully conditional render wrapped in `ErrorBoundary` `app/index.html:13623,13642`. **OBSERVED.**
- **Navigation surfaces**: left sidebar (grouped, collapsible) `app/index.html:13597-13615`; mobile bottom-nav (4 primary + More) `app/index.html:13647-13659`; `MoreSheet` `app/index.html:12471`; `CommandPalette` (Cmd/Ctrl-K) `app/index.html:12501`, opened `app/index.html:13382`. **OBSERVED.**
- **Top-bar context**: `EmployerSwitcher` `app/index.html:13590` selects the employer/tenant (payroll home) for every tab; client picking lives inside Invoicing/Sessions, not globally. **OBSERVED.**
- **Cross-tab deep-links** (programmatic, not URLs): `openContractor(workerId)` → switches to Contractors + opens that profile `app/index.html:13474-13482`; `openPeriodForEdit(p)` → switches to Calculate with a period loaded `app/index.html:13489-13497`. **OBSERVED.**
- **Auth/role gating** before any tab renders: ConnectScreen / Loading `app/index.html:13541-13555`; SignInScreen `app/index.html:13557`; access-check loading `app/index.html:13558`; AccessErrorScreen `app/index.html:13559`; NotAuthorizedScreen `app/index.html:13560`. Role from `admin_users.role` (`owner`/`admin`/null) `app/index.html:13535`; `isOwner` gates the Admins button + AdminsModal + owner-only Configuration controls `app/index.html:13576,13582,13592`. **OBSERVED.**

### Contractor portal — routing (`portal/index.html`)
- Root component `App` `portal/index.html:2240`; signed-in shell `Portal` `portal/index.html:1580`. **OBSERVED.**
- Tab state: `const [tab,setTab]=useState("home")` `portal/index.html:1581`; conditional render switch `portal/index.html:1607-1612`; bottom tab bar `portal/index.html:1614-1625`. **OBSERVED.**
- **Enumerated tab set (6)**: `home` `portal/index.html:1607` · `pay` (Pay slips) `:1608` · `time` `:1609` · `sessions` `:1610` · `docs` `:1611` · `me` (Profile) `:1612`. **OBSERVED.**
- **Auth/stage gating** in `App` before the shell `portal/index.html:2266-2277`: not-ready → Loading `:2267`; no session → `Login` `:2268`; `must_set_password` metadata → `SetPassword` `:2271-2272`; onboarding enabled & not done → `OnboardingFlow` `:2275-2276`; else `Portal` + `ToolsPopup` `:2277`. Gating reads `portal_settings.onboarding_config` + `onboarding_progress` `portal/index.html:2247-2253`. **OBSERVED.**
- **RLS scoping**: all portal queries use the contractor's own session (e.g. `workers.select().maybeSingle()` `portal/index.html:1585`); data is row-scoped server-side. **OBSERVED** (queries) / **INFERRED** (RLS enforcement — schema not in Track-1 scope).

---

## Admin app — screens / features

| Name | file:line | User task | Entry point + click-depth | Role / state | Evidence |
|---|---|---|---|---|---|
| Overview (dashboard) | `app/index.html:12206` (router `:13623`) | Landing KPI dashboard; jump to tabs | Landing screen (depth 0); sidebar "Overview" | admin; pinned to selected employer | OBSERVED |
| Contractors (roster) | `app/index.html:2565` (router `:13630`) | Browse/search roster; open a profile; add/deactivate/delete | Sidebar "Contractors" (depth 1); also via `openContractor` deep-link | admin; employer-scoped roster | OBSERVED |
| ProfileModal | `app/index.html:2837` | View/edit one contractor (4 sub-tabs) | Contractors row/Edit (depth 2) `app/index.html:2815`; OnboardingDrilldown "Edit details" `:11465` | admin | OBSERVED |
| → Profile sub-tab | `ptab="profile"` `app/index.html:3284,3391` | Name/contract/email/phone/dates + inline `ShiftEditor` `:3430` | ProfileModal default (depth 3) | admin | OBSERVED |
| → Pay & payout sub-tab | `ptab` `app/index.html:3560` | Effective-dated rate (per hour/session/period), payout method, Wise recipient + inline `ExternalSourcesPanel` `:3690` | ProfileModal tab (depth 3) | admin | OBSERVED |
| → Personal/HR sub-tab | `ptab` `app/index.html:3525` | Personal/HR fields | ProfileModal tab (depth 3) | admin | OBSERVED |
| → Portal & login sub-tab | `ptab` `app/index.html:3482` | Create/revoke/reset portal login | ProfileModal tab (depth 3) | admin | OBSERVED |
| ShiftEditor | `app/index.html:624` | Edit a contractor's weekly shift schedule | Inline in ProfileModal profile tab `app/index.html:3430` | admin | OBSERVED |
| ExternalSourcesPanel | `app/index.html:3706` | Reconcile Wise recipient + Hubstaff user drift | Inline in ProfileModal pay tab `app/index.html:3690` | admin | OBSERVED |
| OnboardingAdmin | `app/index.html:11962` (router `:13641`) | Hiring queue: list onboarding state, hire new, configure | Sidebar "Hiring & Onboarding" (depth 1) | admin | OBSERVED |
| OnboardingDrilldown | `app/index.html:11285` | Per-contractor onboarding review (agreements/profile/docs/tools) | OnboardingAdmin "Review" per row (depth 2) `app/index.html:12049` | admin | OBSERVED |
| AgreementsPanel | `app/index.html:11017` | Show signed agreements; countersign; set signed date | Inside OnboardingDrilldown (depth 3) | admin (countersigner) | OBSERVED |
| Documents | `app/index.html:7467` (router `:13635`) | Track contractor documents + expiry | Sidebar "Documents" (depth 1) | admin | OBSERVED |
| TimeImport | `app/index.html:4393` (router `:13631`) | Import time (CSV parse + match) / Hubstaff API sync into time_entries | Sidebar "Time & Approval" (depth 1) | admin | OBSERVED |
| TimeApproval | `app/index.html:5259` | Approve per-period hours; add/edit entries | Embedded at bottom of TimeImport `app/index.html:4959-4965` (depth 1-2; reveal `:4964`) | admin | OBSERVED |
| Payroll (Calculate) | `app/index.html:6025` (router `:13633`) | Pick period → calculate pay statements → lock batch | Sidebar "Calculate" (depth 1); deep-link `openPeriodForEdit` | admin | OBSERVED |
| HolidayEditor | `app/index.html:5990` | Edit holidays affecting expected/holiday pay | Inline expand in Payroll `app/index.html:7031` (`showHol` `:6066`) | admin | OBSERVED |
| ProcessPayroll (Process and Pay) | `app/index.html:9098` (router `:13634`) | Open locked batch; pay via files or Wise API drafts | Sidebar "Process and Pay" (depth 1) | admin; Fund affordances gated by `apiPayoutsEnabled` `:13634` | OBSERVED |
| → Pay-channel filter | `payTab` `app/index.html:9117` (pills `:10392-10395`) | Filter pay list by channel: `wise`/`bpi`/`other`/`all` | Segmented control in ProcessPayroll (depth 2) | admin | OBSERVED |
| WisePayouts | `app/index.html:8637` | Create Wise API drafts (and Fund when enabled) | Card 3 inside ProcessPayroll `app/index.html:10628` (depth 2) | admin; owner toggles API-payouts | OBSERVED |
| ProcessPayroll (Review & Recon Batches) | `app/index.html:9098` (router `:13636`, `reconcileOnly`) | Reconcile locked+paid batches | Sidebar "Review & Recon Batches" (depth 1) | admin | OBSERVED |
| ReconcileOverview | `app/index.html:9003` | Payment-status summary for a batch | Inside ProcessPayroll reconcile mode `app/index.html:9911` (depth 1-2) | admin | OBSERVED |
| WiseReconciliation | `app/index.html:8105` | Cross-check/backfill Wise transfers vs payments | Inline in Configuration `app/index.html:13348` (depth 1) | admin | OBSERVED |
| Reports | `app/index.html:7608` (router `:13637`) | Period rollups + 3 stacked sub-reports | Sidebar "Reports" (depth 1) | admin | OBSERVED |
| → PerContractorSummary | `app/index.html:7803` | Per-contractor pay summary (multi-select) | Stacked in Reports `app/index.html:7790` (depth 1) | admin | OBSERVED |
| → ContractorHistory | `app/index.html:7989` | One contractor's pay history over periods | Stacked in Reports `app/index.html:7792` (depth 1) | admin | OBSERVED |
| → UtilizationReport | `app/index.html:8454` | Tracked-hours utilization (multi-select) | Stacked in Reports `app/index.html:7794` (depth 1) | admin | OBSERVED |
| Invoicing | `app/index.html:13048` (router `:13638`) | Build client invoice: per-hour + per-session lines | Sidebar "Invoicing" (depth 1); needs a single client picked (`selClient` `:13061`) | admin; client-scoped | OBSERVED |
| SessionsApproval | `app/index.html:12865` (router `:13639`) | Pick a client → approve flat-fee service sessions | Sidebar "Service Sessions" (depth 1); client picker `selClient` `:12870` | admin; client-scoped | OBSERVED |
| SessionsClientView | `app/index.html:12893` | Log/approve sessions for the picked client | Inside SessionsApproval after client picked `app/index.html:12885` (depth 2) | admin | OBSERVED |
| DeleteImports (Imports) | `app/index.html:4971` (router `:13632`) | Bulk-delete imported time + its draft batch by date range | Sidebar "Imports" (depth 1); blocked if period locked `:5042-5053` | admin | OBSERVED |
| AuditLog | `app/index.html:10735` (router `:13640`) | Browse the audit trail | Sidebar "Audit Log" (depth 1) | admin | OBSERVED |
| Configuration | `app/index.html:13327` (router `:13642`) | Hub: open 6 config modals + inline reconciliation | Sidebar "Configuration" (depth 1) | admin; owner-only controls | OBSERVED |

Auth/utility screens (pre-shell): `ConnectScreen` `app/index.html:1201`, `SignInScreen` `:1221` (Google OAuth), `NotAuthorizedScreen` `:1251`, `AccessErrorScreen` `:1268`. **OBSERVED.**

---

## Contractor portal — screens / features

| Name | file:line | User task | Entry point + click-depth | Role / state | Evidence |
|---|---|---|---|---|---|
| Login | `portal/index.html:661` | Email+password sign-in (+ Turnstile, password reset) | App gate, no session `portal/index.html:2268` (depth 0) | unauthenticated; Turnstile `:664-688` | OBSERVED |
| SetPassword | `portal/index.html:2148` | Force first-login password change | App gate `must_set_password` `portal/index.html:2271-2272` (depth 0) | authed, temp-password flag | OBSERVED |
| OnboardingFlow | `portal/index.html:1883` | Guided 3-stage onboarding wizard | App gate, onboarding enabled & not done `portal/index.html:2275` (depth 0) | authed, onboarding incomplete | OBSERVED |
| → WelcomeIntro | `portal/index.html:1644` | Intro / Start | OnboardingFlow before stage 1 `:1911` (depth 1) | onboarding | OBSERVED |
| → Stage1Agreements | `portal/index.html:1836` | Review & sign agreements | `stage==="stage1_sign"` `portal/index.html:1912-1913` (depth 1) | onboarding stage 1 | OBSERVED |
| → Stage2Profile | `portal/index.html:1944` | Fill profile (4 sections: contact/personal/payout/about) `STAGE2_SECTIONS :1922` | `stage==="stage2_profile"` `:1914` (depth 1) | onboarding stage 2 | OBSERVED |
| → Stage3Docs | `portal/index.html:2083` | Upload required documents | `stage==="stage3_docs"` `:1915` (depth 1) | onboarding stage 3 | OBSERVED |
| Home | `portal/index.html:1418` | Greeting, announcements, weather/NY panel, quick links, log session, mood check-in, doc reminder | Tab `home` (default, depth 0) `portal/index.html:1607` | authed contractor | OBSERVED |
| PaySlips | `portal/index.html:731` | View own pay statements (expandable periods) | Tab `pay` (depth 1) `portal/index.html:1608` | authed; RLS own rows | OBSERVED |
| TimeView | `portal/index.html:799` | View own tracked time by period | Tab `time` (depth 1) `portal/index.html:1609` | authed; RLS own rows | OBSERVED |
| SessionsView | `portal/index.html:864` | Log / delete own service sessions (pending until admin approves) | Tab `sessions` (depth 1) `portal/index.html:1610`; "Log a session" `:916`, insert `:889`, delete `:900` | authed | OBSERVED |
| DocsView | `portal/index.html:952` | View/upload own documents | Tab `docs` (depth 1) `portal/index.html:1611`; badge shows outstanding count `:1619` | authed | OBSERVED |
| ProfileView | `portal/index.html:1041` | View/edit own profile fields (portal-permitted) + sign out | Tab `me` (depth 1) `portal/index.html:1612` | authed; field set from portal_settings | OBSERVED |

Home sub-features (depth 1 within Home): `QuickLinks` `portal/index.html:1169`, `NyPanel` (weather) `:1307`, `ActivityChart` `:1356`, mood prompt `:1564`, `DocReminder` popup `:1232`. **OBSERVED.**

---

## Modals & drawers

### Admin app
| Name | Host screen | file:line (def) | Trigger | Purpose |
|---|---|---|---|---|
| CommandPalette | App shell (global) | `app/index.html:12501` | Cmd/Ctrl-K `:13382`; rendered `:13581` | Quick-find: jump to tab / contractor / period |
| MoreSheet | App shell (mobile) | `app/index.html:12471` | "More" bottom-nav button `:13656` | Bottom sheet of all tab groups (≤768px) |
| AdminsModal | App topbar (owner) | `app/index.html:1284` | "Admins" topbar button `:13592` | Manage admin users / roles / invites |
| EmployerSwitcher | App topbar | `app/index.html:1495` | Always shown `:13590` | Pick active employer/tenant (dropdown — INFERRED not full overlay) |
| DangerConfirm | Global (promise host) | `app/index.html:12072` | `confirmDanger({...})` callers; mounted `:13580` | Styled type-to-confirm for money/destructive actions |
| UnsavedChangesModal | Root (global) | `app/index.html:1661` | `confirmUnsaved()` on dirty nav; mounted `:13691` | "Leave and lose unsaved changes?" guard |
| ProfileModal | Contractors / OnboardingDrilldown | `app/index.html:2837` | Row/Edit `:2815`; "Edit details" `:11465` | Full contractor editor (4 sub-tabs) |
| AddContractorWizard | Contractors + OnboardingAdmin | `app/index.html:2206` | "+ Add contractor" `:2766`; "+ Hire new contractor" `:12017` | 3-step hire wizard (`step` state `:2221`) |
| HireDraftBanner | Contractors + OnboardingAdmin | `app/index.html:1595` | Always rendered `:2816,:12024` | Banner to resume an in-progress hire draft (not a modal) |
| BulkImport | Contractors | `app/index.html:1694` | "⇪ Bulk import" `:2757` | Import roster via CSV/paste |
| PullRecipients | Contractors | `app/index.html:8509` | "⤓ Pull IDs from Wise" `:2754` | Match Wise recipients to contractors, store IDs |
| AnnouncementsModal | Contractors | `app/index.html:2140` | "📣 Announcements" `:2760` | Post/delete portal announcements |
| AgreementTemplatesModal | OnboardingAdmin + Configuration | `app/index.html:11644` | "📄 Agreement templates" `:12019`; Config "Open" `:13344` | Edit agreement wording (IC/NDA/etc) |
| OnboardingConfigModal | OnboardingAdmin + Configuration | `app/index.html:11702` | "⚙ Onboarding config" `:12020`; Config "Open" `:13345` | Toggle onboarding + required docs/agreements + review-notify |
| CountersignModal | AgreementsPanel (in OnboardingDrilldown) | `app/index.html:10959` | "Countersign" `:11200` | Admin countersigns a signed agreement |
| ToolsProvisionModal | OnboardingDrilldown | `app/index.html:11228` | "🔑 Tool access" `:11455`; auto-open `:11419` | Enter tool credentials for new-hire handoff |
| ReasonPicker | OnboardingDrilldown (doc review) | `app/index.html:11608` | "Needs replacement" `:11540` | Capture reason for a rejected doc |
| DeferPicker | OnboardingDrilldown (doc review) | `app/index.html:11574` | "Defer…" `:11542,:11556` | Set collect-by date + reason to defer a doc |
| Resend-login (inline) | OnboardingDrilldown | `app/index.html:11472-11495` | "Update login & resend" | Change email + reissue temp password + resend welcome |
| MiscModal | Payroll (Calculate) | `app/index.html:7256` | "Misc" per-row `:7191` (`miscRowId` `:7234`) | Add per-contractor misc earnings/deductions |
| WiseApiDialog | ProcessPayroll | `app/index.html:10643` | "Pay via Wise API" `:10356` (`wiseDialog` `:10632`) | Step-through Wise payout review/confirm/fund (3 steps `:10645`) |
| CompaniesModal | Configuration | `app/index.html:12591` | "Employer"/"Clients" rows `:13340-13341` (`show=employer`/`clients`) | Add/edit/archive employer or client companies |
| HubstaffProjectsModal | Configuration | `app/index.html:13253` | "Hubstaff Projects → Clients" `:13342` (`show=projects`) | Map Hubstaff projects to client companies |
| PortalSettingsModal | Configuration | `app/index.html:2088` | "Portal Fields" `:13343` (`show=portal`) | Choose contractor-editable portal fields |

Native `window.confirm` / `window.prompt` dialogs (not styled modals) coexist with DangerConfirm — e.g. portal-login create/revoke/reset `app/index.html:2960,2973,2985`; period lock `:6848`; invoice void `:13161`; Wise single-payee fund `:8918`; typed-token prompts `:2685,:6606,:13423`. **OBSERVED** (flagged as UX inconsistency for downstream tracks).

### Contractor portal
| Name | Host screen | file:line (def) | Trigger | Purpose |
|---|---|---|---|---|
| UnsavedGuardModal | Root (global) | `portal/index.html:485` | `confirmUnsaved()` on dirty nav; mounted `:2280` | Save/Discard/Stay guard for in-progress edits |
| AgreementViewer | Stage1Agreements | `portal/index.html:1772` | "Review & sign" `:1868` (`openK` `:1837`) | Full-screen agreement reader + SignaturePad |
| DocReminder | Home / DocsView | `portal/index.html:1232` | Home post-mood popup `:1575`; inline in Docs `:988` | Reminds contractor of outstanding documents |
| Mood check-in | Home | `portal/index.html:1564` (`moodPrompt` `:1421`) | Auto on shift start/end window `:1479-1480` | Capture start/end-of-shift mood |
| ToolsPopup | Root (post-onboarding) | `portal/index.html:2210` | Rendered with Portal `:2277` | Surface provisioned tool credentials to the hire |

---

## Edge-function-backed features

10 edge functions total. 8 are invoked from the UI; **documents-expiry-check** and **hiring-docs-review-check** are cron-only (no in-app `invoke` — confirmed via grep; caller-auth = cron-secret OR admin JWT `supabase/functions/hiring-docs-review-check/index.ts:91-94`). **OBSERVED / ABSENT (no UI trigger).**

| UI action | file:line | Edge fn + action |
|---|---|---|
| Admin add/remove/set-role/update | `app/index.html:1339` | `admin-manage` (`add_admin`/`remove_admin`/`set_role`/`update_admin`) |
| ProfileModal: look up Wise recipient | `app/index.html:1778` | `wise-payouts` / `get_recipient` |
| AddContractorWizard: create portal login | `app/index.html:2355` | `portal-admin` / `create_login` |
| Contractors: delete contractor | `app/index.html:2689` | `portal-admin` / `delete_contractor` |
| Contractors: create portal login | `app/index.html:2963` | `portal-admin` / `create_login` |
| Contractors: revoke login | `app/index.html:2976` | `portal-admin` / `revoke_login` |
| Contractors: reset password | `app/index.html:2988` | `portal-admin` / `reset_password` |
| ExternalSourcesPanel: get recipient | `app/index.html:3740` | `wise-payouts` / `get_recipient` |
| ExternalSourcesPanel: Hubstaff user lookup | `app/index.html:3763` | `hubstaff-sync` (get_user — INFERRED from context) |
| ProfileModal: get recipient by id | `app/index.html:4039` | `wise-payouts` / `get_recipient` |
| ProfileModal: search Wise contacts | `app/index.html:4058` | `wise-payouts` / `search_contacts` |
| TimeImport: list Hubstaff orgs | `app/index.html:4610` | `hubstaff-sync` / `list_orgs` |
| TimeImport: sync ingest | `app/index.html:4634` | `hubstaff-sync` / `sync_ingest` |
| TimeImport: sync (default action) | `app/index.html:4651` | `hubstaff-sync` (no explicit action) |
| WiseReconciliation: list recipients | `app/index.html:8138` | `wise-payouts` / `recipients` |
| WiseReconciliation: get Hubstaff user | `app/index.html:8156` | `hubstaff-sync` / `get_user` |
| WiseReconciliation: recipients | `app/index.html:8209` | `wise-payouts` / `recipients` |
| WiseReconciliation: match | `app/index.html:8258` | `wise-payouts` / `match` (window_days:14) |
| PullRecipients: list recipients | `app/index.html:8518` | `wise-payouts` / `recipients` |
| WisePayouts: fund transfer | `app/index.html:8720` | `wise-payouts` / `fund` |
| WisePayouts: create batch | `app/index.html:8794` | `wise-payouts` / `batch` |
| ProcessPayroll: transfer status | `app/index.html:9379` | `wise-payouts` / `status` |
| ProcessPayroll: poll drafts | `app/index.html:9551` | `wise-payouts` / `poll` |
| ProcessPayroll: probe recipient | `app/index.html:9636` | `wise-payouts` / `get_recipient` |
| ProcessPayroll: match (no refresh) | `app/index.html:9713` | `wise-payouts` / `match` |
| ProcessPayroll: match (refresh) | `app/index.html:9729` | `wise-payouts` / `match` |
| ProcessPayroll: poll | `app/index.html:9774` | `wise-payouts` / `poll` |
| ProcessPayroll: match (window 14) | `app/index.html:9794` | `wise-payouts` / `match` |
| AgreementsPanel: countersign | `app/index.html:11080` | `portal-countersign` / `countersign` |
| AgreementsPanel: set signed date | `app/index.html:11094` | `portal-review` / `set_signed_date` |
| ToolsProvisionModal: send tools email | `app/index.html:11246` | `portal-admin` / `send_tools_email` |
| OnboardingDrilldown: withdraw offer | `app/index.html:11325` | `portal-admin` / `withdraw_offer` |
| OnboardingDrilldown: delete contractor | `app/index.html:11347` | `portal-admin` / `delete_contractor` |
| OnboardingDrilldown: update login & resend | `app/index.html:11357` | `portal-admin` / `update_login_and_resend` |
| OnboardingDrilldown: doc review | `app/index.html:11386` | `portal-review` (`approve`/`needs_replacement`/`waive`/`defer`) |
| HubstaffProjectsModal: list projects | `app/index.html:13273` | `hubstaff-sync` / `list_projects` |
| ProfileView: update profile | `portal/index.html:1066` | `portal-self` / `update_profile` |
| SignaturePad: sign agreement | `portal/index.html:1696` | `portal-sign` / `sign` |
| Stage1Agreements: advance from stage 1 | `portal/index.html:1847` | `portal-self` / `advance_from_stage1` |
| Stage2Profile: complete tab | `portal/index.html:1972` | `portal-self` / `complete_tab` |
| Stage3Docs: finish onboarding | `portal/index.html:2113` | `portal-self` / `finish_onboarding` |
| SetPassword: set password | `portal/index.html:2161` | `portal-self` / `set_password` |

**Full action sets per function (OBSERVED via grep of `supabase/functions/*`):** `wise-payouts` = batch, draft, fund, poll, status, match, rates, recipients, get_recipient, search_contacts, find_transfers_by_recipient, profile. `hubstaff-sync` = cron_ingest, sync_ingest, activity_backfill, get_user, list_orgs, list_projects. `portal-admin` = create_login, reset_password, revoke_login, resend_hire_emails, send_tools_email, update_login_and_resend, withdraw_offer, delete_contractor. `portal-self` = update_profile, complete_tab, advance_from_stage1, finish_onboarding, set_password. `portal-review` = defer, needs_replacement, waive, set_signed_date (+ approve — INFERRED, called via `reqBody` `app/index.html:11386` but not surfaced by the case grep). `portal-sign` = sign. `portal-countersign` = countersign. `admin-manage` = add_admin, remove_admin, set_role, update_admin.

**Note on `wise-payouts` actions ABSENT from the UI**: `draft`, `rates`, `profile`, `find_transfers_by_recipient` are implemented but not invoked from either app's render tree (no matching call-site found). `hubstaff-sync` `cron_ingest`/`activity_backfill` are likewise cron/secret-gated, not UI-triggered. **OBSERVED (no call-site) / for downstream confirmation.**

---

## Navigation map

### Admin app (`app/index.html`)
```
[Connect/SignIn (Google)] → role check (admin_users.role)
   ├─ null → NotAuthorized
   ├─ error → AccessError (retry)
   └─ owner|admin → App shell
        topbar: EmployerSwitcher · Find(⌘K→CommandPalette) · [owner: Admins→AdminsModal] · Sign out
        sidebar (groups) / mobile bottom-nav(4)+More→MoreSheet:
        ├─ Home ▸ Overview ──(goTab)──▶ any tab
        ├─ Manage Team
        │   ├─ Contractors ─▶ ProfileModal {Profile|Pay|Personal|Portal} ─▶ ShiftEditor / ExternalSourcesPanel
        │   │                 ├▶ AddContractorWizard  ├▶ BulkImport  ├▶ PullRecipients  ├▶ AnnouncementsModal  └▶ HireDraftBanner
        │   ├─ Hiring & Onboarding (OnboardingAdmin)
        │   │     ├▶ AddContractorWizard  ├▶ AgreementTemplatesModal  ├▶ OnboardingConfigModal
        │   │     └▶ OnboardingDrilldown ─▶ AgreementsPanel▶CountersignModal · ToolsProvisionModal · ReasonPicker · DeferPicker · ProfileModal(reuse)
        │   └─ Documents
        ├─ Run payroll
        │   ├─ Time & Approval (TimeImport ⊃ TimeApproval) ──(approve→openPeriodForEdit)──▶ Calculate
        │   ├─ Calculate (Payroll) ─▶ HolidayEditor · MiscModal ──(unlock→openPeriodForEdit)──▶ self
        │   └─ Process and Pay (ProcessPayroll) ─ payTab[wise|bpi|other|all] ─▶ WisePayouts ▶ WiseApiDialog
        ├─ Review
        │   ├─ Review & Recon Batches (ProcessPayroll reconcileOnly) ─▶ ReconcileOverview
        │   ├─ Reports ─ stacked: PerContractorSummary · ContractorHistory · UtilizationReport
        │   ├─ Invoicing (pick client) ─ per-hour + per-session lines
        │   ├─ Service Sessions (pick client) ─▶ SessionsClientView
        │   ├─ Imports (DeleteImports)
        │   └─ Audit Log
        └─ Configuration (show=employer|clients|projects|portal|tpl|cfg)
              ├▶ CompaniesModal(employer/client)  ├▶ HubstaffProjectsModal  ├▶ PortalSettingsModal
              ├▶ AgreementTemplatesModal  ├▶ OnboardingConfigModal  └ inline WiseReconciliation
        global: DangerConfirm · UnsavedChangesModal · ErrorBoundary(→/?ui=classic)
```

### Contractor portal (`portal/index.html`)
```
[App gate]
  no session ─▶ Login (email+pw + Turnstile + reset)
  must_set_password ─▶ SetPassword
  onboarding enabled & !done ─▶ OnboardingFlow
        WelcomeIntro ─▶ Stage1Agreements ─▶ AgreementViewer ▶ SignaturePad
                     ─▶ Stage2Profile {contact|personal|payout|about}
                     ─▶ Stage3Docs ▶ UploadSlot ─▶ complete
  else ─▶ Portal shell (bottom tab bar) + ToolsPopup
        ├─ Home ─ QuickLinks · NyPanel(weather) · ActivityChart · MoodCheck · DocReminder · Log a session
        ├─ Pay slips (PaySlips)
        ├─ Time (TimeView)
        ├─ Sessions (SessionsView) ─ log/delete own sessions (pending)
        ├─ Docs (DocsView ⊃ DocReminder/UploadSlot) [badge: outstanding count]
        └─ Profile (ProfileView) ─ edit allowed fields · Sign out
        global: UnsavedGuardModal
```

---

## Assumptions & absences

- **ASSUMPTION**: `EmployerSwitcher` `app/index.html:1495` is a dropdown, not a full-screen modal — rendered inline in the topbar with no `role="dialog"`. Classified as a control, not a modal.
- **ASSUMPTION**: `hubstaff-sync` invoke at `app/index.html:3763` resolves to a Hubstaff user lookup (`get_user`) — inferred from the surrounding ExternalSourcesPanel drift-reconciliation context; the body string wasn't captured in the 3-line window.
- **OBSERVED inconsistency** (for downstream tracks): two confirm systems coexist — the styled `DangerConfirm`/`confirmDanger` `app/index.html:12072` and many native `window.confirm`/`window.prompt` calls on money/destructive paths (period lock `:6848`, invoice void `:13161`, portal-login mutations `:2960-2985`, Wise single-payee fund `:8918`).
- **OBSERVED stale comment**: Configuration's `show` state comment lists `"companies"` `app/index.html:13328`, but the real values are `employer`/`clients`/`projects`/`portal`/`tpl`/`cfg` `:13340-13354`.
- **OBSERVED dual-purpose component**: `ProcessPayroll` `app/index.html:9098` backs BOTH the `process` and `batches` tabs (`reconcileOnly` prop `:13636`); `ProfileModal` is reused in two contexts (Contractors + OnboardingDrilldown). These are screens with two entry points, not duplicates.
- **OBSERVED reuse-vs-confusion**: the `time` tab (TimeImport — *import* time) and the `imports` tab (DeleteImports — *delete* imported time) are different screens with similar names; TimeApproval is embedded inside TimeImport, not its own tab.
- **OBSERVED — edge actions with no UI call-site (ABSENT from UI)**: `wise-payouts` `draft`/`rates`/`profile`/`find_transfers_by_recipient`; `hubstaff-sync` `cron_ingest`/`activity_backfill`; entire `documents-expiry-check` and `hiring-docs-review-check` functions (cron-only). Implemented server-side but not reachable from either app's render tree.
- **ABSENT**: no URL/hash routing, no browser-history integration, and no shareable deep-link URLs in either app — all navigation is in-memory `tab` state (last admin tab persisted to `localStorage` `app/index.html:13364`; portal nav state is not persisted).
- **NOTE (not audited)**: `app/legacy.html` is the frozen `?ui=classic` rollback copy `app/index.html:13682`; existence noted only, per scope.
