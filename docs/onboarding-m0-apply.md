# Onboarding M0 — Apply Runbook (review before pasting to prod)

**Status: NOT YET APPLIED.** These eight migrations are **inert/additive** — they
create new types and tables and add unused columns. They change *nothing* in the
running admin app or portal until later milestones (M1–M5) wire them up. The
onboarding gate does **not** turn on here. Safe to apply on prod, but review first.

All SQL is **user-pasted** in the Supabase SQL Editor (project `cgsidolrauzsowqlllsz`).
Each file is idempotent (safe to re-run). Files live in `schema/migrations/`.

## Paste order

| # | File | Notes |
|---|------|-------|
| 1 | `2026-05-31_onboarding_enums.sql` | **First** — others depend on these types. |
| 2 | `2026-05-31_onboarding_progress.sql` | gate-state table (read-only RLS; no write policy). |
| 3 | `2026-05-31_onboarding_signatures.sql` | eSign ledger (read-only RLS; immutable). |
| 4 | `2026-05-31_documents_review_cols.sql` | adds review columns + neutralizes legacy docs. |
| 5 | `2026-05-31_document_kind_values.sql` | ⚠️ **paste & run ALONE** (enum add can't share a txn with use). |
| 6 | `2026-05-31_onboarding_config.sql` | config blob on `portal_settings` (flag defaults **false**). |
| 7 | `2026-05-31_portal_notifications.sql` | banner table. |
| 8 | `2026-05-31_onboarding_reminders.sql` | reminder dedupe log (service-role only). |

> Items 1–4 and 6–8 may be pasted together in one run if you like; **item 5 must be
> its own separate run.** After each, run the `VERIFY` query in the file's footer.

## One-shot post-apply sanity check

```sql
select
  (select count(*) from pg_type where typname in
     ('onboarding_stage','agreement_kind','signature_method','signature_status','review_status')) as enums,      -- 5
  (select count(*) from information_schema.tables where table_name in
     ('onboarding_progress','onboarding_signatures','portal_notifications','onboarding_reminders')) as new_tables, -- 4
  (select count(*) from information_schema.columns where table_name='documents'
     and column_name in ('review_status','reviewed_by','issued_on','mime_type','file_size_bytes')) as doc_cols,   -- 5
  (select onboarding_config->>'onboarding_enabled' from portal_settings where id=1) as flag,                       -- false
  (select count(*) from documents where review_status='pending') as pending_docs;                                 -- 0
```

## What is deliberately NOT here (later milestones)

- **A7** `is_onboarded()` helper **+ grandfather backfill** → M1. (Until existing
  contractors are backfilled, the gate must never turn on.)
- **A8** the RLS gate predicate `and is_onboarded()` on feature read policies → M5
  (the cutover; the one HIGH-risk step).
- All edge functions, portal UI, admin UI, notifications wiring.

## Rollback

Everything here is additive. If you want to undo before anything depends on it:
drop the four new tables, drop the seven `documents` columns, drop the three enum
types and `portal_notification_kind`, and drop the `onboarding_config` column.
(Note: enum **values** added to `document_kind` in step 5 cannot be dropped —
Postgres limitation — but they are harmless if unused.)

## Open decisions reflected in these files (confirm or change)

1. **`reviewed_by` → `auth.users(id)`** (not `workers(id)`): reviewers are admins,
   who are not workers. Change if your reviewer identity model differs.
2. **Legacy docs neutralized to `approved`** so the HR queue starts empty.
3. **Feature flag inside `onboarding_config` jsonb** (`onboarding_enabled`), not a
   separate column.
