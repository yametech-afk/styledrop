# Building the StyleDrop Android APK

## Requirements (local machine)

- Flutter SDK **3.47.2 stable** (Dart 3.9+)
- JDK **17** (Eclipse Temurin recommended)
- Android SDK with `platforms;android-34`, `build-tools;34.0.0` (or newer)
  - Add to `~/.bashrc` / `~/.zshrc`:
    ```bash
    export ANDROID_HOME=$HOME/Android/Sdk
    export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
    ```
- Git

## One-time checks

```bash
flutter doctor
# Fix anything marked [✗]. At minimum you need the "Android toolchain" ✔.
```

## 1. Firebase config (best effort)

The repo ships with a **placeholder** `lib/firebase_options.dart` (compile-safe, runtime
falls back gracefully). To use real Firebase Auth / Firestore:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=styledrop-wardrobe --platforms=android
```

This rewrites `lib/firebase_options.dart` with your real project IDs and API keys.
Then add your Android app's SHA-1 debug/release fingerprints in the Firebase console:
`Project settings > Your apps > Android app > Add fingerprint`.

## 2. Release signing (recommended, not required to install)

By default `android/app/build.gradle.kts` signs release builds with the **debug** key,
which is fine for personal sideloading but not Play Store. For a proper release key:

```bash
# 1) Generate keystore (password: pick your own)
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload -storepass changeit -keypass changeit \
  -dname "CN=StyleDrop, OU=Dev, O=StyleDrop, L=Manila, C=PH"

# 2) Create android/key.properties
echo "storePassword=changeit"   > android/key.properties
echo "keyPassword=changeit"     >> android/key.properties
echo "keyAlias=upload"          >> android/key.properties
echo "storeFile=$HOME/upload-keystore.jks" >> android/key.properties
```

Then uncomment/add the `signingConfigs.release` block in
`android/app/build.gradle.kts` and point `buildTypes.release.signingConfig` to it.

## 3. Build the APK

```bash
cd styledrop
flutter pub get
flutter build apk --release \
  --dart-define=PROXY_BASE_URL=https://styledrop-proxy.pages.dev \
  --dart-define=APP_SHARED_SECRET=
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## 4. Verify the APK

```bash
# With Android build-tools on PATH:
aapt dump badging build/app/outputs/flutter-apk/app-release.apk | head -5

# Or with unzip:
unzip -l build/app/outputs/flutter-apk/app-release.apk | tail -5

sha256sum build/app/outputs/flutter-apk/app-release.apk
```

## 5. Circular build in CI (alternative, no local setup)

A GitHub Actions workflow is included at
`.github/workflows/build-apk.yml`. Push the repo to GitHub, open
**Actions → Build Android APK (StyleDrop) → Run workflow**, then download the
`styledrop-release-apk` artifact.

## Troubleshooting

| Problem | Fix |
|---|---|
| `flutter: command not found` | Add `flutter/bin` to `PATH` or use `fvm` |
| Gradle downloads very slowly | Use a wired connection; first build downloads ~1–2 GB |
| `Failed to find build tools` | `sdkmanager "build-tools;34.0.0" "platforms;android-34"` then `flutter doctor` |
| `Unsupported Java version` | Install JDK 17: `sdk install java 17.0.x-tem` (SDKMAN) |
| `Execution failed for task ':app:validateSigningRelease'` | Keystore/password mismatch in `key.properties` — regenerate it |
| OOM during build | Lower `org.gradle.jvmargs=-Xmx` in `android/gradle.properties` |
