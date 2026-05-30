-- ============================================================================
-- Workers — capture the rest of the PH "201 file" personal info. APPLY TO PROD.
-- ----------------------------------------------------------------------------
-- Gov IDs (SSS/PhilHealth/Pag-IBIG/TIN) deliberately NOT stored: those are PH
-- EMPLOYEE systems; our people are independent contractors who handle their own,
-- and holding them adds misclassification + privacy risk with no operational use.
-- W-8BEN (already a document kind) is the relevant US-side artifact.
-- ============================================================================
alter table workers add column if not exists emergency_name text;
alter table workers add column if not exists emergency_relationship text;
alter table workers add column if not exists emergency_mobile text;
alter table workers add column if not exists permanent_address text;
alter table workers add column if not exists address_landmark text;
alter table workers add column if not exists postal_code text;
alter table workers add column if not exists marital_status text;
alter table workers add column if not exists education_level text;
alter table workers add column if not exists course text;
alter table workers add column if not exists year_graduated text;
alter table workers add column if not exists school text;
-- free-form / culture bits (favorite color/food, motto, etc.) — feeds the
-- welcome-page recognition features later.
alter table workers add column if not exists profile_extras jsonb not null default '{}'::jsonb;
