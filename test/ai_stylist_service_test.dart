import 'package:flutter_test/flutter_test.dart';
import 'package:styledrop/models/wardrobe_item.dart';
import 'package:styledrop/models/outfit.dart';
import 'package:styledrop/services/ai_stylist_service.dart';

/// Unit tests for the AI stylist engine.
///
/// These are pure-function tests (no Hive, no network) covering the two
/// properties that matter most for a stylist users can trust:
///   1. It NEVER invents items — every outfit only references wardrobe IDs.
///   2. Scores are DETERMINISTIC — the same outfit always scores the same,
///      so rankings are stable across taps (this was previously broken by
///      random jitter added inside each score function).
WardrobeItem _item({
  required String id,
  required String category,
  String type = 'Thing',
  String color = 'Black',
  String style = 'Streetwear',
  String fit = 'Regular',
}) {
  return WardrobeItem(
    id: id,
    category: category,
    type: type,
    color: color,
    style: style,
    fit: fit,
  );
}

List<WardrobeItem> _minimalWardrobe() => [
  _item(id: 't1', category: ItemCategory.top, type: 'Tee', fit: 'Oversized'),
  _item(id: 't2', category: ItemCategory.top, type: 'Hoodie', color: 'White'),
  _item(id: 'b1', category: ItemCategory.bottom, type: 'Jeans', fit: 'Slim'),
  _item(id: 'b2', category: ItemCategory.bottom, type: 'Cargo', color: 'Gray'),
  _item(id: 's1', category: ItemCategory.shoes, type: 'Sneakers', color: 'White'),
  _item(id: 's2', category: ItemCategory.shoes, type: 'Boots', color: 'Brown'),
];

void main() {
  group('AiStylistService.generateOutfits', () {
    test('returns empty when wardrobe lacks a top/bottom/shoe', () {
      final onlyTops = [
        _item(id: 't1', category: ItemCategory.top),
      ];
      final result = AiStylistService.generateOutfits(
        wardrobe: onlyTops,
        occasion: 'Casual',
        style: 'Streetwear',
        colorPreference: 'Any',
        weatherCondition: 'Mild',
        temperatureC: 24,
        shoePreference: 'Any',
      );
      expect(result, isEmpty);
    });

    test('produces outfits that only reference owned wardrobe items', () {
      final wardrobe = _minimalWardrobe();
      final ownedIds = wardrobe.map((i) => i.id).toSet();

      final outfits = AiStylistService.generateOutfits(
        wardrobe: wardrobe,
        occasion: 'Casual',
        style: 'Streetwear',
        colorPreference: 'Any',
        weatherCondition: 'Mild',
        temperatureC: 24,
        shoePreference: 'Any',
        count: 5,
      );

      expect(outfits, isNotEmpty);
      for (final outfit in outfits) {
        for (final id in outfit.itemIds) {
          expect(
            ownedIds.contains(id),
            isTrue,
            reason: 'Outfit referenced non-owned item "$id"',
          );
        }
        // Every outfit must contain the three mandatory categories.
        final cats = outfit.itemIds
            .map((id) => wardrobe.firstWhere((i) => i.id == id).category)
            .toSet();
        expect(cats.contains(ItemCategory.top), isTrue);
        expect(cats.contains(ItemCategory.bottom), isTrue);
        expect(cats.contains(ItemCategory.shoes), isTrue);
      }
    });

    test('does not return duplicate outfits (same item set)', () {
      final wardrobe = _minimalWardrobe();
      final outfits = AiStylistService.generateOutfits(
        wardrobe: wardrobe,
        occasion: 'Casual',
        style: 'Streetwear',
        colorPreference: 'Any',
        weatherCondition: 'Mild',
        temperatureC: 24,
        shoePreference: 'Any',
        count: 8,
      );
      final signatures = outfits
          .map((o) => (List<String>.from(o.itemIds)..sort()).join(','))
          .toList();
      expect(signatures.toSet().length, equals(signatures.length));
    });

    test('respects shoe preference filter', () {
      final wardrobe = _minimalWardrobe();
      final outfits = AiStylistService.generateOutfits(
        wardrobe: wardrobe,
        occasion: 'Casual',
        style: 'Streetwear',
        colorPreference: 'Any',
        weatherCondition: 'Mild',
        temperatureC: 24,
        shoePreference: 'Boots',
        count: 5,
      );
      for (final outfit in outfits) {
        final shoe = outfit.itemIds
            .map((id) => wardrobe.firstWhere((i) => i.id == id))
            .firstWhere((i) => i.category == ItemCategory.shoes);
        expect(shoe.type.toLowerCase().contains('boots'), isTrue);
      }
    });

    test('adds outerwear when cold', () {
      final wardrobe = [
        ..._minimalWardrobe(),
        _item(id: 'o1', category: ItemCategory.outerwear, type: 'Puffer'),
      ];
      final outfits = AiStylistService.generateOutfits(
        wardrobe: wardrobe,
        occasion: 'Casual',
        style: 'Streetwear',
        colorPreference: 'Any',
        weatherCondition: 'Cold',
        temperatureC: 8,
        shoePreference: 'Any',
        count: 5,
      );
      final anyHasOuter = outfits.any(
        (o) => o.itemIds.any(
          (id) =>
              wardrobe.firstWhere((i) => i.id == id).category ==
              ItemCategory.outerwear,
        ),
      );
      expect(anyHasOuter, isTrue);
    });
  });

  group('deterministic scoring', () {
    test('same item set yields identical scores across runs', () {
      final top = _item(id: 't1', category: ItemCategory.top, fit: 'Oversized');
      final bottom = _item(id: 'b1', category: ItemCategory.bottom, fit: 'Slim');
      final shoe = _item(id: 's1', category: ItemCategory.shoes);
      final wardrobe = [top, bottom, shoe];

      double scoreOnce() {
        final outfits = AiStylistService.generateOutfits(
          wardrobe: wardrobe,
          occasion: 'Casual',
          style: 'Streetwear',
          colorPreference: 'Any',
          weatherCondition: 'Mild',
          temperatureC: 24,
          shoePreference: 'Any',
          count: 1,
        );
        return outfits.single.scoreBreakdown.overall;
      }

      final a = scoreOnce();
      final b = scoreOnce();
      final c = scoreOnce();
      expect(a, equals(b));
      expect(b, equals(c));
    });

    test('scores stay within the documented 55..99 range', () {
      final wardrobe = _minimalWardrobe();
      final outfits = AiStylistService.generateOutfits(
        wardrobe: wardrobe,
        occasion: 'Party',
        style: 'Y2K',
        colorPreference: 'Black',
        weatherCondition: 'Mild',
        temperatureC: 24,
        shoePreference: 'Any',
        count: 5,
      );
      for (final o in outfits) {
        final b = o.scoreBreakdown;
        for (final s in [
          b.colorMatch,
          b.styleMatch,
          b.occasionMatch,
          b.proportion,
        ]) {
          expect(s, greaterThanOrEqualTo(55));
          expect(s, lessThanOrEqualTo(99));
        }
      }
    });
  });

  group('remixOutfit', () {
    test('keeps pinned items and only references owned items', () {
      final wardrobe = _minimalWardrobe();
      final base = AiStylistService.generateOutfits(
        wardrobe: wardrobe,
        occasion: 'Casual',
        style: 'Streetwear',
        colorPreference: 'Any',
        weatherCondition: 'Mild',
        temperatureC: 24,
        shoePreference: 'Any',
        count: 1,
      ).single;

      final keepId = base.itemIds.first;
      final remix = AiStylistService.remixOutfit(
        original: base,
        wardrobe: wardrobe,
        keepItemIds: {keepId},
        occasion: 'Casual',
        style: 'Streetwear',
        temperatureC: 24,
        weatherCondition: 'Mild',
      );

      expect(remix.itemIds.contains(keepId), isTrue);
      final ownedIds = wardrobe.map((i) => i.id).toSet();
      for (final id in remix.itemIds) {
        expect(ownedIds.contains(id), isTrue);
      }
    });
  });

  group('suggestMissingItems', () {
    test('suggests outerwear when wardrobe has none', () {
      final wardrobe = _minimalWardrobe(); // no outerwear
      final suggestions = AiStylistService.suggestMissingItems(wardrobe);
      expect(
        suggestions.any((s) => s.toLowerCase().contains('jacket')),
        isTrue,
      );
    });
  });

  group('OutfitScoreBreakdown', () {
    test('overall is the mean of the four sub-scores', () {
      const b = OutfitScoreBreakdown(
        colorMatch: 80,
        styleMatch: 90,
        occasionMatch: 70,
        proportion: 60,
      );
      expect(b.overall, equals((80 + 90 + 70 + 60) / 4));
    });
  });
}
