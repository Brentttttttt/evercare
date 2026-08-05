create table public.journal_entry_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade
    default auth.uid(),
  journal_entry_id uuid not null references public.journal_entries(id)
    on delete cascade,
  storage_path text not null unique,
  display_order integer not null default 0 check (display_order >= 0),
  created_at timestamptz not null default now(),
  constraint journal_entry_photos_owner_path_check check (
    storage_path like user_id::text || '/' || journal_entry_id::text || '/%'
  )
);

create index journal_entry_photos_entry_order_idx
  on public.journal_entry_photos(journal_entry_id, display_order, created_at);
create index journal_entry_photos_user_idx
  on public.journal_entry_photos(user_id, created_at desc);

alter table public.journal_entry_photos enable row level security;

create policy "Users own their journal photos"
on public.journal_entry_photos for all to authenticated
using (
  user_id = auth.uid()
  and exists (
    select 1
    from public.journal_entries entry
    where entry.id = journal_entry_photos.journal_entry_id
      and entry.user_id = auth.uid()
  )
)
with check (
  user_id = auth.uid()
  and exists (
    select 1
    from public.journal_entries entry
    where entry.id = journal_entry_photos.journal_entry_id
      and entry.user_id = auth.uid()
  )
);

revoke all on table public.journal_entry_photos from anon, authenticated;
grant select, insert, update, delete on table public.journal_entry_photos
  to authenticated;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'journal-photos',
  'journal-photos',
  false,
  8388608,
  array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif'
  ]
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "Journal owners can upload private photos"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'journal-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
  and exists (
    select 1
    from public.journal_entries entry
    where entry.user_id = auth.uid()
      and entry.id::text = (storage.foldername(name))[2]
  )
);

create policy "Journal owners can read private photos"
on storage.objects for select to authenticated
using (
  bucket_id = 'journal-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
  and exists (
    select 1
    from public.journal_entry_photos photo
    where photo.user_id = auth.uid()
      and photo.storage_path = name
  )
);

create policy "Journal owners can delete private photos"
on storage.objects for delete to authenticated
using (
  bucket_id = 'journal-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
  and exists (
    select 1
    from public.journal_entries entry
    where entry.user_id = auth.uid()
      and entry.id::text = (storage.foldername(name))[2]
  )
);
