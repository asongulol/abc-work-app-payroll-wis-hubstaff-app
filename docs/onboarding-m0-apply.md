# Onboarding M0 — Apply Runbook (review before pasting to prod)

**Status: NOT YET APPLIED.** These eight migrations are **inert/additive** — they
create new types and tables and add unused columns. They change *nothing* in the
running admin app or portal until later milestones (M1–M5) wire them up. The
onboarding gate does **not** turn on here. Safe to apply on prod, but review first.

All SQL is **user-pasted** in the Supabase SQL Editor (project `cgsidolrauzsowqlllsz`).
Each file is idempotent (safe to re-run). Files live in `schema/migrations/`.

## Paste order

| Run | File(s) | Notes |
|-----|---------|-------|
| **Run 1 (alone)** | `2026-05-31_onboarding_enums.sql` | Creates all 6 enum types. **Must be its own run** — the Supabase SQL Editor does not make a type created inside a `DO` block visible to later statements in the *same* submission, so the tables can't be in this run. Let it commit first. |
| **Run 2** | `…_onboarding_progress.sql` + `…_onboarding_signatures.sql` + `…_documents_review_cols.sql` + `…_onboarding_config.sql` + `…_portal_notifications.sql` + `…_onboarding_reminders.sql` | All tables/columns. Paste together — they only *use* the now-committed types. |
| **Run 3 (alone)** | `2026-05-31_document_kind_values.sql` | ⚠️ Run by itself — an enum `ADD VALUE` can't share a transaction with anything that uses the value. |

> Why the split: a `CREATE TYPE` inside `do $$ … $$` isn't visible to a later
> `CREATE TABLE` in the **same** SQL Editor submission (one transaction). Creating
> the types in their own run (so they commit) before the tables avoids the
> `type "onboarding_stage" does not exist` error. After each run, the `VERIFY`
> query in each file's footer confirms it.

## One-shot post-apply sanity check

```sql
select
  (select count(*) from pg_type where typname in
     ('onboarding_stage','agreement_kind','signature_method','signature_status','review_status','portal_notification_kind')) as enums,  -- 6
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
