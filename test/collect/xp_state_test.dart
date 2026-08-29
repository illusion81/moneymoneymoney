import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/collect/models/xp_state.dart';

void main() {
  test('the curve matches the published thresholds', () {
    expect(XpState.xpForLevel(1), 0);
    expect(XpState.xpForLevel(2), 50);
    expect(XpState.xpForLevel(3), 150);
    expect(XpState.xpForLevel(4), 300);
    expect(XpState.xpForLevel(5), 500);
  });

  test('levelForXp agrees with the curve at every boundary', () {
    for (var level = 1; level <= 20; level++) {
      final threshold = XpState.xpForLevel(level);
      expect(XpState.levelForXp(threshold), level, reason: 'at level $level');
      if (level > 1) {
        expect(XpState.levelForXp(threshold - 1), level - 1,
            reason: 'below level $level');
      }
    }
  });

  test('the level is capped', () {
    expect(XpState(totalXp: 99999999).level, XpState.maxLevel);
    expect(XpState(totalXp: 99999999).levelProgress, 1.0);
    expect(XpState(totalXp: 99999999).xpForNextLevel, 0);
  });

  test('progress within a level is a 0..1 fraction', () {
    const state = XpState(totalXp: 100); // level 2 spans 50..150
    expect(state.level, 2);
    expect(state.xpIntoLevel, 50);
    expect(state.xpForNextLevel, 100);
    expect(state.levelProgress, closeTo(0.5, 0.0001));
  });

  test('gaining XP accumulates and never decreases', () {
    expect(const XpState.empty().gain(10).gain(5).totalXp, 15);
    expect(() => const XpState.empty().gain(-1), throwsArgumentError);
  });
}