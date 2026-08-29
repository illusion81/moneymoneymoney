import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../state/hive_state.dart';
import '../theme/hive_colors.dart';
import '../theme/hive_shadows.dart';

/// A quick, easy-to-answer mock survey (pushed route from Settings).
///
/// Four multiple-choice questions, one tap per answer; completing the survey
/// credits 50 honey exactly once.
class SurveyScreen extends ConsumerStatefulWidget {
  const SurveyScreen({super.key});

  @override
  ConsumerState<SurveyScreen> createState() => _SurveyScreenState();
}

class _Question {
  const _Question(this.prompt, this.options);

  final String prompt;
  final List<String> options;
}

const List<_Question> _questions = <_Question>[
  _Question('How do you feel about your money this week?', <String>[
    'On track',
    'A bit wobbly',
    'No idea',
  ]),
  _Question('What should the hive do first?', <String>[
    'Help me save more',
    'Cut a subscription',
    'Just keep the streak',
  ]),
  _Question('How often do you check your balance?', <String>[
    'Daily',
    'Weekly',
    'Rarely',
  ]),
  _Question('Would you tell a friend about TallyHive?', <String>[
    'Yes',
    'Maybe',
    'Not yet',
  ]),
];

class _SurveyScreenState extends ConsumerState<SurveyScreen> {
  int _index = 0;
  bool _done = false;

  void _answer(String option) {
    if (_index < _questions.length - 1) {
      setState(() => _index += 1);
      return;
    }
    if (!_done) {
      ref.read(hiveStateProvider.notifier).addHoney(50);
    }
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HiveColors.light.canvas,
      body: Stack(
        children: <Widget>[
          ListView(
            padding: const EdgeInsets.fromLTRB(18, 62, 18, 40),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'Quick survey',
                  style: GoogleFonts.caveat(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                    color: HiveColors.light.ink,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_done) _buildDone() else _buildQuestion(),
            ],
          ),
          Positioned(top: 12, left: 18, child: _backButton(() => context.pop())),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    final _Question q = _questions[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${_index + 1} of ${_questions.length}',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: HiveColors.light.honeyText,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          q.prompt,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: HiveColors.light.ink,
          ),
        ),
        const SizedBox(height: 16),
        for (final String option in q.options) ...<Widget>[
          _optionRow(option),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _optionRow(String option) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _answer(option),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: HiveColors.light.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: HiveShadows.card,
        ),
        child: Text(
          option,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: HiveColors.light.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildDone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HiveColors.light.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: HiveShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Thanks!',
                style: GoogleFonts.caveat(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.12,
                  color: HiveColors.light.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your answers help the hive get smarter. +50 honey for your trouble.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  color: HiveColors.light.inkMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _primaryButton('Done', () => context.pop()),
      ],
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: HiveColors.light.ink,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: HiveColors.light.cream,
          ),
        ),
      ),
    );
  }

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

/// A drawn back chevron in `#7A5230` (brownDeep alternate) — no icon fonts.
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
