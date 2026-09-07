import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/profile_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/outfit_provider.dart';
import '../services/notification_service.dart';
import '../services/usage_limit_service.dart';
import '../utils/constants.dart';
import '../utils/color_mapper.dart';
import '../widgets/paywall.dart';
import 'analytics_screen.dart';
import 'missing_items_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;
    final wardrobe = context.watch<WardrobeProvider>();
    final outfitProvider = context.watch<OutfitProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.surfaceAlt,
                  child: Text(
                    profile.name.isNotEmpty
                        ? profile.name[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      fontSize: 24,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        profile.isGuest ? 'Guest account' : profile.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: profile.subscriptionTier == 'FREE'
                              ? AppColors.surfaceAlt
                              : AppColors.ink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          profile.subscriptionTier,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: profile.subscriptionTier == 'FREE'
                                ? AppColors.ink
                                : AppColors.background,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _statBox(context, '${wardrobe.totalItems}', 'Items'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statBox(
                    context,
                    '${outfitProvider.totalGenerated}',
                    'Outfits Made',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statBox(
                    context,
                    '${outfitProvider.savedOutfits.length}',
                    'Saved',
                  ),
                ),
              ],
            ),
            if (!UsageLimitService.isPro(profile.subscriptionTier)) ...[
              const SizedBox(height: 20),
              _FreeTierUsageCard(
                wardrobeCount: wardrobe.totalItems,
                savedCount: outfitProvider.savedOutfits.length,
                onUpgrade: () => showPaywall(context),
              ),
            ],
            const SizedBox(height: 28),
            Text('STYLE DNA', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferred styles',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.styleDna.preferredStyles
                          .map((s) => Chip(label: Text('🔥 $s')))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Favorite colors',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: profile.styleDna.favoriteColors
                          .map(
                            (c) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 8,
                                  backgroundColor: ColorMapper.fromName(c),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  c,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Preferred fit: ',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          profile.styleDna.preferredFit,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Avoid: ',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '❌ ${profile.styleDna.avoidColors.join(', ')}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AI Style Profile',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    ...profile.styleDna.styleAffinity.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: Text(
                                e.key,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: e.value / 100,
                                  minHeight: 6,
                                  backgroundColor: AppColors.surfaceAlt,
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppColors.gold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${e.value.round()}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            _editStyleDna(context, profileProvider),
                        child: const Text('Edit preferences'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _menuTile(
              context,
              Icons.bar_chart_rounded,
              'Wardrobe Analytics',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              ),
            ),
            _menuTile(
              context,
              Icons.lightbulb_outline,
              'Missing Item Suggestions',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MissingItemsScreen()),
              ),
            ),
            _menuTile(
              context,
              Icons.workspace_premium_outlined,
              'Upgrade to PRO',
              () => showPaywall(context),
            ),
            _menuTile(
              context,
              Icons.notifications_outlined,
              'Notifications',
              () => _showNotifications(context),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _logout(context),
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(BuildContext context, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _menuTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.ink),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: AppColors.mutedText),
        onTap: onTap,
      ),
    );
  }

  void _editStyleDna(BuildContext context, ProfileProvider provider) {
    final selectedStyles = Set<String>.from(
      provider.profile.styleDna.preferredStyles,
    );
    final selectedColors = Set<String>.from(
      provider.profile.styleDna.favoriteColors,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Style DNA',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Preferred styles',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.styles.map((s) {
                    final selected = selectedStyles.contains(s);
                    return FilterChip(
                      label: Text(s),
                      selected: selected,
                      onSelected: (v) => setSheetState(() {
                        if (v) {
                          selectedStyles.add(s);
                        } else {
                          selectedStyles.remove(s);
                        }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Favorite colors',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                        'Black',
                        'White',
                        'Gray',
                        'Beige',
                        'Navy',
                        'Brown',
                        'Olive',
                      ].map((c) {
                        final selected = selectedColors.contains(c);
                        return FilterChip(
                          label: Text(c),
                          selected: selected,
                          onSelected: (v) => setSheetState(() {
                            if (v) {
                              selectedColors.add(c);
                            } else {
                              selectedColors.remove(c);
                            }
                          }),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await provider.updateStyleDna(
                        preferredStyles: selectedStyles.toList(),
                        favoriteColors: selectedColors.toList(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('SAVE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    final notifications = NotificationService.history;
    NotificationService.markAllRead();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: notifications.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔔', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text(
                      'No notifications yet',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Generate an outfit or plan one on the calendar to '
                      'see real-time alerts here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ],
                ),
              )
            : ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                children: notifications
                    .map(
                      (n) => ListTile(
                        leading: Text(
                          n.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(n.title),
                        subtitle: Text(n.body),
                        trailing: Text(
                          _relativeTime(n.createdAt),
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  void _logout(BuildContext context) async {
    // Signing out flips the Firebase auth stream; the StreamBuilder in
    // AppRoot (main.dart) automatically returns to the LoginScreen, so no
    // manual navigation is required here.
    await context.read<ProfileProvider>().logout();
  }
}

/// Shows a FREE-tier user their remaining daily AI-generation quota and
/// wardrobe/saved-outfit usage against the enforced caps, with a quick
/// upgrade shortcut. Hidden entirely for PRO/PRO+ users.
class _FreeTierUsageCard extends StatelessWidget {
  final int wardrobeCount;
  final int savedCount;
  final VoidCallback onUpgrade;

  const _FreeTierUsageCard({
    required this.wardrobeCount,
    required this.savedCount,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = UsageLimitService.remainingGenerations('FREE');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FREE PLAN USAGE',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              TextButton(onPressed: onUpgrade, child: const Text('Upgrade')),
            ],
          ),
          const SizedBox(height: 8),
          _usageLine(
            context,
            '✨ AI generations today',
            '$remaining / ${UsageLimitService.freeDailyGenerationLimit} left',
          ),
          _usageLine(
            context,
            '👕 Wardrobe items',
            '$wardrobeCount / ${UsageLimitService.freeWardrobeItemLimit}',
          ),
          _usageLine(
            context,
            '❤️ Saved outfits',
            '$savedCount / ${UsageLimitService.freeSavedOutfitLimit}',
          ),
        ],
      ),
    );
  }

  Widget _usageLine(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
