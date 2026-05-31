-- ============================================================================
-- Portal — refresh editable_fields to the FULL self-service allow-list.
--
-- WHY: the original portal_settings seed ran `on conflict (id) do nothing`, so
-- when the 201 personal/HR + payout fields were added later they were never
-- added to editable_fields. Result: contractors saw those fields read-only in
-- the portal. This overwrites editable_fields with the complete set (the same
-- set portal-self enforces server-side as SAFE_FIELDS). APPLY TO PROD.
--
-- Note: this is a SUPERSET. portal-self still hard-caps writes to SAFE_FIELDS,
-- so adding a field here can never expose payout destination / rate / status.
-- ============================================================================
insert into portal_settings (id, editable_fields)
values (1, '[
  "first_name","middle_name","last_name",
  "mobile","ph_address","permanent_address","address_landmark","postal_code","date_of_birth",
  "emergency_name","emergency_relationship","emergency_mobile",
  "marital_status","education_level","course","year_graduated","school",
  "gcash","paymaya","paypal","wise_tag",
  "favorite_color","favorite_food","motto"
]'::jsonb)
on conflict (id) do update set editable_fields = excluded.editable_fields;
