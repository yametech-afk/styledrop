import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/wardrobe_item.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/outfit_provider.dart';
import '../providers/profile_provider.dart';
import '../services/weather_service.dart';
import '../services/ai_stylist_service.dart';
import '../services/notification_service.dart';
import '../services/usage_limit_service.dart';
import '../utils/constants.dart';
import '../widgets/paywall.dart';
import 'outfit_result_screen.dart';

class AiGeneratorScreen extends StatefulWidget {
  const AiGeneratorScreen({super.key});

  @override
  State<AiGeneratorScreen> createState() => _AiGeneratorScreenState();
}

class _AiGeneratorScreenState extends State<AiGeneratorScreen> {
  String _occasion = 'Casual';
  String _style = 'Streetwear';
  String _colorPref = 'Any';
  String _shoePref = 'Any';
  bool _autoWeather = true;
  final bool _onlyMyWardrobe = true;
  int _numberOfOutfits = 5;
  bool _generating = false;
  WeatherInfo? _weather;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final w = await WeatherService.fetchWeather();
      if (mounted) setState(() => _weather = w);
    });
  }

  Future<void> _generate() async {
    final wardrobe = context.read<WardrobeProvider>().items;

    if (wardrobe.where((i) => i.category == ItemCategory.top).isEmpty ||
        wardrobe.where((i) => i.category == ItemCategory.bottom).isEmpty ||
        wardrobe.where((i) => i.category == ItemCategory.shoes).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You need at least one top, bottom, and pair of shoes in your wardrobe.',
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

    setState(() => _generating = true);

    // When "Automatic" weather is ON, use the live/estimated reading so
    // outfits are weather-appropriate. When the user turns it OFF, generate
    // without any weather constraint (mild neutral defaults) so results
    // aren't filtered by temperature/rain — this makes the toggle actually
    // do something instead of being ignored.
    final double temperatureC;
    final String weatherCondition;
    if (_autoWeather) {
      final weather = _weather ?? await WeatherService.fetchWeather();
      temperatureC = weather.temperatureC;
      weatherCondition = weather.condition;
    } else {
      temperatureC = 24; // mild — no jacket forced, not "too hot" either
      weatherCondition = 'Mild';
    }

    final outfits = AiStylistService.generateOutfits(
      wardrobe: wardrobe,
      occasion: _occasion,
      style: _style,
      colorPreference: _colorPref,
      weatherCondition: weatherCondition,
      temperatureC: temperatureC,
      shoePreference: _shoePref,
      count: _numberOfOutfits,
    );

    if (!mounted) return;
    setState(() => _generating = false);

    if (outfits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not generate outfits with current filters. Try loosening preferences.',
          ),
        ),
      );
      return;
    }

    context.read<OutfitProvider>().setLastGenerated(outfits);
    context.read<OutfitProvider>().recordGenerated(outfits.length);
    await UsageLimitService.recordGeneration(tier);
    unawaited(NotificationService.notifyOutfitGenerated(outfits.length));

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
    final tier = context.watch<ProfileProvider>().profile.subscriptionTier;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('✨ AI Stylist')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text(
              'Create your outfit',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (!UsageLimitService.isPro(tier)) ...[
              const SizedBox(height: 6),
              Text(
                '${UsageLimitService.remainingGenerations(tier)} of ${UsageLimitService.freeDailyGenerationLimit} free generations left today',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
              ),
            ],
            const SizedBox(height: 20),
            _sectionLabel('Occasion'),
            _dropdown(
              _occasion,
              AppConstants.occasions,
              (v) => setState(() => _occasion = v),
            ),
            const SizedBox(height: 16),
            _sectionLabel('Style'),
            _dropdown(
              _style,
              AppConstants.styles,
              (v) => setState(() => _style = v),
            ),
            const SizedBox(height: 16),
            _sectionLabel('Color preference'),
            _dropdown(
              _colorPref,
              AppConstants.colorPreferences,
              (v) => setState(() => _colorPref = v),
            ),
            const SizedBox(height: 16),
            _sectionLabel('Weather'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _weather == null
                      ? 'Automatic'
                      : 'Automatic (${_weather!.temperatureC.round()}°C ${_weather!.condition})',
                ),
                value: _autoWeather,
                activeThumbColor: AppColors.ink,
                onChanged: (v) => setState(() => _autoWeather = v),
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('Shoes'),
            _dropdown(
              _shoePref,
              AppConstants.shoePreferences,
              (v) => setState(() => _shoePref = v),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use only my wardrobe'),
                subtitle: const Text(
                  'Never suggests items you don\'t own',
                  style: TextStyle(fontSize: 11),
                ),
                value: _onlyMyWardrobe,
                activeThumbColor: AppColors.ink,
                onChanged: null, // Always true - this is the core product rule
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('Number of outfits'),
            _dropdownInt(_numberOfOutfits, [
              3,
              5,
              8,
            ], (v) => setState(() => _numberOfOutfits = v)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generating ? null : _generate,
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
                label: Text(_generating ? 'GENERATING...' : 'GENERATE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );

  Widget _dropdown(
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _dropdownInt(
    int value,
    List<int> options,
    ValueChanged<int> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text('$o outfits')))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
