-- ============================================================================
-- Onboarding M0 · A6 — onboarding_config on portal_settings (data-driven
-- "what must be signed/uploaded" + the dark-launch feature flag).
-- INERT: the portal only reads this once M2 ships; the flag defaults FALSE so
-- even after M2 lands on main the onboarding flow stays hidden until you flip
-- it. Idempotent. APPLY TO PROD. Depends on: portal_settings (already exists).
--
-- OWNER DECISION (plan §7.2): the feature flag lives INSIDE this jsonb as
-- onboarding_config->>'onboarding_enabled' (rather than a separate column), so
-- there's one config blob to manage. The portal reads it on boot. doc_version
-- here is the agreement version; doc_sha256 is filled later by the
-- agreement-authoring step, not seeded now.
-- ============================================================================
alter table portal_settings
  add column if not exists onboarding_config jsonb not null default '{
    "onboarding_enabled": false,
    "agreements": [
      {"order": 1, "kind": "ic_agreement",        "title": "Independent Contractor Agreement",            "version": "1.0", "required": true},
      {"order": 2, "kind": "non_compete",          "title": "Non-Compete Agreement",                        "version": "1.0", "required": true},
      {"order": 3, "kind": "confidentiality_nda",  "title": "Confidentiality / Non-Disclosure Agreement",   "version": "1.0", "required": true},
      {"order": 4, "kind": "baa",                  "title": "Business Associate Agreement (BAA)",           "version": "1.0", "required": true}
    ],
    "profile_tabs": ["contact", "personal", "payout", "about"],
    "documents": [
      {"kind": "resume",        "title": "Resume / CV",                          "required": true},
      {"kind": "diploma",       "title": "Diploma or Transcript of Records",     "required": true},
      {"kind": "nbi_clearance", "title": "NBI Clearance",                        "required": true, "freshness_months": 6},
      {"kind": "gov_id",        "title": "Government-issued ID or Passport",     "required": true, "sides": ["front", "back"]}
    ]
  }'::jsonb;

-- Safety net: ensure the singleton settings row exists (the add-column default
-- backfills it if it already does, which it should).
insert into portal_settings (id) values (1) on conflict (id) do nothing;

-- VERIFY:
--   select onboarding_config->>'onboarding_enabled' as enabled,
--          jsonb_array_length(onboarding_config->'agreements') as n_agreements,
--          jsonb_array_length(onboarding_config->'documents')  as n_documents
--     from portal_settings where id = 1;
--   -- expect: enabled=false, n_agreements=4, n_documents=4
