import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/hexagon.dart';
import '../data/report_data.dart';
import '../models/models.dart';
import '../state/hive_state.dart';
import '../theme/hive_colors.dart';
import '../theme/hive_shadows.dart';
import '../widgets/honey_snack.dart';
import '../widgets/primitives/primitives.dart';

// ── Colour literals (design.md §1.1 alternates, used in their exact context) ─
/// honeyText on honeyTint — report kicker + accepted-suggestion button.
const Color _honeyTextOnTint = Color(0xFF8A5E12);

/// inkFaint `.45` — report meta line.
const Color _metaInk = Color(0x7333251A);

/// inkMuted `.6` — regenerate label.
const Color _regenerateInk = Color(0x9933251A);

/// honeyTint alternate — summary gradient bottom `#FDE7B4`.
const Color _summaryBottom = Color(0xFFFDE7B4);

/// surfaceSunk alternate `#F3EDDF` — "where it went" track.
const Color _track = Color(0xFFF3EDDF);

/// cream-on-dark opacity steps (design.md §1.1).
const Color _cream80 = Color(0xCCF6EFE0);
const Color _cream50 = Color(0x80F6EFE0);
const Color _cream30 = Color(0x4DF6EFE0);

// ── Data ────────────────────────────────────────────────────────────────────
/// Saved sparkline ramp (README "Report"): `#F0E5CE` with last two
/// `#FFDD8A` / `#F5B322`.
const List<Color> _savedBars = <Color>[
  Color(0xFFF0E5CE),
  Color(0xFFF0E5CE),
  Color(0xFFF0E5CE),
  Color(0xFFF0E5CE),
  Color(0xFFFFDD8A),
  Color(0xFFF5B322),
];

/// Debt-burn sparkline ramp (design.md §1.1 clay sparkline steps).
const List<Color> _debtBars = <Color>[
  Color(0xFFF0DCD6),
  Color(0xFFF0DCD6),
  Color(0xFFF0DCD6),
  Color(0xFFE8C3B9),
  Color(0xFFD4806A),
  Color(0xFFC4634C),
];

/// Dollar amounts for the "Where it went" rows, keyed by the same labels as
/// [kWhereItWent] (README detail-sheet expense breakdown).
const Map<String, String> _whereItWentAmounts = <String, String>{
  'Groceries': '\$742',
  'Subscriptions': '\$164',
  'Transport': '\$318',
};

/// "Reading the hive…" progress steps (README "Report" / prototype genSteps).
const List<(String, Color, Color)> _genSteps = <(String, Color, Color)>[
  ('Reading 26 check-in answers', Color(0xFFF5B322), Color(0xFFF6EFE0)),
  ('Pulling balances from 2 linked banks', Color(0xFFF5B322), _cream80),
  ('Comparing to your last three months', _cream30, _cream50),
];

/// The Report screen (README "Report", design.md §Report).
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HiveState state = ref.watch(hiveStateProvider);
    final HiveNotifier notifier = ref.read(hiveStateProvider.notifier);

    final String meta = state.reportRun > 0
        ? 'August · regenerated just now · 26 check-ins · 2 accounts'
        : 'August · generated 3 days ago · 24 check-ins · 2 accounts';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 62, 18, 100),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            'What the hive noticed',
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
          meta,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.11,
            color: _metaInk,
          ),
        ),
        const SizedBox(height: 14),
        if (state.generatingReport)
          const _GeneratingCard()
        else ...<Widget>[
          _buildSummary(),
          const SizedBox(height: 14),
          _buildStats(),
          const SizedBox(height: 14),
          _buildWhereItWent(),
          const SizedBox(height: 14),
          _buildSuggestions(state, notifier),
          const SizedBox(height: 14),
          const _QuizCta(),
          const SizedBox(height: 14),
          _buildRegenerate(notifier),
        ],
      ],
    );
  }

  /// 150° `#FFF3D6 → #FDE7B4` summary card (README "Report").
  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -0.866),
          end: Alignment(0.5, 0.866),
          colors: <Color>[Color(0xFFFFF3D6), _summaryBottom],
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
                'THE SHORT OF IT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.05,
                  color: _honeyTextOnTint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            kReportSummary,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.5,
              letterSpacing: -0.135,
              color: HiveColors.light.ink,
            ),
          ),
        ],
      ),
    );
  }

  /// "Saved" / "Debt burn" stat cards, side by side (README "Report").
  Widget _buildStats() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCard(
            label: 'SAVED',
            figure: '\$2,122',
            values: const <double>[38, 52, 31, 64, 58, 100],
            barColors: _savedBars,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'DEBT BURN',
            figure: '\u2212\$410',
            values: const <double>[100, 92, 88, 74, 66, 55],
            barColors: _debtBars,
          ),
        ),
      ],
    );
  }

  /// "Where it went" card (README "Report").
  Widget _buildWhereItWent() {
    final List<MapEntry<String, WhereItWentRow>> entries = kWhereItWent.entries
        .toList();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: HiveColors.light.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: HiveShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Where it went',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: HiveColors.light.ink,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < entries.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 10),
            _WhereItWentRowView(
              label: entries[i].key,
              amount: _whereItWentAmounts[entries[i].key] ?? '',
              row: entries[i].value,
            ),
          ],
        ],
      ),
    );
  }

  /// "What the hive suggests" cards (README "Report").
  Widget _buildSuggestions(HiveState state, HiveNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            'What the hive suggests',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: HiveColors.light.ink,
            ),
          ),
        ),
        for (int i = 0; i < kSuggestions.length; i++) ...<Widget>[
          const SizedBox(height: 9),
          _SuggestionCard(
            suggestion: kSuggestions[i],
            accepted: state.acceptedSuggestionIds.contains(kSuggestions[i].id),
            onTap: () => notifier.acceptSuggestion(kSuggestions[i]),
          ),
        ],
      ],
    );
  }

  /// Full-width "Regenerate from latest check-ins" pill.
  Widget _buildRegenerate(HiveNotifier notifier) {
    return GestureDetector(
      onTap: () => notifier.regenerateReport(),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: HiveColors.light.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: HiveShadows.card,
        ),
        child: Text(
          'Regenerate from latest check-ins',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: _regenerateInk,
          ),
        ),
      ),
    );
  }
}

/// One stat card: label, figure, 6-bar sparkline (README "Report").
/// Demo dressing that closes the report: an invitation to the money quiz.
///
/// The quiz itself is not wired into this UI yet, so the tap announces itself
/// through [showHoneySnack] rather than navigating somewhere empty.
class _QuizCta extends StatelessWidget {
  const _QuizCta();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: HiveColors.light.honeyTint,
        borderRadius: BorderRadius.circular(18),
        boxShadow: HiveShadows.summaryAmber,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'How do you really spend?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: HiveColors.light.ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Two minutes of questions sharpens what the hive can tell you.',
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
                showHoneySnack(context, 'The quiz is a demo placeholder.'),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HiveColors.light.honey,
                borderRadius: BorderRadius.circular(13),
                boxShadow: HiveShadows.pillHoney,
              ),
              child: Text(
                'Take the quiz',
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.figure,
    required this.values,
    required this.barColors,
  });

  final String label;
  final String figure;
  final List<double> values;
  final List<Color> barColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: HiveColors.light.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: HiveShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.63,
              color: HiveColors.light.inkFaint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            figure,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: HiveColors.light.ink,
            ),
          ),
          const SizedBox(height: 8),
          Sparkline(values: values, barColors: barColors, height: 30),
        ],
      ),
    );
  }
}

/// One "Where it went" row: label (+ inline note) / amount over a track.
class _WhereItWentRowView extends StatelessWidget {
  const _WhereItWentRowView({
    required this.label,
    required this.amount,
    required this.row,
  });

  final String label;
  final String amount;
  final WhereItWentRow row;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(text: label),
                  if (row.note != null)
                    TextSpan(
                      text: ' ${row.note}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: HiveColors.light.clay,
                      ),
                    ),
                ],
              ),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: HiveColors.light.ink,
              ),
            ),
            Text(
              amount,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: HiveColors.light.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width =
                constraints.maxWidth * row.fraction.clamp(0.0, 1.0);
            return Container(
              height: 7,
              decoration: BoxDecoration(
                color: _track,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: width,
                  decoration: BoxDecoration(
                    color: row.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// One "What the hive suggests" card with its accept button.
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.accepted,
    required this.onTap,
  });

  final Suggestion suggestion;
  final bool accepted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HiveColors.light.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: accepted ? HiveShadows.ownedCard : HiveShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            suggestion.body,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: HiveColors.light.ink,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  suggestion.source,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: HiveColors.light.inkFaint,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accepted
                        ? HiveColors.light.honeyTint
                        : HiveColors.light.ink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    accepted ? 'In check-ins' : 'Add as task',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: accepted
                          ? _honeyTextOnTint
                          : HiveColors.light.cream,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The dark "Reading the hive…" card shown while the report regenerates.
class _GeneratingCard extends StatelessWidget {
  const _GeneratingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: HiveColors.light.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Reading the hive…',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: HiveColors.light.cream,
            ),
          ),
          for (int i = 0; i < _genSteps.length; i++) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                ClipPath(
                  clipper: const HexPointyClipper(),
                  child: Container(width: 8, height: 9, color: _genSteps[i].$2),
                ),
                const SizedBox(width: 9),
                Text(
                  _genSteps[i].$1,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: _genSteps[i].$3,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
