import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/wardrobe_provider.dart';
import '../services/ai_stylist_service.dart';

class MissingItemsScreen extends StatelessWidget {
  const MissingItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();
    final suggestions = AiStylistService.suggestMissingItems(wardrobe.items);
    final counts = wardrobe.categoryCounts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Wardrobe Analysis')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'YOUR WARDROBE ANALYSIS',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You have:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    for (final entry in counts.entries)
                      if (entry.value > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            '✓ ${entry.value} ${entry.key.toLowerCase()}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (suggestions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your wardrobe is well balanced! No obvious gaps found.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Text('Missing:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              for (final suggestion in suggestions)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Adding these items could unlock approximately ${suggestions.length * 6}+ additional outfit combinations.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
