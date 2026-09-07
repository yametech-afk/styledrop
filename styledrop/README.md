# StyleDrop 🎨

**Your AI Wardrobe Stylist** — a Flutter app that catalogs your clothes,
scores outfits with AI, and syncs your wardrobe across devices.

## What's inside

- **Flutter app** (this repo root) — 15 screens: wardrobe, AI outfit
  generator, mix & match, calendar, analytics; Firebase Auth
  (Google / Apple / Email / Guest) with Firestore sync and Hive local
  storage; free/PRO tier gating.
- **GitHub Actions** — `.github/workflows/build-apk.yml` builds a release APK
  on every push to `main` and uploads it as the `styledrop-release-apk`
  artifact.
- **`firestore.rules`** — per-user data isolation for cloud sync.

## Quick start

```bash
flutter pub get
flutter run
```

**Required before sign-in / sync works:** see [SETUP_GUIDE.md](SETUP_GUIDE.md)
for `google-services.json`, SHA-1 fingerprints, and Firestore setup. The
committed `lib/firebase_options.dart` is a placeholder that compiles but does
not authenticate.

## Build a release APK

```bash
flutter build apk --release \
  --dart-define=PROXY_BASE_URL=https://styledrop-proxy.pages.dev \
  --dart-define=APP_SHARED_SECRET=
```

Or run the **Build Android APK (StyleDrop)** workflow from the Actions tab —
no local Flutter SDK needed. Full details: [BUILD_ANDROID.md](BUILD_ANDROID.md).

## Repository layout

```
.github/workflows/   CI: Build Android APK (StyleDrop)
lib/                 Flutter source (screens, services, models)
assets/              Icon, splash, seed item images
android/ ios/ web/ linux/ macos/ windows/   Platform hosts
firestore.rules      Firestore security rules
SETUP_GUIDE.md       Firebase + build setup (start here)
BUILD_ANDROID.md     Local APK build & signing
FIREBASE_SETUP.md    Firebase project walkthrough
FIRESTORE_SETUP.md   Cloud sync setup
PATCH_NOTES.md       Change history
```

## Security notes

- `android/app/google-services.json` and `android/key.properties` are
  git-ignored on purpose — never commit or share them.
- The release signing keystore is **not** in the repo; generate your own for
  Play Store uploads.
