import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/outfit_provider.dart';
import '../models/outfit.dart';
import '../widgets/item_image.dart';
import 'outfit_result_screen.dart';
import 'outfit_calendar_screen.dart';
import 'mix_match_screen.dart';
import 'remix_screen.dart';

class SavedOutfitsScreen extends StatelessWidget {
  const SavedOutfitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final outfitProvider = context.watch<OutfitProvider>();
    final saved = outfitProvider.savedOutfits;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Outfits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Outfit Calendar',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OutfitCalendarScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.dashboard_customize_outlined),
            tooltip: 'Mix & Match',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MixMatchScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: saved.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('❤️', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        'No saved outfits yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Generate an outfit with the AI Stylist and tap SAVE.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.78,
                ),
                itemCount: saved.length,
                itemBuilder: (context, i) => _SavedOutfitCard(outfit: saved[i]),
              ),
      ),
    );
  }
}

class _SavedOutfitCard extends StatelessWidget {
  final Outfit outfit;
  const _SavedOutfitCard({required this.outfit});

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OutfitResultScreen(outfits: [outfit])),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                _rename(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.checkroom_outlined),
              title: const Text('Wear today'),
              onTap: () async {
                await context.read<OutfitProvider>().markWornToday(outfit.id);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Remix'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RemixScreen(outfit: outfit),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                await context.read<OutfitProvider>().deleteOutfit(outfit.id);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _rename(BuildContext context) {
    final ctrl = TextEditingController(text: outfit.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename outfit'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'e.g. Friday Fit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<OutfitProvider>().renameOutfit(
                outfit.id,
                ctrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();
    final items = wardrobe.byIds(outfit.itemIds);
    final score = outfit.scoreBreakdown.overall;
    final scoreEmoji = score >= 90 ? '⭐' : (score >= 80 ? '🔥' : '💎');

    return GestureDetector(
      onTap: () => _openDetail(context),
      onLongPress: () => _showActions(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: items
                    .take(4)
                    .map(
                      (i) => ItemImage(
                        item: i,
                        size: 46,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              outfit.name.isNotEmpty ? outfit.name : '${outfit.style} Fit',
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(scoreEmoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '${(score / 10).toStringAsFixed(1)}/10',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
