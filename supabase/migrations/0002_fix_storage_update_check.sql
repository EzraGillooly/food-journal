-- Harden the storage UPDATE policy for entry photos.
--
-- The original entry_photos_update_own policy had only a USING clause, which
-- gates WHICH existing objects a user may update but not the NEW value of the
-- object path. Supabase's storage move/copy is an UPDATE of objects.name, so
-- without a WITH CHECK a user could rename/move their own object into another
-- user's {uid}/ folder. Adding WITH CHECK confines the destination to the
-- caller's own folder, matching insert/select/delete.

drop policy if exists entry_photos_update_own on storage.objects;
create policy entry_photos_update_own
  on storage.objects for update
  using (
    bucket_id = 'entry-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'entry-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
