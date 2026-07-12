-- Multiple dishes per entry.
--
-- One photo can contain several dishes, each with its own name/rating/notes/
-- recipe. Stored as a JSONB array on the entry; the legacy name/rating/notes/
-- recipe columns continue to mirror the first (primary) dish so the feed's
-- sort, search, and pre-existing rows keep working unchanged.
--
-- No RLS change needed: dishes live on food_entries, already scoped by the
-- existing owner-only policies.

alter table public.food_entries
  add column if not exists dishes jsonb;
