import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/color_mapper.dart';

/// A small circular swatch showing an item's color, optionally followed by the
/// color name. More scannable and more "fashion app" than plain text.
class ColorSwatchDot extends StatelessWidget {
  final String colorName;
  final double size;
  final bool showLabel;

  const ColorSwatchDot({
    super.key,
    required this.colorName,
    this.size = 12,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final swatch = Semantics(
      label: 'Colour: $colorName',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: ColorMapper.fromName(colorName),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line, width: 1),
        ),
      ),
    );

    if (!showLabel) return swatch;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 6),
        Text(colorName, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
