# Appendix 05 — Overview, Reports, Invoicing, Imports, Audit Log, Configuration

> Granular build spec with `app/index.html` line anchors. Master overview: [../FEATURES.md](../FEATURES.md).

Shared helpers: `money` (5806), `downloadCSV` (8707, RFC-4180), `periodFor` (5901), `methodLabel` (717), `useSortFilter` (1098), `logEvent` (1064), `ONB_DOC_KINDS` (10571).

## 1. Overview — `Overview` (11808-12068)
Mounts only when active. One batched query (`Promise.allSettled`, scope helper `S(q)`): periods8 (11820, last 8 pay_periods + embedded payments), pendingTime (11821), drafts (11822, locked + status draft/queued), failed (11823), links+rates (11824, setup gaps), pendDocs (11826), onb open (11827). **SWR** from `sessionStorage["eis_ov_"+scope]` (11837); cold load only → 6 skeleton tiles.
- **THIS PAY CYCLE hero** (11976): period, state (`stLabel`), pay-day countdown (`payday` 11924), contractor count, **Net this period** (Σ payments.net_php), **pipeline** Time→Calc→Lock→Sent→Settled (11906, each done/active/todo).
- **KPI tiles** (`tile()` 11955; 12003): Current pay period→process; **Locked, not yet sent**→process; **Time pending approval**→time; **Contractors needing setup** (no payout_method OR no current rate)→contractors; **Docs & onboarding**→documents; **Payout issues** (failed)→batches.
- **Net-pay sparkline** (`Sparkline` 11781, SVG; 12029) + delta pill. **Data-quality** (`runDq` 11854): |tracked−paid|>0.5h flags for the latest period; links to Calculate/Reports.
- Motion: `ov-anim`/`ovIn` staggered fade-up only (CSS 252). **No weather** here ("From New York" is the portal welcome label, AnnouncementsModal 2170).

## 2. Reports — `Reports` (7484-7673)
One `pageAll(headCount, rangeFn)` payments query (7487, full set, joins pay_periods/companies/workers).
- **Summary cards** (7552): Total net / Total ≈ USD ref / Unpaid / Period count.
- **Payout by pay period** (7569): year/month multi-select (default current; `MONTHS` 7540); columns expander/[Company]/Period/Pay date/Contractors/Net/≈USD ref/Unpaid; expandable per-period breakdown (7617): Contractor/Hours/Rate/Gross/Health/13th/Lunch/Bonus/Misc earn/**Deductions** (tooltip: actually subtracted)/**Perf. short** (tooltip: rate−gross, NOT subtracted)/Net/Method/Status.
- **PerContractorSummary "Contractor Pay Summary"** (7679): own pageAll; From/To + This year/Last year + `ContractorPicker` (7443); totals table Contractor/[Company]/Periods/Hours/Gross/Misc(red if<0)/Net/Paid; **expandable per-period statement rows** (7823) Pay period/Pay date/Hours/Gross/Health/13th/Lunch/Bonus/Misc/Net/Status; exports **Summary CSV** → `contractor_summary_*.csv` and **Statements CSV** → `contractor_statements_*.csv` (7752).
- **ContractorHistory "Contractor pay & hours history"** (7865): `<select>` contractor → payments + time_entries(limit 5000) bucketed; table Pay period/Worked h/PTO h/Health/Lunch/13th/Gross/Net/Method/Status; expandable to daily; Export CSV → `{name}_history.csv`.
- **UtilizationReport "Avg. Weekly Activity"** (8330): pageAll approved time; ContractorPicker; per ISO week (`weekStart` 8343) avg activity_pct + hours.
- `WiseReconciliation` (7981) is **rendered in Configuration** (12705), not Reports.

## 3. Invoicing — `Invoicing` (12464-12605)
Bills a **client** for worked hours × USD bill rate (PTO not billed).
- Client `<select>` (12559; `__all__` = history). From/To (default current period), **Markup %**, Preview.
- `buildPreview` (12486): load client roster `bill_rate_usd` → employer time_entries → lines `{worked_hours, bill_rate_usd, amount_usd}` (>0, sorted). Heads-up if no bill rate.
- Preview table (12571): Contractor/Position/Hours/Rate("not set" warn if 0)/Amount + Total (+`→ ${markup'd}`). **Generate invoice** / **Export CSV** → `invoice_preview_*.csv`.
- `generate` (12517): `rpc("allocate_invoice_no")` → `invoices` (status draft, subtotal/total/markup) [constraint `one_live_per_period`] + `invoice_lines`; logs `invoice_generated`.
- History table (12586): Invoice #/[Client]/Period/Total/Status (pill draft amber/sent blue/paid green/void red); Print / Mark sent / Mark paid / Void (confirm, `voidInvoice` 12533).
- `printInvoice` (12535): standalone HTML "INVOICE" navy, From "Aaron Anderson E.H.S. LLC", Bill to, lines, Subtotal+Markup+Total, "paid time off is not billed".

## 4. Imports — `DeleteImports` (4944-5229)
Cleanup tool (importing is on Time & Approval; Hubstaff project mapping is in Configuration; the OneDrive backfill was a one-off DB op).
- **Delete by date range** (5102): From/To → `armRange` (5056) dry-run preview (per-contractor Rows/Hours/Date span) + overlap check. Normal path one-click Confirm; **safe path** (overlaps locked/paid) requires typed **DELETE** + lists overlapping periods. `doDeleteRange` (5039) deletes time_entries + `clearOpenBatchPayments` (open overlap only, 4996).
- **Delete by import batch** (5190): recent batches (≤12), View (`viewBatch` 4962) + Delete (`doDeleteBatch` 5004, blocked if dates in locked/paid).

## 5. Audit Log — `AuditLog` (10456-10534)
Query (10462): audit_log limit 500, optional from/to (server, inclusive to). `AUDIT_LABELS` (10448): import/delete_import/approve/reject/lock/unlock_period/delete_statement/mark_paid/mark_unpaid/manual_hours/set_rate/undo/wise_recipient_sync/wise_lock_release/wise_lock_warning/add_contractor/edit_contractor/delete_contractor/recalculate/override.gross (others show raw). Filters: From/To + Last 7d/30d/year + FilterBox; sortable When/Action/Item/By; Export CSV → `audit_log_*.csv`. Table When/Action(pill)/Item/Detail(`summarizeDetail` 10535 renders before→after diffs)/By. Cap-500 footnote.

## 6. Configuration — `Configuration` (12684-12714)
Six rows (Open buttons) + embedded WiseReconciliation:
- **Employer / Clients** → `CompaniesModal kind` (12193): Add (name + Hubstaff org ID); Active/Archived lists; Edit (name, Tax ID, Hubstaff org ID, Address, Phone (PhoneInput), Website, repeatable **Contacts** first/last/title/Email/Mobile/Office/Ext/Fax). **Archive** (keeps history, `company_archived`/`company_restored`) vs **Delete** (owner-only, only a genuinely empty company via typed-name confirm `confirmWord:c.name`, `countDeps` 12284). **Employer can't be archived/deleted** (12406).
- **Hubstaff Projects → Clients** → `HubstaffProjectsModal` (12610): org `<select>`, Load projects (`hubstaff-sync list_projects`), per-project client `<select>`, Save (upsert/delete `hubstaff_projects`, `hubstaff_projects_mapped`).
- **Portal Fields** → `PortalSettingsModal` (2088): checklist of 27 `CANDIDATES` (2091) self-editable fields; payout destination always admin-only; saves `portal_settings.editable_fields`.
- **Agreement Templates** → `AgreementTemplatesModal` (11261).
- **Onboarding Configuration** → `OnboardingConfigModal` (11319).
- **WiseReconciliation** card (12705 → 7981): Backfill all paid periods / Email cross-check / Cross-system drift scan.

**Connection/secrets/cron** — no in-app status panels; tokens live in Supabase secrets; the daily Hubstaff `cron_ingest` + review-digest crons run server-side. Surfaced only via action error strings + OnboardingConfig "Also needs Resend".

### Key anchors
Tab wiring 12882-12978; Overview 11808-12068 (Sparkline 11781); Reports 7484-7673 (ContractorPicker 7443, PerContractorSummary 7679, ContractorHistory 7865, UtilizationReport 8330); Invoicing 12464-12605 (HubstaffProjectsModal 12610); DeleteImports 4944-5229; AuditLog 10456-10534 (AUDIT_LABELS 10448, summarizeDetail 10535); Configuration 12684-12714 (CompaniesModal 12193, PortalSettingsModal 2088, EmployerSwitcher 1495).

> Two corrections to common assumptions: **WiseReconciliation is in Configuration, not Reports** (12705); the admin **Overview has no weather animations** — "From New York" weather is a contractor-portal feature.
