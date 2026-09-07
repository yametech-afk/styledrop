import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/outfit.dart';

/// Visualizes an [OutfitScoreBreakdown]'s four sub-scores (color, style,
/// occasion, proportion) as labelled progress bars, plus the overall score.
///
/// This showcases the stylist's reasoning instead of hiding it behind a single
/// number — making the app feel smarter and more trustworthy.
class ScoreBreakdownView extends StatelessWidget {
  final OutfitScoreBreakdown breakdown;
  final bool animate;

  const ScoreBreakdownView({
    super.key,
    required this.breakdown,
    this.animate = true,
  });

  Color _scoreColor(double v) {
    if (v >= 85) return AppColors.success;
    if (v >= 70) return AppColors.gold;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final overall = breakdown.overall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Style Score', style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            Text(
              '${overall.round()}%',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: _scoreColor(overall)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _bar(context, 'Color', breakdown.colorMatch),
        _bar(context, 'Style', breakdown.styleMatch),
        _bar(context, 'Occasion', breakdown.occasionMatch),
        _bar(context, 'Proportion', breakdown.proportion),
      ],
    );
  }

  Widget _bar(BuildContext context, String label, double value) {
    final pct = (value.clamp(0, 100)) / 100.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: animate ? pct : pct),
                duration: animate
                    ? const Duration(milliseconds: 700)
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation(_scoreColor(value)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(
              '${value.round()}%',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
