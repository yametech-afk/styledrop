## 🔄 Rebrand: FitAI → StyleDrop (2026-09-07)

This build carries the full brand rename executed on 2026-09-07:

- **Display name:** StyleDrop
- **Package name / Bundle ID:** com.styledrop.app
- **Tagline:** “Your AI Wardrobe Stylist”
- **Flutter package:** styledrop
- Every code, config, doc, and comment reference to FitAI / fitai / fit-ai /
  WardrobeWizard / wardrobewizard / flutter_app was renamed
  (see ../BRAND_CHANGELOG.md for the file-by-file diff).

---

# StyleDrop — Patch Notes & Setup

This is your StyleDrop Flutter project with security & quality fixes applied by the
code review. Below is exactly what changed and how to wire up the new secure
backend.

## 🔥 NEW — Firebase Authentication (Phase A)

Real login has replaced the old mock (which hardcoded a fake email). The app now
uses **Firebase Auth**: Google, Apple, Email/Password, and Anonymous "Guest".

**Files added/changed:**
- `pubspec.yaml` — added `firebase_core`, `firebase_auth`, `google_sign_in`,
  `sign_in_with_apple`, `crypto`.
- `lib/services/auth_service.dart` *(new)* — all sign-in methods + friendly
  error mapping + Apple nonce/SHA-256.
- `lib/providers/profile_provider.dart` — identity now sourced from the signed-in
  Firebase user; `syncWithFirebaseUser()`; `logout()` calls Firebase sign-out.
- `lib/main.dart` — `Firebase.initializeApp()` + a `StreamBuilder` on
  `authStateChanges` that auto-routes between LoginScreen and MainShell.
- `lib/screens/login_screen.dart` — buttons wired to real `AuthService`; full
  email sign-in/sign-up form with password + forgot-password.
- `lib/screens/profile_screen.dart` — logout simplified (stream handles nav).
- `lib/firebase_options.dart` *(new, placeholder)* — replace via
  `flutterfire configure`.

**➡️ To make login actually work, follow `FIREBASE_SETUP.md`.** The code
compiles now with placeholder config, but `Firebase.initializeApp()` will fail
at runtime until you run `flutterfire configure` with your own project.

Status: `flutter analyze` → **No issues found**.

## ☁️ NEW — Firestore Cloud Sync (Phase B)

A user's wardrobe, outfits, and Style DNA now sync to the cloud and appear on
every device they sign into. Built on Phase A auth.

**Files added/changed:**
- `pubspec.yaml` — added `cloud_firestore`.
- `lib/services/firestore_service.dart` *(new)* — per-user Firestore read/write
  (`users/{uid}/wardrobe`, `.../outfits`, `.../meta/profile`); strips image
  bytes to stay under the 1 MB doc limit.
- `lib/services/sync_repository.dart` *(new)* — the single write gateway:
  **Hive = offline cache, Firestore = source of truth.** Writes go local-first
  then mirror to the cloud; sign-in pulls the cloud library and pushes up any
  local-only leftovers.
- `lib/providers/wardrobe_provider.dart` & `outfit_provider.dart` — writes now
  route through `SyncRepository`.
- `lib/main.dart` — `AppRoot` pulls from the cloud on sign-in (with a
  "Syncing your wardrobe…" splash) and refreshes the providers.
- `firestore.rules` *(new)* — every doc scoped to its owner's UID; no account
  can read another's data.

Behaviour: guests (anonymous) stay **local-only**; upgrading a guest to a real
account migrates their local library up. Offline writes cache locally and
re-sync later.

**➡️ To turn cloud sync on, follow `FIRESTORE_SETUP.md`** (create the Firestore
DB + deploy `firestore.rules`).

Status: `flutter analyze` → **No issues found**; `flutter test` → **21 passed**.

## What changed

### 🔐 Security: API key removed from the app (biggest fix)
**File:** `lib/services/clothing_detection_service.dart`

Before, the app embedded `GSK_TOKEN` via `--dart-define` and called the LLM
directly. That key was **extractable from the shipped app binary**. Now the app
calls **your own backend proxy** (`POST /api/detect`) which holds the key
server-side. The app only knows a public URL and (optionally) a rotatable
shared secret.

The secure proxy source lives in the parent `webapp/` project (Cloudflare
Worker + Hono). Deploy it, then point the app at it (see "Build" below).

### 🐛 Bug #4 — Deterministic outfit scores
**File:** `lib/services/ai_stylist_service.dart`

Each score function added `_rng.nextInt(...)`, so the *same outfit* scored
differently every generation, making rankings unstable. Replaced with
`_stableVariance()` — a deterministic per-outfit hash. Outfit *selection* is
still varied; only the *scoring* is now stable and testable.

### 🐛 Bug #5 — BuildContext safety after await
**Files:** `ai_generator_screen.dart`, `home_screen.dart`, `add_item_screen.dart`

Added `if (!mounted) return;` guards after `await showPaywall(...)`.

### 🐛 Bug #6 — No more silent failures / latent crash
**Files:** `outfit_provider.dart`, `wardrobe_provider.dart`

`planOutfit` / `markWornToday` / `renameOutfit` used a nested `firstWhere`
that threw an **uncaught** `StateError` if the id wasn't in either list.
Replaced with a null-safe `_findOutfit()` helper that logs and no-ops.

### 🐛 Bug #12 — "Automatic weather" toggle now works
**File:** `ai_generator_screen.dart`

When the toggle is OFF, generation now runs with neutral weather (24°C, "Mild")
instead of always applying the live reading.

### 🧪 Tests added
- `test/ai_stylist_service_test.dart` — never-invents-items, determinism,
  dedup, shoe filter, cold-weather outerwear, remix, missing-item suggestions.
- `test/usage_limit_service_test.dart` — tier gating & caps.
- `test/widget_test.dart` — replaced the crashy full-app pump with model
  round-trip tests.

Run: `flutter test`

## Build (pointing the app at your proxy)

After deploying the proxy (e.g. to `https://styledrop-proxy.pages.dev`):

```bash
flutter build apk \
  --dart-define=PROXY_BASE_URL=https://styledrop-proxy.pages.dev \
  --dart-define=APP_SHARED_SECRET=your-optional-shared-secret
```

If `PROXY_BASE_URL` is omitted, the app still runs and gracefully falls back to
the local heuristic detector (no crash), so debug builds work with no config.

## Still recommended (not done here — needs your accounts)
1. **Real auth** (Firebase Auth / Sign in with Apple) — login is still mocked.
2. **Real payments** (RevenueCat) — the paywall still just flips the tier flag.
3. **Cloud sync** — wardrobe is local-only (Hive); lost if the device is lost.
4. **Rebrand** — Android label is still `styledrop`; README is the default.
