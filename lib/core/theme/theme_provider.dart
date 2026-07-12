import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// Holds the active theme preset, persisted across sessions. Defaults to Soft
/// Blush until a saved choice loads (and if none was ever saved).
class ThemeController extends Notifier<AppTheme> {
  static const _key = 'theme_preset';

  @override
  AppTheme build() {
    _load();
    return AppTheme.softBlush;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    if (name == null) return;
    final preset = AppThemePreset.values
        .where((p) => p.name == name)
        .firstOrNull;
    if (preset != null) state = AppTheme.byPreset(preset);
  }

  Future<void> select(AppThemePreset preset) async {
    state = AppTheme.byPreset(preset);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, preset.name);
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, AppTheme>(
  ThemeController.new,
);
