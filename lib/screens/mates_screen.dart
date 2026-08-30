import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/hexagon.dart';
import '../data/members.dart';
import '../models/models.dart';
import '../state/hive_state.dart';
import '../theme/hive_colors.dart';
import '../theme/hive_shadows.dart';
import '../widgets/honey_snack.dart';
import '../widgets/primitives/primitives.dart';

/// 150° gradient travel direction for the swarm-goal card (design.md §1.1
/// `darkGradientEnd`; same convention as market_art_tile.dart).
final double _sDx = math.sin(150 * math.pi / 180);
final double _sDy = -math.cos(150 * math.pi / 180);

/// 158° gradient travel direction for the invite hex (honeycomb.dart
/// convention).
final double _iDx = math.sin(158 * math.pi / 180);
final double _iDy = -math.cos(158 * math.pi / 180);

/// The Hive-mates screen (README "Screen 5 — Hive-mates", design.md §4.4).
class MatesScreen extends ConsumerWidget {
  const MatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HiveState state = ref.watch(hiveStateProvider);
    final HiveNotifier notifier = ref.read(hiveStateProvider.notifier);

    return Scaffold(
      backgroundColor: HiveColors.light.canvas,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 62, 18, 100),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              "Sam's five",
              style: GoogleFonts.caveat(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                height: 1.12,
                color: HiveColors.light.ink,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _swarmGoalCard(),
          const SizedBox(height: 14),
          _inviteRow(
            sent: state.invites > 0,
            invites: state.invites,
            onTap: notifier.inviteFriend,
          ),
          const SizedBox(height: 14),
          for (final Member m in kMembers) ...[
            _memberRow(
              member: m,
              nudged: state.nudgedFriends.contains(m.id),
              onNudge: () => notifier.nudgeFriend(m.id),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  /// The dark "Weekly swarm goal" card (150° gradient, 80 % progress).
  Widget _swarmGoalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-_sDx, -_sDy),
          end: Alignment(_sDx, _sDy),
          colors: <Color>[
            HiveColors.light.ink,
            HiveColors.light.darkGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
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
                'Weekly swarm goal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: HiveColors.light.cream,
                ),
              ),
              Text(
                '28/35',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: HiveColors.light.honey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          // 8 px track on 18 % cream, 80 % honey fill (prototype).
          ProgressBar(
            value: 0.8,
            fill: HiveColors.light.honey,
            track: const Color(0x2EF6EFE0),
          ),
          const SizedBox(height: 11),
          Text(
            '7 more check-ins between the five of you unlocks the group honey drop.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              // 65 % cream (design.md §1.1).
              color: const Color(0xA6F6EFE0),
            ),
          ),
        ],
      ),
    );
  }

  /// The invite row: amber "+" hex + copy + ink "+100" pill. Flips to the
  /// sent state (honeyTint + owned-card shadow) once at least one invite has
  /// gone out.
  Widget _inviteRow({
    required bool sent,
    required int invites,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: sent ? HiveColors.light.honeyTint : HiveColors.light.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: sent ? HiveShadows.ownedCard : HiveShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                ClipPath(
                  clipper: const HexPointyClipper(),
                  child: Container(
                    width: 34,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-_iDx, -_iDy),
                        end: Alignment(_iDx, _iDy),
                        colors: <Color>[
                          HiveColors.light.honeyLight, // #FFD972
                          HiveColors.light.honeyDeep, // #E08C1B
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: HiveColors.light.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        sent
                            ? 'Invite sent · +100 honey'
                            : 'Invite a hive-mate',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: HiveColors.light.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sent
                            ? 'They join with a 3-day grace period. $invites sent.'
                            : 'Both of you get 100 honey when they log their first check-in.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          // 50 % ink — sub-line alternate (prototype).
                          color: const Color(0x8033251A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  decoration: BoxDecoration(
                    color: HiveColors.light.ink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const _InvitePillJar(),
                      const SizedBox(width: 5),
                      Text(
                        '+100',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: HiveColors.light.cream,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _shareLinks(),
          ],
        ),
      ),
    );
  }

  /// Demo dressing: the share row stands on its own rather than waiting for
  /// an invite, so a walkthrough does not have to discover it.
  Widget _shareLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Share your hive',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: HiveColors.light.inkFaint,
          ),
        ),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _DemoShareLink(
              key: Key('mates-share-facebook'),
              platform: 'Facebook',
            ),
            _DemoShareLink(
              key: Key('mates-share-instagram'),
              platform: 'Instagram',
            ),
            _DemoShareLink(
              key: Key('mates-share-tiktok'),
              platform: 'TikTok',
            ),
          ],
        ),
      ],
    );
  }

  /// One hive-mate row (README: avatar / name+tag / status / nudge pill).
  Widget _memberRow({
    required Member member,
    required bool nudged,
    required VoidCallback onNudge,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: HiveColors.light.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: HiveShadows.card,
      ),
      child: Row(
        children: <Widget>[
          BreathingHive(honey: member.honey, streak: member.streak),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        member.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: HiveColors.light.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _streakTag(member),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    // 45 % ink — member-status alternate (design.md §1.1).
                    color: const Color(0x7333251A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          _actionPill(isYou: member.isYou, nudged: nudged, onNudge: onNudge),
        ],
      ),
    );
  }

  /// The streak tag chip ("31d" / "quiet" / "you", design.md §4.4).
  Widget _streakTag(Member member) {
    final String label;
    final Color bg;
    final Color fg;
    if (member.isYou) {
      label = 'you';
      bg = HiveColors.light.ink;
      fg = HiveColors.light.honey;
    } else if (member.streak >= 25) {
      label = '${member.streak}d';
      bg = HiveColors.light.honeyTint;
      fg = const Color(0xFF8A5E12);
    } else if (member.streak > 0) {
      label = '${member.streak}d';
      bg = const Color(0xFFF3EDDF);
      fg = const Color(0x8033251A); // 50 % ink
    } else {
      label = 'quiet';
      bg = const Color(0xFFF3EDDF);
      fg = const Color(0x8033251A); // 50 % ink
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }

  /// The right-hand action pill: "Nudge" → "Sent", or a non-interactive "you"
  /// on the signed-in user's own row.
  Widget _actionPill({
    required bool isYou,
    required bool nudged,
    required VoidCallback onNudge,
  }) {
    if (isYou) {
      return Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        child: Text(
          'you',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            // 35 % ink (prototype "you" pill).
            color: const Color(0x5933251A),
          ),
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onNudge,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: nudged
              ? HiveColors.light.honeyTint
              : HiveColors.light.surfaceSunk,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          nudged ? 'Sent' : 'Nudge',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: nudged ? const Color(0xFF8A5E12) : HiveColors.light.ink,
          ),
        ),
      ),
    );
  }
}

/// The 10×12 jar in the invite pill (design.md §4.4): lid `#B8801A`, solid
/// honey body.
class _InvitePillJar extends StatelessWidget {
  const _InvitePillJar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 12,
      child: Stack(
        children: <Widget>[
          Positioned(
            top: 0,
            left: 2,
            right: 2,
            height: 2.5,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFB8801A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            top: 2.5,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: HiveColors.light.honey,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                  bottom: Radius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One fake share button. Nothing is wired to a social SDK, so the tap says
/// so through [showHoneySnack] rather than sitting dead under a finger.
class _DemoShareLink extends StatelessWidget {
  const _DemoShareLink({super.key, required this.platform});

  final String platform;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showHoneySnack(
        context,
        'Sharing to $platform is a demo placeholder.',
      ),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: HiveColors.light.surfaceSunk,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Share to $platform',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: HiveColors.light.ink,
          ),
        ),
      ),
    );
  }
}
