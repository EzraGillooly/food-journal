# PLAN — Food Journal

> Narrative implementation plan derived from [SPEC.md](SPEC.md).
> Work is sliced **vertically**: each task delivers one complete, verifiable path (UI → state → data), not a horizontal layer.
> The task checklist lives in [TASKS.md](TASKS.md).

Last updated: 2026-07-11.

---

## Guiding principles

1. **RLS-first.** Security is the sole responsibility of Postgres Row Level Security (there is no server). Every data task ships with the policy that protects it, and every feature phase ends by proving isolation between two accounts.
2. **Vertical slices.** A task isn't "build the model layer" — it's "a user can create an entry and see it saved." Each task is demoable.
3. **Deploy early, deploy always.** GitHub Pages deploy is wired up in Phase 0, so every later phase is verifiable on the real host, not just localhost.
4. **Thin before rich.** The entry form lands as a working save first, then gains photo upload, then polish.

---

## Dependency graph

```
Phase 0  Scaffold + Supabase schema + CI/Pages
            │
Phase 1  Design foundation (theme tokens, shared widgets)
            │
Phase 2  F1 Auth ──────────────┐   (needs auth session before any user data)
            │                  │
Phase 3  F2 Create entry ──────┤   (needs model + repo + storage)
            │                  │
Phase 4  F3 Feed ──────────────┘   ← CHECKPOINT: cross-account RLS isolation proven here
            │
Phase 5  F4 Entry detail (deep-linkable)
            │
Phase 6  F5 Edit + Delete (delete also removes Storage object)
            │
Phase 7  F6 Filter + search
            │
Phase 8  F7 Theme switch (low priority, nice-to-have)
```

Auth (P2) gates everything user-scoped. Create (P3) and Feed (P4) form the core loop. P5–P8 layer onto existing entries and can be reordered if priorities shift.

---

## Checkpoints (human review / verify gates)

- **CP-0 — after Phase 0:** A blank, Soft-Blush-themed app is live on GitHub Pages; `flutter analyze` clean; migrations applied in Supabase.
- **CP-1 — after Phase 2:** Two separate accounts can sign up, confirm, log in, and log out. Router guards block logged-out access.
- **CP-2 — after Phase 4 (most important):** With two accounts each holding entries, account B's feed shows **zero** of account A's entries and cannot fetch them by direct id. This proves RLS. **Do not proceed past here until this passes.**
- **CP-3 — after Phase 6:** Full CRUD works end-to-end on the deployed site, including photo cleanup on delete.
- **CP-4 — after Phase 8:** Filters, search, and theme switching all work on mobile-width viewport.

---

## What requires the human (not automatable)

- Creating the Supabase project and the GitHub repo (I'll provide exact steps + the SQL/CI files).
- Supplying `SUPABASE_URL` and `SUPABASE_ANON_KEY` as `--dart-define` values locally and as GitHub Actions repo variables. (Anon key is public-safe; still passed via define, never hardcoded.)
- Enabling GitHub Pages on the repo and setting source to GitHub Actions.
- Deciding a free maps/geocoding path later (see note below). v1 location stays a typed text field.

### Free location note (deferred, non-blocking)
Google Maps Platform requires a billing account even for its free credit. A genuinely free, no-billing, no-key alternative for place-name autocomplete later is **OpenStreetMap Nominatim** (respect its usage policy) or **Photon**. v1 ships plain typed text; this is a Phase-8+ enhancement only if wanted.

---

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| RLS misconfigured → data leak | Dedicated isolation test at CP-2; RLS policy written in the same task as each table op. |
| Flutter web image_picker quirks | Validate photo capture on web early (Phase 3, T3.2) before building form polish. |
| GitHub Pages routing 404 on refresh | Hash routing via go_router + correct `base-href`, validated at CP-0. |
| CanvasKit initial load weight | Accepted trade-off for fidelity; monitor, add loading splash in web/index.html. |
| Secret leakage | anon-key-only in client; service-role key never in repo/CI; `.env` never read. |

---

## Definition of done (per task)

A task is done when: its acceptance criteria pass, `flutter analyze` is clean, `dart format` applied, its test(s) pass, and — for anything user-facing — it's verified on a mobile-width viewport.
