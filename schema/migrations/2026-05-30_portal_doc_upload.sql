-- ============================================================================
-- Contractor portal — document upload (Phase: refinements #3). APPLY TO PROD.
-- ----------------------------------------------------------------------------
-- Contractors upload their own IC Agreement / W-8BEN / Gov ID from the portal.
-- Files go to a PRIVATE Storage bucket 'contractor-docs' (one folder per login,
-- keyed by auth.uid()); a documents row is created. Read is already scoped by
-- the earlier documents_contractor_read policy. Here we add INSERT (own only,
-- excluding internal 'other') + the Storage object policies.
--
-- PREREQ: create the bucket first (Supabase → Storage → New bucket →
--   name "contractor-docs", PRIVATE). Then run this.
-- ============================================================================

-- 1) documents: contractor may INSERT rows for their own worker, safe kinds only
drop policy if exists documents_contractor_insert on documents;
create policy documents_contractor_insert on documents for insert to authenticated
  with check ( worker_id = my_worker_id() and kind <> 'other' );

-- 2) Storage objects: contractor uploads/reads only inside their own
--    auth.uid() folder in the contractor-docs bucket; admins can read all.
drop policy if exists "contractor_docs_insert_own" on storage.objects;
create policy "contractor_docs_insert_own" on storage.objects for insert to authenticated
  with check ( bucket_id = 'contractor-docs' and (storage.foldername(name))[1] = auth.uid()::text );

drop policy if exists "contractor_docs_read_own" on storage.objects;
create policy "contractor_docs_read_own" on storage.objects for select to authenticated
  using ( bucket_id = 'contractor-docs'
          and ( (storage.foldername(name))[1] = auth.uid()::text or is_admin() ) );

drop policy if exists "contractor_docs_delete_own" on storage.objects;
create policy "contractor_docs_delete_own" on storage.objects for delete to authenticated
  using ( bucket_id = 'contractor-docs' and (storage.foldername(name))[1] = auth.uid()::text );
