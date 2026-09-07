# styledrop

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## 🔄 StyleDrop rebrand notes (2026-09-07)

### Cloudflare Pages project URL
An existing Pages project URL (e.g. `https://fitai-proxy.pages.dev`) **cannot be renamed** after creation. For new deployments, create a fresh project so the URL matches the brand; existing deployments keep working on their old URL until migrated:

```bash
npx wrangler pages project create styledrop-proxy
npm run deploy
```

### Firebase project ID
Firebase **project IDs are permanent and cannot be renamed**. Reuse the existing project (re-run `flutterfire configure --project=<existing-id>`) or create a new one named `styledrop-wardrobe`. After configure, re-download `google-services.json` and regenerate `firebase_options.dart` — the placeholder in this repo must be replaced before real sign-in/sync works.
