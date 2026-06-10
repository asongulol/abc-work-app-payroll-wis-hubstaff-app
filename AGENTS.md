# Memory

## Me
Bronxon (otrinidad@abckidsny.com). Works on the HR & Payroll app for PH contractors (ABC Kids NY / "asongulol" Supabase project).

## Preferences

### Engineering conventions (apply to ALL projects, current and future)
- **ID-first entity matching for ALL API integrations.** When importing/syncing entities (people, recipients, records) from any external API (Hubstaff, Wise, etc.), match to existing local records by the provider's **stable ID first**, falling back to a hardened name/identifier match only when no ID is stored yet. Persist the provider ID on first match so future syncs are ID-based and immune to name changes. **Match-before-create**: never insert a new record without first checking for an existing match. → Full spec: memory/context/engineering-conventions.md
- Verify edits before declaring done (transpile/lint, behavioral tests, confirm DB state).
- Never auto-run permanent deletes/commits on production without explicit per-action confirmation.

## Projects
| Name | What |
|------|------|
| **HR & Payroll app** | Single-file React app (app/index.html) on Supabase. Contractors paid in PHP via Wise. Time from Hubstaff (CSV + API sync edge function). |
→ Details: memory/projects/

## Key facts
| Thing | Value |
|------|------|
| Supabase project | cgsidolrauzsowqlllsz ("asongulol's Project", PRODUCTION) |
| App file | app/index.html (React via in-browser Babel) |
| Edge functions | hubstaff-sync, wise-payouts (tokens server-side in Supabase secrets) |
| Payout | Contractors paid in PHP; Wise is the payout rail |
