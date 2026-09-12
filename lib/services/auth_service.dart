import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/wardrobe_item.dart';
import '../models/outfit.dart';
import 'firestore_service.dart';

/// Real authentication backed by Firebase Auth.
///
/// Replaces the previous mock login (which just hardcoded a fake email).
/// Supports:
///   - Google Sign-In
///   - Sign in with Apple (iOS/macOS; required by App Store if you offer
///     other social logins on iOS)
///   - Email/password (sign-up + sign-in)
///   - Anonymous "Guest" mode (can be upgraded to a real account later)
///
/// All methods throw [AuthException] with a user-friendly message on failure
/// so the UI can show a clean SnackBar instead of a raw Firebase error.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Emits the current user whenever auth state changes (login/logout).
  /// Used by the app root to decide which screen to show.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
  bool get isGuest => _auth.currentUser?.isAnonymous ?? false;

  // ------------------------------------------------------------------
  // Google
  // ------------------------------------------------------------------
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // On web, use the popup flow directly through Firebase.
        final provider = GoogleAuthProvider();
        final cred = await _auth.signInWithPopup(provider);
        return cred.user;
      }

      final googleUser = await GoogleSignIn(
        // The Web client ID from google-services.json (client_type: 3).
        // Required for Google Sign-In on Android to work with Firebase Auth.
        serverClientId:
            '497002874460-msl7q6fg667oqk1l85h91dt86tlnh8d1.apps.googleusercontent.com',
      ).signIn();
      if (googleUser == null) return null; // user cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    } catch (e) {
      throw AuthException('Google sign-in failed. Please try again.');
    }
  }

  // ------------------------------------------------------------------
  // Apple
  // ------------------------------------------------------------------
  Future<User?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final cred = await _auth.signInWithCredential(oauthCredential);

      // Apple only returns the name on the FIRST sign-in — capture it.
      final givenName = appleCredential.givenName;
      final familyName = appleCredential.familyName;
      if (cred.user != null &&
          (cred.user!.displayName == null ||
              cred.user!.displayName!.isEmpty) &&
          (givenName != null || familyName != null)) {
        final full = [givenName, familyName].whereType<String>().join(' ');
        if (full.trim().isNotEmpty) {
          await cred.user!.updateDisplayName(full.trim());
        }
      }
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw AuthException('Apple sign-in failed. Please try again.');
    } catch (e) {
      throw AuthException('Apple sign-in failed. Please try again.');
    }
  }

  // ------------------------------------------------------------------
  // Email / password
  // ------------------------------------------------------------------
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  Future<User?> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null && displayName.trim().isNotEmpty) {
        await cred.user?.updateDisplayName(displayName.trim());
      }
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  // ------------------------------------------------------------------
  // Guest (anonymous)
  // ------------------------------------------------------------------
  Future<User?> signInAsGuest() async {
    try {
      final cred = await _auth.signInAnonymously();
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  Future<void> signOut() async {
    // Sign out of Google too so the account picker shows next time.
    try {
      if (!kIsWeb) await GoogleSignIn(
        serverClientId:
            '497002874460-msl7q6fg667oqk1l85h91dt86tlnh8d1.apps.googleusercontent.com',
      ).signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ------------------------------------------------------------------
  // Account deletion (Google Play Account Deletion policy requirement:
  // apps that allow account creation must let users delete the account
  // and its cloud data from inside the app).
  // ------------------------------------------------------------------

  /// Deletes the cloud library for the signed-in user (wardrobe, outfits,
  /// profile) via a Firestore batch, then deletes the Firebase Auth account
  /// itself. Guests are a no-op (they have no real account and sync nothing).
  ///
  /// Local-only data (Hive) is cleared by the caller afterwards.
  ///
  /// May throw [AuthException], e.g. `requires-recent-login` when the session
  /// is too old — the UI prompts the user to sign in again and retry.
  Future<void> deleteAccount({required List<WardrobeItem> items, required List<Outfit> outfits}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1) Cloud data first (needs an authenticated session; deleting the auth
    //    account first would make the rules reject these writes).
    if (!user.isAnonymous) {
      await FirestoreService.instance.deleteAllUserData(
        items: items,
        outfits: outfits,
      );
    }

    // 2) The auth account itself.
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------
  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please choose a stronger password (6+ characters).';
      case 'account-exists-with-different-credential':
        return 'This email is already linked to a different sign-in method.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
