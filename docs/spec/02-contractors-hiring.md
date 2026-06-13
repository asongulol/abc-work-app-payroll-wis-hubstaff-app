# Appendix 02 — Contractors, Profile editor, Hire wizard & Bulk import

> Granular build spec with `app/index.html` line anchors. Master overview: [../FEATURES.md](../FEATURES.md). Server handlers in `supabase/functions/portal-admin/index.ts`.

All four UIs use the **employer/client model** (`index.html:2571-2587`): roster rows are the **employer** link (Aaron Anderson EHS LLC == company `11111111`); the **Client column** shows separate `worker_companies` links where `companies.kind==="client"`. Pay is employer-level; client is a billing tag.

---

## Shared helpers
- **`fullName(w)`** `843` — joins `first middle last`, filtering blanks.
- **`methodLabel(m)`** `717` — `"bpi"→"BPI"`, else Capitalized.
- **`codeHint(kind,val)`** `725-736` — plain-language `title=` tooltips for contract/status/method/pay.
- **`PAYOUT_CHANNELS`** `5804` = `["wise","bpi","gcash","paymaya","paypal"]` (canonical dropdown order).
- **`PhoneInput`** `969`, **`EmailInput`** `1019`, **`Avatar`** `1034` + **`fileToAvatarDataUri`** `1044` (256px JPEG data-URI in a text column; no bucket).
- **`useSortFilter`** `1098`, **`FilterBox`** `1127`, **`logEvent`** `1064`.
- Name normalization `nameKey`/`looseKey`/`nameTokens` `4313-4334` (strip accents, `Ma`→`Maria`, drop suffixes, sort tokens).

---

## 1. Contractors tab — `Contractors` (`2559-2820`)

### Data (2560-2587)
Primary `useQuery` (2560): `worker_companies` ⨝ `companies(name)` ⨝ `workers(…)`; when not consolidated + companyId → `.eq("company_id",companyId)` (employer links). Client-engagement query (2576): active links ⨝ `companies(name,kind)`; `clientsByWorker` keeps only `kind==="client"`.

### Toolbar (2737-2764)
Title "Contractors" + sub. **Show inactive** (2744); **⤓ Pull IDs from Wise** (2748, `PullRecipients` 8385); **⇪ Bulk import** (2751); **📣 Announcements** (2754); **Quick add** (2757, `addContractor` 2698 — inserts blank worker + link, opens ProfileModal); **+ Add contractor** (2760, wizard). `FilterBox` placeholder "Filter by name, client, role…".

### Columns (2768-2808) — sort keys at 2628-2631
| Column | `<Th k>` | Cell |
|---|---|---|
| Name | name (`_name`) | Avatar 28 + bold name, clickable → ProfileModal |
| Client | company (`_company`) | joined client names or "—" |
| Role | role | `r.role` or "—" |
| Contract | contract | pill `ft`/`pt` (FT navy / PT pink), `title=codeHint` |
| Payout | method (`_method`) | `methodLabel` or amber `pill warn` **"not set"** |
| Status | status | pill active/inactive |
| (actions) | — | Edit / Deactivate-Reactivate / Delete |

Search `["_name","_company","_role"]`. Inactive rows `opacity:.6`; key `worker.id|company_id`. `isActive(r)` (2615) = worker active AND link active.

### Row actions
- **Edit** (2793) → `setSelected({...r,w})`.
- **Deactivate/Reactivate** (2794) → `setActive(r,makeActive)` (2634): `workers.status` → `active`/`ended`; link `{status, ended_on}`; `onBillingChange(...)` (next Calculate/Lock/pay re-prompts).
- **Delete** (2799) → `deleteContractor(r)` (2658): (1) count payments+time → if any, alert "deactivate instead", abort. (2) count signatures+documents to size prompt + set `force`. (3) `window.prompt` typed-confirm "Type '{name|email|worker_id}' to confirm". (4) `portal-admin {action:"delete_contractor", worker_id, force:records>0}`. **Server** (`portal-admin/index.ts:518-563`): re-validates UUID; re-probes payments/time (fail-closed 502/409 `has_history`); without force, 409 `has_records`; deletes worker (FK cascade → links/rates/logins/onboarding), Storage files (`contractor-docs`), auth user; own audit row.

### Footer (2809-2816)
ProfileModal; `HireDraftBanner` (2810, def 1595); conditional AddContractorWizard/BulkImport/PullRecipients/AnnouncementsModal. Cross-tab open via `pendingWorkerId` (2596). First-load skeleton only when `loading && !data` (2733).

---

## 2. ProfileModal (`2831-3673`)

Header (3352): close × + fullName + sub `{company} · {status}`. Avatar 64 + Upload/Change/Remove photo (`onPickPhoto` 2912, `removePhoto` 2927). **Four tabs** (3370): profile / pay / personal / portal.

### TAB "Profile" (3375-3456)
First/Middle*(opt)/Last; **Contract** `<select>` FT/PT (3384); **Role** text; **Expected hours/week** `number 1-60 step .5` placeholder 20(PT)/40(FT); **Payout method** `<select>` (— not set —, then PAYOUT_CHANNELS via methodLabel) — **instant-save** `savePayMethod` (3125), amber when unset; Personal email (EmailInput); Work email (EmailInput work); Mobile / Work number (PhoneInput PH) + Ext; Hire date / DOB; **ShiftEditor** (3409) two PHT time inputs + Save shift + Reset to 8–5 ET; PH address; Hubstaff name; Health allowance + 13th checkboxes; **Save details**.

**Client engagements** (3418-3454): per-membership card — name + pill active/ended + Deactivate/Reactivate (`toggleMembership` 3336) + **Position** + **Bill rate (USD/hr)** `number min0 step.01` + Save (`saveEngagement` 3297). **Add company** `<select>` (assignable = all minus linked) + Add (`addCompany` 3314, multi-client confirm guardrail).

### TAB "Pay & payout" (3535-3664)
**Rate (PHP per period)** `number step.01` + "Effective from" date + Save (`saveRate` 3189: same-day UPDATE, else close prior open rate `effective_end` then INSERT `period_basis:"semi_monthly"`). **Rate history** table (3546): Effective from/to/Amount/(Edit date `saveRateEffectiveEdit` 3068 / Delete `deleteRateRow` 3101). **Wise recipients** (3612): `{id,label}` list, Make default / Remove / Add (`addRecip` 3251); separate **Wise recipient UUID** (for manual Batch CSV) + Save (`persistUuid` 3265). `ExternalSourcesPanel` (3663, def 3679).

### TAB "Personal / HR" (3500-3534)
`<details>` collapsible. Emergency contact + **Relationship** `<select>` `REL_OPTS` (2828: Parent/Spouse/Sibling/Child/Grandparent/Relative/Friend/Partner/Guardian/Other) + Emergency mobile (PhoneInput); Permanent address (+ "Same as current" `sameAddr`); Landmark; Postal; **Marital** `<select>` `MARITAL_OPTS` (2829: Single/Married/Widowed/Separated/Annulled/Divorced); Education level; Course; **Year graduated** `<select>` `GRAD_YEARS` (2830: current → −60); School; About/culture (favorite_color/food/motto → `profile_extras` jsonb merge); **Save details**.

### TAB "Portal & login" (3457-3499)
No login → **Create portal login** (`createPortalLogin` 2951, confirm → `portal-admin create_login`, temp-pw banner). Login exists → pill + email + **Reset password** (`resetPortalPassword` 2978) + **Revoke** (`revokePortalLogin` 2966). Onboarding row → pill + **Require onboarding/again** (`requireOnboarding` 2994). Temp-password green banner (3490); Wise Tag blue banner (3494).

### Saving (`saveDetails` 3138)
`auditDiff` (2894) for worker fields + link (`contract/role/hubstaff_name/weekly_hours`) + culture; updates `workers` + `worker_companies`; logs `edit_contractor`; resets guard baseline; returns false on error. `onBillingChange`/`reportBilling` (2835) on payout-affecting saves. Unsaved guard (3033): dirty when `{f,contract,role,hubName}` ≠ baseline, `save:()=>saveDetails()`; `escClose:false`; `refreshLocal` (2844) repaints only when clean.

---

## 3. AddContractorWizard (`2206-2557`)

Creates nothing until "Create contractor". Header + 3-segment bar + "Step N of 3 · {Identity | Engagement (IC terms) | Portal & onboarding}". `DEFAULTS` 2208. Draft autosave (2216-2267) key `eis_hire_draft_<companyId>`, debounced, resumes to saved step ("↩ Resumed your saved draft." + Start fresh).

### Step 1 — Identity (2442)
First *, Middle, Last *; **Personal email *** (EmailInput); Current address; Permanent address + "Same as current address"; DOB.

### Step 2 — Engagement (IC terms) (2455)
**Company *** `<select>` (— select company — + active companies). **Contract *** `<select>` FT/PT — change auto-sets hours 40/20 (2466). **Expected hours/week *** `number 1-60 step.5`. **Role/position *** text. **Rate (PHP/period)** `number` + **Contract date** `date`. **Hire date (start) *** `date`. Health + 13th checkboxes. **Daily shift *** (2479) two PHT `type=time` + "Reset to 8–5 ET". **Company countersigner *** `<select>` (— select admin — + admins filtered `can_countersign!==false`, label `{name} ({email})`) + free-text "Name shown on the agreement". **IC Agreement addendum** `<select>` (No addendum / Scope of Work `scope_of_work` / Other `other`) + textarea. **Additional documents to request** (dynamic list + "+ Add document").

### Step 3 — Portal & onboarding (2520)
**Invite to the contractor portal** checkbox (default true). **Tools to provision** card: Gmail / Providersoft / Hubstaff / Zoom checkboxes + "Other tools" text. **Summary** card.

### Validation `validateStep(s)` (2269)
Step1: first/last Required; email Required+valid when inviting/present. Step2: company "Select a company"; role Required; rate Required & >0; hours Required & >0; hire_date Required; countersigner "Assign a countersigner"; shift "Set a shift start and end". `next()` validates current; `create()` validates 1+2 and jumps to the offending step.

### Duplicate prevention (`create()` 2289)
1. Email hard-block (existing worker) `workers.ilike(email)` → "{name} already uses {email}…", abort. 2. Email hard-block (existing login) `contractor_logins.ilike(email)` → abort. 3. Name soft-warn `workers.ilike(first).ilike(last)` → `confirmDanger` typed `DUPLICATE` → "Create anyway".

### Writes (2337-2396)
`workers` (payout_method fallback "wise") → `worker_companies` `{contract,role,weekly_hours,status,started_on}` → `rates` (if rate>0) → `portal-admin create_login` (if invite) → IC prefill `onboarding_agreements` (`f_rate/f_position/f_start_date/f_company_name/f_employment_type/f_hours_per_week/f_schedule (ET via phtShiftToEtLabel)/addendum/countersigner/prepared_*`) → other agreements (`ONB_AGR_KINDS` 10600) → `onboarding_progress.extra_documents` → `set_tools_requested` RPC → log `add_contractor`. **Rollback** (2397): delete the just-created worker on any later failure.

### Success (2417)
"✓ Contractor added" + (if invited) Email + Temp password card + **Copy**.

---

## 4. BulkImport (`1694-2083`)

Modal; matches **Wise id → Wise UUID → Hubstaff id → strict name → loose name**; single company only. Stages input/preview/done; draft key `eis_import_draft_<companyId>`.

- **Input** (2005): `<textarea>` + "…or upload CSV" + "⬇ Download CSV template" + Preview. "Prefer the Wise account name" checkbox (default true). Collapsible "Accepted columns".
- **Parse** (1714): delimiter auto (tab/comma); `parseDelimited` quote-aware; header via `BULK_COLMAP` (1524) after `normHdr`.
- **`buildRow`** (1815): names; type coercion (Wise id digits, UUID, Hubstaff id, payout via `BULK_PAYOUT` 1563, contract pt/ft, `parseBool` 1565, rate>0, status active/ended, dates `YYYY-MM-DD`). Match order ID-first; blanks never overwrite; action update/create/error.
- **Preview** (2036): count pills "N new / N update / N skipped"; table # / Name (+Wise badge) / Action / Matched via / Wise id / UUID / Rate / Changes-notes.
- **`commit`** (1935): update (merge recipients, link if missing, `upsertRate`) / create (full worker, link, 23505 race-recover); per-row errors → result.
- **Done** (2069): "Import complete — N created, M updated, K skipped, J failed" + errors table + Import more / Done.

---

### Key anchors
Contractors `2559-2820` (`setActive` 2634, `deleteContractor` 2658, Quick add 2698). ProfileModal `2831-3673` (`saveDetails` 3138, `saveRate` 3189, logins 2951-3010, engagements 3291-3346). AddContractorWizard `2206-2557` (`validateStep` 2269, `create` 2289). BulkImport `1694-2083` (`buildRow` 1815, `commit` 1935, `BULK_COLMAP` 1524). HireDraftBanner 1595. Server delete/create-login `portal-admin/index.ts:518-563` / `250-319`.
