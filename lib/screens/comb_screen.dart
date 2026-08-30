import 'dart:math' as math;

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/hexagon.dart';
import '../data/badges.dart';
import '../models/models.dart';
import '../theme/hive_colors.dart';
import '../theme/hive_shadows.dart';
import '../widgets/primitives/primitives.dart';

/// 158° gradient travel direction for badge fills (design.md §1.2; same
/// convention as honeycomb.dart: CSS angles are measured clockwise from 12
/// o'clock, so the lighter "top" colour starts at the begin alignment).
final double _gDx = math.sin(158 * math.pi / 180);
final double _gDy = -math.cos(158 * math.pi / 180);
final Alignment _gBegin = Alignment(-_gDx, -_gDy);
final Alignment _gEnd = Alignment(_gDx, _gDy);

/// The Comb (achievements) screen (README "Screen 4 — Comb", design.md §1.2).
class CombScreen extends ConsumerWidget {
  const CombScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: HiveColors.light.canvas,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 62, 18, 100),
        children: <Widget>[
          _header(),
          const SizedBox(height: 16),
          _nextBadgeCard(),
          const SizedBox(height: 16),
          _legend(),
          const SizedBox(height: 16),
          _badgeHoneycomb(),
        ],
      ),
    );
  }

  /// Screen title + meta line (README: "Sam's comb" / "9 of 24 cells …").
  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            "Sam's comb",
            style: GoogleFonts.caveat(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              height: 1.12,
              color: HiveColors.light.ink,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '9 of 24 cells filled since March',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            // 45 % ink — the meta-line alternate (prototype; design.md §2).
            color: const Color(0x7333251A),
          ),
        ),
      ],
    );
  }

  /// The "Next: Frugal Forager" progress card (white, 18 radius, card shadow).
  Widget _nextBadgeCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: HiveColors.light.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: HiveShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                'Next: Frugal Forager',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: HiveColors.light.ink,
                ),
              ),
              Text(
                '6/10',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: HiveColors.light.honeyText, // #B8801A
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 8 px track, honey → honeyDeep gradient fill at 60 %. The handoff
          // paints progress tracks with `#F3EDDF` (design.md §1.1 alternate).
          const ProgressBar(
            value: 0.6,
            gradient: true,
            track: Color(0xFFF3EDDF),
          ),
          const SizedBox(height: 10),
          Text(
            'Log 10 no-spend days in one month',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              // 50 % ink — sub-line alternate (prototype).
              color: const Color(0x8033251A),
            ),
          ),
        ],
      ),
    );
  }

  /// The four-item category legend (README: Saving/Debt/Habit/Hive).
  Widget _legend() {
    final List<({String label, Color color})> entries =
        <({String label, Color color})>[
      (label: 'Saving', color: HiveColors.light.honey),
      (label: 'Debt', color: HiveColors.light.clay),
      (label: 'Habit', color: HiveColors.light.teal),
      (label: 'Hive', color: HiveColors.light.brown),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Wrap(
        spacing: 14,
        runSpacing: 7,
        children: <Widget>[
          for (final ({String label, Color color}) entry in entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ClipPath(
                  clipper: const HexPointyClipper(),
                  child: Container(
                    width: 9,
                    height: 10,
                    color: entry.color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  entry.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: HiveColors.light.inkMuted,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// The interlocked 3-2-3-2 honeycomb of badges (design.md §5: cells
  /// 104×116, 5 px gaps, rows centred, 29 px row overlap).
  Widget _badgeHoneycomb() {
    const double cellHeight = 116;
    const double gap = 5;
    const double rowOverlap = 29;
    const double rowStep = cellHeight - rowOverlap; // 87
    const List<int> rowLengths = <int>[3, 2, 3, 2];

    final List<Widget> rows = <Widget>[];
    int index = 0;
    for (final int count in rowLengths) {
      final List<Widget> cells = <Widget>[];
      for (int c = 0; c < count; c++) {
        cells.add(_BadgeCell(badge: kBadges[index]));
        index += 1;
        if (c < count - 1) {
          cells.add(const SizedBox(width: gap));
        }
      }
      rows.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: cells,
        ),
      );
    }

    final double totalHeight = (rowLengths.length - 1) * rowStep + cellHeight;
    return SizedBox(
      height: totalHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          for (int r = 0; r < rows.length; r++)
            Positioned(top: r * rowStep, child: rows[r]),
        ],
      ),
    );
  }
}

/// One pointy-top hexagon badge cell: category gradient (or surfaceSunk for
/// the locked cell), a JetBrains Mono glyph and a two-line label
/// (design.md §1.2).
class _BadgeCell extends StatelessWidget {
  const _BadgeCell({required this.badge});

  final Badge badge;

  /// Badge gradient colours per category (design.md §1.2).
  static List<Color> _gradientColors(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.saving:
        return const <Color>[Color(0xFFFFD972), Color(0xFFF0A81A)];
      case BadgeCategory.debt:
        return const <Color>[Color(0xFFD98572), Color(0xFFC4634C)];
      case BadgeCategory.habit:
        return const <Color>[Color(0xFF7FB0A8), Color(0xFF5C8C86)];
      case BadgeCategory.hive:
        return const <Color>[Color(0xFFA2764C), Color(0xFF6E4826)];
    }
  }

  /// Glyph colour per category (design.md §1.2 "Glyph/label on badge").
  static Color _glyphColor(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.saving:
        return const Color(0xFF33251A); // ink
      case BadgeCategory.debt:
        return const Color(0xFFFFF6F2);
      case BadgeCategory.habit:
        return const Color(0xFFF4FAF8);
      case BadgeCategory.hive:
        return const Color(0xFFFBF3E6);
    }
  }

  /// Label colour per category: 60 % ink on amber, off-white elsewhere.
  static Color _labelColor(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.saving:
        return const Color(0x9933251A); // 60 % ink
      case BadgeCategory.debt:
        return const Color(0xFFFFF6F2);
      case BadgeCategory.habit:
        return const Color(0xFFF4FAF8);
      case BadgeCategory.hive:
        return const Color(0xFFFBF3E6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool unlocked = badge.unlocked;
    // Locked cell: glyph at 30 % ink, label at 35 % ink (design.md §1.2).
    final Color glyphColor =
        unlocked ? _glyphColor(badge.category) : const Color(0x4D33251A);
    final Color labelColor =
        unlocked ? _labelColor(badge.category) : const Color(0x5933251A);

    return ClipPath(
      clipper: const HexPointyClipper(),
      child: Container(
        width: 104,
        height: 116,
        decoration: BoxDecoration(
          color: unlocked ? null : HiveColors.light.surfaceSunk,
          gradient: unlocked
              ? LinearGradient(
                  begin: _gBegin,
                  end: _gEnd,
                  colors: _gradientColors(badge.category),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              badge.glyph,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: glyphColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              unlocked ? badge.label : 'Locked',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
