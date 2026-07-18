-- Demo content: a week of realistic entries for tester@foodjournal.dev so the
-- app can be seen "full". Run in the Supabase SQL Editor, then log in as
-- tester@foodjournal.dev / journal123.
--
-- Safe to re-run: it clears this account's existing entries first.
-- Photos: each entry points at a free Unsplash image (CORS-enabled, so it
-- renders under the web CanvasKit renderer). photo_path holds the absolute URL
-- directly; the app uses it as-is instead of signing a Storage path. Real
-- user uploads still go to the private Storage bucket as before.

do $$
declare
  uid uuid;
begin
  select id into uid from auth.users where email = 'tester@foodjournal.dev';
  if uid is null then
    raise exception 'tester@foodjournal.dev not found - run dev_users.sql first';
  end if;

  delete from public.food_entries where user_id = uid;

  insert into public.food_entries
    (user_id, name, rating, category, is_homemade, notes, recipe, location, photo_path, eaten_at)
  select uid, e.name, e.rating, e.category, e.is_homemade, e.notes, e.recipe, e.location,
         'https://images.unsplash.com/photo-' || e.photo || '?w=1200&q=80&auto=format&fit=crop',
         now() - e.ago
  from (values
    -- today
    ('Margherita pizza', 9, 'dinner', false, 'Best crust in town, blistered just right.', null, 'Lucia''s Pizzeria', '1513104890138-7c749659a591', interval '2 hours'),
    ('Cold brew coffee', 8, 'drink', false, 'Smooth and low-acid.', null, 'Blue Bottle', '1461023058943-07fcbe16d735', interval '6 hours'),
    ('Avocado toast', 7, 'breakfast', true, 'Needed a touch more salt.', 'Sourdough, smashed avocado, chili flakes, lemon, olive oil.', 'Home', '1541519227354-08fa5d50c44d', interval '9 hours'),
    -- yesterday
    ('Pad see ew', 9, 'dinner', false, 'Perfectly smoky wok hei.', null, 'Thai Basil', '1552611052-33e04de081de', interval '1 day 3 hours'),
    ('Dark chocolate square', 7, 'snack', false, '70% - just enough.', null, 'Home', '1511381939415-e44015466834', interval '1 day 6 hours'),
    ('Chicken caesar wrap', 6, 'lunch', false, 'A little soggy by the time I ate it.', null, 'Corner Deli', '1550304943-4f24f54ddde9', interval '1 day 8 hours'),
    ('Greek yogurt bowl', 8, 'breakfast', true, 'Filling and bright.', 'Greek yogurt, honey, granola, blueberries.', 'Home', '1488477181946-6428a0291777', interval '1 day 11 hours'),
    -- 2 days ago
    ('Poke bowl', 9, 'lunch', false, 'Super fresh tuna.', null, 'Island Poke', '1546069901-ba9599a7e63c', interval '2 days 5 hours'),
    ('Banana bread', 8, 'snack', true, 'Used up the brown bananas.', 'Flour, 3 ripe bananas, brown sugar, butter, eggs, cinnamon, walnuts.', 'Home', '1606101273945-e9eba91c0dc4', interval '2 days 7 hours'),
    ('Matcha latte', 8, 'drink', true, 'Whisked it properly this time.', 'Ceremonial matcha, oat milk, a little honey.', 'Home', '1536256263959-770b48d82b0a', interval '2 days 10 hours'),
    -- 3 days ago
    ('Espresso martini', 7, 'drink', false, 'A well-earned treat.', null, 'The Alley Bar', '1514362545857-3bc16c4c7d1b', interval '3 days 2 hours'),
    ('Lentil soup', 8, 'lunch', true, 'Cozy and cheap.', 'Red lentils, carrot, celery, onion, cumin, vegetable stock.', 'Home', '1603105037880-880cd4edfb0d', interval '3 days 6 hours'),
    ('Scrambled eggs on toast', 6, 'breakfast', true, 'Standard weekday fuel.', null, 'Home', '1525351484163-7529414344d8', interval '3 days 10 hours'),
    -- 4 days ago
    ('Sushi platter', 9, 'dinner', false, 'Date night.', null, 'Sakura', '1579871494447-9811cf80d66c', interval '4 days 3 hours'),
    ('Iced oat latte', 7, 'drink', false, null, null, 'Grind House', '1517701550927-30cf4ba1dba5', interval '4 days 7 hours'),
    ('Blueberry pancakes', 10, 'breakfast', true, 'Sunday best - worth the flip anxiety.', 'Flour, milk, egg, baking powder, fresh blueberries, maple syrup.', 'Home', '1567620905732-2d1ec7ab7445', interval '4 days 10 hours'),
    -- 5 days ago
    ('Popcorn', 5, 'snack', true, 'Movie night. Burnt a little.', null, 'Home', '1578849278619-e73505e9610f', interval '5 days 4 hours'),
    ('Falafel wrap', 8, 'lunch', false, 'That garlic sauce is unreal.', null, 'Aleppo Kitchen', '1615870216519-2f9fa575fa5c', interval '5 days 7 hours'),
    ('Overnight oats', 7, 'breakfast', true, 'Meal prep paid off.', 'Oats, chia, almond milk, peanut butter, sliced banana.', 'Home', '1517673400267-0251440c45dc', interval '5 days 11 hours'),
    -- 6 days ago
    ('Roast chicken dinner', 9, 'dinner', true, 'Proper Sunday roast.', 'Whole chicken, potatoes, carrots, thyme, garlic, lemon.', 'Home', '1598103442097-8b74394b95c6', interval '6 days 4 hours'),
    ('Croissant', 8, 'snack', false, 'Flaky perfection.', null, 'Petit Four Bakery', '1555507036-ab1f4038808a', interval '6 days 8 hours')
  ) as e(name, rating, category, is_homemade, notes, recipe, location, photo, ago);

  raise notice 'seeded % demo entries for tester@foodjournal.dev',
    (select count(*) from public.food_entries where user_id = uid);
end $$;
