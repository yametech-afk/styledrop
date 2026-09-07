import 'package:flutter/foundation.dart';
import '../models/wardrobe_item.dart';
import '../services/storage_service.dart';
import '../services/sync_repository.dart';

class WardrobeProvider extends ChangeNotifier {
  List<WardrobeItem> _items = [];

  List<WardrobeItem> get items => List.unmodifiable(_items);

  /// Reads come from the fast local Hive cache; writes are mirrored to the
  /// cloud by [SyncRepository] when a real user is signed in.
  void load() {
    _items = StorageService.getWardrobe();
    notifyListeners();
  }

  List<WardrobeItem> byCategory(String category) =>
      _items.where((i) => i.category == category).toList();

  int countByCategory(String category) =>
      _items.where((i) => i.category == category).length;

  WardrobeItem? byId(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<WardrobeItem> byIds(List<String> ids) {
    return ids.map((id) => byId(id)).whereType<WardrobeItem>().toList();
  }

  Future<void> addItem(WardrobeItem item) async {
    await SyncRepository.instance.saveItem(item);
    load();
  }

  Future<void> updateItem(WardrobeItem item) async {
    await SyncRepository.instance.saveItem(item);
    load();
  }

  Future<void> deleteItem(String id) async {
    await SyncRepository.instance.deleteItem(id);
    load();
  }

  Future<void> incrementWorn(String id) async {
    final item = byId(id);
    if (item == null) return;
    final updated = item.copyWith(timesWorn: item.timesWorn + 1);
    await SyncRepository.instance.saveItem(updated);
    load();
  }

  int get totalItems => _items.length;

  Map<String, int> get categoryCounts {
    final map = <String, int>{};
    for (final c in ItemCategory.all) {
      map[c] = countByCategory(c);
    }
    return map;
  }

  /// Most / least worn items for analytics.
  WardrobeItem? get mostUsed {
    if (_items.isEmpty) return null;
    final sorted = List<WardrobeItem>.from(_items)
      ..sort((a, b) => b.timesWorn.compareTo(a.timesWorn));
    return sorted.first;
  }

  WardrobeItem? get leastUsed {
    if (_items.isEmpty) return null;
    final sorted = List<WardrobeItem>.from(_items)
      ..sort((a, b) => a.timesWorn.compareTo(b.timesWorn));
    return sorted.first;
  }

  String get mostCommonColor {
    if (_items.isEmpty) return 'N/A';
    final counts = <String, int>{};
    for (final item in _items) {
      counts[item.color] = (counts[item.color] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  double get mostCommonColorPercentage {
    if (_items.isEmpty) return 0;
    final counts = <String, int>{};
    for (final item in _items) {
      counts[item.color] = (counts[item.color] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return (sorted.first.value / _items.length) * 100;
  }
}
