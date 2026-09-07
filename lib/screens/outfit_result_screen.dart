import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/outfit.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/outfit_provider.dart';
import '../providers/profile_provider.dart';
import '../services/usage_limit_service.dart';
import '../widgets/item_image.dart';
import '../widgets/paywall.dart';
import 'remix_screen.dart';

class OutfitResultScreen extends StatefulWidget {
  final List<Outfit> outfits;
  final int initialIndex;
  const OutfitResultScreen({
    super.key,
    required this.outfits,
    this.initialIndex = 0,
  });

  @override
  State<OutfitResultScreen> createState() => _OutfitResultScreenState();
}

class _OutfitResultScreenState extends State<OutfitResultScreen> {
  late PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('AI Outfit #${_index + 1} / ${widget.outfits.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.outfits.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => _OutfitDetailView(
          outfit: widget.outfits[i],
          allOutfits: widget.outfits,
        ),
      ),
    );
  }
}

class _OutfitDetailView extends StatelessWidget {
  final Outfit outfit;
  final List<Outfit> allOutfits;
  const _OutfitDetailView({required this.outfit, required this.allOutfits});

  Future<void> _save(BuildContext context) async {
    final tier = context.read<ProfileProvider>().profile.subscriptionTier;
    final savedCount = context.read<OutfitProvider>().savedOutfits.length;
    if (!UsageLimitService.canSaveOutfit(tier, savedCount)) {
      await showPaywall(
        context,
        reason:
            'You can save up to ${UsageLimitService.freeSavedOutfitLimit} '
            'outfits on the Free plan. Upgrade to save unlimited outfits.',
      );
      return;
    }

    outfit.favorite = true;
    await context.read<OutfitProvider>().saveOutfit(outfit);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❤️ Outfit saved to your favorites')),
    );
  }

  Future<void> _share(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📤 Outfit link copied — share sheet coming soon'),
      ),
    );
  }

  void _remix(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RemixScreen(outfit: outfit)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();
    final items = wardrobe.byIds(outfit.itemIds);
    final breakdown = outfit.scoreBreakdown;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: items
                  .map(
                    (item) => ItemImage(
                      item: item,
                      size: 100,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥 ', style: TextStyle(fontSize: 14)),
                Text(
                  '${outfit.style.toUpperCase()} FIT',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${_accessoryEmoji(item.category)} ${item.color} ${item.type}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STYLE SCORE',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                '${breakdown.overall.round()}%',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: breakdown.overall / 100,
              minHeight: 10,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(AppColors.ink),
            ),
          ),
          const SizedBox(height: 16),
          _scoreRow(context, 'Color Match', breakdown.colorMatch),
          _scoreRow(context, 'Style Match', breakdown.styleMatch),
          _scoreRow(context, 'Occasion', breakdown.occasionMatch),
          _scoreRow(context, 'Proportion', breakdown.proportion),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI STYLIST',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '"${outfit.aiExplanation}"',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _save(context),
                  icon: const Icon(Icons.favorite_border, size: 18),
                  label: const Text('SAVE'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _remix(context),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('REMIX'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _share(context),
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('SHARE'),
            ),
          ),
        ],
      ),
    );
  }

  String _accessoryEmoji(String category) {
    const map = {
      'Tops': '👕',
      'Bottoms': '👖',
      'Shoes': '👟',
      'Outerwear': '🧥',
      'Accessories': '🧢',
      'Bags': '👜',
      'Watches': '⌚',
      'Jewelry': '⛓️',
    };
    return map[category] ?? '•';
  }

  Widget _scoreRow(BuildContext context, String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 6,
                backgroundColor: AppColors.surfaceAlt,
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${value.round()}%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
