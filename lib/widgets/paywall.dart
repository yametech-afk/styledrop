import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/profile_provider.dart';

/// Shared upgrade sheet used everywhere a Free-tier limit is hit (AI
/// generation quota, wardrobe size cap, saved-outfit cap) as well as from
/// the Profile screen's "Upgrade to PRO" menu item.
///
/// Selecting a plan immediately (and locally) sets [UserProfile.subscriptionTier]
/// via [ProfileProvider] — there's no real payment processor wired up in this
/// build, but the tier change is genuinely persisted (Hive) and genuinely
/// unlocks the previously-enforced Free-tier limits, unlike the old sheet
/// which was purely decorative and didn't change any state.
///
/// Returns `true` if the user upgraded, `false`/`null` if they dismissed
/// without upgrading.
Future<bool?> showPaywall(BuildContext context, {String? reason}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.background,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upgrade your plan',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            if (reason != null) ...[
              const SizedBox(height: 6),
              Text(
                reason,
                style: Theme.of(
                  ctx,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
              ),
            ],
            const SizedBox(height: 16),
            _PlanCard(
              tierCode: 'PRO',
              tier: 'PRO',
              price: '₱149/month',
              features: const [
                'Unlimited wardrobe',
                'Unlimited outfit generation',
                'Advanced styles',
                'Outfit calendar',
                'Weather-based recommendations',
                'AI wardrobe analysis',
              ],
            ),
            const SizedBox(height: 12),
            _PlanCard(
              tierCode: 'PRO_PLUS',
              tier: 'PRO+',
              price: '₱299/month',
              features: const [
                'Everything in Pro',
                'Virtual try-on',
                'Personal style profile',
                'Advanced AI styling',
                'Higher-quality visualization',
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _PlanCard extends StatelessWidget {
  final String tierCode; // Value stored in UserProfile.subscriptionTier
  final String tier; // Display label
  final String price;
  final List<String> features;

  const _PlanCard({
    required this.tierCode,
    required this.tier,
    required this.price,
    required this.features,
  });

  Future<void> _select(BuildContext context) async {
    final profileProvider = context.read<ProfileProvider>();
    profileProvider.profile.subscriptionTier = tierCode;
    await profileProvider.save();
    if (!context.mounted) return;
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🎉 Upgraded to $tier — limits removed!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _select(context),
      child: Container(
        width: double.infinity,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tier, style: Theme.of(context).textTheme.titleLarge),
                Text(price, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 10),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _select(context),
                child: Text('CHOOSE $tier'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
