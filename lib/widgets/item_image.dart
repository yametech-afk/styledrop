import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/wardrobe_item.dart';
import '../theme/app_theme.dart';

/// Renders a wardrobe item's image, supporting both bundled asset images
/// (seed data) and user-captured file images, with a graceful fallback
/// showing the category emoji.
class ItemImage extends StatelessWidget {
  final WardrobeItem item;
  final double size;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const ItemImage({
    super.key,
    required this.item,
    this.size = 64,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(14);

    Widget child;
    if (item.imageBytes != null) {
      child = Image.memory(
        item.imageBytes!,
        fit: fit,
        width: size,
        height: size,
      );
    } else if (!kIsWeb &&
        item.imagePath != null &&
        File(item.imagePath!).existsSync()) {
      child = Image.file(
        File(item.imagePath!),
        fit: fit,
        width: size,
        height: size,
      );
    } else if (item.assetPath != null) {
      child = Image.asset(item.assetPath!, fit: fit, width: size, height: size);
    } else {
      child = Container(
        width: size,
        height: size,
        color: AppColors.surfaceAlt,
        alignment: Alignment.center,
        child: Text(
          ItemCategory.emoji(item.category),
          style: TextStyle(fontSize: size * 0.4),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: AppColors.surfaceAlt,
        child: child,
      ),
    );
  }
}
