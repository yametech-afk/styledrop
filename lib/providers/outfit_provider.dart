import 'package:flutter/foundation.dart';
import '../models/outfit.dart';
import '../services/storage_service.dart';
import '../services/sync_repository.dart';

class OutfitProvider extends ChangeNotifier {
  List<Outfit> _outfits = [];
  List<Outfit> _lastGenerated = [];

  List<Outfit> get outfits => List.unmodifiable(_outfits);
  List<Outfit> get lastGenerated => List.unmodifiable(_lastGenerated);
  List<Outfit> get savedOutfits => _outfits.where((o) => o.favorite).toList();
  List<Outfit> get plannedOutfits =>
      _outfits.where((o) => o.plannedDate != null).toList();

  int get totalGenerated => StorageService.getOutfitsGeneratedCount();

  void load() {
    _outfits = StorageService.getOutfits();
    notifyListeners();
  }

  void setLastGenerated(List<Outfit> outfits) {
    _lastGenerated = outfits;
    notifyListeners();
  }

  Future<void> recordGenerated(int count) async {
    await StorageService.incrementOutfitsGenerated(count);
    notifyListeners();
  }

  Future<void> saveOutfit(Outfit outfit) async {
    await SyncRepository.instance.saveOutfit(outfit);
    load();
  }

  Future<void> toggleFavorite(Outfit outfit) async {
    outfit.favorite = !outfit.favorite;
    await SyncRepository.instance.saveOutfit(outfit);
    load();
  }

  Future<void> deleteOutfit(String id) async {
    await SyncRepository.instance.deleteOutfit(id);
    load();
  }

  Future<void> renameOutfit(String id, String name) async {
    final outfit = _findOutfit(id);
    if (outfit == null) {
      debugPrint('OutfitProvider.renameOutfit: outfit "$id" not found');
      return;
    }
    outfit.name = name;
    await SyncRepository.instance.saveOutfit(outfit);
    load();
  }

  /// Finds an outfit by id in either the persisted list or the last-generated
  /// (not-yet-saved) list. Returns null if it exists in neither, instead of
  /// throwing an uncaught StateError that would crash the caller.
  Outfit? _findOutfit(String id) {
    for (final o in _outfits) {
      if (o.id == id) return o;
    }
    for (final o in _lastGenerated) {
      if (o.id == id) return o;
    }
    return null;
  }

  Future<void> planOutfit(String id, DateTime date) async {
    final outfit = _findOutfit(id);
    if (outfit == null) {
      debugPrint('OutfitProvider.planOutfit: outfit "$id" not found');
      return;
    }
    outfit.plannedDate = date;
    await SyncRepository.instance.saveOutfit(outfit);
    load();
  }

  Future<void> markWornToday(String id) async {
    final outfit = _findOutfit(id);
    if (outfit == null) {
      debugPrint('OutfitProvider.markWornToday: outfit "$id" not found');
      return;
    }
    outfit.timesWorn += 1;
    await SyncRepository.instance.saveOutfit(outfit);
    load();
  }

  List<Outfit> outfitsForDate(DateTime date) {
    return _outfits
        .where(
          (o) =>
              o.plannedDate != null &&
              o.plannedDate!.year == date.year &&
              o.plannedDate!.month == date.month &&
              o.plannedDate!.day == date.day,
        )
        .toList();
  }
}
