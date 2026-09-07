import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/outfit.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/outfit_provider.dart';
import '../providers/profile_provider.dart';
import '../services/ai_stylist_service.dart';
import '../services/weather_service.dart';
import '../services/usage_limit_service.dart';
import '../widgets/item_image.dart';
import '../widgets/paywall.dart';
import 'outfit_result_screen.dart';

class RemixScreen extends StatefulWidget {
  final Outfit outfit;
  const RemixScreen({super.key, required this.outfit});

  @override
  State<RemixScreen> createState() => _RemixScreenState();
}

class _RemixScreenState extends State<RemixScreen> {
  late Set<String> _keepIds;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    // Default: keep top & bottom, change the rest.
    _keepIds = {};
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();
    final items = wardrobe.byIds(widget.outfit.itemIds);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Remix Outfit')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  Text(
                    'Select items to KEEP. Unselected items will be changed by the AI.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ...items.map((item) {
                    final kept = _keepIds.contains(item.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: CheckboxListTile(
                        value: kept,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.ink,
                        secondary: ItemImage(item: item, size: 48),
                        title: Text('${item.color} ${item.type}'),
                        subtitle: Text(item.category),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _keepIds.add(item.id);
                            } else {
                              _keepIds.remove(item.id);
                            }
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generating ? null : _generateRemix,
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
                  label: Text(_generating ? 'REMIXING...' : '✨ REMIX'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateRemix() async {
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

    setState(() => _generating = true);
    final wardrobe = context.read<WardrobeProvider>().items;
    final weather = await WeatherService.fetchWeather();
    await Future.delayed(const Duration(milliseconds: 900));

    final remixed = AiStylistService.remixOutfit(
      original: widget.outfit,
      wardrobe: wardrobe,
      keepItemIds: _keepIds,
      occasion: widget.outfit.occasion,
      style: widget.outfit.style,
      temperatureC: weather.temperatureC,
      weatherCondition: weather.condition,
    );

    if (!mounted) return;
    setState(() => _generating = false);

    context.read<OutfitProvider>().recordGenerated(1);
    await UsageLimitService.recordGeneration(tier);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OutfitResultScreen(outfits: [remixed])),
    );
  }
}
