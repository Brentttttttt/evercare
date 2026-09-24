-- The profile already has avatar_path. Store only a private object path there;
-- no new profile column, profile backfill, or wider profile RLS is required.
insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'profile-pictures',
  'profile-pictures',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- The app generates a fresh name for every replacement:
-- <authenticated user UUID>/<random filename>.png
-- Folder ownership is verified by the server, not a client-provided user ID.
create policy "Profile owners can upload private pictures"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'profile-pictures'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Profile owners can read private pictures"
on storage.objects for select to authenticated
using (
  bucket_id = 'profile-pictures'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Profile owners can delete private pictures"
on storage.objects for delete to authenticated
using (
  bucket_id = 'profile-pictures'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

-- Deliberately no UPDATE policy: replacement is a new object, not an overwrite.
-- Existing journal-photo policies remain scoped to the journal-photos bucket.
