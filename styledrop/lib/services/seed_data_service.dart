import 'package:uuid/uuid.dart';
import '../models/wardrobe_item.dart';
import 'storage_service.dart';

/// Populates the wardrobe with realistic starter items on first launch so
/// the app feels alive immediately (matching the home screen mock: 24 tops,
/// 12 bottoms, 8 shoes, 5 jackets, 7 accessories). Uses bundled asset images
/// generated for the demo.
class SeedDataService {
  // Cached process-wide UUID generator (Uuid() is not a const constructor).
  static final Uuid _uuid = Uuid();

  static Future<void> seedIfNeeded() async {
    if (StorageService.getSeedApplied()) return;

    final items = <WardrobeItem>[
      // Tops
      WardrobeItem(
        id: _uuid.v4(),
        category: ItemCategory.top,
        type: 'Oversized T-Shirt',
        color: 'Black',
        pattern: 'Plain',
        style: 'Streetwear',
        fit: 'Oversized',
        season: 'All Season',
        assetPath: 'assets/images/black_tee.png',
        timesWorn: 24,
      ),
      WardrobeItem(
        id: _uuid.v4(),
        category: ItemCategory.top,
        type: 'Plain T-Shirt',
        color: 'White',
        pattern: 'Plain',
        style: 'Minimalist',
        fit: 'Regular',
        season: 'All Season',
        assetPath: 'assets/images/white_tee.png',
        timesWorn: 18,
      ),
      for (int i = 0; i < 22; i++)
        WardrobeItem(
          id: _uuid.v4(),
          category: ItemCategory.top,
          type: [
            'Graphic Tee',
            'Polo Shirt',
            'Hoodie',
            'Button-up Shirt',
            'Sweater',
            'Long Sleeve Tee',
          ][i % 6],
          color: ['Black', 'White', 'Gray', 'Navy', 'Beige', 'Olive'][i % 6],
          pattern: i % 4 == 0 ? 'Graphic' : 'Plain',
          style: [
            'Streetwear',
            'Casual',
            'Minimalist',
            'Smart Casual',
            'Korean',
          ][i % 5],
          fit: ['Oversized', 'Regular', 'Slim', 'Relaxed'][i % 4],
          season: 'All Season',
          assetPath: i.isEven
              ? 'assets/images/black_tee.png'
              : 'assets/images/white_tee.png',
          timesWorn: (i * 2) % 20,
        ),

      // Bottoms
      WardrobeItem(
        id: _uuid.v4(),
        category: ItemCategory.bottom,
        type: 'Cargo Pants',
        color: 'Gray',
        pattern: 'Plain',
        style: 'Streetwear',
        fit: 'Relaxed',
        season: 'All Season',
        assetPath: 'assets/images/gray_cargo.png',
        timesWorn: 15,
      ),
      WardrobeItem(
        id: _uuid.v4(),
        category: ItemCategory.bottom,
        type: 'Straight Jeans',
        color: 'Black',
        pattern: 'Plain',
        style: 'Casual',
        fit: 'Regular',
        season: 'All Season',
        assetPath: 'assets/images/black_jeans.png',
        timesWorn: 20,
      ),
      for (int i = 0; i < 10; i++)
        WardrobeItem(
          id: _uuid.v4(),
          category: ItemCategory.bottom,
          type: [
            'Chinos',
            'Denim Shorts',
            'Sweatpants',
            'Wide-leg Trousers',
          ][i % 4],
          color: ['Black', 'Gray', 'Beige', 'Navy'][i % 4],
          pattern: 'Plain',
          style: ['Streetwear', 'Casual', 'Smart Casual', 'Minimalist'][i % 4],
          fit: ['Regular', 'Relaxed', 'Slim'][i % 3],
          season: 'All Season',
          assetPath: i.isEven
              ? 'assets/images/gray_cargo.png'
              : 'assets/images/black_jeans.png',
          timesWorn: (i * 3) % 18,
        ),

      // Shoes
      WardrobeItem(
        id: _uuid.v4(),
        category: ItemCategory.shoes,
        type: 'Sneakers',
        color: 'White',
        pattern: 'Plain',
        style: 'Streetwear',
        fit: 'Regular',
        season: 'All Season',
        assetPath: 'assets/images/white_sneakers.png',
        timesWorn: 30,
      ),
      WardrobeItem(
        id: _uuid.v4(),
        category: ItemCategory.shoes,
        type: 'Ankle Boots',
        color: 'Black',
        pattern: 'Plain',
        style: 'Old Money',
        fit: 'Regular',
        season: 'Winter',
        assetPath: 'assets/images/black_boots.png',
        timesWorn: 8,
      ),
      for (int i = 0; i < 6; i++)
        WardrobeItem(
          id: _uuid.v4(),
          category: ItemCategory.shoes,
          type: ['Running Shoes', 'Loafers', 'Sandals', 'High-tops'][i % 4],
          color: ['White', 'Black', 'Gray', 'Brown'][i % 4],
          pattern: 'Plain',
          style: ['Sporty', 'Old Money', 'Streetwear', 'Casual'][i % 4],
          fit: 'Regular',
          season: 'All Season',
          assetPath: i.isEven
              ? 'assets/images/white_sneakers.png'
              : 'assets/images/black_boots.png',
          timesWorn: (i * 2) % 15,
        ),

      // Outerwear
      WardrobeItem(
        id: _uuid.v4(),
        category: ItemCategory.outerwear,
        type: 'Bomber Jacket',
        color: 'Beige',
        pattern: 'Plain',
        style: 'Streetwear',
        fit: 'Relaxed',
        season: 'Spring/Fall',
        assetPath: 'assets/images/beige_jacket.png',
        timesWorn: 12,
      ),
      for (int i = 0; i < 4; i++)
        WardrobeItem(
          id: _uuid.v4(),
          category: ItemCategory.outerwear,
          type: [
            'Denim Jacket',
            'Windbreaker',
            'Overcoat',
            'Puffer Jacket',
          ][i % 4],
          color: ['Black', 'Navy', 'Beige', 'Gray'][i % 4],
          pattern: 'Plain',
          style: ['Streetwear', 'Casual', 'Old Money', 'Techwear'][i % 4],
          fit: 'Regular',
          season: 'Winter',
          assetPath: 'assets/images/beige_jacket.png',
          timesWorn: (i * 2) % 10,
        ),

      // Accessories (cap, chain, bag)
      WardrobeItem(
        id: _uuid.v4(),
        category: ItemCategory.accessory,
        type: 'Cap',
        color: 'Black',
        pattern: 'Plain',
        style: 'Streetwear',
        fit: 'Regular',
        season: 'All Season',
        assetPath: 'assets/images/black_cap.png',
        timesWorn: 22,
      ),
      WardrobeItem(
        id: _uuid.v4(),
        category: ItemCategory.jewelry,
        type: 'Chain Necklace',
        color: 'Silver',
        pattern: 'Plain',
        style: 'Streetwear',
        fit: 'Regular',
        season: 'All Season',
        assetPath: 'assets/images/silver_chain.png',
        timesWorn: 14,
      ),
      WardrobeItem(
        id: _uuid.v4(),
        category: ItemCategory.bag,
        type: 'Crossbody Bag',
        color: 'Brown',
        pattern: 'Plain',
        style: 'Old Money',
        fit: 'Regular',
        season: 'All Season',
        assetPath: 'assets/images/brown_bag.png',
        timesWorn: 9,
      ),
      for (int i = 0; i < 4; i++)
        WardrobeItem(
          id: _uuid.v4(),
          category: [ItemCategory.accessory, ItemCategory.watch][i % 2],
          type: ['Beanie', 'Sunglasses', 'Analog Watch', 'Smart Watch'][i % 4],
          color: ['Black', 'Gray', 'Brown', 'Silver'][i % 4],
          pattern: 'Plain',
          style: ['Streetwear', 'Minimalist', 'Old Money', 'Techwear'][i % 4],
          fit: 'Regular',
          season: 'All Season',
          assetPath: 'assets/images/black_cap.png',
          timesWorn: (i * 2) % 10,
        ),
    ];

    for (final item in items) {
      await StorageService.saveItem(item);
    }

    await StorageService.setSeedApplied();
  }
}
