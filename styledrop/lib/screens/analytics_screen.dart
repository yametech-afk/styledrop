import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/wardrobe_item.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/outfit_provider.dart';
import '../widgets/item_image.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();
    final outfitProvider = context.watch<OutfitProvider>();
    final counts = wardrobe.categoryCounts;
    final mostUsed = wardrobe.mostUsed;
    final leastUsed = wardrobe.leastUsed;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Wardrobe Insights')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    context,
                    '${wardrobe.totalItems}',
                    'Total Items',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    context,
                    '${outfitProvider.totalGenerated}',
                    'Outfits Generated',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Category Breakdown',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY:
                          (counts.values.isEmpty
                                  ? 1
                                  : counts.values.reduce(
                                      (a, b) => a > b ? a : b,
                                    ))
                              .toDouble() +
                          4,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final categories = ItemCategory.all;
                              final idx = value.toInt();
                              if (idx < 0 || idx >= categories.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  ItemCategory.emoji(categories[idx]),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barGroups: List.generate(ItemCategory.all.length, (i) {
                        final cat = ItemCategory.all[i];
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: (counts[cat] ?? 0).toDouble(),
                              color: AppColors.ink,
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _usageCard(context, 'Most Used', mostUsed, wardrobe),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _usageCard(context, 'Least Used', leastUsed, wardrobe),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Most Common Color',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '⚫ ${wardrobe.mostCommonColor} — ${wardrobe.mostCommonColorPercentage.round()}%',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Style',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '🔥 Streetwear',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _usageCard(
    BuildContext context,
    String title,
    WardrobeItem? item,
    WardrobeProvider wardrobe,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          if (item != null) ...[
            ItemImage(item: item, size: 56),
            const SizedBox(height: 8),
            Text(
              '${item.color} ${item.type}',
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Used ${item.timesWorn} times',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else
            Text('No data yet', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
