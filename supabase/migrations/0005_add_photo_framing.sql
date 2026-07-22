-- Per-entry framing for how the photo is cropped/positioned in the small card
-- thumbnails (Journal, Home "Lately", Calendar). The detail view and cover keep
-- showing the full photo.
--
-- focus_x / focus_y: alignment of the visible window, each in [-1, 1]
--   (0,0 = centered, matching the previous plain center-crop).
-- zoom: scale relative to "cover" fill; 1 = cover (default), <1 reveals more of
--   the photo (zoom out), >1 crops in further.

alter table public.food_entries
  add column if not exists photo_focus_x real not null default 0,
  add column if not exists photo_focus_y real not null default 0,
  add column if not exists photo_zoom real not null default 1;
