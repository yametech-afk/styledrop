import 'package:hive_flutter/hive_flutter.dart';
import '../models/wardrobe_item.dart';
import '../models/outfit.dart';
import '../models/style_dna.dart';

/// Central local persistence layer built on Hive.
/// Boxes:
///  - wardrobe: id -> WardrobeItem map
///  - outfits: id -> Outfit map
///  - saved_outfits: set of outfit ids marked favorite/saved
///  - profile: single UserProfile map under key 'profile'
///  - meta: misc counters (outfitsGenerated, etc.)
class StorageService {
  static const String wardrobeBox = 'wardrobe_box';
  static const String outfitsBox = 'outfits_box';
  static const String profileBox = 'profile_box';
  static const String metaBox = 'meta_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(wardrobeBox);
    await Hive.openBox(outfitsBox);
    await Hive.openBox(profileBox);
    await Hive.openBox(metaBox);
  }

  // ---------------- Wardrobe ----------------
  static Box get _wardrobe => Hive.box(wardrobeBox);

  static List<WardrobeItem> getWardrobe() {
    return _wardrobe.values
        .map((e) => WardrobeItem.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> saveItem(WardrobeItem item) async {
    await _wardrobe.put(item.id, item.toMap());
  }

  static Future<void> deleteItem(String id) async {
    await _wardrobe.delete(id);
  }

  // ---------------- Outfits ----------------
  static Box get _outfits => Hive.box(outfitsBox);

  static List<Outfit> getOutfits() {
    return _outfits.values
        .map((e) => Outfit.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> saveOutfit(Outfit outfit) async {
    await _outfits.put(outfit.id, outfit.toMap());
  }

  static Future<void> deleteOutfit(String id) async {
    await _outfits.delete(id);
  }

  // ---------------- Profile ----------------
  static Box get _profile => Hive.box(profileBox);

  static UserProfile getProfile() {
    final raw = _profile.get('profile');
    if (raw == null) return UserProfile();
    return UserProfile.fromMap(Map<dynamic, dynamic>.from(raw as Map));
  }

  static Future<void> saveProfile(UserProfile profile) async {
    await _profile.put('profile', profile.toMap());
  }

  // ---------------- Meta counters ----------------
  static Box get _meta => Hive.box(metaBox);

  static int getOutfitsGeneratedCount() =>
      (_meta.get('outfits_generated') as int?) ?? 0;

  static Future<void> incrementOutfitsGenerated([int by = 1]) async {
    await _meta.put('outfits_generated', getOutfitsGeneratedCount() + by);
  }

  static bool getSeedApplied() => (_meta.get('seed_applied') as bool?) ?? false;

  static Future<void> setSeedApplied() async {
    await _meta.put('seed_applied', true);
  }

  static bool getOnboarded() => (_meta.get('onboarded') as bool?) ?? false;

  static Future<void> setOnboarded() async {
    await _meta.put('onboarded', true);
  }

  /// Theme mode preference: 'system' (default), 'light', or 'dark'.
  static String getThemeMode() =>
      (_meta.get('theme_mode') as String?) ?? 'system';

  static Future<void> setThemeMode(String mode) async {
    await _meta.put('theme_mode', mode);
  }

  // ---------------- Daily usage counters (Free-tier gating) ----------------
  // Keyed by calendar date so counters automatically reset at midnight
  // without needing a background job.
  static String _todayKey(String prefix) {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${prefix}_${now.year}-$m-$d';
  }

  static int getDailyGenerationsUsed() =>
      (_meta.get(_todayKey('gen_used')) as int?) ?? 0;

  static Future<void> incrementDailyGenerationsUsed() async {
    await _meta.put(_todayKey('gen_used'), getDailyGenerationsUsed() + 1);
  }
}
