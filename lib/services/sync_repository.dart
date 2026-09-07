import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/wardrobe_item.dart';
import '../models/outfit.dart';
import 'storage_service.dart';
import 'firestore_service.dart';

/// The single data gateway the app writes through.
///
/// Strategy: **Hive is the offline cache, Firestore is the source of truth.**
///
///  - Reads are served instantly from Hive (so the UI is never blocked on the
///    network), so callers keep using [StorageService.getWardrobe] /
///    [getOutfits] for the fast local list.
///  - Writes go to Hive first (instant, offline-safe) and are then mirrored to
///    Firestore in the background when a real (non-guest) user is signed in.
///  - On sign-in, [pullFromCloud] merges the cloud copy into Hive so a fresh
///    device is populated, and [migrateLocalToCloud] pushes an existing local
///    library up the first time a user connects an account.
///
/// Guests (anonymous auth) are entirely local — nothing is written to the
/// cloud until they upgrade to a real account, at which point their local
/// library is migrated up.
class SyncRepository {
  SyncRepository._();
  static final SyncRepository instance = SyncRepository._();

  final FirestoreService _cloud = FirestoreService.instance;

  bool get _canSync => _cloud.canSync;

  // ------------------------------------------------------------------
  // Wardrobe
  // ------------------------------------------------------------------
  Future<void> saveItem(WardrobeItem item) async {
    await StorageService.saveItem(item); // local first (instant, offline-safe)
    if (_canSync) {
      // Fire-and-forget: never block the UI on the network.
      unawaited(_guard(() => _cloud.upsertItem(item), 'upsertItem'));
    }
  }

  Future<void> deleteItem(String id) async {
    await StorageService.deleteItem(id);
    if (_canSync) {
      unawaited(_guard(() => _cloud.deleteItem(id), 'deleteItem'));
    }
  }

  // ------------------------------------------------------------------
  // Outfits
  // ------------------------------------------------------------------
  Future<void> saveOutfit(Outfit outfit) async {
    await StorageService.saveOutfit(outfit);
    if (_canSync) {
      unawaited(_guard(() => _cloud.upsertOutfit(outfit), 'upsertOutfit'));
    }
  }

  Future<void> deleteOutfit(String id) async {
    await StorageService.deleteOutfit(id);
    if (_canSync) {
      unawaited(_guard(() => _cloud.deleteOutfit(id), 'deleteOutfit'));
    }
  }

  // ------------------------------------------------------------------
  // Sign-in sync
  // ------------------------------------------------------------------
  /// Called after a real user signs in. Pulls the cloud library down and
  /// merges it into the local Hive cache so this device shows the account's
  /// data. Merge rule: cloud wins for documents that exist in both (Firestore
  /// is the source of truth), local-only items are preserved and pushed up.
  ///
  /// Returns true if any cloud data was applied.
  Future<bool> pullFromCloud() async {
    if (!_canSync) return false;

    try {
      final cloudItems = await _cloud.fetchWardrobe();
      final cloudOutfits = await _cloud.fetchOutfits();

      final localItems = {for (final i in StorageService.getWardrobe()) i.id: i};
      final localOutfits = {for (final o in StorageService.getOutfits()) o.id: o};

      // 1) Cloud -> local (cloud wins on conflicts).
      for (final item in cloudItems) {
        // Preserve any locally-cached image bytes the cloud copy dropped.
        final local = localItems[item.id];
        final merged = (local?.imageBytes != null && item.imageBytes == null)
            ? item.copyWith(imageBytes: local!.imageBytes)
            : item;
        await StorageService.saveItem(merged);
        localItems.remove(item.id);
      }
      for (final outfit in cloudOutfits) {
        await StorageService.saveOutfit(outfit);
        localOutfits.remove(outfit.id);
      }

      // 2) Local-only leftovers -> push up to the cloud so nothing is lost.
      if (localItems.isNotEmpty || localOutfits.isNotEmpty) {
        await _cloud.pushAll(
          items: localItems.values.toList(),
          outfits: localOutfits.values.toList(),
        );
      }

      // 3) Bring the profile (Style DNA / tier) down if present.
      final cloudProfile = await _cloud.fetchProfile();
      if (cloudProfile != null) {
        final localProfile = StorageService.getProfile();
        // Keep Firebase-owned identity local values; take app data from cloud.
        localProfile.styleDna = cloudProfile.styleDna;
        localProfile.subscriptionTier = cloudProfile.subscriptionTier;
        await StorageService.saveProfile(localProfile);
      }
      return true;
    } catch (e) {
      debugPrint('SyncRepository.pullFromCloud failed: $e');
      return false;
    }
  }

  /// Pushes the entire local library to the cloud. Used when a guest upgrades
  /// to a real account, or as a manual "back up now" action.
  Future<void> migrateLocalToCloud() async {
    if (!_canSync) return;
    await _guard(
      () => _cloud.pushAll(
        items: StorageService.getWardrobe(),
        outfits: StorageService.getOutfits(),
        profile: StorageService.getProfile(),
      ),
      'migrateLocalToCloud',
    );
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------
  Future<void> _guard(Future<void> Function() op, String label) async {
    try {
      await op();
    } catch (e) {
      // Network/permission failures are non-fatal: the local copy is already
      // saved and will be re-pushed on the next pull/migrate.
      debugPrint('SyncRepository.$label failed (will retry later): $e');
    }
  }
}
