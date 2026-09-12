# StyleDrop — Setup Guide

Complete setup for building and running the StyleDrop Flutter app. Follow the
steps in order.

---

## 1. Prerequisites (local machine)

| Tool | Version | Check |
|---|---|---|
| Flutter SDK | 3.47.2 stable (Dart 3.9+) | `flutter doctor` |
| JDK | 17 (Temurin recommended) | `java -version` |
| Android SDK | platform 34+, build-tools 34+ | `sdkmanager --list` |
| Node.js | 20+ (only for the Cloudflare proxy) | `node -v` |

---

## 2. google-services.json — REQUIRED (not in this repo)

The Android build **will fail without this file**, and it is intentionally
**NOT committed** to this repository (it contains project-specific Firebase
API keys — never share it publicly).

### How to get it

1. Go to the [Firebase console](https://console.firebase.google.com/) and open
   your project (this app uses project **`styledrop-e0c02`**).
2. **Project settings (⚙️) → General → Your apps → Android app**
   (`com.styledrop.app`).
3. Click **Download google-services.json**.
4. Place the file at exactly this path:
   ```
   android/app/google-services.json
   ```
5. Verify:
   ```bash
   ls -la android/app/google-services.json
   ```

> **Security note:** `android/.gitignore` excludes this file, so it is NOT
> tracked in git — do not force-add it (`git add -f`).

`lib/firebase_options.dart` contains **real config** for the Android app of
project `styledrop-e0c02` (web/iOS entries still need a re-run of
`flutterfire configure` with those platforms registered). If you need to
regenerate it:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=styledrop-e0c02 --platforms=android
```

---

## 3. Enable Firebase Authentication

Firebase console → **Build → Authentication → Sign-in method**, enable:

- [x] **Anonymous** — guest mode
- [x] **Email/Password** — email sign-up / sign-in
- [x] **Google** — requires the SHA-1 step below
- [x] **Apple** — iOS only (required if you ship other social login on iOS)

---

## 4. SHA-1 fingerprint (required for Google Sign-In)

Without a registered SHA-1, the `oauth_client` array in
`google-services.json` stays empty and Google Sign-In fails at runtime.

```bash
# Debug keystore (for testing builds)
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android

# Release keystore (for production builds)
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

Copy the `SHA1:` (and `SHA256:`) lines → Firebase console → **Project settings
→ Your apps → Android app → SHA certificate fingerprints → Add fingerprint**.

Then **re-download `google-services.json`** (step 2) — the fresh file now
contains the OAuth client entries — and replace the old copy.

---

## 5. Firestore database

1. Firebase console → **Build → Firestore Database → Create database**
   (production mode; pick a region close to your users, e.g. `asia-southeast1`).
2. Deploy the bundled rules:
   ```bash
   firebase deploy --only firestore:rules
   ```
   The rules in `firestore.rules` restrict every document to its owning
   `request.auth.uid`.

---

## 6. Cloudflare AI proxy

The app's AI clothing detection calls a secure proxy. Deploy your own:

```bash
# in the proxy/webapp checkout (not this repo)
npm install
npx wrangler pages project create styledrop-proxy
npm run deploy
```

Set secrets on the Pages project:

```bash
echo "$OPENAI_API_KEY" | npx wrangler pages secret put OPENAI_API_KEY
# optional shared secret:
echo "$APP_SHARED_SECRET" | npx wrangler pages secret put APP_SHARED_SECRET
```

Health check: `curl https://styledrop-proxy.pages.dev/api/health`

---

## 7. Build the App Bundle (AAB)

```bash
flutter pub get

flutter build appbundle --release \
  --dart-define=PROXY_BASE_URL=https://styledrop-proxy.pages.dev \
  --dart-define=APP_SHARED_SECRET=
```

Output: `build/app/outputs/bundle/release/app-release.aab`

The Play Store requires an **.aab** (App Bundle) for new apps — use
`flutter build apk` only for local sideloading / quick device tests.

If you omit the `--dart-define`s the app still builds and runs — AI detection
falls back to a local heuristic instead of crashing.

**CI option:** this repo has a GitHub Actions workflow
(`.github/workflows/build-apk.yml`, "Build Android App Bundle (StyleDrop)")
that builds the release AAB on every push to `main` / `master` (plus manual
`workflow_dispatch`) and uploads it as the `styledrop-release-aab` artifact —
no local Flutter SDK needed. If you add the repo secrets
(`ANDROID_UPLOAD_KEY_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`,
`KEY_ALIAS`), CI restores your upload keystore and produces a **signed** AAB
ready for the Play Console; without secrets it falls back to the debug key.

> The workflow runs `flutter pub get` and `flutter build appbundle` at the
> **repo root** — do not add a `working-directory:` to these steps; `pubspec.yaml`
> lives at the repository root.

---

## 8. App icon & splash (optional)

`assets/icon/logo.png` and `assets/icon/splash.png` are already wired into
`pubspec.yaml`. Regenerate platform assets after replacing either file:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## 9. Release signing (Play Store)

`android/app/build.gradle.kts` falls back to the **debug** key when
`android/key.properties` is absent — fine for sideloading, not for Play.

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` (already git-ignored):

```properties
storePassword=<your password>
keyPassword=<your password>
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

**Back up the keystore** — losing it means you can never update the app on
the Play Store under the same listing.

---

## Quick troubleshooting

| Symptom | Fix |
|---|---|
| Build fails: `File google-services.json is missing` | Section 2 — download and place the file |
| Google Sign-In error code 10 | Section 4 — SHA-1 not registered; re-download config |
| `Firebase.initializeApp` fails at runtime | Section 2 — replace the placeholder `firebase_options.dart` via `flutterfire configure` |
| Firestore `permission-denied` | Section 5 — deploy `firestore.rules` |
| AI detection always uses fallback | Section 6 — proxy not deployed or `PROXY_BASE_URL` wrong |
| `pub get` version conflict | `flutter clean && flutter pub get`; do not hand-edit `pubspec.lock` |
