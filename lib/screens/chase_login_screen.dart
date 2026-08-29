import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../state/hive_state.dart';
import '../theme/hive_colors.dart';
import '../theme/hive_shadows.dart';

/// A mock Chase bank sign-in (pushed route from Settings). Prefilled,
/// non-editable credentials and a short fake "connecting" delay — no real
/// network or credentials are involved. On success it marks Chase linked and
/// pops back to Settings.
class ChaseLoginScreen extends ConsumerStatefulWidget {
  const ChaseLoginScreen({super.key});

  @override
  ConsumerState<ChaseLoginScreen> createState() => _ChaseLoginScreenState();
}

class _ChaseLoginScreenState extends ConsumerState<ChaseLoginScreen> {
  static const Color _chaseBlue = Color(0xFF3B5C86);
  static const Color _chaseTile = Color(0xFFE9EFF6);

  bool _submitting = false;

  void _signIn() {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) {
        return;
      }
      ref.read(hiveStateProvider.notifier).linkBank('chase');
      context.pop();
    });
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
                  'Connect Chase',
                  style: GoogleFonts.caveat(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                    color: HiveColors.light.ink,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(),
            ],
          ),
          Positioned(top: 12, left: 18, child: _backButton(() => context.pop())),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HiveColors.light.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: HiveShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _chaseTile,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  'C',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _chaseBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Chase · checking',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: HiveColors.light.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _field('Email', 'sam.jones@example.com'),
          const SizedBox(height: 12),
          _field('Password', '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022'),
          const SizedBox(height: 16),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _signIn,
            child: Container(
              width: double.infinity,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _submitting ? HiveColors.light.surfaceSunk : _chaseBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _submitting ? 'Connecting securely\u2026' : 'Sign in',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _submitting ? HiveColors.light.inkMuted : HiveColors.light.cream,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Mock sign-in for the prototype \u2014 no credentials are sent anywhere.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: HiveColors.light.inkFaint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.05,
            color: const Color(0x6633251A),
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: HiveColors.light.surfaceWarm,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: HiveColors.light.ink,
            ),
          ),
        ),
      ],
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
