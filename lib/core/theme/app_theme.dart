import 'package:flutter/material.dart';

/// A named palette + font pairing for the app.
///
/// Soft Blush is the primary theme; the others are saved alternates from the
/// spec so the look can be swapped from one place (see [AppTheme.all]).
enum AppThemePreset { softBlush, cottageCream, warmBakery, gardenFresh }

/// Immutable design tokens for a single theme preset.
@immutable
class AppTheme {
  const AppTheme({
    required this.preset,
    required this.label,
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.ink,
    required this.inkMuted,
    required this.tagBg,
    required this.tagInk,
    required this.headingFont,
    required this.bodyFont,
  });

  final AppThemePreset preset;
  final String label;
  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color ink;
  final Color inkMuted;
  final Color tagBg;
  final Color tagInk;
  final String headingFont;
  final String bodyFont;

  /// Text/icon colour that sits on top of [primary]-filled surfaces. Centralised
  /// so on-primary contrast lives in one place instead of hardcoded per widget.
  Color get onPrimary => Colors.white;

  /// Primary theme - matches the reference aesthetic.
  static const softBlush = AppTheme(
    preset: AppThemePreset.softBlush,
    label: 'Soft Blush',
    background: Color(0xFFF6EEEA),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFC98A93),
    secondary: Color(0xFFD9B48A),
    ink: Color(0xFF6B3B42),
    inkMuted: Color(0xFF9A7A80),
    tagBg: Color(0xFFF2E2E5),
    tagInk: Color(0xFF8A4A56),
    headingFont: 'LibreBodoni',
    bodyFont: 'Karla',
  );

  static const cottageCream = AppTheme(
    preset: AppThemePreset.cottageCream,
    label: 'Cottage Cream',
    background: Color(0xFFFBF8F0),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF7C8A5A),
    secondary: Color(0xFFB6A16A),
    ink: Color(0xFF3F4A32),
    inkMuted: Color(0xFF7A7A6E),
    tagBg: Color(0xFFEAEFDC),
    tagInk: Color(0xFF5A6B38),
    headingFont: 'LibreBodoni',
    bodyFont: 'Karla',
  );

  static const warmBakery = AppTheme(
    preset: AppThemePreset.warmBakery,
    label: 'Warm Bakery',
    background: Color(0xFFFAF6F2),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFC08552),
    secondary: Color(0xFFE0B87A),
    ink: Color(0xFF5A4632),
    inkMuted: Color(0xFF8A7A6A),
    tagBg: Color(0xFFF5E6D3),
    tagInk: Color(0xFF8A5A2A),
    headingFont: 'LibreBodoni',
    bodyFont: 'Karla',
  );

  static const gardenFresh = AppTheme(
    preset: AppThemePreset.gardenFresh,
    label: 'Garden Fresh',
    background: Color(0xFFF4F6F1),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF6E9457),
    secondary: Color(0xFFE3A94E),
    ink: Color(0xFF33482F),
    inkMuted: Color(0xFF6E7A66),
    tagBg: Color(0xFFE0EBD6),
    tagInk: Color(0xFF4A6B3A),
    headingFont: 'LibreBodoni',
    bodyFont: 'Karla',
  );

  static const List<AppTheme> all = [
    softBlush,
    cottageCream,
    warmBakery,
    gardenFresh,
  ];

  static AppTheme byPreset(AppThemePreset preset) =>
      all.firstWhere((t) => t.preset == preset, orElse: () => softBlush);

  /// Builds a Material [ThemeData] from these tokens.
  ThemeData toThemeData() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: surface,
      brightness: Brightness.light,
    ).copyWith(onPrimary: Colors.white, onSurface: ink);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: bodyFont,
      textTheme: _textTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: headingFont,
          fontSize: 22,
          color: ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(44, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontFamily: bodyFont,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inkMuted.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inkMuted.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: TextStyle(color: inkMuted),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  TextTheme _textTheme() {
    return TextTheme(
      displaySmall: TextStyle(fontFamily: headingFont, color: ink),
      headlineMedium: TextStyle(fontFamily: headingFont, color: ink),
      headlineSmall: TextStyle(fontFamily: headingFont, color: ink),
      titleLarge: TextStyle(fontFamily: headingFont, color: ink),
      titleMedium: TextStyle(fontFamily: bodyFont, color: ink),
      bodyLarge: TextStyle(fontFamily: bodyFont, color: ink, fontSize: 16),
      bodyMedium: TextStyle(fontFamily: bodyFont, color: ink, fontSize: 16),
      bodySmall: TextStyle(fontFamily: bodyFont, color: inkMuted),
      labelLarge: TextStyle(fontFamily: bodyFont, color: ink),
    );
  }
}
