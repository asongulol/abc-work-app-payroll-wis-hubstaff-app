# Add-Contractor Process — Implementation Plan

## 1. Goal & current state

**Today:** clicking **+ Add contractor** (Contractors tab) runs `addContractor()`,
which *immediately* inserts a `workers` row literally named "New Contractor" +
a `worker_companies` link, then opens `ProfileModal` to fill the rest. Problems:
- Creates a junk row on click; abandoning the modal leaves a "New Contractor"
  ghost (the reason a delete button was just needed).
- No validation up front; no payout/rate captured in the flow.
- Disconnected from onboarding — the admin hand-enters everything instead of
  letting the contractor self-complete via the portal.

**Goal:** replace the instant-blank-row behavior with a short guided
**Add Contractor wizard** that (a) collects the essentials, (b) **creates nothing
until you confirm**, and (c) optionally provisions a portal login so the
contractor finishes the rest through onboarding (sign → profile → documents).

## 2. Proposed flow (`<AddContractorWizard/>` modal)

A 3-step modal opened by the button (replaces the immediate insert). Single
modal, stepper header ("Step 2 of 3"), Back/Next, no DB writes until **Create**.

| Step | Collects | Notes |
|------|----------|-------|
| **1 · Identity** | first / middle / last name, **personal email**, work email + work number (optional) | name + a valid email required. Email is the portal-login key. |
| **2 · Engagement** | company (default = current), contract FT/PT, role, **rate (PHP/period)** + effective date, Hubstaff name, HA / 13th-month eligibility | company + contract required; rate optional but recommended. Mirrors `ProfileModal` rate logic. |
| **3 · Portal & onboarding** | "Invite this contractor to the portal?" toggle → if on, shows the generated temp password on create; "Require onboarding" (sign + profile + docs) checkbox | If invited, the contractor is **not** grandfathered → sees onboarding on first login (when the flag is on). If not invited, admin fills the profile manually as today. |
| **Review** | summary of all of the above | **Create** commits everything in order; shows temp password + a "copy" button if a login was made. |

### What "Create" does (in order; stop + surface on first error)
1. `insert workers` (real name + emails + eligibility + DOB if given).
2. `insert worker_companies` (company, contract, role, hubstaff_name).
3. If rate given → `insert rates` (worker, company, amount, effective_start) —
   reuse the effective-dated logic from `ProfileModal.saveRate`.
4. If "invite" → `invoke('portal-admin', {action:'create_login', worker_id, email})`
   → capture temp password for display. (Onboarding triggers automatically on
   first login because there's no completed `onboarding_progress` row.)
5. `logEvent add_contractor` with a richer detail payload (company, contract,
   invited?, rate?).
6. Close → `reload()` → optionally open `ProfileModal` on the new worker.

## 3. Data model touched (all existing tables)

- `workers` — first/middle/last_name, email, work_email, work_number,
  date_of_birth, health_allowance_eligible, thirteenth_month_eligible, status.
- `worker_companies` — worker_id, company_id, contract, role, hubstaff_name, status.
- `rates` — worker_id, company_id, amount_php, effective_start.
- `contractor_logins` (via `portal-admin create_login`, service role) — only if invited.
- No schema change required. No new migration.

## 4. Validation (client; server already enforces auth/RLS)
- Name: first + last required.
- Email: required if "invite" is on; format-checked; **uniqueness** — pre-check
  `contractor_logins`/`workers` for the email so create doesn't fail late.
- Company: required (block in consolidated view, like today).
- Rate: optional; if present, must be a positive number; effective date defaults today.
- Reuse `validateTabClient`-style inline errors.

## 5. Onboarding tie-in (the point of this)
- An invited contractor has no `onboarding_progress` row → the portal boot gate
  shows onboarding on first login **once `onboarding_enabled` is true**.
- A non-invited contractor is just a payroll record the admin maintains.
- Optionally (decision below): when inviting, also `insert onboarding_progress
  (worker_id, current_stage:'stage1_sign')` so they appear in the admin
  Onboarding queue as "In progress" immediately (mirrors the planned
  `portal-admin` provisioning hook from the onboarding M1 follow-ups).

## 6. Edge cases
- **Abandon mid-wizard** → nothing created (the core fix).
- **Duplicate email** → caught by the pre-check with a clear message; if the
  race slips through, `create_login` returns a 409 surfaced via `fnErrorMessage`.
- **Consolidated view** → require picking a company first (as today).
- **Login created but a later step fails** → create the worker rows *before*
  the login (login last), so a login failure doesn't orphan; surface the temp
  password only on full success.
- **No rate at create** → allowed; flagged "rate not set" in the contractor list
  (existing "not set" pill pattern).

## 7. Implementation steps (each ≈ one commit)
1. **[code]** `<AddContractorWizard/>` shell + stepper + state + open/close wiring;
   repoint the **+ Add contractor** button to open it instead of `addContractor()`.
2. **[code]** Step 1 (Identity) + validation.
3. **[code]** Step 2 (Engagement) — company/contract/role/rate, reuse rate save logic.
4. **[code]** Step 3 (Portal & onboarding) toggle + temp-password display.
5. **[code]** Review step + the ordered `createContractor()` transaction + audit.
6. **[code]** Optional `onboarding_progress` seed on invite (decision #3).
7. **[code]** Remove/retire the old instant-insert `addContractor()` (keep a
   minimal fallback or delete). esbuild check each commit.

## 8. Open decisions for owner review
1. **Replace vs. add:** fully replace the instant-create with the wizard
   (recommended), or keep the old quick-add too?
2. **Invite by default?** Should "Invite to portal" default ON (push data entry
   to the contractor) or OFF (admin fills everything)?
3. **Seed `onboarding_progress` on invite** so they show in the Onboarding queue
   immediately (recommended), or let it appear only after their first sign-in?
4. **Open ProfileModal after create?** (handy for adding a photo / Wise recipient)
   or just return to the list.
5. **Scope of step 2:** include rate now, or keep rate/payout in the profile only?
