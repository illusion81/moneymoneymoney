import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../state/hive_state.dart';
import '../theme/hive_colors.dart';
import '../theme/hive_shadows.dart';
import '../widgets/primitives/primitives.dart';

/// The three report cadences (README "Screen 6 — Settings").
const List<String> _cadences = <String>['Weekly', 'Monthly', 'Quarterly'];

/// The three nudge toggles, keyed into [HiveState.nudgeSettings].
const List<({String key, String label})> _nudgeRows =
    <({String key, String label})>[
  (key: 'morning', label: 'Morning check-in reminder'),
  (key: 'drift', label: 'Alert me when a category drifts'),
  (key: 'streakVisible', label: 'Let hive-mates see my streak'),
];

/// One linked-account row definition (logo tile colours from design.md §1.1).
class _Bank {
  const _Bank({
    required this.key,
    required this.name,
    required this.initial,
    required this.logoBg,
    required this.logoColor,
  });

  final String key;
  final String name;
  final String initial;
  final Color logoBg;
  final Color logoColor;
}

const List<_Bank> _banks = <_Bank>[
  _Bank(
    key: 'chase',
    name: 'Chase · checking',
    initial: 'C',
    logoBg: Color(0xFFE9EFF6),
    logoColor: Color(0xFF3B5C86),
  ),
  _Bank(
    key: 'ally',
    name: 'Ally · savings ••4021',
    initial: 'A',
    logoBg: Color(0xFFEAF0EE),
    logoColor: Color(0xFF5C8C86),
  ),
  _Bank(
    key: 'amex',
    name: 'Amex · credit card',
    initial: 'X',
    logoBg: Color(0xFFF3EDDF),
    logoColor: Color(0xFF6E4826),
  ),
];

/// The Settings screen (README "Screen 6 — Settings"). Reached as a pushed
/// route from the home gear button, so it carries its own back affordance.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HiveState state = ref.watch(hiveStateProvider);
    final HiveNotifier notifier = ref.read(hiveStateProvider.notifier);

    return Scaffold(
      backgroundColor: HiveColors.light.canvas,
      body: Stack(
        children: <Widget>[
          ListView(
            padding: const EdgeInsets.fromLTRB(18, 62, 18, 100),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'Your setup',
                  style: GoogleFonts.caveat(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                    color: HiveColors.light.ink,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _group(
                'Linked accounts',
                children: <Widget>[
                  for (final _Bank bank in _banks)
                    _bankRow(
                      bank: bank,
                      linked: state.banks[bank.key] ?? false,
                      onToggle: () => notifier.toggleBank(bank.key),
                    ),
                  _connectBankCard(context),
                  const SizedBox(height: 8),
                  _viewSpendingCard(context),
                  const SizedBox(height: 8),
                  _openForestCard(context),
                ],
              ),
              const SizedBox(height: 16),
              _group(
                'AI report',
                children: <Widget>[_aiReportCard(state, notifier)],
              ),
              const SizedBox(height: 16),
              _group(
                'Nudges',
                children: <Widget>[
                  for (final ({String key, String label}) row in _nudgeRows)
                    _toggleRow(
                      label: row.label,
                      value: state.nudgeSettings[row.key] ?? false,
                      onToggle: () => notifier.toggleNudge(row.key),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 18,
            child: _backButton(() => context.pop()),
          ),
        ],
      ),
    );
  }

  /// A labelled group: uppercase heading 9 px above its cards, which sit 8 px
  /// apart. That is tighter than the 16 px between groups, so a group still
  /// reads as one unit while its cards stay legibly separate.
  Widget _group(String heading, {required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _heading(heading),
        const SizedBox(height: 9),
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 8),
          children[i],
        ],
      ],
    );
  }

  /// Group heading: 10.5/700 caps, 40 % ink (design.md §1.1).
  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.05,
          color: const Color(0x6633251A),
        ),
      ),
    );
  }

  /// One linked-account row: logo tile, name + status, and a bank toggle.
  Widget _bankRow({
    required _Bank bank,
    required bool linked,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: HiveColors.light.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: HiveShadows.card,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bank.logoBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              bank.initial,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: bank.logoColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  bank.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: HiveColors.light.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  linked
                      ? 'syncing · updated 4h ago'
                      : 'not linked · report runs blind here',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: linked
                        ? HiveColors.light.positive
                        : HiveColors.light.clay,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Toggle(value: linked, onChanged: (_) => onToggle()),
        ],
      ),
    );
  }

  /// The "Connect another bank" action card.
  /// The real bank hook-up. The rows above this card are a static mock of
  /// already-linked accounts; this is the one that opens the live consent /
  /// statement-upload flow, so it is deliberately the only tappable one.
  Widget _connectBankCard(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/connect-bank'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: HiveColors.light.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: HiveShadows.card,
        ),
        child: Text(
          'Connect a bank or upload a statement',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: HiveColors.light.honeyText,
          ),
        ),
      ),
    );
  }

  /// The full Forest experience: questionnaire, plan, tree, streaks, shop,
  /// circle. Everything the hive tabs do not cover yet.
  Widget _openForestCard(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/forest'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: HiveColors.light.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: HiveShadows.card,
        ),
        child: Text(
          'Open the full app',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: HiveColors.light.honeyText,
          ),
        ),
      ),
    );
  }

  /// Opens the live spending screen — real transactions, real categories.
  Widget _viewSpendingCard(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/spending'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: HiveColors.light.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: HiveShadows.card,
        ),
        child: Text(
          'See your real spending',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: HiveColors.light.honeyText,
          ),
        ),
      ),
    );
  }

  /// The AI-report card: question + cadence segmented control + note.
  Widget _aiReportCard(HiveState state, HiveNotifier notifier) {
    final int selected = _cadences.indexOf(state.reportCadence);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HiveColors.light.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: HiveShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'How often should the hive report back?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: HiveColors.light.ink,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedControl(
            options: _cadences,
            selectedIndex: selected < 0 ? 1 : selected,
            onChanged: (int i) => notifier.setCadence(_cadences[i]),
          ),
          const SizedBox(height: 12),
          Text(
            'Reports read your check-in answers plus balances from linked accounts. Nothing leaves your hive.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.45,
              // 48 % ink (prototype note line).
              color: const Color(0x7A33251A),
            ),
          ),
        ],
      ),
    );
  }

  /// A nudge toggle row: label + toggle.
  Widget _toggleRow({
    required String label,
    required bool value,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: HiveColors.light.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: HiveShadows.card,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: HiveColors.light.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Toggle(value: value, onChanged: (_) => onToggle()),
        ],
      ),
    );
  }

  /// A 34 px white back button with a drawn chevron (no icon fonts —
  /// design.md §4.4 settings-gear treatment, §6 "drawn").
  Widget _backButton(VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: HiveColors.light.surface,
          borderRadius: BorderRadius.circular(11),
          boxShadow: HiveShadows.pillNeutral,
        ),
        child: const _BackChevron(),
      ),
    );
  }
}

/// A drawn back chevron in `#7A5230` (brownDeep alternate).
class _BackChevron extends StatelessWidget {
  const _BackChevron();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 14,
      height: 14,
      child: CustomPaint(painter: _BackChevronPainter()),
    );
  }
}

class _BackChevronPainter extends CustomPainter {
  const _BackChevronPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF7A5230)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Path path = Path()
      ..moveTo(size.width * 0.60, size.height * 0.22)
      ..lineTo(size.width * 0.36, size.height * 0.5)
      ..lineTo(size.width * 0.60, size.height * 0.78);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BackChevronPainter oldDelegate) => false;
}
