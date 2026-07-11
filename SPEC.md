# SPEC — Food Journal

> A minimalist food journal web + future mobile app.
> Log what you eat and drink through the day: photo, name, rating, notes, recipe/ingredients, category, location, made-vs-bought, and time.
> Built for a friend first, but multi-user from day one.

Status: **Draft — pending approval.**
Last updated: 2026-07-11.

---

## 1. Objective

### What we're building

A personal food journal.
Throughout the day a user snaps a photo of a meal or drink and logs it with a few quick fields.
Over time they build a scrollable, photo-forward diary of everything they've eaten, which they can browse, filter, and revisit.

The feel is calm and minimal — soft, editorial, cottagecore.
Logging one entry should take well under a minute on a phone.

### Target users

- **Primary:** the friend this is being built for. Logs food daily, mostly on her phone.
- **Secondary:** anyone who signs up. The app is multi-user; each account sees only its own journal.

### Success looks like

- She actually uses it every day because logging is fast and the app is pretty.
- Entries sync across her phone and laptop (same account, same data).
- Photos are preserved and load quickly.
- Zero chance of one user seeing another user's entries.

### Explicit non-goals (v1)

- No social feed, following, sharing, or comments.
- No calorie/macro tracking or nutrition database.
- No AI food recognition.
- No native app store release yet (the codebase is built so this is possible later).
- No offline-first sync engine (basic connectivity assumed; graceful errors when offline).

---

## 2. Tech stack

| Layer | Choice | Notes |
|---|---|---|
| Language | **Dart 3.11+** | Installed: 3.11.5 |
| Framework | **Flutter 3.41+** (stable) | Installed: 3.41.9. Web now; iOS/Android later with the same codebase. |
| Target (v1) | **Flutter Web**, CanvasKit renderer | CanvasKit chosen for pixel-consistency with the future mobile build. |
| State management | **Riverpod** (`flutter_riverpod`, `riverpod_annotation`) | Testable, compile-safe, no `BuildContext` coupling. |
| Backend | **Supabase** (`supabase_flutter`) | Auth + Postgres + Storage, all from the client. |
| Auth | Supabase Auth — email/password + magic link | Email confirmation on. |
| Database | Supabase Postgres | Row Level Security is the ONLY thing isolating users (see §7). |
| File storage | Supabase Storage | Private bucket `entry-photos`, per-user folders. |
| Photo capture | `image_picker` | Works on web + mobile (camera/gallery). |
| Image compression | `flutter_image_compress` (mobile) / canvas resize (web) | Compress before upload; cap longest edge ~1600px. |
| Routing | **go_router** with hash strategy | `#/`-style URLs so GitHub Pages refresh doesn't 404. |
| Hosting | **GitHub Pages**, new dedicated repo `food-journal` | Static build; CI publishes on push to `main`. |
| CI/CD | GitHub Actions | Build Flutter web with correct `base-href`, deploy to Pages. |
| Testing | `flutter_test` + `integration_test` | Unit/widget + E2E. |
| Linting | `flutter_lints` (+ `custom_lint`/`riverpod_lint`) | `flutter analyze` clean is required. |

### Consequences of a static, client-only host (read before coding)

- **There is no server.** All logic runs in the browser/app. Any secret shipped is public.
- The Supabase **anon key is safe to ship** (it's designed to be public). The **service-role key must NEVER be in the client or repo.**
- Because there's no server to gate data access, **security is enforced entirely by Postgres Row Level Security policies.** This is the single most important correctness surface in the app. See §5 (schema) and §7 (boundaries).

---

## 3. Design system

### Chosen theme: **Soft Blush** (primary)

Dusty rose + cream, elegant serif display. Feminine, calm, editorial.

| Token | Hex | Role |
|---|---|---|
| `--bg` | `#F6EEEA` | App background / cream |
| `--surface` | `#FFFFFF` | Cards, sheets |
| `--primary` | `#C98A93` | Dusty rose — accents, ratings, active states |
| `--secondary` | `#D9B48A` | Warm sand — secondary accents, tags |
| `--ink` | `#6B3B42` | Deep rose-brown — headings, primary text |
| `--ink-muted` | `#9A7A80` | Muted text, captions |
| `--tag-bg` | `#F2E2E5` | Tag/pill background |
| `--tag-ink` | `#8A4A56` | Tag/pill text |

- **Display / headings font:** Libre Bodoni (serif).
- **Body / UI font:** Karla (sans).
- Fonts bundled locally via `pubspec.yaml` (no runtime Google Fonts fetch — faster, works offline, GitHub-Pages friendly).

### Saved alternate themes (implement as swappable `AppTheme` presets)

Keep these defined in the theme layer so switching is a one-line change if she prefers another look.

| Theme | bg | primary | secondary | ink | Heading / Body font |
|---|---|---|---|---|---|
| **01 Cottage Cream** | `#FBF8F0` | `#7C8A5A` | `#B6A16A` | `#3F4A32` | Playfair Display / Karla |
| **02 Warm Bakery** | `#FAF6F2` | `#C08552` | `#E0B87A` | `#5A4632` | Fraunces / Nunito Sans |
| **04 Garden Fresh** | `#F4F6F1` | `#6E9457` | `#E3A94E` | `#33482F` | Cormorant Garamond / Public Sans |

### Design principles

- Photo-forward: the food photo is the hero of every entry card.
- Generous whitespace, hairline dividers, soft rounded corners (12–16px on cards).
- No hardcoded colors in widgets — always reference theme tokens.
- Minimum 16px body text; 44×44px minimum touch targets.
- Respect reduced-motion; keep transitions 150–300ms.
- SVG/icon set, never emoji as icons.

---

## 4. Core features & acceptance criteria

### F1 — Authentication (multi-user)
- Sign up with email + password; email confirmation required.
- Log in / log out; session persists across reloads.
- Password reset via email.
- **AC:** A logged-out user cannot reach any journal screen. A logged-in user lands on their own feed. Two different accounts never see each other's data.

### F2 — Create an entry
Fields, per the friend's request:
- **Photo** (capture or pick; optional but encouraged) — required to compress + upload.
- **Name** (text, required).
- **Rating** 1–10 (required).
- **Category** — breakfast / lunch / dinner / snack / drink (required, single select).
- **Made or bought** (toggle, required).
- **Notes** (free text, optional).
- **Ingredients / recipe** (free text, optional).
- **Location** (text tag, optional — v1 is a typed place name, not a map).
- **Time** — defaults to now, editable (date + time).
- **AC:** A complete entry saves in one action, uploads the photo, and appears at the top of the feed immediately.

### F3 — Feed / journal view
- Reverse-chronological list of the user's entries, grouped by day.
- Each card shows photo, name, category tag, made/bought, rating, time.
- **AC:** Scrolls smoothly with 100+ entries; images lazy-load.

### F4 — Entry detail
- Full-screen view of a single entry with all fields and the full-size photo.
- **AC:** Reachable from a feed card; shareable via a URL that (when logged in as owner) opens that entry.

### F5 — Edit & delete
- Edit any field of an existing entry; delete an entry (with confirm).
- **AC:** Deleting an entry also removes its photo from Storage.

### F6 — Filter & browse
- Filter feed by category and by made/bought; optional search by name.
- **AC:** Filters combine and update the list without a full reload.

### F7 — Theme (nice-to-have, low priority)
- Setting to switch between the saved themes.
- **AC:** Switching theme restyles the whole app live and persists the choice.

### Priority order
F1 → F2 → F3 → F4 → F5 → F6 → F7.

---

## 5. Project structure

New dedicated repo: `food-journal`.

```
food-journal/
├── .github/workflows/deploy.yml   # build Flutter web + deploy to Pages
├── SPEC.md
├── PLAN.md                        # (created by /plan)
├── TASKS.md                       # (created by /plan)
├── pubspec.yaml
├── analysis_options.yaml          # flutter_lints + riverpod_lint
├── web/                           # index.html (base-href), manifest, icons
├── assets/
│   └── fonts/                     # Libre Bodoni, Karla (+ alternates)
├── supabase/
│   ├── migrations/                # SQL: tables, RLS policies, storage policies
│   └── seed.sql                   # optional local seed
├── lib/
│   ├── main.dart                  # bootstrap: Supabase.init, ProviderScope, router
│   ├── app.dart                   # MaterialApp.router, theme wiring
│   ├── router.dart                # go_router (hash strategy) + auth redirect
│   ├── core/
│   │   ├── theme/                 # tokens, AppTheme presets (Soft Blush + alternates)
│   │   ├── supabase/              # client provider, auth provider
│   │   └── utils/                 # image compression, formatting
│   ├── features/
│   │   ├── auth/                  # login, signup, reset — widgets + controllers
│   │   ├── entries/
│   │   │   ├── data/              # FoodEntry model, repository (Supabase queries)
│   │   │   ├── application/       # Riverpod providers/controllers
│   │   │   └── presentation/      # feed, entry_form, entry_detail widgets
│   │   └── settings/              # theme switcher
│   └── shared/                    # reusable widgets (buttons, tags, rating control)
├── test/                          # unit + widget tests (mirror lib/)
└── integration_test/              # E2E flows
```

### Data model (`food_entries` table)

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | `default gen_random_uuid()` |
| `user_id` | uuid | `references auth.users(id)`, `default auth.uid()`, not null |
| `name` | text | not null |
| `rating` | int | check between 1 and 10, not null |
| `category` | text | check in (breakfast,lunch,dinner,snack,drink) |
| `is_homemade` | boolean | true = made, false = bought |
| `notes` | text | nullable |
| `recipe` | text | ingredients / recipe, nullable |
| `location` | text | nullable |
| `photo_path` | text | Storage object path, nullable |
| `eaten_at` | timestamptz | defaults to now, editable |
| `created_at` | timestamptz | `default now()` |
| `updated_at` | timestamptz | maintained on edit |

- **RLS enabled**, with policies so a row is readable/writable ONLY when `user_id = auth.uid()`. Applies to select, insert, update, delete.
- **Storage:** private bucket `entry-photos`; objects stored under `{user_id}/{entry_id}.jpg`; storage policy restricts access to the owning user's folder.

---

## 6. Commands

Assumes Flutter/Dart on PATH (verified installed).

| Task | Command |
|---|---|
| Install deps | `flutter pub get` |
| Run (web, dev) | `flutter run -d chrome` |
| Analyze / lint | `flutter analyze` |
| Format | `dart format .` |
| Unit + widget tests | `flutter test` |
| E2E tests (web) | `flutter test integration_test` |
| Build web (Pages) | `flutter build web --release --web-renderer canvaskit --base-href /food-journal/` |
| Codegen (Riverpod) | `dart run build_runner build --delete-conflicting-outputs` |

- **Supabase migrations** are applied via the Supabase dashboard SQL editor or the Supabase CLI (`supabase db push`). SQL lives in `supabase/migrations/`.

### Environment config
- `SUPABASE_URL` and `SUPABASE_ANON_KEY` supplied at build via `--dart-define` (and as GitHub Actions repo variables for CI).
- **Never** commit a `.env` or any key file. The anon key is public-safe but still passed via define, not hardcoded.

---

## 7. Boundaries

### Always do
- Enforce user data isolation through **Supabase RLS on every table and Storage bucket** — treat the client as untrusted.
- Reference **theme tokens**, never hardcoded hex, in widgets.
- Compress images **before** upload; set descriptive alt/semantics on images.
- Keep `flutter analyze` clean and `dart format` applied before every commit.
- Write a test for each feature's core acceptance criterion (see §4).
- Default new entries' `eaten_at` to now but keep it editable.
- Use the friend's exact field set (§F2) — name, rating 1–10, category, made/bought, notes, recipe/ingredients, location, time, photo.

### Ask first
- Adding any new third-party dependency beyond those listed in §2.
- Any schema change after the initial migration is approved.
- Changing the primary theme away from Soft Blush.
- Adding features outside the v1 list (§4) — e.g. maps, nutrition, sharing.
- Anything that would put data access decisions in client code instead of RLS.

### Never do
- **Never** ship or commit the Supabase **service-role key** (or any secret) — client + repo are public.
- Never read `.env`, `.env.*`, or any secrets file.
- Never disable or weaken RLS to "make a query work."
- Never store another user's data path or expose cross-user queries.
- Never use emoji as UI icons or hardcode off-theme colors/fonts.
- Never add a `Co-Authored-By: Claude` trailer to commits.

---

## Open questions (none blocking)
- Exact GitHub Pages URL / custom domain — default `ezragillooly.github.io/food-journal/` unless a domain is chosen.
- Whether "location" should upgrade to real geolocation/map in a later version (deferred).
