import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';

/// Holds the active theme preset. Defaults to Soft Blush.
///
/// Persistence across reloads is added in a later task; for now this keeps the
/// selection in memory so the app can be re-themed from a single source.
class ThemeController extends Notifier<AppTheme> {
  @override
  AppTheme build() => AppTheme.softBlush;

  void select(AppThemePreset preset) => state = AppTheme.byPreset(preset);
}

final themeControllerProvider = NotifierProvider<ThemeController, AppTheme>(
  ThemeController.new,
);
