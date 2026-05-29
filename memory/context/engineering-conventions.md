# Engineering Conventions

Standing conventions Bronxon wants applied to **all** projects, current and future.

## ID-first entity matching for API integrations

**Rule:** Whenever syncing or importing entities from an external API (Hubstaff, Wise,
payroll providers, CRMs, anything), match incoming records to existing local records
using the provider's **stable unique ID as the primary key**, with a hardened
name/identifier match as fallback only.

**Why:** Names and human-readable labels are fuzzy — they get reordered, misspelled,
gain middle names, change on marriage, etc. Matching on them creates duplicate records.
A provider's numeric/UUID ID never changes, so once stored it makes matching bulletproof.

**The pattern (implement every time):**

1. **Store the provider ID.** Add a column to hold the external stable id
   (e.g. `hubstaff_user_id`, `wise_recipient_id`). Add a per-scope unique index
   (partial: `where <id> is not null`) so the same external entity can't link twice.

2. **Match in priority order:**
   - (a) provider stable ID, when the incoming record carries one AND we've stored it;
   - (b) strict normalized key (e.g. sorted lowercased name tokens, accents stripped);
   - (c) loose fallback key (e.g. first + last token).

3. **Match-before-create.** Before inserting a new local record for an incoming item,
   search existing records by the keys above. If found, reuse + relink — never blindly
   insert. Only create a new record when truly nothing matches.

4. **Persist the ID on first match.** When an incoming record is matched (or added) and
   carries a provider ID, write that ID onto the local record. From the next sync on,
   matching is ID-based and immune to name changes.

5. **Keep CSV/manual paths working.** Some sources (e.g. CSV exports) carry no ID — those
   still use the hardened name match. ID-first means "prefer ID when available," not
   "require ID."

**Reference implementation:** HR & Payroll app (app/index.html) — `nameTokens`/`nameKey`/
`looseKey`, `indexLinks`/`matchExisting` (ID-first, name fallback), and `addContractor`
(match-before-create). Hubstaff `hubstaff_user_id` on `worker_companies`.

## Verification
- Verify edits before declaring done: transpile/lint, run behavioral tests for the
  matching logic (include a negative test that a genuinely new entity does NOT match),
  and confirm DB state with a read-back query.

## Production safety
- Never auto-run permanent deletes or commits on a production database without explicit
  per-action user confirmation. Dry-run (BEGIN…ROLLBACK or a counting query) first.
- Never enter/store API tokens or credentials on the user's behalf; keep secrets
  server-side (edge functions + Supabase secrets), and have the user set them.
