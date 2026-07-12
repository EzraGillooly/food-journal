-- Demo content: a week of realistic entries for tester@foodjournal.dev so the
-- app can be seen "full". Run in the Supabase SQL Editor, then log in as
-- tester@foodjournal.dev / journal123.
--
-- Safe to re-run: it clears this account's existing entries first.
-- Note: photos live in Storage, not the DB, so seeded entries have no photo and
-- show the placeholder. Add a few through the app to see photo-forward cards.

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
    (user_id, name, rating, category, is_homemade, notes, recipe, location, eaten_at)
  select uid, e.name, e.rating, e.category, e.is_homemade, e.notes, e.recipe, e.location, now() - e.ago
  from (values
    -- today
    ('Margherita pizza', 9, 'dinner', false, 'Best crust in town, blistered just right.', null, 'Lucia''s Pizzeria', interval '2 hours'),
    ('Cold brew coffee', 8, 'drink', false, 'Smooth and low-acid.', null, 'Blue Bottle', interval '6 hours'),
    ('Avocado toast', 7, 'breakfast', true, 'Needed a touch more salt.', 'Sourdough, smashed avocado, chili flakes, lemon, olive oil.', 'Home', interval '9 hours'),
    -- yesterday
    ('Pad see ew', 9, 'dinner', false, 'Perfectly smoky wok hei.', null, 'Thai Basil', interval '1 day 3 hours'),
    ('Dark chocolate square', 7, 'snack', false, '70% - just enough.', null, 'Home', interval '1 day 6 hours'),
    ('Chicken caesar wrap', 6, 'lunch', false, 'A little soggy by the time I ate it.', null, 'Corner Deli', interval '1 day 8 hours'),
    ('Greek yogurt bowl', 8, 'breakfast', true, 'Filling and bright.', 'Greek yogurt, honey, granola, blueberries.', 'Home', interval '1 day 11 hours'),
    -- 2 days ago
    ('Poke bowl', 9, 'lunch', false, 'Super fresh tuna.', null, 'Island Poke', interval '2 days 5 hours'),
    ('Banana bread', 8, 'snack', true, 'Used up the brown bananas.', 'Flour, 3 ripe bananas, brown sugar, butter, eggs, cinnamon, walnuts.', 'Home', interval '2 days 7 hours'),
    ('Matcha latte', 8, 'drink', true, 'Whisked it properly this time.', 'Ceremonial matcha, oat milk, a little honey.', 'Home', interval '2 days 10 hours'),
    -- 3 days ago
    ('Espresso martini', 7, 'drink', false, 'A well-earned treat.', null, 'The Alley Bar', interval '3 days 2 hours'),
    ('Lentil soup', 8, 'lunch', true, 'Cozy and cheap.', 'Red lentils, carrot, celery, onion, cumin, vegetable stock.', 'Home', interval '3 days 6 hours'),
    ('Scrambled eggs on toast', 6, 'breakfast', true, 'Standard weekday fuel.', null, 'Home', interval '3 days 10 hours'),
    -- 4 days ago
    ('Sushi platter', 9, 'dinner', false, 'Date night.', null, 'Sakura', interval '4 days 3 hours'),
    ('Iced oat latte', 7, 'drink', false, null, null, 'Grind House', interval '4 days 7 hours'),
    ('Blueberry pancakes', 10, 'breakfast', true, 'Sunday best - worth the flip anxiety.', 'Flour, milk, egg, baking powder, fresh blueberries, maple syrup.', 'Home', interval '4 days 10 hours'),
    -- 5 days ago
    ('Popcorn', 5, 'snack', true, 'Movie night. Burnt a little.', null, 'Home', interval '5 days 4 hours'),
    ('Falafel wrap', 8, 'lunch', false, 'That garlic sauce is unreal.', null, 'Aleppo Kitchen', interval '5 days 7 hours'),
    ('Overnight oats', 7, 'breakfast', true, 'Meal prep paid off.', 'Oats, chia, almond milk, peanut butter, sliced banana.', 'Home', interval '5 days 11 hours'),
    -- 6 days ago
    ('Roast chicken dinner', 9, 'dinner', true, 'Proper Sunday roast.', 'Whole chicken, potatoes, carrots, thyme, garlic, lemon.', 'Home', interval '6 days 4 hours'),
    ('Croissant', 8, 'snack', false, 'Flaky perfection.', null, 'Petit Four Bakery', interval '6 days 8 hours')
  ) as e(name, rating, category, is_homemade, notes, recipe, location, ago);

  raise notice 'seeded % demo entries for tester@foodjournal.dev',
    (select count(*) from public.food_entries where user_id = uid);
end $$;
