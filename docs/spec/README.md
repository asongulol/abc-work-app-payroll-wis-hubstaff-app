# Feature spec — detailed appendices

Granular, subsystem-by-subsystem build specs with exact `file:line` anchors, dropdown options, validation rules, formulas, and workflows. These are the deep-dive companions to the master overview in [../FEATURES.md](../FEATURES.md).

| # | Appendix | Covers |
|---|---|---|
| 01 | [Shell & design system](01-shell-design-system.md) | Colors/typography/tokens, app shell, navigation, global components, data-entry helpers, unsaved guard, drafts, confirmDanger, modal a11y, kill switch + cache self-update |
| 02 | [Contractors & hiring](02-contractors-hiring.md) | Contractors list, ProfileModal (every field + dropdown), AddContractorWizard (3 steps + validation + dup prevention), BulkImport |
| 03 | [Onboarding & agreements](03-onboarding-agreements.md) | OnboardingAdmin, OnboardingDrilldown (edit/resend/withdraw/delete), AgreementsPanel + mergeAgreement, templates, document review, tools, AdminsModal, OnboardingConfig |
| 04 | [Payroll pipeline](04-payroll-pipeline.md) | Time & Approval (Hubstaff CSV+API), Calculate (pay-component formulas), Process & Pay (3 Wise paths), Review & Recon |
| 05 | [Reports & config](05-reports-config.md) | Overview dashboard, Reports (4 sub-reports), Invoicing, Imports, Audit Log, Configuration (companies/projects/portal fields) |
| 06 | [Portal & backend](06-portal-backend.md) | The contractor portal (login → set password → 3-stage onboarding → home), all 10 edge functions, data model, RLS, cron |

**Recommended reading order to recreate:** master `FEATURES.md` → 01 (foundations) → 06 backend (data model + RLS) → 02–05 (admin features) → 06 portal.
