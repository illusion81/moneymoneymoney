import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/hexagon.dart';
import '../data/pot_layers.dart';
import '../models/models.dart';
import '../state/hive_state.dart';
import '../theme/hive_colors.dart';
import '../theme/hive_shadows.dart';
import '../widgets/honey_snack.dart';
import '../widgets/primitives/primitives.dart';

/// Screen 1 — Hive (home), per the handoff README "Screen 1 — Hive".
///
/// Top-to-bottom: header (date / greeting / streak pill / settings), streak
/// banner, unified income/expense honeycomb, the honey-pot card, and the daily
/// check-ins list. All layout, copy and colours follow design.md / the README;
/// state comes from [hiveStateProvider].
class HiveScreen extends ConsumerWidget {
  const HiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HiveState state = ref.watch(hiveStateProvider);

    return Scaffold(
      backgroundColor: HiveColors.light.canvas,
      body: ListView(
        // design.md §3: 18 horizontal · 62 top · 100 bottom.
        padding: const EdgeInsets.fromLTRB(18, 62, 18, 100),
        children: <Widget>[
          _buildHeader(context),
          const SizedBox(height: 16),
          const _StreakBanner(),
          const SizedBox(height: 16),
          _buildUnifiedHive(ref, state),
          const SizedBox(height: 16),
          _buildHoneyPot(ref, state),
          const SizedBox(height: 16),
          _buildCheckIns(ref, state),
          const SizedBox(height: 16),
          const _SponsorAd(),
        ],
      ),
    );
  }

  // --- 1. Header ---------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'TUESDAY, 12 AUG',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: 0.69, // .06em
                  color: HiveColors.light.inkFaint,
                ),
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 2), // Caveat descenders.
                child: Text(
                  'Morning, Sam',
                  style: GoogleFonts.caveat(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                    color: HiveColors.light.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: <Widget>[
              const _StreakPill(),
              const SizedBox(width: 8),
              _SettingsButton(onTap: () => context.push('/settings')),
            ],
          ),
        ),
      ],
    );
  }

  // --- 3. Unified hive ---------------------------------------------------

  Widget _buildUnifiedHive(WidgetRef ref, HiveState state) {
    final HiveNotifier notifier = ref.read(hiveStateProvider.notifier);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _hiveLabel(
                kicker: 'INCOME',
                figure: _comma(state.income),
                figureColor: HiveColors.light.honeyText,
                alignEnd: false,
              ),
              const Spacer(),
              _hiveLabel(
                kicker: 'EXPENSE',
                figure: _comma(state.expense),
                figureColor: HiveColors.light.brown,
                alignEnd: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Full-width stack: the comb is centred inside, and the BeeSwarm flies
        // across the whole row (its start positions are % of the container).
        SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              HoneycombView(
                incomeCells: 7,
                totalCells: 12,
                cellWidth: 52,
                cellHeight: 58,
                onCellTap: (bool isIncome) => notifier
                    .openSheet(isIncome ? SheetKind.income : SheetKind.expense),
              ),
              Positioned.fill(
                child: BeeSwarm(beesIn: 4, beesOut: 6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            const Expanded(child: _DashedRule()),
            const SizedBox(width: 9),
            Text(
              'level ${state.level} · '
              '${(state.expense / state.income * 100).round()}% spent · '
              '4 in, 6 out',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: HiveColors.light.inkFaint,
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(child: _DashedRule()),
          ],
        ),
      ],
    );
  }

  Widget _hiveLabel({
    required String kicker,
    required String figure,
    required Color figureColor,
    required bool alignEnd,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          kicker,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: 1.05, // .11em
            color: HiveColors.light.inkFaint,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          figure,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.72, // -.03em
            color: figureColor,
          ),
        ),
      ],
    );
  }

  // --- 4. Honey pot card -------------------------------------------------

  Widget _buildHoneyPot(WidgetRef ref, HiveState state) {
    final HiveNotifier notifier = ref.read(hiveStateProvider.notifier);
    final List<PotLayer> topDown = kPotLayers.reversed.toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: HiveColors.light.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: HiveShadows.card,
      ),
      child: Column(
        children: <Widget>[
          // Pressable header → opens the pot sheet.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => notifier.openSheet(SheetKind.pot),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Sam\u2019s honey pot',
                        style: GoogleFonts.caveat(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.12,
                          color: HiveColors.light.ink,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'press for the full flow',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.38, // .04em
                          color: HiveColors.light.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$18,420',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: HiveColors.light.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              HoneyJar(
                layers: kPotLayers,
                selectedId: state.potLayer,
                onSelectLayer: (String id) => notifier.selectPotLayer(id),
                width: 118,
                height: 176,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < topDown.length; i++) ...[
                        if (i > 0) const SizedBox(height: 7),
                        _legendRow(ref, state, topDown[i]),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _potCaption(state),
        ],
      ),
    );
  }

  Widget _legendRow(WidgetRef ref, HiveState state, PotLayer layer) {
    final bool selected = state.potLayer == layer.id;
    final double amount = kPotAmounts[layer.id] ?? 0;
    final Color amountColor = layer.id == 'debt'
        ? HiveColors.light.clay
        : const Color(0x9933251A); // 60% ink (pot legend amounts).

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(hiveStateProvider.notifier).selectPotLayer(layer.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? HiveColors.light.surfaceWarm : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: layer.fill,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                layer.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: HiveColors.light.ink,
                ),
              ),
            ),
            Text(
              _money(amount),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _potCaption(HiveState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: HiveColors.light.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _potCaptions[state.potLayer] ?? _potCaptions['cash']!,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          height: 1.45,
          color: const Color(0xB833251A), // 72% ink (pot caption).
        ),
      ),
    );
  }

  // --- 5. Check-ins ------------------------------------------------------

  Widget _buildCheckIns(WidgetRef ref, HiveState state) {
    final int doneCount = state.tasks.where((Task t) => t.done).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Expanded(
                child: Text(
                  'Today, in your words',
                  style: GoogleFonts.caveat(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                    color: HiveColors.light.ink,
                  ),
                ),
              ),
              Text(
                '$doneCount / ${state.tasks.length}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: HiveColors.light.honeyText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 252),
          child: ShaderMask(
            shaderCallback: (Rect bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: <double>[0.0, 0.88, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 4),
              physics: const ClampingScrollPhysics(),
              itemCount: state.tasks.length,
              itemBuilder: (BuildContext context, int index) {
                final Task task = state.tasks[index];
                return _TaskRow(
                  task: task,
                  onTap: () => ref
                      .read(hiveStateProvider.notifier)
                      .toggleTask(task.id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// --- Private widgets -----------------------------------------------------

/// The honey jar + "18" streak pill (design.md §4.4).
class _StreakPill extends StatelessWidget {
  const _StreakPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: HiveColors.light.honeyTint,
        borderRadius: BorderRadius.circular(11),
        boxShadow: HiveShadows.pillHoney,
      ),
      child: Row(
        children: <Widget>[
          const JarGlyph(width: 13, height: 15),
          const SizedBox(width: 6),
          Text(
            '18',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8A5E12), // honeyText in honeyTint pills.
            ),
          ),
        ],
      ),
    );
  }
}

/// The white settings gear button (design.md §4.4 "pill (neutral control)").
class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: HiveColors.light.surface,
          borderRadius: BorderRadius.circular(11),
          boxShadow: HiveShadows.pillNeutral,
        ),
        alignment: Alignment.center,
        child: const _SettingsGlyph(),
      ),
    );
  }
}

/// Drawn three-line slider glyph (README header: knobs offset 9 / 1 / 6 px).
class _SettingsGlyph extends StatelessWidget {
  const _SettingsGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 13,
      child: CustomPaint(painter: const _SettingsGlyphPainter()),
    );
  }
}

class _SettingsGlyphPainter extends CustomPainter {
  const _SettingsGlyphPainter();

  // #7A5230 — brownDeep alternate (jar rim / settings gear glyph).
  static const Color _ink = Color(0xFF7A5230);
  static const List<double> _knobLefts = <double>[9, 1, 6];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()..color = _ink;
    final Paint knobInk = Paint()..color = _ink;
    final Paint knobWhite = Paint()..color = Colors.white;

    for (int i = 0; i < 3; i++) {
      final double top = i * 5.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, top, 16, 2),
          const Radius.circular(2),
        ),
        linePaint,
      );
      // 7×7 knob: 2 px ink ring around a white centre (border, not a UI border).
      final Offset knobCenter = Offset(_knobLefts[i] + 3.5, top + 1);
      canvas.drawCircle(knobCenter, 3.5, knobInk);
      canvas.drawCircle(knobCenter, 1.5, knobWhite);
    }
  }

  @override
  bool shouldRepaint(covariant _SettingsGlyphPainter oldDelegate) => false;
}

/// The 96° ink→dark gradient streak banner with three pointy hex dots.
class _StreakBanner extends StatelessWidget {
  const _StreakBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            HiveColors.light.ink, // #33251A
            HiveColors.light.darkGradientEnd, // #4C3824
          ],
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '2 check-ins from a 3-week comb',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.125, // -.01em
                color: HiveColors.light.cream,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _Hex(width: 8, height: 9, color: HiveColors.light.honey),
          const SizedBox(width: 3),
          _Hex(width: 8, height: 9, color: HiveColors.light.honey),
          const SizedBox(width: 3),
          // Cream @ 25% (design.md §1.1).
          const _Hex(width: 8, height: 9, color: Color(0x40F6EFE0)),
        ],
      ),
    );
  }
}

/// A pointy-top hexagon filled with [color].
class _Hex extends StatelessWidget {
  const _Hex({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const HexPointyClipper(),
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(color: color),
      ),
    );
  }
}

/// A 1px dashed rule (22% ink, 4 px dash / 4 px gap) for the hive footer.
class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(painter: const _DashedRulePainter()),
    );
  }
}

class _DashedRulePainter extends CustomPainter {
  const _DashedRulePainter();

  static const Color _dash = Color(0x3833251A); // 22% ink.

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = _dash;
    const double dash = 4;
    const double gap = 4;
    double x = 0;
    while (x < size.width) {
      canvas.drawRect(Rect.fromLTWH(x, 0, dash, 1), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRulePainter oldDelegate) => false;
}

/// One check-in task row (README "Check-ins").
class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.onTap});

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool done = task.done;
    final Color titleColor =
        done ? const Color(0x7333251A) : HiveColors.light.ink;
    final Color rewardColor =
        done ? const Color(0x4D33251A) : HiveColors.light.honeyText;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: done ? const Color(0xFFF7F2E5) : HiveColors.light.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: done ? HiveShadows.completedTask : HiveShadows.card,
        ),
        child: Row(
          children: <Widget>[
            _HexTick(done: done),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    task.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      letterSpacing: -0.135, // -.01em
                      color: titleColor,
                      decoration:
                          done ? TextDecoration.lineThrough : TextDecoration.none,
                      decorationColor: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.sub,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0x7333251A), // 45% ink (task subs).
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '+${task.reward}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: rewardColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 26×29 hexagon tick: honey + "✓" when done, surfaceSunk when todo.
class _HexTick extends StatelessWidget {
  const _HexTick({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const HexPointyClipper(),
      child: SizedBox(
        width: 26,
        height: 29,
        child: ColoredBox(
          color: done ? HiveColors.light.honey : HiveColors.light.surfaceSunk,
          child: done
              ? Center(
                  child: Text(
                    '\u2713',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: HiveColors.light.ink,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

// --- Copy + formatting helpers ------------------------------------------

/// Per-layer pot caption copy (prototype literals, README omits them).
const Map<String, String> _potCaptions = <String, String>{
  'cash': 'Cash \u00b7 \$3,210 \u00b7 17% of the pot. '
      'Two weeks of runway sitting still.',
  'savings': 'Savings \u00b7 \$8,150 \u00b7 44%. '
      'Growing \$420/mo \u2014 fastest layer in the pot.',
  'invested': 'Invested \u00b7 \$11,180 \u00b7 60% of assets. '
      'Up 2.1% this month, untouched for 9 months.',
  'debt': 'Debt \u00b7 \u2212\$4,120 leaking from the bottom. '
      'At \$410/mo it drains by next April.',
};

/// Demo dressing at the foot of the hive: a sponsored placement.
///
/// The backer is invented and the offer leads nowhere, so the card keeps its
/// "Sponsored" label and [showHoneySnack] names itself a placeholder on tap —
/// a mock rate should not be mistaken for a real financial promotion.
class _SponsorAd extends StatelessWidget {
  const _SponsorAd();

  static const String _brand = 'Pollen Capital';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -0.866),
          end: Alignment(0.5, 0.866),
          colors: <Color>[Color(0xFFFFF3D6), Color(0xFFFDE7B4)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: HiveShadows.summaryAmber,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ClipPath(
                clipper: const HexPointyClipper(),
                child: Container(
                  width: 11,
                  height: 12.5,
                  color: HiveColors.light.honeyDeep,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Sponsored',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: HiveColors.light.inkFaint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            _brand,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: HiveColors.light.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Park your honey at 4.8% p.a.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: HiveColors.light.inkMuted,
            ),
          ),
          const SizedBox(height: 13),
          GestureDetector(
            onTap: () =>
                showHoneySnack(context, '$_brand is a demo placeholder.'),
            child: Container(
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HiveColors.light.honey,
                borderRadius: BorderRadius.circular(13),
                boxShadow: HiveShadows.pillHoney,
              ),
              child: Text(
                'See the offer',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: HiveColors.light.brownDeep,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "6240" -> "6,240"; "-4120" -> "−4,120" (no currency sign).
String _comma(num value) {
  final bool negative = value < 0;
  final String digits = value.abs().round().toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      out.write(',');
    }
    out.write(digits[i]);
  }
  return negative ? '\u2212$out' : out.toString();
}

/// "3210" -> "$3,210"; "-4120" -> "−$4,120".
String _money(num value) {
  final bool negative = value < 0;
  final String digits = value.abs().round().toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      out.write(',');
    }
    out.write(digits[i]);
  }
  return negative ? '\u2212\$$out' : '\$$out';
}
