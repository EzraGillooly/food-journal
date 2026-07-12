-- 1) Allow the new 'dessert' category on entries.
alter table public.food_entries
  drop constraint if exists food_entries_category_check;
alter table public.food_entries
  add constraint food_entries_category_check
  check (category in ('breakfast', 'lunch', 'dinner', 'snack', 'dessert', 'drink'));

-- 2) Per-day notes: a short summary of how a day's eating went.
create table if not exists public.day_notes (
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  entry_date date not null,
  note       text not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, entry_date)
);

alter table public.day_notes enable row level security;

drop policy if exists day_notes_select_own on public.day_notes;
create policy day_notes_select_own
  on public.day_notes for select using (auth.uid() = user_id);

drop policy if exists day_notes_insert_own on public.day_notes;
create policy day_notes_insert_own
  on public.day_notes for insert with check (auth.uid() = user_id);

drop policy if exists day_notes_update_own on public.day_notes;
create policy day_notes_update_own
  on public.day_notes for update
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists day_notes_delete_own on public.day_notes;
create policy day_notes_delete_own
  on public.day_notes for delete using (auth.uid() = user_id);
