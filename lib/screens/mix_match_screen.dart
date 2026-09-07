import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/wardrobe_item.dart';
import '../models/outfit.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/outfit_provider.dart';
import '../providers/profile_provider.dart';
import '../services/usage_limit_service.dart';
import '../widgets/item_image.dart';
import '../widgets/paywall.dart';
import 'outfit_result_screen.dart';

class MixMatchScreen extends StatefulWidget {
  const MixMatchScreen({super.key});

  @override
  State<MixMatchScreen> createState() => _MixMatchScreenState();
}

class _MixMatchScreenState extends State<MixMatchScreen> {
  final Map<String, WardrobeItem?> _slots = {
    ItemCategory.top: null,
    ItemCategory.bottom: null,
    ItemCategory.shoes: null,
    ItemCategory.accessory: null,
  };

  double get _matchScore {
    final chosen = _slots.values.whereType<WardrobeItem>().toList();
    if (chosen.length < 2) return 0;
    // Simple heuristic reusing color/style neutrality logic inline.
    final neutrals = {
      'black',
      'white',
      'gray',
      'grey',
      'beige',
      'navy',
      'brown',
    };
    final neutralCount = chosen
        .where((i) => neutrals.contains(i.color.toLowerCase()))
        .length;
    final sameStyleCount = <String, int>{};
    for (final i in chosen) {
      sameStyleCount[i.style] = (sameStyleCount[i.style] ?? 0) + 1;
    }
    final dominantStyleRatio =
        (sameStyleCount.values.isEmpty
            ? 0
            : sameStyleCount.values.reduce((a, b) => a > b ? a : b)) /
        chosen.length;
    double score =
        55 + (neutralCount / chosen.length) * 25 + dominantStyleRatio * 20;
    return score.clamp(0, 99).toDouble();
  }

  Future<void> _pickItem(String category) async {
    final wardrobe = context.read<WardrobeProvider>();
    final options = wardrobe.byCategory(category);
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No $category in your wardrobe yet.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<WardrobeItem>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose $category',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 320,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: options.length,
                  itemBuilder: (c, i) {
                    final item = options[i];
                    return GestureDetector(
                      onTap: () => Navigator.pop(ctx, item),
                      child: Column(
                        children: [
                          ItemImage(
                            item: item,
                            size: 80,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.color,
                            style: Theme.of(ctx).textTheme.bodySmall,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() => _slots[category] = selected);
    }
  }

  Future<void> _askAi() async {
    final chosen = _slots.values.whereType<WardrobeItem>().toList();
    if (chosen.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick at least 2 items before asking the AI.'),
        ),
      );
      return;
    }

    final tier = context.read<ProfileProvider>().profile.subscriptionTier;
    if (!UsageLimitService.canGenerate(tier)) {
      await showPaywall(
        context,
        reason:
            "You've used all ${UsageLimitService.freeDailyGenerationLimit} "
            'free AI generations for today. Upgrade for unlimited outfits.',
      );
      return;
    }

    final outfit = Outfit(
      id: const Uuid().v4(),
      itemIds: chosen.map((e) => e.id).toList(),
      occasion: 'Casual',
      style: chosen.first.style,
      weatherSummary: 'Manual build',
      scoreBreakdown: OutfitScoreBreakdown(
        colorMatch: _matchScore,
        styleMatch: _matchScore - 3,
        occasionMatch: _matchScore - 5,
        proportion: _matchScore + 2,
      ),
      aiExplanation:
          'This is a manually curated combination. The AI estimates a ${_matchScore.round()}% match based on color harmony and style consistency across your selected pieces.',
    );

    context.read<OutfitProvider>().recordGenerated(1);
    await UsageLimitService.recordGeneration(tier);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OutfitResultScreen(outfits: [outfit])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Outfit')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            for (final entry in _slots.entries) ...[
              _slotTile(entry.key, entry.value),
              if (entry.key != _slots.keys.last)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Center(
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontSize: 20,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${_matchScore.round()}% MATCH',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _askAi,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('✨ ASK AI'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotTile(String category, WardrobeItem? item) {
    return GestureDetector(
      onTap: () => _pickItem(category),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            item != null
                ? ItemImage(item: item, size: 56)
                : Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ItemCategory.emoji(category),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    item != null
                        ? '${item.color} ${item.type}'
                        : 'Tap to select',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}
