/// A generated or manually-built outfit, referencing WardrobeItem IDs only.
/// This enforces the core product rule: outfits are ALWAYS built from items
/// the user actually owns - never invented items.
class OutfitScoreBreakdown {
  final double colorMatch;
  final double styleMatch;
  final double occasionMatch;
  final double proportion;

  const OutfitScoreBreakdown({
    required this.colorMatch,
    required this.styleMatch,
    required this.occasionMatch,
    required this.proportion,
  });

  double get overall =>
      ((colorMatch + styleMatch + occasionMatch + proportion) / 4);

  Map<String, dynamic> toMap() => {
    'colorMatch': colorMatch,
    'styleMatch': styleMatch,
    'occasionMatch': occasionMatch,
    'proportion': proportion,
  };

  factory OutfitScoreBreakdown.fromMap(Map<dynamic, dynamic> map) =>
      OutfitScoreBreakdown(
        colorMatch: (map['colorMatch'] as num?)?.toDouble() ?? 0,
        styleMatch: (map['styleMatch'] as num?)?.toDouble() ?? 0,
        occasionMatch: (map['occasionMatch'] as num?)?.toDouble() ?? 0,
        proportion: (map['proportion'] as num?)?.toDouble() ?? 0,
      );
}

class Outfit {
  final String id;
  final List<String> itemIds; // wardrobe item ids composing the outfit
  final String occasion;
  final String style;
  final String weatherSummary;
  final OutfitScoreBreakdown scoreBreakdown;
  final String aiExplanation;
  final DateTime createdAt;
  bool favorite;
  String name;
  DateTime? plannedDate; // for outfit calendar
  int timesWorn;

  Outfit({
    required this.id,
    required this.itemIds,
    required this.occasion,
    required this.style,
    required this.weatherSummary,
    required this.scoreBreakdown,
    required this.aiExplanation,
    DateTime? createdAt,
    this.favorite = false,
    this.name = '',
    this.plannedDate,
    this.timesWorn = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'itemIds': itemIds,
    'occasion': occasion,
    'style': style,
    'weatherSummary': weatherSummary,
    'scoreBreakdown': scoreBreakdown.toMap(),
    'aiExplanation': aiExplanation,
    'createdAt': createdAt.toIso8601String(),
    'favorite': favorite,
    'name': name,
    'plannedDate': plannedDate?.toIso8601String(),
    'timesWorn': timesWorn,
  };

  factory Outfit.fromMap(Map<dynamic, dynamic> map) {
    return Outfit(
      id: map['id'] as String,
      itemIds: List<String>.from(map['itemIds'] as List? ?? []),
      occasion: map['occasion'] as String? ?? 'Casual',
      style: map['style'] as String? ?? 'Casual',
      weatherSummary: map['weatherSummary'] as String? ?? '',
      scoreBreakdown: OutfitScoreBreakdown.fromMap(
        map['scoreBreakdown'] as Map? ?? {},
      ),
      aiExplanation: map['aiExplanation'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      favorite: map['favorite'] as bool? ?? false,
      name: map['name'] as String? ?? '',
      plannedDate: map['plannedDate'] != null
          ? DateTime.tryParse(map['plannedDate'] as String)
          : null,
      timesWorn: (map['timesWorn'] as num?)?.toInt() ?? 0,
    );
  }
}
