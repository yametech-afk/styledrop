import 'package:flutter_test/flutter_test.dart';
import 'package:styledrop/services/usage_limit_service.dart';

/// Unit tests for the Free vs PRO/PRO+ gating rules.
///
/// Only the pure, storage-independent branches are tested here (tier checks
/// and count-based caps). The daily-generation counter relies on Hive via
/// StorageService, which needs an initialized box, so it's covered by
/// integration tests rather than this pure unit suite.
void main() {
  group('isPro', () {
    test('FREE is not pro', () {
      expect(UsageLimitService.isPro('FREE'), isFalse);
    });
    test('PRO and PRO_PLUS are pro', () {
      expect(UsageLimitService.isPro('PRO'), isTrue);
      expect(UsageLimitService.isPro('PRO_PLUS'), isTrue);
    });
    test('unknown tier is treated as not pro', () {
      expect(UsageLimitService.isPro('GOLD'), isFalse);
    });
  });

  group('canAddWardrobeItem', () {
    test('FREE user blocked at the item limit', () {
      final limit = UsageLimitService.freeWardrobeItemLimit;
      expect(UsageLimitService.canAddWardrobeItem('FREE', limit - 1), isTrue);
      expect(UsageLimitService.canAddWardrobeItem('FREE', limit), isFalse);
      expect(UsageLimitService.canAddWardrobeItem('FREE', limit + 5), isFalse);
    });
    test('PRO user is never blocked', () {
      expect(UsageLimitService.canAddWardrobeItem('PRO', 9999), isTrue);
      expect(UsageLimitService.canAddWardrobeItem('PRO_PLUS', 9999), isTrue);
    });
  });

  group('canSaveOutfit', () {
    test('FREE user blocked at the saved-outfit limit', () {
      final limit = UsageLimitService.freeSavedOutfitLimit;
      expect(UsageLimitService.canSaveOutfit('FREE', limit - 1), isTrue);
      expect(UsageLimitService.canSaveOutfit('FREE', limit), isFalse);
    });
    test('PRO user is never blocked', () {
      expect(UsageLimitService.canSaveOutfit('PRO', 9999), isTrue);
    });
  });

  group('remainingGenerations', () {
    test('PRO user reports unlimited (-1)', () {
      expect(UsageLimitService.remainingGenerations('PRO'), equals(-1));
      expect(UsageLimitService.remainingGenerations('PRO_PLUS'), equals(-1));
    });
  });
}
