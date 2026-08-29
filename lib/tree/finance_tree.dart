import 'package:flutter/material.dart';

import '../models/finance_profile.dart';
import '../models/forest_day.dart';
import 'finance_tree_view.dart';
import 'finance_tree_view_model.dart';

/// The public entry point for the finance tree.
///
/// Combines the two health signals — the finance profile (via
/// [FinanceTreeViewModel], which derives the pillars that shape the tree) and
/// the check-in summary (which owns streaks and withering) — and renders the
/// resulting [FinanceTreeView].
///
/// Host screens that already carry a [FinanceProfile] and a [ForestSummary]
/// can drop this in with no further wiring:
///
/// ```dart
/// FinanceTree(profile: profile, summary: summary)
/// ```
class FinanceTree extends StatelessWidget {
  const FinanceTree({
    super.key,
    required this.profile,
    required this.summary,
    this.seed = 1,
    this.height = 240,
    this.growDuration = const Duration(seconds: 4),
  });

  final FinanceProfile profile;
  final ForestSummary summary;

  /// Same seed plus same profile gives the same tree, every time.
  final int seed;

  /// The height the tree is laid out at; width is taken from the parent.
  final double height;

  final Duration growDuration;

  @override
  Widget build(BuildContext context) {
    final state = FinanceTreeViewModel(
      profile: profile,
      summary: summary,
    ).state;

    return SizedBox(
      height: height,
      child: FinanceTreeView(
        pillars: state.pillars,
        withered: state.withered,
        seed: seed,
        growDuration: growDuration,
      ),
    );
  }
}
