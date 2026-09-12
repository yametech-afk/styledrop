# StyleDrop — Play Store Launch Checklist (repo-specific)

Status as of **2026-09-12**, based on a full file-by-file audit of this
repository. Repo work items are checked; items that must happen in external
consoles (Firebase, Cloudflare, Play, Apple) are marked with their owner.

---

## ✅ Done in the repo (this audit)

- [x] **CI builds an .aab** — `.github/workflows/build-apk.yml` now runs
  `flutter build appbundle --release` (Play requires App Bundles for new
  apps) and can produce a **signed** bundle when the keystore secrets
  (`ANDROID_UPLOAD_KEY_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`,
  `KEY_ALIAS`) are added to repo Secrets.
- [x] **`google-services.json` untracked** — it was committed despite the
  docs claiming otherwise; `git rm --cached` keeps the local file (still
  needed by some tooling) but removes it from the repo going forward.
- [x] **In-app account deletion** (Play Account Deletion policy — a review
  blocker if missing): Profile → Delete account wipes Firestore data
  (batched, ≤500-op chunks) then the Firebase Auth account, then the local
  Hive cache (`AuthService.deleteAccount` → `FirestoreService.deleteAllUserData`
  → `StorageService.clearAll`).
- [x] **Privacy policy draft** — `PRIVACY_POLICY.md` (fill in the
  `[BRACKETED]` values, verify the proxy zero-retention claim, host publicly).
- [x] **Docs corrected** — stale "placeholder firebase_options" and
  "APK artifact" claims updated in README / SETUP_GUIDE / BUILD_ANDROID /
  FIREBASE_SETUP.

## 🔎 Audit findings you should know

- `lib/firebase_options.dart` is **NOT a placeholder anymore** — Android
  entries are real (project `styledrop-e0c02`). But the **web/iOS entries
  reuse the Android appId** (`1:…:android:…`). Web/iOS builds will misbehave
  until you register those platforms in Firebase and re-run
  `flutterfire configure`.
- `android/app/build.gradle.kts` does **not** apply the
  `com.google.gms.google-services` plugin — Firebase initializes purely from
  `firebase_options.dart`. Keep its Android values accurate.
- Release signing is **already wired** in `build.gradle.kts` (reads
  `android/key.properties`, falls back to debug key when absent).
- Auth service hardcodes Google `serverClientId` and Google Sign-In works
  only where the matching SHA-1 fingerprints are registered.
- Tier gating is client-side only (Hive) — trivially bypassable; fine for
  v1, move entitlements server-side before scaling monetization.
- `styledrop/` (nested duplicate app tree), `fixed_files/`,
  `styledrop_gradle_agp_fix.patch`, `BEFORE_AFTER_DIFF.txt` are stale
  artifacts — safe to delete from the repo (not done automatically).

## Phase 1 — App internals (YOU: Firebase console)

- [ ] Create/verify Firebase project **`styledrop-e0c02`**.
- [ ] Enable Auth providers: Google, Apple, Email/Password, Anonymous.
- [ ] Create **Cloud Firestore** in production mode.
- [ ] Deploy rules: `firebase deploy --only firestore:rules` (file:
  `firestore.rules` — per-UID isolation, verified sane in audit).
- [ ] `flutterfire configure --project=styledrop-e0c02` — regenerate
  `firebase_options.dart` and register web/iOS apps (fixes the appId reuse).
- [ ] Add SHA-1 **and** SHA-256 fingerprints (debug keystore now; upload
  keystore + Play App Signing key after Phase 2/4), re-download
  `google-services.json`.

## Phase 2 — Keystore (YOU: local machine)

- [ ] `keytool -genkey -v -keystore ~/styledrop-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
- [ ] Create `android/key.properties` (git-ignored; pattern is in
  SETUP_GUIDE.md §9).
- [ ] **Back up keystore + passwords** somewhere safe (no recovery otherwise).

## Phase 3 — Build the AAB

- [ ] Local: `flutter build appbundle --release --dart-define=PROXY_BASE_URL=https://styledrop-proxy.pages.dev --dart-define=APP_SHARED_SECRET=<secret>`
  → `build/app/outputs/bundle/release/app-release.aab`
- [ ] Or CI: run **Build Android App Bundle (StyleDrop)** after adding the
  four keystore secrets (signed output).
- [ ] Bump `versionCode` in `pubspec.yaml` (`1.0.0+1` → `+2`, `+3`, …) for
  every upload — Play rejects duplicates.

## Phase 4 — Play Developer account (YOU)

- [ ] Register at play.google.com/console ($25 one-time; identity
  verification can take days — start now).
- [ ] Enable **Play App Signing** (default). Add BOTH the upload-key
  fingerprints and the Play-managed app-signing key fingerprints to Firebase,
  then refresh `google-services.json`.

## Phase 5 — Store listing (YOU)

- [ ] Listing assets: name, short (≤80 chars) + full descriptions, 512×512
  icon, 1024×500 feature graphic, 2+ phone screenshots (4–8 recommended).
- [ ] **Privacy policy URL** — publish `PRIVACY_POLICY.md` (fill brackets).
- [ ] Data Safety form: declare account data, photos, location
  (matches the app's real flows).
- [ ] Content rating questionnaire + target audience settings.
- [ ] App access: provide a demo/test login for reviewers.

## Phase 6 — Proxy, testing, submission

- [ ] Deploy the Regolo/Cloudflare proxy (separate repo), set
  `REGOLO_API_KEY` + `APP_SHARED_SECRET` secrets, get the public URL.
  Optional for v1 — the app falls back to local heuristics without it, but
  real AI detection requires it.
- [ ] Upload the .aab to **Internal testing**; verify on real devices:
  Google/Apple/Email/Guest login, cross-device sync, AI detection, free-tier
  limits, account deletion.
- [ ] Closed testing track if the new-account testing requirement applies to
  your account type (12 testers / 14 days — verify current policy in console).
- [ ] Promote to Production and submit for review.

---

### Gotchas (from the audit, watch these)

1. `google-services.json` is now untracked — after adding fingerprints and
   re-downloading it, do **not** `git add -f` it back.
2. The workflow file is still named `build-apk.yml` (renaming would break
   cached Actions references) — the *job* name and output are AAB now.
3. Web/iOS `firebase_options.dart` entries are wrong until reconfigured —
   ship Android first or fix before any web/iOS release.
4. Photos never sync to the cloud (by design, 1 MB doc cap) — a restored
   device gets metadata but not photo bytes until Firebase Storage (Phase B+).
5. After deleting an account, sign-up with the same email works again
   (fresh account) — seeded demo items will reappear; that is by design.
