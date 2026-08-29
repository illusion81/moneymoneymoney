import 'package:flutter/material.dart';

/// An encouragement line that escalates with the streak, so the message
/// still feels earned on day 30 rather than repeating day 1's praise.
String encouragementForStreak(int streak) {
  if (streak >= 30) {
    return 'A full month within budget. This is who you are now.';
  }
  if (streak >= 14) {
    return 'Two weeks straight — your forest is really taking root.';
  }
  if (streak >= 7) {
    return 'A whole week on plan. The habit is forming.';
  }
  if (streak >= 3) {
    return 'Three days running. Momentum is on your side.';
  }
  return 'You stayed within budget today. That is how it starts.';
}

/// Celebrates a healthy check-in. Shown only when the day was actually
/// within budget — never after overspending.
void showCelebrationDialog({
  required BuildContext context,
  required int earnedXp,
  required int earnedCoins,
  required int streak,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => _CelebrationDialog(
      earnedXp: earnedXp,
      earnedCoins: earnedCoins,
      streak: streak,
    ),
  );
}

class _CelebrationDialog extends StatelessWidget {
  const _CelebrationDialog({
    required this.earnedXp,
    required this.earnedCoins,
    required this.streak,
  });

  final int earnedXp;
  final int earnedCoins;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('celebration-dialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xffedf8ed),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.park,
              size: 40,
              color: Color(0xff2f7d50),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nice work!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xff173b2f),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            encouragementForStreak(streak),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RewardTile(
                icon: Icons.auto_awesome,
                color: const Color(0xff3f8f8a),
                value: '+$earnedXp',
                label: 'XP',
              ),
              _RewardTile(
                icon: Icons.monetization_on,
                color: const Color(0xffc79a33),
                value: '+$earnedCoins',
                label: 'coins',
              ),
              _RewardTile(
                icon: Icons.local_fire_department,
                color: const Color(0xffd97f4a),
                value: '$streak',
                label: streak == 1 ? 'day streak' : 'day streak',
              ),
            ],
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          key: const Key('celebration-continue-button'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
