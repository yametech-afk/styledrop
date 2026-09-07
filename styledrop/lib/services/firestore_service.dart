import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/wardrobe_item.dart';
import '../models/outfit.dart';
import '../models/style_dna.dart';
import 'auth_service.dart';

/// Cloud persistence backed by Cloud Firestore.
///
/// Data layout (scoped per user by UID):
///
///   users/{uid}
///     wardrobe/{itemId}   -> WardrobeItem document
///     outfits/{outfitId}  -> Outfit document
///     meta/profile        -> Style DNA + subscription tier + display fields
///
/// The Firestore security rules (see firestore.rules) restrict every path
/// under users/{uid} to that same authenticated user, so one account can
/// never read or write another account's data.
///
/// IMPORTANT — image bytes: raw image bytes (the base64 `imageBytesB64` field
/// used for the web platform) are intentionally **stripped** before writing to
/// Firestore. A Firestore document is capped at ~1 MB, and a single photo can
/// exceed that. Only lightweight metadata + references (assetPath / imagePath)
/// are synced. Binary photos should live in Firebase Storage — that's a
/// follow-up (Phase B+); this service is deliberately safe against the 1 MB
/// limit so a large photo can never break a sync.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// True only when a NON-anonymous user is signed in. Guests stay local-only.
  bool get canSync {
    final user = AuthService.instance.currentUser;
    return user != null && !user.isAnonymous;
  }

  String? get _uid => AuthService.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>>? get _wardrobeCol =>
      _userDoc?.collection('wardrobe');

  CollectionReference<Map<String, dynamic>>? get _outfitsCol =>
      _userDoc?.collection('outfits');

  // ------------------------------------------------------------------
  // Wardrobe
  // ------------------------------------------------------------------
  Future<List<WardrobeItem>> fetchWardrobe() async {
    final col = _wardrobeCol;
    if (col == null) return [];
    final snap = await col.get();
    return snap.docs
        .map((d) => WardrobeItem.fromMap(d.data()))
        .toList(growable: false);
  }

  Future<void> upsertItem(WardrobeItem item) async {
    final col = _wardrobeCol;
    if (col == null) return;
    await col.doc(item.id).set(_stripImageBytes(item.toMap()));
  }

  Future<void> deleteItem(String id) async {
    final col = _wardrobeCol;
    if (col == null) return;
    await col.doc(id).delete();
  }

  // ------------------------------------------------------------------
  // Outfits
  // ------------------------------------------------------------------
  Future<List<Outfit>> fetchOutfits() async {
    final col = _outfitsCol;
    if (col == null) return [];
    final snap = await col.get();
    return snap.docs
        .map((d) => Outfit.fromMap(d.data()))
        .toList(growable: false);
  }

  Future<void> upsertOutfit(Outfit outfit) async {
    final col = _outfitsCol;
    if (col == null) return;
    await col.doc(outfit.id).set(outfit.toMap());
  }

  Future<void> deleteOutfit(String id) async {
    final col = _outfitsCol;
    if (col == null) return;
    await col.doc(id).delete();
  }

  // ------------------------------------------------------------------
  // Profile (Style DNA + subscription tier)
  // ------------------------------------------------------------------
  Future<UserProfile?> fetchProfile() async {
    final doc = _userDoc;
    if (doc == null) return null;
    final snap = await doc.collection('meta').doc('profile').get();
    final data = snap.data();
    if (data == null) return null;
    return UserProfile.fromMap(data);
  }

  Future<void> upsertProfile(UserProfile profile) async {
    final doc = _userDoc;
    if (doc == null) return;
    // Don't persist the raw photo bytes / local file path into the profile doc.
    final map = profile.toMap();
    map.remove('photoPath'); // photoURL is owned by Firebase Auth
    await doc.collection('meta').doc('profile').set(map);
  }

  // ------------------------------------------------------------------
  // Bulk push (used for first-time migration of an existing local library)
  // ------------------------------------------------------------------
  Future<void> pushAll({
    required List<WardrobeItem> items,
    required List<Outfit> outfits,
    UserProfile? profile,
  }) async {
    if (!canSync) return;
    final batch = _db.batch();
    final wardrobeCol = _wardrobeCol;
    final outfitsCol = _outfitsCol;
    if (wardrobeCol == null || outfitsCol == null) return;

    for (final item in items) {
      batch.set(wardrobeCol.doc(item.id), _stripImageBytes(item.toMap()));
    }
    for (final outfit in outfits) {
      batch.set(outfitsCol.doc(outfit.id), outfit.toMap());
    }
    if (profile != null) {
      final map = profile.toMap()..remove('photoPath');
      batch.set(
        _userDoc!.collection('meta').doc('profile'),
        map,
      );
    }
    try {
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreService.pushAll failed: $e');
    }
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------
  /// Removes heavy binary payloads so a document can never exceed the ~1 MB
  /// Firestore limit. The lightweight references (assetPath / imagePath) and
  /// all metadata are preserved.
  Map<String, dynamic> _stripImageBytes(Map<String, dynamic> map) {
    final copy = Map<String, dynamic>.from(map);
    copy.remove('imageBytesB64');
    return copy;
  }
}
