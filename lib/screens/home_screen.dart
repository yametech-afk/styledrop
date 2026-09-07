import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/wardrobe_item.dart';
import '../models/outfit.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/outfit_provider.dart';
import '../providers/profile_provider.dart';
import '../services/weather_service.dart';
import '../services/ai_stylist_service.dart';
import '../services/notification_service.dart';
import '../services/usage_limit_service.dart';
import '../widgets/item_image.dart';
import '../widgets/paywall.dart';
import '../widgets/shimmer.dart';
import '../widgets/color_swatch_dot.dart';
import '../widgets/score_breakdown.dart';
import 'outfit_result_screen.dart';
import 'ai_generator_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int index) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WeatherInfo? _weather;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWeather());
  }

  Future<void> _loadWeather() async {
    final w = await WeatherService.fetchWeather();
    if (mounted) setState(() => _weather = w);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _quickGenerate() async {
    final wardrobe = context.read<WardrobeProvider>().items;
    if (wardrobe.where((i) => i.category == ItemCategory.top).isEmpty ||
        wardrobe.where((i) => i.category == ItemCategory.bottom).isEmpty ||
        wardrobe.where((i) => i.category == ItemCategory.shoes).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add a few tops, bottoms & shoes to your wardrobe first.',
          ),
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
      if (!mounted) return;
      return;
    }

    final preferredStyles = context
        .read<ProfileProvider>()
        .profile
        .styleDna
        .preferredStyles;
    final preferredStyle = preferredStyles.isNotEmpty
        ? preferredStyles.first
        : 'Streetwear';

    HapticFeedback.mediumImpact();
    setState(() => _generating = true);
    final weather = _weather ?? await WeatherService.fetchWeather();

    final outfits = AiStylistService.generateOutfits(
      wardrobe: wardrobe,
      occasion: 'Casual',
      style: preferredStyle,
      colorPreference: 'Any',
      weatherCondition: weather.condition,
      temperatureC: weather.temperatureC,
      shoePreference: 'Any',
      count: 3,
    );

    if (!mounted) return;
    setState(() => _generating = false);

    if (outfits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough wardrobe items to generate an outfit yet.'),
        ),
      );
      return;
    }

    context.read<OutfitProvider>().setLastGenerated(outfits);
    context.read<OutfitProvider>().recordGenerated(outfits.length);
    await UsageLimitService.recordGeneration(tier);
    unawaited(NotificationService.notifyOutfitGenerated(outfits.length));

    // Celebrate a great result with a stronger haptic.
    if (outfits.first.scoreBreakdown.overall >= 90) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.selectionClick();
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutfitResultScreen(outfits: outfits, initialIndex: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();
    final profile = context.watch<ProfileProvider>().profile;
    final counts = wardrobe.categoryCounts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.ink,
          onRefresh: () async {
            await WeatherService.fetchWeather(forceRefresh: true);
            _loadWeather();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STYLEDROP',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surfaceAlt,
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '${_greeting()} 👋',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'What are you wearing today?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generating ? null : _quickGenerate,
                  icon: _generating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(
                    _generating ? 'GENERATING...' : 'GENERATE OUTFIT',
                  ),
                ),
              ),
              if (!UsageLimitService.isPro(profile.subscriptionTier)) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${UsageLimitService.remainingGenerations(profile.subscriptionTier)} of ${UsageLimitService.freeDailyGenerationLimit} free generations left today',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _WeatherCard(weather: _weather),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'YOUR WARDROBE',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  TextButton(
                    onPressed: () => widget.onNavigate(1),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  _WardrobeStatTile(
                    emoji: '👕',
                    label: 'Tops',
                    count: counts[ItemCategory.top] ?? 0,
                  ),
                  _WardrobeStatTile(
                    emoji: '👖',
                    label: 'Bottoms',
                    count: counts[ItemCategory.bottom] ?? 0,
                  ),
                  _WardrobeStatTile(
                    emoji: '👟',
                    label: 'Shoes',
                    count: counts[ItemCategory.shoes] ?? 0,
                  ),
                  _WardrobeStatTile(
                    emoji: '🧥',
                    label: 'Jackets',
                    count: counts[ItemCategory.outerwear] ?? 0,
                  ),
                  _WardrobeStatTile(
                    emoji: '🧢',
                    label: 'Accessories',
                    count: counts[ItemCategory.accessory] ?? 0,
                  ),
                  _WardrobeStatTile(
                    emoji: '👜',
                    label: 'Bags',
                    count: counts[ItemCategory.bag] ?? 0,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                '🔥 Recommended Today',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              _RecommendedOutfitCard(
            onQuickGenerate: _quickGenerate,
            weather: _weather,
          ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AiGeneratorScreen(),
                        ),
                      ),
                      child: const Text('CUSTOM STYLE'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final WeatherInfo? weather;
  const _WeatherCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: weather == null
          ? Row(
              children: [
                Shimmer.box(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.box(width: 120, height: 10),
                      const SizedBox(height: 8),
                      Shimmer.box(width: 80, height: 14),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Text(weather!.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather!.locationLabel != null
                            ? "Today's Weather • ${weather!.locationLabel}"
                            : "Today's Weather",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${weather!.temperatureC.round()}°C  •  ${weather!.condition}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                if (!weather!.isLive)
                  Tooltip(
                    message:
                        'Location unavailable — showing an estimated reading. '
                        'Grant location permission for live weather.',
                    child: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _WardrobeStatTile extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;

  const _WardrobeStatTile({
    required this.emoji,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text('$count', style: Theme.of(context).textTheme.titleMedium),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Shows a REAL top-scoring outfit computed from the user's actual wardrobe,
/// with its genuine score breakdown — no more hardcoded 94%.
class _RecommendedOutfitCard extends StatefulWidget {
  final VoidCallback onQuickGenerate;
  final WeatherInfo? weather;
  const _RecommendedOutfitCard({
    required this.onQuickGenerate,
    required this.weather,
  });

  @override
  State<_RecommendedOutfitCard> createState() => _RecommendedOutfitCardState();
}

class _RecommendedOutfitCardState extends State<_RecommendedOutfitCard> {
  Outfit? _recommended;
  String _signature = '';

  /// Recompute only when the wardrobe or weather actually changes, so the
  /// recommendation is stable between rebuilds (no flicker).
  void _recompute(List<WardrobeItem> wardrobe) {
    final weather = widget.weather;
    final sig =
        '${wardrobe.length}_${weather?.temperatureC.round()}_${weather?.condition}';
    if (sig == _signature) return;
    _signature = sig;

    final preferredStyles =
        context.read<ProfileProvider>().profile.styleDna.preferredStyles;
    final style = preferredStyles.isNotEmpty ? preferredStyles.first : 'Casual';

    final outfits = AiStylistService.generateOutfits(
      wardrobe: wardrobe,
      occasion: 'Casual',
      style: style,
      colorPreference: 'Any',
      weatherCondition: weather?.condition ?? 'Mild',
      temperatureC: weather?.temperatureC ?? 22,
      shoePreference: 'Any',
      count: 1,
    );
    _recommended = outfits.isNotEmpty ? outfits.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();
    _recompute(wardrobe.items);

    final outfit = _recommended;
    if (outfit == null) {
      return _EmptyRecommendation(onQuickGenerate: widget.onQuickGenerate);
    }

    final items = wardrobe.byIds(outfit.itemIds);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: items
                .take(5)
                .map<Widget>(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ItemImage(item: item, size: 56),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                    ItemCategory.emoji(item.category),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  ColorSwatchDot(colorName: item.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${item.color} ${item.type}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // REAL score breakdown from the generated outfit.
          ScoreBreakdownView(breakdown: outfit.scoreBreakdown),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onQuickGenerate,
              child: const Text('VIEW OUTFIT'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecommendation extends StatelessWidget {
  final VoidCallback onQuickGenerate;
  const _EmptyRecommendation({required this.onQuickGenerate});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a top, a bottom and a pair of shoes to get your first '
            'recommended outfit here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onQuickGenerate,
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('TRY GENERATING'),
          ),
        ],
      ),
    );
  }
}
