import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Wardrobe categories exactly as specified in the product spec.
class ItemCategory {
  ItemCategory._();
  static const String top = 'Tops';
  static const String bottom = 'Bottoms';
  static const String shoes = 'Shoes';
  static const String outerwear = 'Outerwear';
  static const String accessory = 'Accessories';
  static const String bag = 'Bags';
  static const String watch = 'Watches';
  static const String jewelry = 'Jewelry';

  static const List<String> all = [
    top,
    bottom,
    shoes,
    outerwear,
    accessory,
    bag,
    watch,
    jewelry,
  ];

  static String emoji(String category) {
    switch (category) {
      case top:
        return '👕';
      case bottom:
        return '👖';
      case shoes:
        return '👟';
      case outerwear:
        return '🧥';
      case accessory:
        return '🧢';
      case bag:
        return '👜';
      case watch:
        return '⌚';
      case jewelry:
        return '💍';
      default:
        return '👕';
    }
  }
}

class WardrobeItem {
  final String id;
  final String category;
  final String type; // e.g. "Oversized T-Shirt"
  final String color; // primary color name
  final String secondaryColor;
  final String pattern; // Plain, Striped, Graphic, Checked...
  final String style; // Streetwear, Casual, Minimalist, Formal...
  final String fit; // Oversized, Slim, Regular, Relaxed...
  final String season; // All Season, Summer, Winter...
  final String brand;
  final String? imagePath; // local file path (mobile/desktop)
  final String? assetPath; // bundled asset path (seed data)
  final Uint8List? imageBytes; // in-memory bytes (web platform)
  final int timesWorn;
  final DateTime createdAt;
  final bool isFavoriteItem;

  WardrobeItem({
    required this.id,
    required this.category,
    required this.type,
    required this.color,
    this.secondaryColor = '',
    this.pattern = 'Plain',
    this.style = 'Casual',
    this.fit = 'Regular',
    this.season = 'All Season',
    this.brand = '',
    this.imagePath,
    this.assetPath,
    this.imageBytes,
    this.timesWorn = 0,
    DateTime? createdAt,
    this.isFavoriteItem = false,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasImage =>
      (!kIsWeb && imagePath != null && File(imagePath!).existsSync()) ||
      assetPath != null ||
      imageBytes != null;

  WardrobeItem copyWith({
    String? category,
    String? type,
    String? color,
    String? secondaryColor,
    String? pattern,
    String? style,
    String? fit,
    String? season,
    String? brand,
    String? imagePath,
    String? assetPath,
    Uint8List? imageBytes,
    int? timesWorn,
    bool? isFavoriteItem,
  }) {
    return WardrobeItem(
      id: id,
      category: category ?? this.category,
      type: type ?? this.type,
      color: color ?? this.color,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      pattern: pattern ?? this.pattern,
      style: style ?? this.style,
      fit: fit ?? this.fit,
      season: season ?? this.season,
      brand: brand ?? this.brand,
      imagePath: imagePath ?? this.imagePath,
      assetPath: assetPath ?? this.assetPath,
      imageBytes: imageBytes ?? this.imageBytes,
      timesWorn: timesWorn ?? this.timesWorn,
      createdAt: createdAt,
      isFavoriteItem: isFavoriteItem ?? this.isFavoriteItem,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'category': category,
    'type': type,
    'color': color,
    'secondaryColor': secondaryColor,
    'pattern': pattern,
    'style': style,
    'fit': fit,
    'season': season,
    'brand': brand,
    'imagePath': imagePath,
    'assetPath': assetPath,
    'imageBytesB64': imageBytes != null ? base64Encode(imageBytes!) : null,
    'timesWorn': timesWorn,
    'createdAt': createdAt.toIso8601String(),
    'isFavoriteItem': isFavoriteItem,
  };

  factory WardrobeItem.fromMap(Map<dynamic, dynamic> map) {
    final b64 = map['imageBytesB64'] as String?;
    return WardrobeItem(
      id: map['id'] as String,
      category: map['category'] as String,
      type: map['type'] as String? ?? '',
      color: map['color'] as String? ?? 'Black',
      secondaryColor: map['secondaryColor'] as String? ?? '',
      pattern: map['pattern'] as String? ?? 'Plain',
      style: map['style'] as String? ?? 'Casual',
      fit: map['fit'] as String? ?? 'Regular',
      season: map['season'] as String? ?? 'All Season',
      brand: map['brand'] as String? ?? '',
      imagePath: map['imagePath'] as String?,
      assetPath: map['assetPath'] as String?,
      imageBytes: b64 != null ? base64Decode(b64) : null,
      timesWorn: (map['timesWorn'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isFavoriteItem: map['isFavoriteItem'] as bool? ?? false,
    );
  }
}
