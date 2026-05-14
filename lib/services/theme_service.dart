import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

enum AppThemeMode { light, dark, system }

class ThemeService extends ChangeNotifier {
  static const _key = 'themeMode';

  AppThemeMode _mode = AppThemeMode.system;

  AppThemeMode get mode => _mode;

  ThemeMode get flutterThemeMode {
    switch (_mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  static ThemeData get lightTheme => AppTheme.light;
  static ThemeData get darkTheme => AppTheme.dark;

  ThemeService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null) {
      _mode = AppThemeMode.values.firstWhere(
        (e) => e.name == stored,
        orElse: () => AppThemeMode.system,
      );
      notifyListeners();
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  Future<void> cycleMode() async {
    final next = AppThemeMode.values[(_mode.index + 1) % AppThemeMode.values.length];
    await setMode(next);
  }
}
