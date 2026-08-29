/// Total experience. The level is always derived, never stored, so the two can
/// never disagree.
class XpState {
  const XpState({required this.totalXp});

  const XpState.empty() : totalXp = 0;

  static const int maxLevel = 50;

  final int totalXp;

  /// Cumulative XP required to reach [level].
  static int xpForLevel(int level) => 25 * level * (level - 1);

  static int levelForXp(int xp) {
    if (xp <= 0) {
      return 1;
    }
    var level = 1;
    while (level < maxLevel && xp >= xpForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  int get level => levelForXp(totalXp);

  int get xpIntoLevel => totalXp - xpForLevel(level);

  /// The span of the current level, or 0 at the cap.
  int get xpForNextLevel =>
      level >= maxLevel ? 0 : xpForLevel(level + 1) - xpForLevel(level);

  double get levelProgress =>
      xpForNextLevel == 0 ? 1.0 : xpIntoLevel / xpForNextLevel;

  XpState gain(int amount) {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must not be negative');
    }
    return XpState(totalXp: totalXp + amount);
  }
}