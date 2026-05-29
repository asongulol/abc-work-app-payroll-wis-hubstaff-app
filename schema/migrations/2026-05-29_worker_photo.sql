-- Add an optional contractor photo to workers.
-- Stored as a small (256px, center-cropped) JPEG data URI by the app, so no
-- Supabase Storage bucket or RLS policy is needed. NULL = show initials.
alter table workers add column if not exists photo_url text;
