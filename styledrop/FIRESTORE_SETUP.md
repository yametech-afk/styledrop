# StyleDrop — Firestore Cloud Sync Guide (Phase B)

Phase B makes a user's **wardrobe, outfits, and Style DNA sync to the cloud**
so they appear on every device they sign into. It builds directly on the
Phase A authentication (see `FIREBASE_SETUP.md` — do that first).

> **What's already done in the code**
> - `cloud_firestore` added to `pubspec.yaml`.
> - `lib/services/firestore_service.dart` — per-user Firestore read/write.
> - `lib/services/sync_repository.dart` — Hive cache + Firestore source-of-truth.
> - `WardrobeProvider` & `OutfitProvider` now write through the repository.
> - `main.dart` (`AppRoot`) pulls the cloud library on sign-in and shows a
>   "Syncing your wardrobe…" splash.
> - `firestore.rules` — per-UID security rules.
>
> You only need the console steps below.

---

## The data model

Everything is namespaced under the signed-in user's UID:

```
users/{uid}
  ├── wardrobe/{itemId}    → one document per WardrobeItem (metadata only)
  ├── outfits/{outfitId}   → one document per Outfit
  └── meta/profile         → Style DNA + subscription tier
```

The security rules guarantee a user can only read/write documents under their
own `{uid}` — no account can ever see another's data.

---

## Sync strategy (how it behaves)

| Situation | Behaviour |
|---|---|
| **Read** (viewing wardrobe/outfits) | Served instantly from the local Hive cache — never blocked on the network. |
| **Write** (add/edit/delete/plan/wear) | Saved to Hive first (instant, offline-safe), then mirrored to Firestore in the background. |
| **Sign in on a new device** | `pullFromCloud()` downloads the account's library and merges it into Hive; cloud wins on conflicts. A "Syncing…" splash shows briefly. |
| **Local-only items exist at sign-in** | They're pushed up to the cloud so nothing is lost. |
| **Guest (anonymous) user** | Entirely local — nothing is written to the cloud. |
| **Guest upgrades to a real account** | Their local library is migrated up on the first cloud pull. |
| **Offline** | Writes still succeed locally and re-sync on the next pull. |

> **Images:** raw photo bytes are **not** written to Firestore (a doc is capped
> at ~1 MB and a photo can exceed that). Only lightweight metadata + asset
> references sync. Storing the actual photos in **Firebase Storage** is a small
> follow-up (Phase B+) — the code is already safe against the size limit.

---

## Step 1 — Create the Firestore database

1. [Firebase console](https://console.firebase.google.com) → your project →
   **Build → Firestore Database → Create database**.
2. Choose a location (closest to your users).
3. Start in **production mode** (we deploy real rules in Step 2 — don't leave it
   in open "test mode").

`cloud_firestore` is already configured through the `firebase_options.dart`
you generated in Phase A — no extra platform config needed.

---

## Step 2 — Deploy the security rules

The rules live in `firestore.rules` at the project root.

**Option A — Firebase CLI (recommended):**
```bash
# one-time, if you haven't already:
firebase init firestore     # when asked, keep the existing firestore.rules

firebase deploy --only firestore:rules
```

**Option B — Console:** Firestore → **Rules** tab → paste the contents of
`firestore.rules` → **Publish**.

> ⚠️ Do not skip this. Without the rules, Firestore is either fully locked
> (writes fail) or fully open (anyone can read all data).

---

## Step 3 — (Optional) Add an index

The app currently reads whole collections (no compound queries), so **no
custom indexes are required**. If you later add filtered/ordered queries,
Firestore will print a one-click "create index" link in the debug console.

---

## Step 4 — Run and verify

```bash
flutter pub get
flutter run          # or -d chrome
```

**Test checklist:**
1. Sign in with a **real** account (not guest).
2. Add a wardrobe item / save an outfit.
3. In the Firebase console → Firestore, confirm a document appears under
   `users/{yourUid}/wardrobe` / `.../outfits`.
4. Sign out, sign in on a **second device / browser** with the same account →
   the item/outfit appears after the "Syncing…" splash.
5. Sign in as **Guest** → add an item → confirm **nothing** is written to
   Firestore (guests are local-only).

---

## How the pieces fit together

```
UI (add/edit/delete)
      │
providers (WardrobeProvider / OutfitProvider)
      │
SyncRepository ──► StorageService (Hive)        ← instant local write / cache
      │
      └────────► FirestoreService (Firestore)   ← background mirror (real users)

Sign-in (AppRoot in main.dart)
      │
SyncRepository.pullFromCloud()
      ├─ cloud docs  → merge into Hive (cloud wins)
      └─ local-only  → push up to cloud
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `PERMISSION_DENIED` on write | Rules not deployed (Step 2), or you're testing with a guest under a real-user path. |
| Nothing syncs, no errors | You're signed in as **Guest** — guests are local-only by design. |
| Data doesn't appear on 2nd device | Confirm both devices use the **same** account; check the "Syncing…" splash ran; look for `pullFromCloud failed` in logs. |
| `FirebaseException: [cloud_firestore/unavailable]` | Offline — writes are cached locally and re-sync automatically later. |
| Huge document error | Shouldn't happen — image bytes are stripped. If it does, a non-image field is oversized. |

---

## What's next (optional Phase B+)

- **Firebase Storage for photos** — upload item images to
  `users/{uid}/images/{itemId}` and store just the download URL in Firestore,
  so photos sync across devices too.
- **Real-time listeners** — swap the one-shot `fetch*()` for `snapshots()`
  streams so changes on one device appear live on another.
- **Per-field conflict resolution** — currently "cloud wins" on whole
  documents; add `updatedAt` timestamps for last-write-wins at field level.
