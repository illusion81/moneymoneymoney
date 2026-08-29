import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../core/hexagon.dart';
import '../state/hive_state.dart';
import '../theme/hive_colors.dart';
import '../theme/hive_shadows.dart';

/// First-run onboarding: the app's entry point. Walks through a quick survey
/// and a mock Chase link (both optional), then enters the hive. The survey and
/// Chase screens are the same pushed routes reachable later from Settings.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // 0 welcome · 1 survey · 2 chase · 3 done.
  int _step = 0;

  Future<void> _next() async {
    switch (_step) {
      case 0:
        setState(() => _step = 1);
        break;
      case 1:
        await context.push('/survey');
        if (mounted) setState(() => _step = 2);
        break;
      case 2:
        await context.push('/chase-login');
        if (mounted) setState(() => _step = 3);
        break;
      case 3:
        ref.read(hiveStateProvider.notifier).completeOnboarding();
        context.go('/hive');
        break;
    }
  }

  void _skip() {
    setState(() => _step += 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HiveColors.light.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 40, 26, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(),
              _buildStep(),
              const Spacer(),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return Column(
          children: <Widget>[
            _hexMark(),
            const SizedBox(height: 24),
            Text(
              'Welcome to TallyHive',
              textAlign: TextAlign.center,
              style: GoogleFonts.caveat(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                height: 1.12,
                color: HiveColors.light.ink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A bee-themed money tracker. Log check-ins, grow your pot, and keep the swarm honest.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: HiveColors.light.inkMuted,
              ),
            ),
          ],
        );
      case 1:
        return _promptCard(
          title: 'Quick survey',
          body:
              'Four easy questions help the hive learn you. You get +50 honey for your trouble.',
        );
      case 2:
        return _promptCard(
          title: 'Link your bank',
          body:
              'Connect Chase to see real balances in the hive. It is a mock sign-in for now.',
        );
      default:
        return Column(
          children: <Widget>[
            _hexMark(),
            const SizedBox(height: 24),
            Text(
              'You\u2019re all set',
              textAlign: TextAlign.center,
              style: GoogleFonts.caveat(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                height: 1.12,
                color: HiveColors.light.ink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The hive is ready. You can change the survey and bank anytime in Settings.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: HiveColors.light.inkMuted,
              ),
            ),
          ],
        );
    }
  }

  Widget _promptCard({required String title, required String body}) {
    return Column(
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.caveat(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 1.12,
            color: HiveColors.light.ink,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.45,
            color: HiveColors.light.inkMuted,
          ),
        ),
      ],
    );
  }

  Widget _hexMark() {
    return ClipPath(
      clipper: const HexPointyClipper(),
      child: Container(
        width: 72,
        height: 80,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFFFD972), Color(0xFFE08C1B)],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    switch (_step) {
      case 0:
        return _primaryButton('Get started', _next);
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _primaryButton('Take the survey', _next),
            const SizedBox(height: 12),
            _ghostButton('Skip for now', _skip),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _primaryButton('Connect Chase', _next),
            const SizedBox(height: 12),
            _ghostButton('Skip for now', _skip),
          ],
        );
      default:
        return _primaryButton('Enter the hive', _next);
    }
  }

  Widget _primaryButton(String label, Future<void> Function() onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: HiveColors.light.ink,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: HiveColors.light.cream,
          ),
        ),
      ),
    );
  }

  Widget _ghostButton(String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: HiveColors.light.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: HiveShadows.card,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: HiveColors.light.ink,
          ),
        ),
      ),
    );
  }
}
