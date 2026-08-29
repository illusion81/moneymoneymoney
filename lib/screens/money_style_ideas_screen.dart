import 'package:flutter/material.dart';

import '../models/money_style.dart';

/// One concrete, opt-in idea per dimension — the "work on this" version and
/// the "keep this going" version, picked by the sign of that dimension's score.
String ideaFor(
  Dimension dimension, {
  required bool positive,
}) => switch (dimension) {
  Dimension.revolvingDebtNeglect =>
    positive
        ? 'keep the autopay-in-full setting where it is, and glance at the interest line once a month'
        : 'set autopay to the full statement balance once, so it stops being a monthly decision',
  Dimension.convenienceImpulse =>
    positive
        ? 'keep your delivery/rideshare rule, and check the monthly total every so often'
        : 'decide the rule now — “delivery is fine when X” — rather than at the end of a long day',
  Dimension.subscriptionBlindness =>
    positive
        ? 'keep the audit habit: one statement scan every few months is enough'
        : 'read one statement line by line and total up what recurs',
  Dimension.savingsAvoidance =>
    positive
        ? 'leave the automatic transfer alone, and name the number you are saving toward'
        : 'set one small automatic transfer for payday, so saving stops depending on remembering',
  Dimension.priceAnchoring =>
    positive
        ? 'keep setting your own price before you see theirs'
        : 'pick a rough number before you look at the menu or the listing',
  Dimension.financialAvoidance =>
    positive
        ? 'keep the fixed check-in day — the point is that it happens on good and bad weeks alike'
        : 'put a two-minute balance check on the same day each week, good news or not',
};

class MoneyStyleIdeasScreen extends StatelessWidget {
  const MoneyStyleIdeasScreen({
    super.key,
    required this.result,
    required this.onBack,
  });

  final MoneyStyleResult result;
  final VoidCallback onBack;

  /// Up to three ideas: the most critical habit first, then the strongest one
  /// to keep, then the next dimension worth a look.
  List<String> get ideas {
    final lines = <String>[];
    final used = <Dimension>{};

    void add(Dimension? dimension, {required bool positive}) {
      if (dimension == null || used.contains(dimension)) return;
      used.add(dimension);
      lines.add(
        '${dimensionLabel(dimension)}: ${ideaFor(dimension, positive: positive)}.',
      );
    }

    add(result.mostCriticalDimension, positive: false);
    add(result.strongestDimension, positive: true);
    if (lines.length < 3) {
      for (final dimension in kDimensionPriority) {
        if (used.contains(dimension)) continue;
        final score = result.dimensionTotals[dimension];
        if (score == null) continue;
        add(dimension, positive: score > 0);
        if (lines.length >= 3) break;
      }
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ideas for your style')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.archetype.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          const Text('You could try:'),
          ...ideas.map((idea) => Text('• $idea')),
          const SizedBox(height: 12),
          const Text('These are optional prompts, not financial advice.'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onBack,
              child: const Text('Back to Money Style'),
            ),
          ),
        ],
      ),
    ),
  );
}
