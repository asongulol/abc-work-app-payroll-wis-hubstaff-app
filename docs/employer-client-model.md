<!-- Multi-agent design analysis (read-only). Owner decisions pending — see §5. -->

# DESIGN (FINAL): Separating EMPLOYER (Aaron Anderson E.H.S. LLC) from CLIENT companies

## 0. The one-sentence model

`company_id` everywhere in this app means **CLIENT/tenant** — the work-assignment, payroll, and scoping axis — and is correct to keep. The **employer (Aaron Anderson E.H.S. LLC) is a different, constant axis** with no data home today, currently collapsed onto a client row via the Hubstaff org name and mis-named in one agreement. The fix is small: **add an employer constant, relabel "Company"→"Client" in the UI, and — the only real legal correctness item — re-author the one broken agreement (`non_compete`).** Nothing in the money/time/RLS layer moves.

---

## 1. Recommended data model

**Decision: Option (a) — a single configured employer stored in `portal_settings`, NOT a row in `companies`.** Reject (b) `companies.kind` and (c) a separate `employers` + `workers.employer_id` table.

### Why (a) wins — the durable reason first

The employer is **categorically not a payroll-scoping axis.** `payments`, `pay_periods`, `time_entries`, `rates`, `audit_log`, and `admin_companies` all FK to `companies(id)`, and RLS scopes on it. Putting the employer in `companies` (option b) makes it FK-eligible as a payroll tenant — the switcher-leak is the least of it; the deeper error is that a constant identity would become a candidate scoping/disbursement key. A constant belongs in config.

| Option | Verdict | Reason |
|---|---|---|
| **(a) employer constant in `portal_settings`** (singleton row `id=1`, exists from `2026-05-31_onboarding_config.sql`) | **CHOSEN** | The employer is a true constant ("every contractor is an Aaron Anderson contractor — never changes"), referenced by agreement text and branding only — never joined, filtered, or scoped. It must never touch RLS. Zero migration risk: no new FK, no enum, no trigger interaction, no RLS predicate change. |
| **(b) `companies.kind='employer'\|'client'`** | Rejected | Categorically wrong: the employer is not a tenant, so it must not be a `companies` row at all (see above). Secondarily, every RLS predicate, the `CompanySwitcher` (`app/index.html:1267`, `status='active'` with no kind filter), pickers, `v_payouts_by_period`, and `CompaniesModal` would each need a defensive `kind!='employer'` exclusion — one miss = cross-client leak or a bogus employer payroll tenant. |
| **(c) `employers` table + `workers.employer_id`** | Rejected (for now) | Over-models a one-row reality. `workers.employer_id` implies the employer varies per worker — it does not; it is identical for all **50** workers. Only revisit if the owner says >1 employer entity will ever exist (Q5), and even then the shape is `employers` joined from `portal_settings`/agreements, never from `workers`. |

**Config shape note:** `portal_settings` currently stores config as jsonb blobs (`editable_fields`, `onboarding_config`). A scalar `employer text` column is slightly inconsistent with that pattern but is marginally safer (typed, not buried). Either works; the design keeps the typed column.

**Canonical string fix (free, do it):** three spellings exist — `Aaron Anderson EHS LLC` (Hubstaff org + login logo alt `app/index.html:1015`, portal logo alt `portal/index.html:509`), `ABC Kids NY` (agreement chrome + the broken `non_compete` body), and `Aaron Anderson E.H.S. LLC`. **Pick `Aaron Anderson E.H.S. LLC` as the single canonical value, stored once in `portal_settings.employer`.**

### What stays CLIENT-keyed vs becomes EMPLOYER-level

| Concern | Axis | Where |
|---|---|---|
| Payments, pay runs | **CLIENT** `company_id` — STAYS | `payments.company_id`, `pay_periods.company_id` (`schema.sql:179, 131`) |
| Time entries | **CLIENT** `company_id` — STAYS | `time_entries.company_id` (`schema.sql:149`) |
| Rates | **CLIENT** `company_id` — STAYS | `rates.company_id` (`schema.sql:117`) |
| RLS / admin scoping | **CLIENT** `company_id` — STAYS | `is_company_admin`, `my_admin_company_ids`, `admin_can_see_worker`, `admin_companies` |
| Work assignment (M:N) | **CLIENT** `worker_companies` — STAYS | `schema.sql:90-109` |
| Per-client reports | **CLIENT** — STAYS | `v_payouts_by_period`, Reports `app/index.html:7062` |
| **Agreement party (IC/NDA/non-compete/BAA)** | **EMPLOYER** — NEW | `portal_settings.employer` → `{{employer_name}}` |
| **Payer identity (Wise)** | **EMPLOYER** — already singular | `wise-payouts` one business profile (`index.ts:87`) — no change |
| **Employment identity / branding** | **EMPLOYER** — config + chrome | login/portal logos, topbar |
| **Hubstaff org** | **EMPLOYER** — should become enforced 1-org-per-client | `companies.hubstaff_org_id` = **`258598`** on Ability Builders (NOT null — see §4) |

---

## 2. Agreement fix — re-prioritized: the legal fix is `non_compete`, the rest is cosmetic DRY

**Critical re-prioritization (correcting the draft):** the draft called the whole agreement fix "the most urgent correctness item." That is a **priority inversion.** Verified against prod:

- `ic_agreement`, `confidentiality_nda`, `baa` **already hard-code "Aaron Anderson E.H.S. LLC"** as the by-and-between party and use `{{company_name}}` only as the "Assigned Company:" client field. They are **already legally correct.** Tokenizing them changes nothing a contractor sees or signs.
- **`non_compete` is the ONLY legally broken artifact:** it names "ABC Kids NY" as the counterparty, has no `{{company_name}}` token, and no Assigned-Company field. As written it names the wrong legal entity and is arguably voidable. **This is the real fix and it stands alone.**

### Tokenization is a DRY refactor with a legal-regression risk — guard it or skip it

Replacing the hard-coded literal in the three good templates with `{{employer_name}}` from config is **not a safe free win.** `mergeAgreement` leaves unknown tokens verbatim but renders a **present-key-with-empty-value as `"________"`** (`app/index.html:10085/10090`). So a NULL/blank/typo'd `portal_settings.employer` would render `"________"` as the contracting party on a signed legal instrument. A literal cannot misfire; a token can.

**If you tokenize the three good templates, you MUST:** (1) make `portal_settings.employer` `NOT NULL` with a default of the literal string; (2) add a hard fallback to the literal `"Aaron Anderson E.H.S. LLC"` (not `"________"`) in all three `mergeAgreement` copies; (3) add a render-time guard that blocks signing/printing if `{{employer_name}}` resolves empty. Given the near-zero legal value and the regression risk, **tokenizing the three good templates is optional and lower-priority than the `non_compete` rewrite.**

### Token semantics (target)

- **`{{company_name}}` = the CLIENT (assigned company)** — matches the live `ic_agreement`/`confidentiality_nda`/`baa` bodies. **Do not re-point it to the employer.** Source stays `f_company_name` snapshot → `coName` client fallback. Optionally add `{{client_name}}` as a forward-clarity alias; `{{company_name}}` must keep working.
- **`{{employer_name}}` = the EMPLOYER constant**, sourced from `portal_settings.employer` (default `"Aaron Anderson E.H.S. LLC"`). Required for `non_compete`; optional for the other three.

### Concrete changes

1. **Re-author `non_compete` (the actual fix):** replace `"between ABC Kids NY (\"Company\") and {{contractor_name}}"` with the employer party `{{employer_name}}` (or, to avoid the empty-value risk above, the literal employer string), and add `"Assigned Company: {{company_name}}"` if the client is relevant. Live project `cgsidolrauzsowqlllsz`.
2. **`mergeAgreement` (×3):** add `employer_name` (with literal fallback) and optional `client_name` to the substitution object in `app/index.html:10083`, `portal/index.html:1449`, `app/legacy.html:8850`. **These three already diverge** (app/legacy carry `monthly_rate/contractor_address/addendum/today`; the portal copy is a different, shorter object) — so "keep them byte-identical" is already violated. The real requirement is an **explicit cross-file equivalence test** that the same token set resolves consistently, because the contractor signs in the **portal** while the admin prints in **app/index.html** — a missed portal edit means *the signed doc ≠ the filed doc*.
3. **`f_company_name` snapshot STAYS as the CLIENT snapshot** (immutable record of which client the doc named at signing). Do not repurpose it for the employer. Rename conceptually to `f_client_name` only in comments/new code; column name stays for back-compat. Source: `companies.name` of the active `worker_companies` link (`app/index.html:2062, 10171`).
   - **Drift note:** snapshots store short `"Ability Builders"` but live `companies.name` is `"Ability Builders for Children, LLC"`. Confirm canonical client name going forward (Q6).
4. **Multi-client ambiguity (latent):** `onboarding_agreements` PK is `(worker_id, agreement_kind)` — one IC agreement per contractor regardless of client count. `coName` picks `rows.find(active)||rows[0]`, silently naming one client when a worker serves several. Fine today (0 multi-client workers); if per-client agreements are needed, the PK must gain `company_id` (Q4).

---

## 3. Migration path

### Is "Ability Builders for Children, LLC" the employer mis-named, or a client holding everyone?

**Decision: it is a CLIENT that currently holds everyone.** The owner lists "Ability Builders" as a client; the row name is a client name (not "Aaron Anderson"); and `company_id` on this row acts as client/tenant. The employer was never a row — only the *Hubstaff org name* (`Aaron Anderson EHS LLC`, org id **258598**) collapsed onto this client row. **No payroll/time/payment data moves.** Ability Builders stays a client; all **50** workers, 1067 payments, 10514 time_entries, 52 pay_periods, 72 rates stay put.

**Why this is the low-risk outcome:** the `payments` lock trigger never fires because no `company_id` changes. **Correction to the draft's mental model:** the trigger guard is `if old.wise_locked_at is null then return new;` (`schema.sql:363`) — it protects only rows with a `wise_locked_at` timestamp, NOT a `locked` boolean or `status='paid'` (there is no `locked` column on `payments`). The conclusion (trigger untouched) holds; the description was wrong.

### Reversible steps — ORDER CORRECTED (code before templates)

The draft ordered templates (Step 3) before code (Step 4). **That is backwards and a real correctness bug:** `mergeAgreement` leaves unknown tokens verbatim, so a template referencing `{{employer_name}}` before the code defines it renders the raw string `{{employer_name}}` onto a signed doc. **Ship code first.**

**Step 1 — Employer constant (additive, reversible).**
```sql
-- migration: 2026-06-09_employer_identity.sql
alter table portal_settings add column if not exists employer text not null default 'Aaron Anderson E.H.S. LLC';
update portal_settings set employer = 'Aaron Anderson E.H.S. LLC' where id = 1;
```
`NOT NULL` + default chosen deliberately (§2 regression guard). Reverse: `alter table portal_settings drop column employer;`.

**Step 2 — Backfill the schema-drift column (documentation only).** Add the already-live `onboarding_agreements.f_company_name` to a repo migration (`add column if not exists f_company_name text`). No prod change; brings repo in sync. (Schema-drift verified: `f_company_name` is in prod with 13/13 rows populated but appears in zero repo migrations. The column was added by MCP, not committed; the per-hire columns `addendum_type/addendum_text/extra_documents` are in **`2026-06-06_onboarding_per_hire.sql`** — the draft mislabeled this as "2026-06-03.")

**Step 2b — Document the larger template-body drift (bigger than the one column).** The committed `2026-06-03_agreement_templates_and_countersign.sql` seeds **all four templates** with "ABC Kids NY" and zero `{{company_name}}` tokens, but the **live bodies were hand-edited in prod** (live `ic_agreement` ≈ 24,232 chars vs ~1KB seed). A disaster-recovery rebuild or re-seed from repo would **silently replace the real, corrected agreements with placeholder text naming the wrong party.** Capture the current live bodies into a versioned migration (or an `agreement_templates` history insert — the table has a `version` column; bump it) so the prod bodies are recoverable from SQL, not just live state.

**Step 3 — App code (ship BEFORE templates).** Add `{{employer_name}}` handling (with literal fallback + empty-value guard) to all three `mergeAgreement` copies + relabels (§4). Deploy via existing Cloudflare git-push-to-main auto-deploy; kill-switch (`legacy.html` + `?ui=classic` + `FORCE_CLASSIC`) gives instant rollback. **All three code edits must ship atomically** so the classic/kill-switch path also defines `{{employer_name}}`.

**Step 4 — Templates (data edits in `agreement_templates`).** Re-author `non_compete` (the real fix). Optionally tokenize the three good templates **only with the §2 guards in place.** Make rollback SQL-reversible via the version-bump/history row from Step 2b — **not** a manual scratch-note paste.

**Step 5 — (Optional, owner-gated) enforce Hubstaff `hubstaff_org_id` as 1-org-per-client.** See §4 / Q3. Defer the relocation, but note it stores real data (258598), so a relocation migration must preserve/move the value, not no-op.

**No backfill of existing signed `onboarding_agreements` rows** — their field snapshots are immutable legal records. **Caveat the draft missed:** `printDoc` (`app/index.html:10242`) merges the **live** template body with the row's snapshot **field values** — there is **no body snapshot.** So re-printing a historical agreement renders the *current* template text (and current `portal_settings.employer`) under the *old* signature. This is already true today and independent of this design, but it means "snapshots are immutable legal records" is **false for the body** — only field values are snapshotted. If legal integrity matters, the real fix is snapshotting the rendered body at signing (out of scope here, but flag it since we are on this surface — see Q8).

---

## 4. What changes per surface

**DB / schema**
- `portal_settings`: + `employer` column, `NOT NULL` default (Step 1). The employer's home. **Write access MUST be owner-only** (see Open Decisions Q-sec below) — `portal_settings` is in the global-config group (`2026-06-06_admin_company_scoping.sql:20`); if a scoped admin can UPDATE it, a non-owner could silently change the contracting-party name on every contractor's agreements org-wide. Confirm `is_owner()`, not `is_admin()`/`is_company_admin()`, gates the write.
- `onboarding_agreements`: backfill `f_company_name` into a repo migration (Step 2). `f_company_name` = CLIENT snapshot, stays.
- **No change** to `payments`/`pay_periods`/`time_entries`/`rates`/`worker_companies`/`audit_log`/`admin_companies` — all stay client-keyed.
- **No `companies.kind`, no `employers` table, no `workers.employer_id`.**
- `companies.hubstaff_org_id` (`schema.sql:42`): **= `258598` on Ability Builders, null on the two empty clients** (NOT "seed sets null" as the draft claimed). It is unused by code today (all three sync paths read `org_id` from the caller/cron body, not the column), so it is vestigial *in code* but holds real data. Recommend making it the **enforced** source: 1 Hubstaff org per client, ideally `UNIQUE`, before any second client goes live (Q3 / §Hubstaff).
- `documents.company_id` (`schema.sql:239`): legacy IC-agreement doc table, client-keyed, with a comment "IC agreement is per-company" that now **contradicts the employer-level model.** At minimum fix the comment; if any IC PDFs are filed there per-client, that is the same party-confusion bug in a second location. (Omitted entirely by the draft.)

**Agreements / onboarding**
- Re-author `non_compete` (the real fix). Tokenize the other three only with §2 guards.
- `mergeAgreement` ×3: add `{{employer_name}}` with literal fallback; optional `{{client_name}}`. `{{company_name}}` stays = client. Add cross-file equivalence test (§2).
- Footer/chrome literals → employer constant: `app/index.html:10260, 2172, 10132, 10730` (the draft missed **`10730`** "Countersigner — signs for ABC Kids NY"); `legacy.html:8897, 8985, 9242`. **Acceptance gate = `grep -rn "ABC Kids NY"` returning zero in code+templates, not a hand-list.**
- Template help text → document `{{employer_name}}`=employer, `{{company_name}}`=assigned client: `app/index.html:10554`, `legacy.html:9242`.

**Payroll / billing**
- **No structural change.** All `.eq("company_id", companyId)` in Calculate/Lock/Process/Wise/Reports stay client-scoped (`app/index.html:5700-5722, 6301-6315, 8014-8020`). Per-client `payments`/`pay_periods` is the correct cost-attribution layer.
- **No invoicing/markup/margin exists** — billing clients is a new feature, not part of this split (Q7).

**Scoping / UI (cosmetic relabel — "Company" → "Client")**
- `CompanySwitcher`: `"Company"`→`"Client"`, `"— All companies —"`→`"— All clients —"` (`app/index.html:1271, 1279`). Query stays (`1267`); no `kind` filter needed since the employer is not a `companies` row.
- `ProfileModal`: `"Companies"`→`"Client assignments"`; show `Employer: Aaron Anderson E.H.S. LLC` as a static, non-editable fact (`app/index.html:3033-3057`).
- `AddContractorWizard`: `"Company *"`→`"Client *"`, `"— select company —"`→`"— select client —"`, summary `"Client / contract"` (`app/index.html:2142-2147, 2211`).
- `AdminsModal`, roster column/filter, Reports/Audit/Documents headers, per-tab banners → `"client"` copy (`1064-1213, 2414-2432, 7104-7332, 9986, 6961`). Pure copy.
- `CompaniesModal` → "Clients" registry (`app/index.html:11356-11540`).
- Topbar: surface `Aaron Anderson E.H.S. LLC` as fixed employer brand near `app/index.html:11747`; reconcile logo alt spelling (`1015`, `portal/index.html:509`) to canonical.

**Hubstaff**
- `cron_ingest` / browser sync take an `(org_id, company_id)` pair and write **all** of the employer org's hours to one client (`hubstaff-sync/index.ts:208-410, 375`; `app/index.html:4188-4226`). **Works today only because there is one real client.** The org-rollup endpoint (`activities/daily`) returns per-user org-wide totals with **no project/client split**, and `unique(company_id, source_name, work_date)` (`schema.sql:168`) does **not** collide across different `company_id` — so a shared org run for `(258598, ClientA)` then `(258598, ClientB)` **silently writes each worker's full org-wide seconds to BOTH clients = double-counted, double-paid hours, no error.** This is a HARD prerequisite, not MEDIUM: before any second client goes active, either enforce **one Hubstaff org per client** (make `hubstaff_org_id` the enforced/UNIQUE source) or build Hubstaff **projects + project→client mapping**. Add an interim **guard/alert if `distinct_active_companies > 1`** while sync still passes a single `company_id`. The `worker_companies` match index (`hubstaff-sync:296`) is already M:N-correct and stays.

**Wise**
- **No change.** One employer Wise business profile pays everyone, client-agnostic (`wise-payouts/index.ts:87`). **But the multi-client disbursement gap is a HARD blocker, not "fine as the cost layer" (correcting the draft):** `payments` PK is `(pay_period_id, worker_id)` and `pay_periods` is unique per `(company_id, period_start, period_end)`, so a 2-client contractor gets **2 pay_periods → 2 payment rows → 2 Wise transfers in one cycle** — double fees, two payees for one human, and `wise-payouts match` (by pay_period) has no concept of "one human, one expected total." Consolidation is explicitly blocked (`app/index.html:8110`) and does not exist. Latent today (0 multi-client workers) but **enabled the instant a contractor is assigned to a second client — which is the entire point of this split.** Decide before that first assignment (Q2). Optional: stamp client name into `details.reference` for per-client remittance labeling.

---

## 5. OPEN DECISIONS for the owner

Re-prioritized so the two real correctness cliffs sit at the top.

- **Q-sec (MUST-CHECK before shipping) — Is `portal_settings` write owner-only?** Before the employer name lives in config, confirm `is_owner()` (not `is_admin`/`is_company_admin`) gates the UPDATE. Otherwise a scoped admin can silently rewrite the contracting party on every signed agreement.

1. **(HARD BLOCKER before any 2nd-client assignment) Multi-client disbursement: one Wise transfer per cycle, or one per client (today)?** Per-client today = two Wise transfers, two fee hits, two payees for one human, and reconciliation has no "one human, one total" concept. Consolidation does not exist (`8110`). This is the single biggest gap the split *enables*. Must be resolved before the first multi-client assignment.

2. **(HARD BLOCKER before any 2nd-client assignment) Hubstaff org per client, or shared org?** Shared org under the current sync = silent double-counted hours (no error). Either enforce one org per client or build projects→client mapping first. Add the `distinct_active_companies > 1` guard now as a safety net.

3. **(HIGH — confirms the agreement fix) Is the IC/NDA/non-compete/BAA party the EMPLOYER, with the client only as "Assigned Company"?** Design assumes yes (matches three live templates). If a client is ever the contracting party for some doc, that doc needs different wiring.

4. **(MEDIUM — agreements) Will a contractor ever need a SEPARATE agreement per client?** If yes, `onboarding_agreements` PK `(worker_id, agreement_kind)` must gain `company_id` and the portal `AgreementViewer` (`portal/index.html:1472`) needs a client filter. If no, current shape stays.

5. **(LOW — future-proofing) Will there ever be more than ONE employer entity?** If yes, revisit option (c). Design assumes one employer indefinitely.

6. **(LOW — display) Canonical client name: full `"Ability Builders for Children, LLC"` or short `"Ability Builders"`?** Snapshots currently drift to the short form.

7. **(LOW — billing) Will the agency invoice clients (markup/margin)?** No billing concept exists; out of scope for the split. Per-client `payments` is the data you'd need.

8. **(NEW — legal integrity, owner call) Should the rendered agreement BODY be snapshotted at signing?** Today `printDoc` re-merges the live template + live config under the old signature, so a future employer/template edit retroactively changes the displayed text of already-signed docs. Out of scope to fix here, but decide whether body-freezing is required.

---

## Immediate vs later

**Safe quick fixes NOW (no owner decision needed, no money/time/RLS data moves, fully reversible):**
1. **Add `portal_settings.employer` constant** (`NOT NULL` default `'Aaron Anderson E.H.S. LLC'`) — Step 1.
2. **Re-author the `non_compete` template** to name the employer instead of "ABC Kids NY" — the one genuine legal correctness fix. Do this standalone; it does not depend on the tokenization program.
3. **Canonicalize the employer string** and **relabel UI "Company"→"Client"** — pure copy, gated by `grep -rn "ABC Kids NY"` == 0 (catches `app/index.html:10730`).
4. **Backfill the schema-drift migration** for `f_company_name` (doc-only) and **capture live template bodies into a versioned migration / history row** so prod is recoverable from SQL (Steps 2 / 2b).
5. **Verify `portal_settings` write is owner-only** (Q-sec) — a check, not a change; do it before relying on the constant.
6. **Order discipline:** ship the three `mergeAgreement` code edits (with literal fallback + empty-value guard) atomically **before** any template references `{{employer_name}}`.

**Needs the owner's decisions FIRST (do NOT ship until answered):**
- **Multi-client disbursement** (Q1) — hard blocker before assigning any contractor to a 2nd client; double Wise payout is unsolved.
- **Hubstaff org-per-client vs shared org** (Q2) — hard blocker before a 2nd client goes active; shared org silently double-counts hours. (Add the `distinct_active_companies > 1` guard now regardless.)
- **Tokenizing the three already-correct templates** — low legal value, real regression risk; only with §2 guards, and arguably skip it. Owner should weigh DRY vs. leaving correct literals alone.
- **Per-client agreement PK** (Q4), **>1 employer entity** (Q5), **canonical client name** (Q6), **client invoicing** (Q7), and **body-snapshot-at-signing** (Q8).

**Files cited:** `/Users/olivertrinidad/Documents/GitHub/abc-work-app-payroll-wis-hubstaff-app/app/index.html`, `/Users/olivertrinidad/Documents/GitHub/abc-work-app-payroll-wis-hubstaff-app/portal/index.html`, `/Users/olivertrinidad/Documents/GitHub/abc-work-app-payroll-wis-hubstaff-app/app/legacy.html`, `/Users/olivertrinidad/Documents/GitHub/abc-work-app-payroll-wis-hubstaff-app/schema/schema.sql`, `/Users/olivertrinidad/Documents/GitHub/abc-work-app-payroll-wis-hubstaff-app/schema/migrations/2026-05-31_onboarding_config.sql`, `/Users/olivertrinidad/Documents/GitHub/abc-work-app-payroll-wis-hubstaff-app/schema/migrations/2026-06-03_agreement_templates_and_countersign.sql`, `/Users/olivertrinidad/Documents/GitHub/abc-work-app-payroll-wis-hubstaff-app/schema/migrations/2026-06-06_onboarding_per_hire.sql`, `/Users/olivertrinidad/Documents/GitHub/abc-work-app-payroll-wis-hubstaff-app/schema/migrations/2026-06-06_admin_company_scoping.sql`, `/Users/olivertrinidad/Documents/GitHub/abc-work-app-payroll-wis-hubstaff-app/supabase/functions/hubstaff-sync/index.ts`, `/Users/olivertrinidad/Documents/GitHub/abc-work-app-payroll-wis-hubstaff-app/supabase/functions/wise-payouts/index.ts`. Proposed new migrations: `schema/migrations/2026-06-09_employer_identity.sql`, plus a template-body capture/version-bump migration. READ-ONLY analysis — no changes made.