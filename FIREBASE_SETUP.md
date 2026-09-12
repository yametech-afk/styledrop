# StyleDrop — Firebase Setup Guide (Phase A: Authentication)

This guide takes you from the current code (which **compiles** with placeholder
config) to a **fully working, real Firebase login** on Web, Android and iOS.

> **What's already done in the code**
> - `firebase_core`, `firebase_auth`, `google_sign_in`, `sign_in_with_apple`,
>   `crypto` are in `pubspec.yaml`.
> - `lib/services/auth_service.dart` — real Google / Apple / Email / Guest sign-in.
> - `lib/providers/profile_provider.dart` — identity sourced from the Firebase user.
> - `lib/main.dart` — `Firebase.initializeApp()` + `StreamBuilder` auth routing.
> - `lib/screens/login_screen.dart` — buttons wired to `AuthService`.
> - `lib/firebase_options.dart` — **real Android config for project
>   `styledrop-e0c02`**; regenerate via Step 3 if the project changes (web/iOS
>   entries still carry the Android appId until those platforms are
>   registered and configured).
>
> You only need to do the account/console steps below.

---

## Step 0 — Prerequisites (one time)

```bash
# Node (for the Firebase CLI) and the FlutterFire CLI
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# Make sure the dart pub global bin is on your PATH, e.g. add to ~/.zshrc:
export PATH="$PATH":"$HOME/.pub-cache/bin"

firebase login          # opens a browser, sign in with your Google account
```

---

## Step 1 — Create the Firebase project

1. Go to <https://console.firebase.google.com> → **Add project**.
2. Name it e.g. `styledrop-prod`. (Analytics optional.)
3. Wait for it to finish provisioning.

---

## Step 2 — Enable the sign-in methods you want

In the console: **Build → Authentication → Get started → Sign-in method**, then
enable:

| Provider              | Notes |
|-----------------------|-------|
| **Email/Password**    | Enable. (Optional: also enable "Email link".) |
| **Google**            | Enable; pick a support email. Works out of the box on Web/Android; iOS needs the reversed client ID (Step 6). |
| **Apple**             | Enable. Required by Apple if you ship Google/other social login on iOS. Needs an Apple Developer account (Step 7). |
| **Anonymous**         | Enable — this powers "Continue as Guest". |

---

## Step 3 — Generate the real `firebase_options.dart`

From the project root (`styledrop/`):

```bash
flutterfire configure --project=styledrop-prod
```

- Select the platforms you target (Web, Android, iOS).
- This **overwrites** `lib/firebase_options.dart` with your real keys and also
  drops platform config files (see below). Commit the regenerated file.

> The Android entries in `lib/firebase_options.dart` already carry the real
> project values. Re-run `flutterfire configure` only when adding web/iOS or
> changing projects. Android does not use the `google-services` Gradle plugin
> in this repo — Firebase initializes from `firebase_options.dart` alone, so
> keep that file's Android values accurate.

---

## Step 4 — Platform config files (created by Step 3, verify they exist)

- **Android:** `android/app/google-services.json`
- **iOS:** `ios/Runner/GoogleService-Info.plist`

`flutterfire configure` usually adds these. If not, download them from
**Project settings → Your apps** and place them at the paths above.

---

## Step 5 — Android specifics

1. **Min SDK.** Firebase Auth needs `minSdkVersion 21+`. In
   `android/app/build.gradle`:
   ```gradle
   defaultConfig {
       minSdkVersion 23   // 21+ is fine; 23 recommended
   }
   ```
2. **Google sign-in fingerprint.** For Google login on a real device/build,
   add your app's SHA-1 (and SHA-256) fingerprints in
   **Firebase console → Project settings → Your Android app → Add fingerprint**:
   ```bash
   # debug keystore fingerprint
   keytool -list -v -alias androiddebugkey \
     -keystore ~/.android/debug.keystore -storepass android -keypass android
   ```
   Then re-run `flutterfire configure` (or re-download `google-services.json`).

---

## Step 6 — iOS specifics (Google)

Google sign-in on iOS needs the **reversed client ID** URL scheme.

1. Open `ios/Runner/GoogleService-Info.plist`, copy the `REVERSED_CLIENT_ID`.
2. In `ios/Runner/Info.plist` add:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>REVERSED_CLIENT_ID_GOES_HERE</string>
       </array>
     </dict>
   </array>
   ```
3. Set the iOS bundle id consistently (Xcode → Runner → General → Bundle
   Identifier) and match it in the Firebase iOS app + `firebase_options.dart`.

---

## Step 7 — Apple Sign-In (iOS)

1. In **Xcode → Runner → Signing & Capabilities → + Capability → Sign in with
   Apple**.
2. In your [Apple Developer account](https://developer.apple.com/account):
   - Enable **Sign in with Apple** on your App ID.
   - Create a **Services ID** + key if you also want Apple login on the Web.
3. In Firebase → Authentication → Apple provider, fill in the **Services ID**,
   **Apple Team ID**, **Key ID**, and the **private key** (for Web/OAuth flows).

> The code already does the secure **nonce + SHA-256** hashing Apple requires
> (see `AuthService.signInWithApple`).

---

## Step 8 — Web specifics

- `flutterfire configure` writes the web config into `firebase_options.dart`.
- Google sign-in on web uses a Firebase **popup** (already handled by
  `AuthService` via `signInWithPopup`).
- Add your dev/production domains under
  **Authentication → Settings → Authorized domains** (e.g. `localhost`,
  `your-app.pages.dev`).

---

## Step 9 — Run it

```bash
flutter pub get

# Web
flutter run -d chrome

# Android / iOS (device or simulator)
flutter run
```

Test each button:
- Email → Sign up, then sign out, then sign in.
- Google → account picker → returns signed in.
- Apple (iOS only) → returns signed in; name captured on first sign-in.
- Guest → anonymous session; profile shows "Guest account".
- Sign out from Profile → returns to the login screen automatically.

---

## How the pieces fit together

```
main()  ──►  Firebase.initializeApp(DefaultFirebaseOptions.currentPlatform)
                     │
              AppRoot (StreamBuilder on AuthService.authStateChanges)
                     │
        user == null ├──►  LoginScreen  ──► AuthService.signIn* ──┐
        user != null └──►  MainShell                              │
                     ▲                                            │
                     └──────── auth stream emits new user ────────┘
```

- **No manual navigation** on login/logout — the `StreamBuilder` reacts to the
  Firebase auth stream.
- `ProfileProvider.syncWithFirebaseUser()` overlays the Firebase identity
  (name/email/photo/guest) onto the local Hive profile, which still stores
  Style DNA + subscription tier.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `FirebaseException: No Firebase App '[DEFAULT]'` | You didn't run Step 3, or `firebase_options.dart` still has `REPLACE_ME_*`. |
| Google login returns immediately / cancels on Android | Missing SHA-1 fingerprint (Step 5.2). |
| `MissingPluginException` after adding deps | Full stop & restart the app (not hot reload). |
| Apple button errors in simulator | Test Apple sign-in on a **real device** with a signed-in Apple ID. |
| Web: `auth/unauthorized-domain` | Add the domain under Authentication → Settings → Authorized domains (Step 8). |

---

## What's next — Phase B (Firestore cloud sync)

Once auth works, Phase B adds a `FirestoreService` + repository layer so a
user's wardrobe/outfits sync to the cloud (Firestore as source of truth, Hive
as offline cache) with security rules scoping data to `request.auth.uid`. Say
the word and I'll build it.

---

## 🔄 StyleDrop rebrand notes (2026-09-07)

### Cloudflare Pages project URL
An existing Pages project URL (e.g. `https://fitai-proxy.pages.dev`) **cannot be renamed** after creation. For new deployments, create a fresh project so the URL matches the brand; existing deployments keep working on their old URL until migrated:

```bash
npx wrangler pages project create styledrop-proxy
npm run deploy
```

### Firebase project ID
Firebase **project IDs are permanent and cannot be renamed**. This app is wired to the existing project **`styledrop-e0c02`** (see `android/app/google-services.json`, downloaded but git-ignored). Reuse it via `flutterfire configure --project=styledrop-e0c02`. After configure, re-download `google-services.json` and regenerate `firebase_options.dart` — the placeholder in this repo must be replaced before real sign-in/sync works. See [SETUP_GUIDE.md](SETUP_GUIDE.md) for the full walkthrough.
