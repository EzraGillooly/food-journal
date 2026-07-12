import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// Holds the active theme, persisted across sessions. Supports the built-in
/// presets plus a user-created custom theme. Defaults to Soft Blush.
class ThemeController extends Notifier<AppTheme> {
  static const _presetKey = 'theme_preset';
  static const _customKey = 'custom_theme_colors';

  AppTheme? _custom;

  /// The saved custom theme, if the user has created one (may be null until the
  /// async load finishes on startup).
  AppTheme? get customTheme => _custom;

  @override
  AppTheme build() {
    _load();
    return AppTheme.softBlush;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_customKey);
    if (encoded != null) _custom = AppTheme.decodeColors(encoded);
    final name = prefs.getString(_presetKey);
    if (name == null) return;
    if (name == AppThemePreset.custom.name) {
      if (_custom != null) state = _custom!;
      return;
    }
    final preset = AppThemePreset.values
        .where((p) => p.name == name)
        .firstOrNull;
    if (preset != null && preset != AppThemePreset.custom) {
      state = AppTheme.byPreset(preset);
    }
  }

  Future<void> select(AppThemePreset preset) async {
    if (preset == AppThemePreset.custom) {
      if (_custom == null) return;
      state = _custom!;
    } else {
      state = AppTheme.byPreset(preset);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_presetKey, preset.name);
  }

  /// Saves and applies a user-created custom theme.
  Future<void> saveCustom(AppTheme custom) async {
    _custom = custom;
    state = custom;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customKey, custom.encodeColors());
    await prefs.setString(_presetKey, AppThemePreset.custom.name);
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, AppTheme>(
  ThemeController.new,
);
