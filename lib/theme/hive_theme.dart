import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'hive_colors.dart';

/// Builds the Material 3 theme for Hivewise (design.md §1.3, §2).
///
/// Depth is drawn by the app itself (BoxDecoration shadows from `HiveShadows`);
/// this theme zeroes out Material's default elevation so nothing leaks, and
/// leaves `splashFactory` at its default.
ThemeData buildHiveTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: HiveColors.light.honey,
  ).copyWith(
    primary: HiveColors.light.honey,
    secondary: HiveColors.light.brown,
    tertiary: HiveColors.light.teal,
    surface: HiveColors.light.surface,
    onSurface: HiveColors.light.ink,
    error: HiveColors.light.clay,
    onSurfaceVariant: HiveColors.light.inkMuted,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: HiveColors.light.canvas,
    textTheme: _buildTextTheme(),
    extensions: const <ThemeExtension<dynamic>>[HiveColors.light],
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: const CardThemeData(elevation: 0),
  );
}

/// Convenience getter exposing the Hivewise theme.
ThemeData get hiveTheme => buildHiveTheme();

/// The full text theme from design.md §2.
///
/// Caveat line-height is 1.12 minimum (1.0 clips descenders). Slot assignments
/// follow the "Maps to TextTheme slot" column in §2; slots the table leaves
/// unmapped are filled from the closest §2 role so no Material default
/// (Roboto) leaks through.
TextTheme _buildTextTheme() {
  return TextTheme(
    // Caveat display — 700 only, height 1.12.
    displayLarge: GoogleFonts.caveat(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.12,
    ),
    displayMedium: GoogleFonts.caveat(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.12,
    ),
    displaySmall: GoogleFonts.caveat(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.12,
    ),
    headlineLarge: GoogleFonts.caveat(
      fontSize: 25,
      fontWeight: FontWeight.w700,
      height: 1.12,
    ),
    headlineMedium: GoogleFonts.jetBrainsMono(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.72,
    ),
    headlineSmall: GoogleFonts.caveat(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.12,
    ),
    titleLarge: GoogleFonts.caveat(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      height: 1.12,
    ),
    // Plus Jakarta Sans — UI text.
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      height: 1.3,
      letterSpacing: -0.13,
    ),
    titleSmall: GoogleFonts.plusJakartaSans(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      height: 1.45,
    ),
    bodyLarge: GoogleFonts.plusJakartaSans(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      height: 1.5,
      letterSpacing: -0.135,
    ),
    bodyMedium: GoogleFonts.plusJakartaSans(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      height: 1.45,
    ),
    bodySmall: GoogleFonts.plusJakartaSans(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    // JetBrains Mono — figures.
    labelLarge: GoogleFonts.jetBrainsMono(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      height: 1.1,
    ),
    labelMedium: GoogleFonts.jetBrainsMono(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.15,
    ),
    labelSmall: GoogleFonts.jetBrainsMono(
      fontSize: 10.5,
      fontWeight: FontWeight.w500,
      height: 1.15,
    ),
  );
}
