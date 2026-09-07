import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../models/style_dna.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// Profile state, now backed by Firebase Auth for IDENTITY (name, email,
/// photo, guest flag) while keeping the app-specific bits (Style DNA,
/// subscription tier) in the local Hive profile as before.
///
/// The identity fields are always sourced from the signed-in Firebase user
/// so they can't drift out of sync; the Hive record is used as a cache and
/// to persist the fields Firebase doesn't own (styleDna, subscriptionTier).
class ProfileProvider extends ChangeNotifier {
  UserProfile _profile = UserProfile();

  UserProfile get profile => _profile;

  /// Load the locally-cached profile, then overlay the current Firebase
  /// user's identity on top (if signed in).
  void load() {
    _profile = StorageService.getProfile();
    _applyFirebaseUser(AuthService.instance.currentUser);
    notifyListeners();
  }

  /// Call this whenever Firebase auth state changes (from the app root).
  Future<void> syncWithFirebaseUser(fb.User? user) async {
    _profile = StorageService.getProfile();
    _applyFirebaseUser(user);
    await StorageService.saveProfile(_profile);
    notifyListeners();
  }

  void _applyFirebaseUser(fb.User? user) {
    if (user == null) return;
    _profile.isGuest = user.isAnonymous;
    if (!user.isAnonymous) {
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        _profile.name = user.displayName!.trim();
      }
      if (user.email != null && user.email!.isNotEmpty) {
        _profile.email = user.email!;
      }
      if (user.photoURL != null && user.photoURL!.isNotEmpty) {
        _profile.photoPath = user.photoURL;
      }
    } else {
      _profile.name = 'Guest';
      _profile.email = '';
    }
  }

  Future<void> save() async {
    await StorageService.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    _profile.name = name;
    // Also push the display name back to Firebase so it stays consistent.
    try {
      await AuthService.instance.currentUser?.updateDisplayName(name);
    } catch (_) {
      // Non-fatal — the local copy is still updated.
    }
    await save();
  }

  Future<void> updateStyleDna({
    List<String>? preferredStyles,
    List<String>? favoriteColors,
    String? preferredFit,
    List<String>? avoidColors,
  }) async {
    if (preferredStyles != null) {
      _profile.styleDna.preferredStyles = preferredStyles;
    }
    if (favoriteColors != null) {
      _profile.styleDna.favoriteColors = favoriteColors;
    }
    if (preferredFit != null) _profile.styleDna.preferredFit = preferredFit;
    if (avoidColors != null) _profile.styleDna.avoidColors = avoidColors;
    await save();
  }

  /// Sign the user out of Firebase and reset the local profile.
  Future<void> logout() async {
    await AuthService.instance.signOut();
    _profile = UserProfile();
    await save();
  }
}
