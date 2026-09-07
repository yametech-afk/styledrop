// Model-level smoke tests for StyleDrop.
//
// Note: a full-app widget test (pumpWidget(StyleDropApp())) is intentionally
// NOT run here because main() initializes Hive, notifications and seed data,
// which require platform channels unavailable in the pure `flutter test`
// VM. Those flows belong in an integration_test/ driver run on a device.
// Instead we smoke-test the serialization contracts that the whole app
// depends on.

import 'package:flutter_test/flutter_test.dart';
import 'package:styledrop/models/wardrobe_item.dart';
import 'package:styledrop/models/outfit.dart';
import 'package:styledrop/models/style_dna.dart';

void main() {
  test('WardrobeItem round-trips through toMap/fromMap', () {
    final item = WardrobeItem(
      id: 'abc',
      category: ItemCategory.top,
      type: 'Graphic Tee',
      color: 'Black',
      pattern: 'Graphic',
      style: 'Streetwear',
      fit: 'Oversized',
      season: 'Summer',
      brand: 'Nike',
      timesWorn: 7,
    );
    final restored = WardrobeItem.fromMap(item.toMap());
    expect(restored.id, item.id);
    expect(restored.category, item.category);
    expect(restored.type, item.type);
    expect(restored.color, item.color);
    expect(restored.style, item.style);
    expect(restored.fit, item.fit);
    expect(restored.timesWorn, 7);
  });

  test('Outfit round-trips through toMap/fromMap', () {
    final outfit = Outfit(
      id: 'o1',
      itemIds: ['a', 'b', 'c'],
      occasion: 'Party',
      style: 'Y2K',
      weatherSummary: '24°C • Mild',
      scoreBreakdown: const OutfitScoreBreakdown(
        colorMatch: 80,
        styleMatch: 85,
        occasionMatch: 75,
        proportion: 90,
      ),
      aiExplanation: 'Looks great.',
      favorite: true,
      name: 'Friday Fit',
    );
    final restored = Outfit.fromMap(outfit.toMap());
    expect(restored.itemIds, ['a', 'b', 'c']);
    expect(restored.favorite, isTrue);
    expect(restored.name, 'Friday Fit');
    expect(restored.scoreBreakdown.overall, outfit.scoreBreakdown.overall);
  });

  test('UserProfile defaults to FREE tier', () {
    final profile = UserProfile();
    expect(profile.subscriptionTier, 'FREE');
    expect(profile.styleDna.preferredStyles, isNotEmpty);
  });
}
