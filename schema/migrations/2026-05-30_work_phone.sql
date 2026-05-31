-- ============================================================================
-- Workers — add company work number + extension (admin-assigned), distinct from
-- the personal `mobile`. APPLY TO PROD.
-- ============================================================================
alter table workers add column if not exists work_number text;
alter table workers add column if not exists work_extension text;
