import 'dart:math';
import '../models/wardrobe_item.dart';
import '../models/outfit.dart';

/// AI Stylist Engine
///
/// Implements the pipeline described in the product spec:
///   USER INPUT → WARDROBE DATABASE → ITEM ATTRIBUTES → COLOR MATCHING →
///   STYLE COMPATIBILITY → OCCASION MATCHING → WEATHER MATCHING →
///   OUTFIT RANKING → FINAL OUTFIT
///
/// CRITICAL RULE: The stylist NEVER invents clothing. It only recombines
/// items that already exist in the user's wardrobe (WardrobeItem list).
class AiStylistService {
  static final Random _rng = Random();

  // Neutral colors combine well with almost anything.
  static const Set<String> _neutrals = {
    'black',
    'white',
    'gray',
    'grey',
    'beige',
    'cream',
    'navy',
    'brown',
    'tan',
    'khaki',
  };

  // Colors considered "bright" / high-saturation.
  static const Set<String> _brights = {
    'red',
    'orange',
    'yellow',
    'pink',
    'purple',
    'lime',
    'magenta',
    'neon green',
    'turquoise',
  };

  static const Map<String, List<String>> _occasionStyleAffinity = {
    'School': ['Casual', 'Streetwear', 'Korean', 'Minimalist'],
    'College': ['Streetwear', 'Casual', 'Y2K', 'Korean'],
    'Work': ['Smart Casual', 'Minimalist', 'Old Money', 'Formal'],
    'Casual': ['Casual', 'Streetwear', 'Minimalist', 'Sporty'],
    'Date': ['Smart Casual', 'Old Money', 'Minimalist', 'Korean'],
    'Party': ['Y2K', 'Streetwear', 'Grunge', 'Techwear'],
    'Wedding': ['Formal', 'Old Money', 'Smart Casual'],
    'Gym': ['Sporty', 'Techwear'],
    'Travel': ['Casual', 'Streetwear', 'Minimalist', 'Sporty'],
    'Beach': ['Casual', 'Sporty'],
    'Formal': ['Formal', 'Old Money', 'Smart Casual'],
  };

  /// Main entry point. Generates up to [count] ranked outfits from the
  /// user's wardrobe that satisfy the requested criteria.
  static List<Outfit> generateOutfits({
    required List<WardrobeItem> wardrobe,
    required String occasion,
    required String style,
    required String colorPreference, // "Any" or a color name
    required String weatherCondition, // e.g. "Hot", "Cold", "Rain", "Mild"
    required double temperatureC,
    required String shoePreference, // "Any" or category filter
    int count = 5,
  }) {
    final tops = wardrobe.where((i) => i.category == ItemCategory.top).toList();
    final bottoms = wardrobe
        .where((i) => i.category == ItemCategory.bottom)
        .toList();
    final shoes = wardrobe
        .where((i) => i.category == ItemCategory.shoes)
        .toList();
    final outerwear = wardrobe
        .where((i) => i.category == ItemCategory.outerwear)
        .toList();
    final accessories = wardrobe
        .where(
          (i) => [
            ItemCategory.accessory,
            ItemCategory.bag,
            ItemCategory.watch,
            ItemCategory.jewelry,
          ].contains(i.category),
        )
        .toList();

    if (tops.isEmpty || bottoms.isEmpty || shoes.isEmpty) {
      return [];
    }

    // WEATHER MATCHING: decide whether outerwear/lightweight items are needed.
    final needsJacket =
        temperatureC < 22 || weatherCondition.toLowerCase().contains('rain');
    final tooHotForJacket = temperatureC > 30;

    final candidates = <Outfit>[];

    // Generate a pool of candidate combinations (bounded to avoid explosion).
    final shuffledTops = List<WardrobeItem>.from(tops)..shuffle(_rng);
    final shuffledBottoms = List<WardrobeItem>.from(bottoms)..shuffle(_rng);
    final shuffledShoes = List<WardrobeItem>.from(shoes)..shuffle(_rng);

    int attempts = 0;
    final maxAttempts = min(
      60,
      shuffledTops.length * shuffledBottoms.length * shuffledShoes.length,
    );

    for (final top in shuffledTops) {
      for (final bottom in shuffledBottoms) {
        for (final shoe in shuffledShoes) {
          attempts++;
          if (attempts > maxAttempts) break;

          if (shoePreference != 'Any' &&
              !shoe.type.toLowerCase().contains(shoePreference.toLowerCase())) {
            continue;
          }

          WardrobeItem? jacket;
          if (needsJacket && !tooHotForJacket && outerwear.isNotEmpty) {
            jacket = outerwear[_rng.nextInt(outerwear.length)];
          }

          final chosenAccessories = <WardrobeItem>[];
          if (accessories.isNotEmpty) {
            final accCount = min(accessories.length, 1 + _rng.nextInt(2));
            final shuffledAcc = List<WardrobeItem>.from(accessories)
              ..shuffle(_rng);
            chosenAccessories.addAll(shuffledAcc.take(accCount));
          }

          final items = [
            top,
            bottom,
            shoe,
            if (jacket != null) jacket,
            ...chosenAccessories,
          ];

          final colorScore = _colorMatchScore(items, colorPreference);
          final styleScore = _styleMatchScore(items, style);
          final occasionScore = _occasionMatchScore(items, occasion, style);
          final proportionScore = _proportionScore(top, bottom);

          final breakdown = OutfitScoreBreakdown(
            colorMatch: colorScore,
            styleMatch: styleScore,
            occasionMatch: occasionScore,
            proportion: proportionScore,
          );

          final explanation = _buildExplanation(
            items: items,
            occasion: occasion,
            style: style,
            breakdown: breakdown,
            weatherCondition: weatherCondition,
            needsJacket: needsJacket && jacket != null,
          );

          candidates.add(
            Outfit(
              id: 'outfit_${DateTime.now().microsecondsSinceEpoch}_${candidates.length}',
              itemIds: items.map((e) => e.id).toList(),
              occasion: occasion,
              style: style,
              weatherSummary: '${temperatureC.round()}°C • $weatherCondition',
              scoreBreakdown: breakdown,
              aiExplanation: explanation,
            ),
          );
        }
        if (attempts > maxAttempts) break;
      }
      if (attempts > maxAttempts) break;
    }

    // OUTFIT RANKING: sort by overall score, deduplicate similar outfits.
    candidates.sort(
      (a, b) => b.scoreBreakdown.overall.compareTo(a.scoreBreakdown.overall),
    );

    final results = <Outfit>[];
    final seenSignatures = <String>{};
    for (final o in candidates) {
      final sig = (o.itemIds..sort()).join(',');
      if (seenSignatures.contains(sig)) continue;
      seenSignatures.add(sig);
      results.add(o);
      if (results.length >= count) break;
    }

    return results;
  }

  /// Remix: keep some items fixed, regenerate the rest from wardrobe.
  static Outfit remixOutfit({
    required Outfit original,
    required List<WardrobeItem> wardrobe,
    required Set<String> keepItemIds,
    required String occasion,
    required String style,
    required double temperatureC,
    required String weatherCondition,
  }) {
    final keptItems = wardrobe
        .where((i) => keepItemIds.contains(i.id))
        .toList();
    final keptCategories = keptItems.map((i) => i.category).toSet();

    final rng = _rng;
    WardrobeItem pick(String category, WardrobeItem? exclude) {
      final pool = wardrobe
          .where((i) => i.category == category && i.id != exclude?.id)
          .toList();
      if (pool.isEmpty) return exclude!;
      pool.shuffle(rng);
      return pool.first;
    }

    final items = <WardrobeItem>[...keptItems];

    if (!keptCategories.contains(ItemCategory.top)) {
      items.add(pick(ItemCategory.top, null));
    }
    if (!keptCategories.contains(ItemCategory.bottom)) {
      items.add(pick(ItemCategory.bottom, null));
    }
    if (!keptCategories.contains(ItemCategory.shoes)) {
      items.add(pick(ItemCategory.shoes, null));
    }

    final needsJacket = temperatureC < 22;
    final hasOuterwear = items.any((i) => i.category == ItemCategory.outerwear);
    if (needsJacket && !hasOuterwear) {
      final outerwearPool = wardrobe
          .where((i) => i.category == ItemCategory.outerwear)
          .toList();
      if (outerwearPool.isNotEmpty) {
        outerwearPool.shuffle(rng);
        items.add(outerwearPool.first);
      }
    }

    final colorScore = _colorMatchScore(items, 'Any');
    final styleScore = _styleMatchScore(items, style);
    final occasionScore = _occasionMatchScore(items, occasion, style);
    final top = items.firstWhere(
      (i) => i.category == ItemCategory.top,
      orElse: () => items.first,
    );
    final bottom = items.firstWhere(
      (i) => i.category == ItemCategory.bottom,
      orElse: () => items.first,
    );
    final proportionScore = _proportionScore(top, bottom);

    final breakdown = OutfitScoreBreakdown(
      colorMatch: colorScore,
      styleMatch: styleScore,
      occasionMatch: occasionScore,
      proportion: proportionScore,
    );

    final explanation = _buildExplanation(
      items: items,
      occasion: occasion,
      style: style,
      breakdown: breakdown,
      weatherCondition: weatherCondition,
      needsJacket: needsJacket,
    );

    return Outfit(
      id: 'outfit_${DateTime.now().microsecondsSinceEpoch}_remix',
      itemIds: items.map((e) => e.id).toList(),
      occasion: occasion,
      style: style,
      weatherSummary: '${temperatureC.round()}°C • $weatherCondition',
      scoreBreakdown: breakdown,
      aiExplanation: explanation,
    );
  }

  // ---------------- Scoring sub-functions ----------------

  /// Deterministic "natural variance" derived from the outfit's own items
  /// (and a salt so the four sub-scores differ from each other). This keeps
  /// results feeling organic while guaranteeing the SAME outfit always gets
  /// the SAME score — so rankings are stable and the logic is unit-testable.
  /// Returns an int in the range [-range, +range].
  static int _stableVariance(
    List<WardrobeItem> items,
    String salt,
    int range,
  ) {
    final key = '${items.map((i) => i.id).join('|')}#$salt';
    // Simple stable string hash (FNV-1a style, non-cryptographic).
    int hash = 0x811c9dc5;
    for (final codeUnit in key.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    final span = range * 2 + 1;
    return (hash % span) - range;
  }

  static double _colorMatchScore(
    List<WardrobeItem> items,
    String colorPreference,
  ) {
    final colors = items.map((i) => i.color.toLowerCase()).toList();
    double score = 70;

    final neutralCount = colors.where((c) => _neutrals.contains(c)).length;
    final brightCount = colors.where((c) => _brights.contains(c)).length;

    // Neutral-heavy outfits score higher for color harmony.
    score += (neutralCount / colors.length) * 20;

    // Too many bright/clashing colors reduces score.
    if (brightCount > 1) score -= (brightCount - 1) * 12;

    // Preference match bonus.
    if (colorPreference != 'Any') {
      final matches = colors
          .where((c) => c.contains(colorPreference.toLowerCase()))
          .isNotEmpty;
      score += matches ? 8 : -5;
    }

    // Deterministic natural variance so results feel organic but stable.
    score += _stableVariance(items, 'color', 2);

    return score.clamp(55, 99).toDouble();
  }

  static double _styleMatchScore(
    List<WardrobeItem> items,
    String desiredStyle,
  ) {
    final matches = items
        .where((i) => i.style.toLowerCase() == desiredStyle.toLowerCase())
        .length;
    final ratio = matches / items.length;
    double score = 60 + ratio * 35;
    score += _stableVariance(items, 'style', 2);
    return score.clamp(55, 99).toDouble();
  }

  static double _occasionMatchScore(
    List<WardrobeItem> items,
    String occasion,
    String style,
  ) {
    final acceptable = _occasionStyleAffinity[occasion] ?? const [];
    double score = 65;
    if (acceptable.contains(style)) score += 20;
    final matchingItems = items
        .where((i) => acceptable.contains(i.style))
        .length;
    score += (matchingItems / items.length) * 10;
    score += _stableVariance(items, 'occasion', 2);
    return score.clamp(55, 99).toDouble();
  }

  static double _proportionScore(WardrobeItem top, WardrobeItem bottom) {
    double score = 75;
    final topFit = top.fit.toLowerCase();
    final bottomFit = bottom.fit.toLowerCase();

    // Balanced silhouette: oversized top + slim/regular bottom, or vice versa.
    final isBalanced =
        (topFit.contains('oversized') && !bottomFit.contains('oversized')) ||
        (bottomFit.contains('wide') && !topFit.contains('oversized')) ||
        (topFit == bottomFit && topFit == 'regular');

    if (isBalanced) score += 15;
    score += _stableVariance([top, bottom], 'proportion', 3);
    return score.clamp(55, 99).toDouble();
  }

  static String _buildExplanation({
    required List<WardrobeItem> items,
    required String occasion,
    required String style,
    required OutfitScoreBreakdown breakdown,
    required String weatherCondition,
    required bool needsJacket,
  }) {
    final top = items.firstWhere(
      (i) => i.category == ItemCategory.top,
      orElse: () => items.first,
    );
    final bottom = items.firstWhere(
      (i) => i.category == ItemCategory.bottom,
      orElse: () => items.first,
    );

    final colorNote = breakdown.colorMatch > 85
        ? 'The neutral tones create a clean, cohesive contrast that works for almost any setting.'
        : 'The color palette pairs reasonably well, though a more neutral accessory could sharpen the look.';

    final styleNote = breakdown.styleMatch > 85
        ? 'Every piece reflects a consistent $style aesthetic, so the outfit reads as intentional rather than random.'
        : 'Most pieces lean $style, giving the outfit a cohesive identity for $occasion.';

    final weatherNote = needsJacket
        ? ' Since it\'s $weatherCondition today, a light outer layer was added for comfort.'
        : '';

    return 'Your ${top.color.toLowerCase()} ${top.type.toLowerCase()} pairs well with the '
        '${bottom.color.toLowerCase()} ${bottom.type.toLowerCase()} because $colorNote $styleNote$weatherNote';
  }

  /// Suggest what category of item is missing to unlock more outfit combos.
  static List<String> suggestMissingItems(List<WardrobeItem> wardrobe) {
    final suggestions = <String>[];
    final outerwearCount = wardrobe
        .where((i) => i.category == ItemCategory.outerwear)
        .length;
    final shoesCount = wardrobe
        .where((i) => i.category == ItemCategory.shoes)
        .length;
    final neutralTops = wardrobe
        .where(
          (i) =>
              i.category == ItemCategory.top &&
              _neutrals.contains(i.color.toLowerCase()),
        )
        .length;

    if (outerwearCount < 2) {
      suggestions.add(
        'A neutral lightweight jacket could unlock more layered outfit combinations.',
      );
    }
    if (shoesCount < 3) {
      suggestions.add(
        'Adding a versatile pair of neutral sneakers would expand your shoe rotation.',
      );
    }
    if (neutralTops < 3) {
      suggestions.add(
        'A few more neutral-colored tops (black/white/gray) would make mixing easier.',
      );
    }
    return suggestions;
  }
}
