import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/wardrobe_item.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/profile_provider.dart';
import '../services/usage_limit_service.dart';
import '../widgets/item_image.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';
import 'analytics_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ItemCategory.all.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();
    final tier = context.watch<ProfileProvider>().profile.subscriptionTier;
    final isPro = UsageLimitService.isPro(tier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Wardrobe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
            ),
            tooltip: 'Analytics',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: ItemCategory.all
              .map(
                (c) => Tab(
                  text:
                      '${ItemCategory.emoji(c)} $c (${wardrobe.countByCategory(c)})',
                ),
              )
              .toList(),
        ),
      ),
      body: Column(
        children: [
          if (!isPro)
            Container(
              width: double.infinity,
              color: AppColors.surfaceAlt,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${wardrobe.totalItems} / ${UsageLimitService.freeWardrobeItemLimit} items used on the Free plan',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: ItemCategory.all
                  .map((category) => _CategoryGrid(category: category))
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.background,
        onPressed: () {
          final currentCategory = ItemCategory.all[_tabController.index];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddItemScreen(initialCategory: currentCategory),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final String category;
  const _CategoryGrid({required this.category});

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();
    final items = wardrobe.byCategory(category);

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ItemCategory.emoji(category),
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                'No $category yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Tap "Add Item" to snap or upload a photo.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ItemImage(
                  item: item,
                  size: 200,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.type,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              Text(item.color, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}
