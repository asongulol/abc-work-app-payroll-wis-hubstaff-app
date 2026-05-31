-- ============================================================================
-- Workers — add a company work email (@abckidsny.com), distinct from the
-- existing `email` which is the contractor's PERSONAL email (from the 201 file,
-- used for contact + Wise reconciliation). APPLY TO PROD.
-- ============================================================================
alter table workers add column if not exists work_email text;
