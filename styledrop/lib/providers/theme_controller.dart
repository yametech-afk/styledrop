import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// Holds the app's [ThemeMode] (system / light / dark) and persists the choice
/// to Hive so it survives restarts. Exposed via Provider and consumed by the
/// root MaterialApp.
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  void load() {
    _mode = _fromString(StorageService.getThemeMode());
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    await StorageService.setThemeMode(_toString(mode));
    notifyListeners();
  }

  /// Convenience toggle between light and dark (used by the profile switch).
  Future<void> toggleDark(bool dark) =>
      setMode(dark ? ThemeMode.dark : ThemeMode.light);

  ThemeMode _fromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
