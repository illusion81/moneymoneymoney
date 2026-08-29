import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/hexagon.dart';
import '../state/hive_state.dart';
import '../theme/hive_colors.dart';
import '../theme/hive_shadows.dart';

/// The shared detail sheet (design.md §4.6), opened for income / expense / pot.
///
/// Renders only the sheet itself — the scrim and bottom pinning are handled by
/// the router shell. Layout and copy are hardcoded per [kind] from the README
/// "Shared detail sheet" section (cross-checked against the prototype).
class DetailSheet extends ConsumerWidget {
  const DetailSheet({super.key, required this.kind});

  final SheetKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _SheetData data = _sheetData(kind);

    return Container(
      decoration: BoxDecoration(
        color: HiveColors.light.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: HiveShadows.sheet,
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _GrabHandle(),
          const SizedBox(height: 15),
          _buildHeader(ref, data),
          const SizedBox(height: 15),
          _buildMonths(data),
          const SizedBox(height: 15),
          _buildBreakdown(data),
          const SizedBox(height: 15),
          _buildFooter(ref),
        ],
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, _SheetData data) {
    return Row(
      children: <Widget>[
        _SheetHex(top: data.hexTop, bottom: data.hexBottom),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                data.kicker,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: 1.05, // .1em
                  color: HiveColors.light.inkFaint,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.amount,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.78, // -.03em
                  color: HiveColors.light.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 13),
        _CloseButton(
          onTap: () => ref.read(hiveStateProvider.notifier).closeSheet(),
        ),
      ],
    );
  }

  Widget _buildMonths(_SheetData data) {
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final _MonthBar bar in data.months)
            Expanded(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: bar.value / 100,
                        widthFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _barColor(data.accent, bar.value),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    bar.label,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0x6133251A), // 38% ink (month labels).
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBreakdown(_SheetData data) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < data.rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 11),
          _BreakdownRowView(row: data.rows[i]),
        ],
      ],
    );
  }

  Widget _buildFooter(WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(hiveStateProvider.notifier).closeSheet(),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: HiveColors.light.ink,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          'Back to the hive',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: HiveColors.light.cream,
          ),
        ),
      ),
    );
  }

  /// 100% → full accent; >85% → 67% accent; else the neutral track colour.
  Color _barColor(Color accent, int value) {
    if (value == 100) {
      return accent;
    }
    if (value > 85) {
      return accent.withValues(alpha: 0xAA / 255.0); // 67% alpha.
    }
    return const Color(0xFFEFE7D6);
  }
}

// --- Private widgets -----------------------------------------------------

/// The 38×4 centred grab handle.
class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0x2E33251A), // 18% ink.
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

/// The 46×52 header hexagon tinted by source (158° gradient).
class _SheetHex extends StatelessWidget {
  const _SheetHex({required this.top, required this.bottom});

  final Color top;
  final Color bottom;

  @override
  Widget build(BuildContext context) {
    final double dx = math.sin(158 * math.pi / 180);
    final double dy = -math.cos(158 * math.pi / 180);
    return ClipPath(
      clipper: const HexPointyClipper(),
      child: SizedBox(
        width: 46,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-dx, -dy),
              end: Alignment(dx, dy),
              colors: <Color>[top, bottom],
            ),
          ),
        ),
      ),
    );
  }
}

/// The 32×32 "×" close button.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: HiveColors.light.surfaceSunk,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          '\u00d7',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0x8033251A), // 50% ink.
          ),
        ),
      ),
    );
  }
}

/// One breakdown row: label + amount, a 7 px track with % fill, and a note.
class _BreakdownRowView extends StatelessWidget {
  const _BreakdownRowView({required this.row});

  final _BreakdownRow row;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              row.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: HiveColors.light.ink,
              ),
            ),
            Text(
              row.amount,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xB333251A), // 70% ink.
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFFEFE7D6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: row.fraction,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: row.fill,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          row.note,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: const Color(0x7333251A), // 45% ink.
          ),
        ),
      ],
    );
  }
}

// --- Data ----------------------------------------------------------------

class _BreakdownRow {
  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.fraction,
    required this.fill,
    required this.note,
  });

  final String label;
  final String amount;
  final double fraction;
  final Color fill;
  final String note;
}

class _MonthBar {
  const _MonthBar(this.label, this.value);

  final String label;
  final int value; // 0..100 (relative bar height).
}

class _SheetData {
  const _SheetData({
    required this.kicker,
    required this.amount,
    required this.hexTop,
    required this.hexBottom,
    required this.accent,
    required this.months,
    required this.rows,
  });

  final String kicker;
  final String amount;
  final Color hexTop;
  final Color hexBottom;

  /// The full-accent bar colour.
  final Color accent;
  final List<_MonthBar> months;
  final List<_BreakdownRow> rows;
}

_SheetData _sheetData(SheetKind kind) {
  switch (kind) {
    case SheetKind.income:
      return const _SheetData(
        kicker: 'INCOME \u00b7 AUGUST',
        amount: '\$6,240',
        hexTop: Color(0xFFFFD05C),
        hexBottom: Color(0xFFE08C1B), // honeyDeep
        accent: Color(0xFFF5B322), // honey
        months: <_MonthBar>[
          _MonthBar('Mar', 62),
          _MonthBar('Apr', 68),
          _MonthBar('May', 60),
          _MonthBar('Jun', 74),
          _MonthBar('Jul', 80),
          _MonthBar('Aug', 100),
        ],
        rows: <_BreakdownRow>[
          _BreakdownRow(
            label: 'Salary \u00b7 Northwind',
            amount: '\$5,100',
            fraction: 0.82,
            fill: Color(0xFFE08C1B), // honeyDeep
            note: 'Lands 25th \u00b7 unchanged 7 months',
          ),
          _BreakdownRow(
            label: 'Freelance',
            amount: '\$820',
            fraction: 0.38,
            fill: Color(0xFFF5B322), // honey
            note: '3 invoices \u00b7 one still unpaid',
          ),
          _BreakdownRow(
            label: 'Dividends',
            amount: '\$220',
            fraction: 0.14,
            fill: Color(0xFF5C8C86), // teal
            note: 'Reinvested automatically',
          ),
          _BreakdownRow(
            label: 'Refunds & odds',
            amount: '\$100',
            fraction: 0.08,
            fill: Color(0xFFFFDD8A), // honeyLight alt (cash layer)
            note: 'Two returns, one rebate',
          ),
        ],
      );
    case SheetKind.expense:
      return const _SheetData(
        kicker: 'EXPENSE \u00b7 AUGUST',
        amount: '\$4,118',
        hexTop: Color(0xFF8B6039), // brownLight
        hexBottom: Color(0xFF553519), // brownDeep
        accent: Color(0xFF6E4826), // brown
        months: <_MonthBar>[
          _MonthBar('Mar', 88),
          _MonthBar('Apr', 96),
          _MonthBar('May', 84),
          _MonthBar('Jun', 92),
          _MonthBar('Jul', 100),
          _MonthBar('Aug', 86),
        ],
        rows: <_BreakdownRow>[
          _BreakdownRow(
            label: 'Rent',
            amount: '\$1,650',
            fraction: 0.78,
            fill: Color(0xFF6E4826), // brown
            note: 'Fixed \u00b7 26% of income',
          ),
          _BreakdownRow(
            label: 'Groceries',
            amount: '\$742',
            fraction: 0.41,
            fill: Color(0xFFC4634C), // clay
            note: 'Up \$180 \u2014 your biggest drift',
          ),
          _BreakdownRow(
            label: 'Transport',
            amount: '\$318',
            fraction: 0.20,
            fill: Color(0xFF8B6039), // brownLight
            note: 'Down \$40 since the bike',
          ),
          _BreakdownRow(
            label: 'Subscriptions',
            amount: '\$164',
            fraction: 0.14,
            fill: Color(0xFFA2764C), // brown alt (subscriptions fill)
            note: '11 active \u00b7 4 unopened in 60 days',
          ),
        ],
      );
    case SheetKind.pot:
      return const _SheetData(
        kicker: 'POT \u00b7 AUGUST',
        amount: '\$18,420',
        hexTop: Color(0xFFFFD972), // honeyLight
        hexBottom: Color(0xFF5C8C86), // teal
        accent: Color(0xFFF5B322), // honey
        months: <_MonthBar>[
          _MonthBar('Mar', 58),
          _MonthBar('Apr', 64),
          _MonthBar('May', 71),
          _MonthBar('Jun', 80),
          _MonthBar('Jul', 90),
          _MonthBar('Aug', 100),
        ],
        rows: <_BreakdownRow>[
          _BreakdownRow(
            label: 'Cash',
            amount: '\$3,210',
            fraction: 0.17,
            fill: Color(0xFFFFDD8A), // honeyLight alt (cash layer)
            note: 'Two weeks of runway sitting still',
          ),
          _BreakdownRow(
            label: 'Savings',
            amount: '\$8,150',
            fraction: 0.44,
            fill: Color(0xFFF5B322), // honey
            note: '+\$420/mo \u2014 the layer you feed most',
          ),
          _BreakdownRow(
            label: 'Invested',
            amount: '\$11,180',
            fraction: 0.60,
            fill: Color(0xFF5C8C86), // teal
            note: 'Untouched 9 months \u00b7 up 2.1%',
          ),
          _BreakdownRow(
            label: 'Debt',
            amount: '\u2212\$4,120',
            fraction: 0.22,
            fill: Color(0xFFC4634C), // clay
            note: 'Leaks out the bottom at \$410/mo',
          ),
        ],
      );
  }
}
