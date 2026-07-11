-- Food Journal — initial schema, RLS, and storage policies.
-- Security model: this app is a static client (GitHub Pages) with no server.
-- Row Level Security is the ONLY thing isolating one user's data from another's.
-- Every table and storage policy below scopes access to auth.uid().

-- ---------------------------------------------------------------------------
-- Table: food_entries
-- ---------------------------------------------------------------------------
create table if not exists public.food_entries (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name        text not null,
  rating      int  not null check (rating between 1 and 10),
  category    text not null check (category in ('breakfast', 'lunch', 'dinner', 'snack', 'drink')),
  is_homemade boolean not null default true,
  notes       text,
  recipe      text,
  location    text,
  photo_path  text,
  eaten_at    timestamptz not null default now(),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Feed queries order by eaten_at within a user's rows.
create index if not exists food_entries_user_eaten_idx
  on public.food_entries (user_id, eaten_at desc);

-- Keep updated_at fresh on every update.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists food_entries_set_updated_at on public.food_entries;
create trigger food_entries_set_updated_at
  before update on public.food_entries
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Row Level Security — the sole isolation boundary
-- ---------------------------------------------------------------------------
alter table public.food_entries enable row level security;

drop policy if exists food_entries_select_own on public.food_entries;
create policy food_entries_select_own
  on public.food_entries for select
  using (auth.uid() = user_id);

drop policy if exists food_entries_insert_own on public.food_entries;
create policy food_entries_insert_own
  on public.food_entries for insert
  with check (auth.uid() = user_id);

drop policy if exists food_entries_update_own on public.food_entries;
create policy food_entries_update_own
  on public.food_entries for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists food_entries_delete_own on public.food_entries;
create policy food_entries_delete_own
  on public.food_entries for delete
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Storage: private bucket for entry photos, one folder per user
-- Objects are stored at:  entry-photos/{user_id}/{entry_id}.jpg
-- The first path segment must equal the caller's uid.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('entry-photos', 'entry-photos', false)
on conflict (id) do nothing;

drop policy if exists entry_photos_select_own on storage.objects;
create policy entry_photos_select_own
  on storage.objects for select
  using (
    bucket_id = 'entry-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists entry_photos_insert_own on storage.objects;
create policy entry_photos_insert_own
  on storage.objects for insert
  with check (
    bucket_id = 'entry-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists entry_photos_update_own on storage.objects;
create policy entry_photos_update_own
  on storage.objects for update
  using (
    bucket_id = 'entry-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists entry_photos_delete_own on storage.objects;
create policy entry_photos_delete_own
  on storage.objects for delete
  using (
    bucket_id = 'entry-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
