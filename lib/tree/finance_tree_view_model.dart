import '../models/finance_profile.dart';
import '../models/forest_day.dart';
import 'finance_pillars.dart';

/// The combined state that drives one finance tree.
///
/// Two independent health signals feed the tree, and both are preserved:
///
///  * [pillars] — the tree's *shape and vigour*, derived from the user's
///    finance profile by [FinancePillars.fromProfile].
///  * [checkInStatus] / [streak] — check-in-driven health, owned by
///    `ForestEngine`. A missed or over-budget day withers the tree.
///
/// [withered] is the only point where the two meet. A tree renders withered
/// when EITHER the finance profile is unhealthy (the pillars' own gate) OR the
/// latest check-in withered. The signals are OR-ed, never blended, so neither
/// one can mask the other.
class FinanceTreeState {
  const FinanceTreeState({
    required this.pillars,
    required this.withered,
    required this.streak,
    required this.checkInStatus,
  });

  /// Shape and vigour from the finance profile. Never altered by check-in
  /// health — a missed day withers the canopy but does not shrink the tree.
  final FinancePillars pillars;

  /// Whether the tree should render withered, from either signal.
  final bool withered;

  /// Pass-through of the check-in streak, for any readout that wants it.
  final int streak;

  /// The latest check-in status, or null when the user has never checked in.
  final TreeStatus? checkInStatus;
}

/// Combines a finance profile and a check-in summary into [FinanceTreeState].
///
/// Pure and dependency-free: `ForestEngine` is never touched here, only its
/// already-computed [ForestSummary]. That keeps `ForestEngine` the single
/// authority on check-in health and streaks while this class just reads its
/// output.
class FinanceTreeViewModel {
  const FinanceTreeViewModel({
    required this.profile,
    required this.summary,
  });

  final FinanceProfile profile;
  final ForestSummary summary;

  FinanceTreeState get state {
    final pillars = FinancePillars.fromProfile(profile);
    final latestDay = summary.days.isEmpty ? null : summary.days.last;
    final checkInWithered = latestDay?.status == TreeStatus.withered;
    return FinanceTreeState(
      pillars: pillars,
      withered: pillars.isWithered || checkInWithered,
      streak: summary.currentStreak,
      checkInStatus: latestDay?.status,
    );
  }
}
