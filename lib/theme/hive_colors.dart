import 'package:flutter/material.dart';

/// Canonical Hivewise colour palette (design.md §1.1 / §1.2).
///
/// Widgets must reference these tokens — never raw hex — except the
/// per-context alternates documented in design.md (which are quoted at their
/// exact call sites). The [light] instance holds the canonical values.
class HiveColors extends ThemeExtension<HiveColors> {
  const HiveColors({
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.canvas,
    required this.surface,
    required this.surfaceWarm,
    required this.surfaceSunk,
    required this.honey,
    required this.honeyLight,
    required this.honeyDeep,
    required this.honeyText,
    required this.honeyTint,
    required this.brown,
    required this.brownLight,
    required this.brownDeep,
    required this.teal,
    required this.tealLight,
    required this.tealDeep,
    required this.clay,
    required this.clayLight,
    required this.clayDeep,
    required this.money,
    required this.moneyOn,
    required this.positive,
    required this.cream,
    required this.darkGradientEnd,
    required this.beeInBody,
    required this.beeInStripe,
    required this.beeInWing,
    required this.beeOutBody,
    required this.beeOutStripe,
    required this.beeOutWing,
  });

  /// Primary text; dark surfaces (banners, ink buttons, generating card);
  /// active nav label.
  final Color ink;

  /// Secondary text — `rgba(51,37,26,.55)`.
  final Color inkMuted;

  /// Labels, captions — `rgba(51,37,26,.42)`.
  final Color inkFaint;

  /// App background (the "page" behind cards); sheet fill.
  final Color canvas;

  /// Cards.
  final Color surface;

  /// Inset panels, pot caption panel, selected legend row.
  final Color surfaceWarm;

  /// Track fills, inactive chips, progress tracks.
  final Color surfaceSunk;

  /// Primary accent; income; progress fills; toggle-on track.
  final Color honey;

  /// Gradient tops.
  final Color honeyLight;

  /// Gradient bottoms; active tab-bar icon dots.
  final Color honeyDeep;

  /// Amber text on light backgrounds.
  final Color honeyText;

  /// Amber pill/chip backgrounds.
  final Color honeyTint;

  /// Expense; hive/social category.
  final Color brown;

  /// Expense gradient top; subscriptions fill.
  final Color brownLight;

  /// Expense gradient bottom.
  final Color brownDeep;

  /// Invested / habit category.
  final Color teal;

  /// Light teal (art-tile / badge gradients).
  final Color tealLight;

  /// Deep teal (art-tile / badge gradients).
  final Color tealDeep;

  /// Debt / drift warnings; debt amounts.
  final Color clay;

  /// Light clay (debt hatch / badge gradients).
  final Color clayLight;

  /// Deep clay (debt hatch / badge gradients).
  final Color clayDeep;

  /// Real-money price buttons only — never used for honey purchases.
  final Color money;

  /// Text on [money] (real-money price buttons).
  final Color moneyOn;

  /// "syncing" status text in Settings.
  final Color positive;

  /// All text/icons on ink/dark-gradient surfaces.
  final Color cream;

  /// Gradient partner of [ink] on the streak banner and swarm-goal card.
  final Color darkGradientEnd;

  /// Transaction-bee body, flying in over the honey side.
  final Color beeInBody;

  /// Transaction-bee stripe, flying in over the honey side.
  final Color beeInStripe;

  /// Transaction-bee wing (in) — `rgba(255,255,255,.8)`.
  final Color beeInWing;

  /// Transaction-bee body, flying out under the brown side.
  final Color beeOutBody;

  /// Transaction-bee stripe, flying out under the brown side.
  final Color beeOutStripe;

  /// Transaction-bee wing (out) — `rgba(255,255,255,.55)`.
  final Color beeOutWing;

  /// The canonical light palette (design.md §1.1).
  static const HiveColors light = HiveColors(
    ink: Color(0xFF33251A),
    inkMuted: Color(0x8C33251A),
    inkFaint: Color(0x6B33251A),
    canvas: Color(0xFFFBF7EF),
    surface: Color(0xFFFFFFFF),
    surfaceWarm: Color(0xFFF8F3E6),
    surfaceSunk: Color(0xFFF1EADB),
    honey: Color(0xFFF5B322),
    honeyLight: Color(0xFFFFD972),
    honeyDeep: Color(0xFFE08C1B),
    honeyText: Color(0xFFB8801A),
    honeyTint: Color(0xFFFFF3D6),
    brown: Color(0xFF6E4826),
    brownLight: Color(0xFF8B6039),
    brownDeep: Color(0xFF553519),
    teal: Color(0xFF5C8C86),
    tealLight: Color(0xFF7FB0A8),
    tealDeep: Color(0xFF3F6E68),
    clay: Color(0xFFC4634C),
    clayLight: Color(0xFFD98572),
    clayDeep: Color(0xFFAE5641),
    money: Color(0xFF2E6B4F),
    moneyOn: Color(0xFFEAF7EF),
    positive: Color(0xFF7A9B7E),
    cream: Color(0xFFF6EFE0),
    darkGradientEnd: Color(0xFF4C3824),
    beeInBody: Color(0xFF4A3520),
    beeInStripe: Color(0xFFFFD972),
    beeInWing: Color(0xCCFFFFFF),
    beeOutBody: Color(0xFFF0DFC4),
    beeOutStripe: Color(0xFF6E4826),
    beeOutWing: Color(0x8CFFFFFF),
  );

  @override
  HiveColors copyWith({
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    Color? canvas,
    Color? surface,
    Color? surfaceWarm,
    Color? surfaceSunk,
    Color? honey,
    Color? honeyLight,
    Color? honeyDeep,
    Color? honeyText,
    Color? honeyTint,
    Color? brown,
    Color? brownLight,
    Color? brownDeep,
    Color? teal,
    Color? tealLight,
    Color? tealDeep,
    Color? clay,
    Color? clayLight,
    Color? clayDeep,
    Color? money,
    Color? moneyOn,
    Color? positive,
    Color? cream,
    Color? darkGradientEnd,
    Color? beeInBody,
    Color? beeInStripe,
    Color? beeInWing,
    Color? beeOutBody,
    Color? beeOutStripe,
    Color? beeOutWing,
  }) {
    return HiveColors(
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceWarm: surfaceWarm ?? this.surfaceWarm,
      surfaceSunk: surfaceSunk ?? this.surfaceSunk,
      honey: honey ?? this.honey,
      honeyLight: honeyLight ?? this.honeyLight,
      honeyDeep: honeyDeep ?? this.honeyDeep,
      honeyText: honeyText ?? this.honeyText,
      honeyTint: honeyTint ?? this.honeyTint,
      brown: brown ?? this.brown,
      brownLight: brownLight ?? this.brownLight,
      brownDeep: brownDeep ?? this.brownDeep,
      teal: teal ?? this.teal,
      tealLight: tealLight ?? this.tealLight,
      tealDeep: tealDeep ?? this.tealDeep,
      clay: clay ?? this.clay,
      clayLight: clayLight ?? this.clayLight,
      clayDeep: clayDeep ?? this.clayDeep,
      money: money ?? this.money,
      moneyOn: moneyOn ?? this.moneyOn,
      positive: positive ?? this.positive,
      cream: cream ?? this.cream,
      darkGradientEnd: darkGradientEnd ?? this.darkGradientEnd,
      beeInBody: beeInBody ?? this.beeInBody,
      beeInStripe: beeInStripe ?? this.beeInStripe,
      beeInWing: beeInWing ?? this.beeInWing,
      beeOutBody: beeOutBody ?? this.beeOutBody,
      beeOutStripe: beeOutStripe ?? this.beeOutStripe,
      beeOutWing: beeOutWing ?? this.beeOutWing,
    );
  }

  @override
  HiveColors lerp(ThemeExtension<HiveColors>? other, double t) {
    if (other is! HiveColors) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}
