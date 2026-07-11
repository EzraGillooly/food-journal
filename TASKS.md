# TASKS — Food Journal

> Ordered, vertically-sliced task list from [PLAN.md](PLAN.md) / [SPEC.md](SPEC.md).
> Each task: **scope · acceptance criteria · verify**. Check off as completed.
> Legend: `[ ]` todo · `[~]` in progress · `[x]` done · 👤 = needs human action.

Last updated: 2026-07-11.

---

## Phase 0 — Scaffold, schema & deploy pipeline

- [x] **T0.1 — Flutter project + structure**
  Create Flutter app in the repo root; add deps (`flutter_riverpod`, `riverpod_annotation`, `go_router`, `supabase_flutter`, `image_picker`, `flutter_image_compress`); dev deps (`build_runner`, `riverpod_generator`, `flutter_lints`, `riverpod_lint`, `custom_lint`, `integration_test`). Create the `lib/` feature-first skeleton from SPEC §5. Configure `analysis_options.yaml`.
  **AC:** `flutter pub get` and `flutter analyze` both succeed on an empty skeleton.
  **Verify:** run both commands clean.

- [x] **T0.2 — Supabase schema + RLS migration** 👤 (apply step — SQL written; awaiting apply in dashboard)
  Write `supabase/migrations/0001_init.sql`: `food_entries` table (SPEC §5), `enable row level security`, four policies (select/insert/update/delete all `using (auth.uid() = user_id)`), private Storage bucket `entry-photos`, and Storage policies scoping objects to `{user_id}/…`.
  **AC:** SQL applies cleanly; RLS is ON; policies exist for all four verbs.
  **Verify:** apply via Supabase SQL editor; confirm in dashboard that RLS is enabled and policies listed.

- [x] **T0.3 — App bootstrap**
  `main.dart`: `Supabase.initialize` reading `SUPABASE_URL`/`SUPABASE_ANON_KEY` from `--dart-define`; wrap in `ProviderScope`. `app.dart`: `MaterialApp.router` with theme. `router.dart`: `go_router` with **hash** URL strategy + a placeholder home screen.
  **AC:** App boots locally with `flutter run -d chrome` showing a themed placeholder; no hardcoded keys.
  **Verify:** run locally with dart-defines; app renders.

- [x] **T0.4 — GitHub Pages CI** 👤 (workflow written; awaiting Pages enable + repo variables)
  New repo `food-journal`. `web/index.html` with correct `base-href`. `.github/workflows/deploy.yml`: build `flutter build web --release --web-renderer canvaskit --base-href /food-journal/` with dart-defines from repo variables, deploy to Pages on push to `main`.
  **AC:** Push to `main` deploys; the placeholder app loads at the Pages URL and survives a hard refresh (no 404).
  **Verify:** visit deployed URL, refresh on a sub-route.

- **CP-0** ✅ Blank themed app live on Pages · analyze clean · migrations applied.

---

## Phase 1 — Design foundation

- [x] **T1.1 — Theme tokens + presets + fonts**
  Bundle Libre Bodoni + Karla in `assets/fonts/`. Build `AppTheme` with token-based `ThemeData`; implement Soft Blush (primary) + Cottage Cream / Warm Bakery / Garden Fresh presets (SPEC §3).
  **AC:** All colors/fonts come from theme tokens; switching preset restyles a sample screen.
  **Verify:** widget test renders sample screen; visually check each preset.

- [x] **T1.2 — Shared widgets**
  Reusable `RatingControl` (1–10), `CategoryTag`, `MadeBoughtToggle`, primary/secondary buttons — all theme-driven, 44px touch targets, focus states.
  **AC:** Each widget has a widget test and works at mobile width.
  **Verify:** `flutter test` for the shared widgets.

---

## Phase 2 — F1 Authentication (vertical)

- [ ] **T2.1 — Auth state + router guard**
  Riverpod `authProvider` exposing session/user from Supabase `onAuthStateChange`; `go_router` redirect: logged-out → `/login`, logged-in → `/`.
  **AC:** Logged-out users cannot reach any journal route; session persists across reload.
  **Verify:** manual + widget test of redirect logic.

- [ ] **T2.2 — Login screen**
  Email/password login UI wired to Supabase; loading + error states; link to signup/reset.
  **AC:** Valid creds log in and land on feed placeholder; bad creds show a clear inline error.
  **Verify:** log in with a test account on the deployed site.

- [ ] **T2.3 — Sign up screen**
  Email/password signup with email confirmation; post-signup "check your email" state.
  **AC:** New signup creates a user; confirmation email flow completes to a usable session.
  **Verify:** create a fresh account end-to-end.

- [ ] **T2.4 — Password reset + logout**
  Reset-via-email flow; logout action clears session.
  **AC:** Reset email arrives and sets a new password; logout returns to `/login`.
  **Verify:** run both flows on the deployed site.

- **CP-1** ✅ Two accounts can sign up / confirm / log in / log out; guards enforced.

---

## Phase 3 — F2 Create entry (vertical)

- [ ] **T3.1 — Model + repository**
  `FoodEntry` model (SPEC §5 columns); `EntriesRepository` with `create` + `list` against Supabase; Riverpod providers.
  **AC:** Repository insert writes a row with `user_id = auth.uid()`; typed round-trip.
  **Verify:** unit test against a test Supabase project (or mocked client) + one real insert confirmed in dashboard.

- [ ] **T3.2 — Photo pick, compress & upload**
  `image_picker` (camera/gallery, web-compatible) → compress (longest edge ~1600px) → upload to `entry-photos/{user_id}/{entry_id}.jpg`; return `photo_path`.
  **AC:** Selecting a photo on web uploads a compressed object to the user's Storage folder; photo is optional (entry can save without one).
  **Verify:** pick a photo on deployed web; confirm object appears under the correct folder.

- [ ] **T3.3 — Entry form**
  Form with all fields (SPEC §F2): name, rating 1–10, category, made/bought, notes, recipe/ingredients, location (typed), time (defaults now, editable), optional photo. Saves via repository.
  **AC:** A complete entry saves in one action and returns to the feed; required-field validation works.
  **Verify:** create several entries (with and without photo) on the deployed site.

- **CP** entries exist in DB with photos in Storage.

---

## Phase 4 — F3 Feed / journal

- [ ] **T4.1 — Feed list**
  Riverpod provider querying the current user's entries desc by `eaten_at`, grouped by day; entry card (photo, name, category tag, made/bought, rating, time); lazy-loaded images.
  **AC:** Feed shows only the logged-in user's entries, newest first, grouped by day; scrolls smoothly with 100+ items.
  **Verify:** seed 100+ entries; scroll test on mobile width.

- [ ] **T4.2 — RLS isolation test (CP-2 gate)** 👤
  With two accounts each holding entries, verify account B's feed shows none of account A's, and a direct fetch of A's entry id from B returns nothing.
  **AC:** Zero cross-account visibility via UI and via direct id query.
  **Verify:** integration test + manual two-account check on deployed site.

- **CP-2** ✅ **(critical)** Cross-account isolation proven. Do not proceed until green.

---

## Phase 5 — F4 Entry detail

- [ ] **T5.1 — Entry detail screen**
  Full-screen entry view (all fields + full-size photo), reachable from a card via a deep-linkable route `/entry/:id`.
  **AC:** Opening the route as the owner shows the entry; as a non-owner shows not-found (RLS).
  **Verify:** navigate from feed; test the URL directly while logged in as owner and as another user.

---

## Phase 6 — F5 Edit & delete

- [ ] **T6.1 — Edit entry**
  Reuse the entry form pre-filled; update via repository; maintain `updated_at`.
  **AC:** Editing any field persists and reflects in feed/detail.
  **Verify:** edit an entry, confirm changes on reload.

- [ ] **T6.2 — Delete entry**
  Delete with confirm dialog; also remove the Storage photo object.
  **AC:** Deleting removes the row and its photo; feed updates immediately.
  **Verify:** delete an entry with a photo; confirm both row and Storage object are gone.

- **CP-3** ✅ Full CRUD end-to-end on deployed site, photo cleanup included.

---

## Phase 7 — F6 Filter & browse

- [ ] **T7.1 — Filters + search**
  Filter feed by category and made/bought (combinable); search by name.
  **AC:** Filters combine and update the list without full reload; empty states handled.
  **Verify:** apply combined filters + search on a seeded account.

---

## Phase 8 — F7 Theme switch (low priority)

- [ ] **T8.1 — Theme setting**
  Settings control to switch between saved themes; persist choice (local + optional profile).
  **AC:** Switching restyles the whole app live and persists across reloads.
  **Verify:** switch theme, reload, confirm persistence.

- **CP-4** ✅ Filters, search, and theme switching all work at mobile width.

---

## Backlog / deferred (not v1)
- Real geolocation / maps (OpenStreetMap Nominatim or Photon — free, no key).
- Offline-first sync.
- Native iOS/Android release (codebase already Flutter-ready).
