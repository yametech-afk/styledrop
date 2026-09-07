import 'storage_service.dart';

/// Centralizes Free vs PRO/PRO+ feature gating so the same rules are
/// enforced consistently everywhere a limited action is triggered
/// (AI outfit generation, wardrobe size, calendar planning, etc.)
/// instead of being silently unlimited like before.
class UsageLimitService {
  UsageLimitService._();

  /// Max outfit-generation *requests* a FREE user can make per calendar
  /// day. Each request may still return multiple outfits (that's a
  /// wardrobe/style constraint, not a tier limit) — it's the act of
  /// asking the AI stylist that's rationed for Free users.
  static const int freeDailyGenerationLimit = 3;

  /// Max number of wardrobe items a FREE user can store.
  static const int freeWardrobeItemLimit = 25;

  /// Max number of outfits a FREE user can save to favorites.
  static const int freeSavedOutfitLimit = 10;

  static bool isPro(String tier) => tier == 'PRO' || tier == 'PRO_PLUS';

  /// Whether the given tier can perform another AI generation *right now*.
  static bool canGenerate(String tier) {
    if (isPro(tier)) return true;
    return StorageService.getDailyGenerationsUsed() < freeDailyGenerationLimit;
  }

  static int remainingGenerations(String tier) {
    if (isPro(tier)) return -1; // unlimited
    final used = StorageService.getDailyGenerationsUsed();
    final remaining = freeDailyGenerationLimit - used;
    return remaining < 0 ? 0 : remaining;
  }

  /// Records one AI-generation request against today's Free-tier quota.
  /// No-op for PRO/PRO+ (they're unlimited, so we don't bother tracking).
  static Future<void> recordGeneration(String tier) async {
    if (isPro(tier)) return;
    await StorageService.incrementDailyGenerationsUsed();
  }

  static bool canAddWardrobeItem(String tier, int currentItemCount) {
    if (isPro(tier)) return true;
    return currentItemCount < freeWardrobeItemLimit;
  }

  static bool canSaveOutfit(String tier, int currentSavedCount) {
    if (isPro(tier)) return true;
    return currentSavedCount < freeSavedOutfitLimit;
  }
}
