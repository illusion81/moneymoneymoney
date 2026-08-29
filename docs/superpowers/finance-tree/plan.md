# Finance Tree Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A central, procedurally generated, pixelated tree that grows in on screen and whose shape is driven by four financial pillars — profitability, liquidity, solvency, efficiency.

**Architecture:** Three separated layers. `FinancePillars` derives four 0..1 ratios from the existing `FinanceProfile`. `TreeGenerator` is a pure, seeded function returning a complete `List<TreeSegment>`, each stamped with a `growthAt` in [0, 1] — no canvas, fully unit-testable. `PixelTreePainter` quantises those segments onto a cell grid and draws deduped squares, revealing only segments whose `growthAt <= progress`.

**Tech Stack:** Flutter Material, Dart, `dart:math` (`Random` always injected), `CustomPainter`, `flutter_test`. No new package dependencies.

**Spec:** `docs/superpowers/finance-tree/spec.md`

**Reference:** `julienduranleau-sandbox/procedural-2d-tree`

## Global Constraints

- **No new package dependencies.** `pubspec.yaml` must not change.
- **`TreeGenerator` never constructs a `Random`** — it is a required parameter, so generation is reproducible under test.
- **Generation is pure**: no canvas, no widgets, no app state. Rendering is a separate layer.
- **Draw-only**: the tree widget handles no gestures and wraps its subtree in `IgnorePointer`.
- **Every pillar is clamped to [0, 1]**, and zero income yields zeros rather than a division by zero.
- **Every `growthAt` is within [0, 1].**
- **No golden-file tests.**
- `flutter analyze` must print exactly `No issues found!` and `flutter test` must pass before every commit.
- Do not modify anything under `lib/viz/`.

---

## File Structure

- `lib/tree/finance_pillars.dart` — the four ratios and their derivation.
- `lib/tree/tree_segment.dart` — one drawn segment.
- `lib/tree/tree_generator.dart` — pure seeded recursive generation.
- `lib/tree/pixel_tree_painter.dart` — grid quantisation and drawing.
- `lib/tree/finance_tree_view.dart` — ticker-driven grow-in widget.
- `test/tree/finance_pillars_test.dart`, `tree_generator_test.dart`, `pixel_tree_painter_test.dart`, `finance_tree_view_test.dart`.

---

### Task 1: Finance Pillars

**Files:**
- Create: `lib/tree/finance_pillars.dart`
- Test: `test/tree/finance_pillars_test.dart`

**Interfaces:**
- Consumes: `FinanceProfile` from `lib/models/finance_profile.dart` (fields `monthlyIncome`, `fixedMonthlyExpenses`, `monthlySavingsGoal`).
- Produces: `class FinancePillars { const FinancePillars({required double profitability, required double liquidity, required double solvency, required double efficiency}); factory FinancePillars.fromProfile(FinanceProfile profile); const FinancePillars.balanced(); final double profitability, liquidity, solvency, efficiency; double get health; bool get isWithered; static const double witheredThreshold = 0.25; }`

- [ ] **Step 1: Write the failing pillar tests**

Create `test/tree/finance_pillars_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/finance_profile.dart';
import 'package:moneymoneymoney/tree/finance_pillars.dart';

void main() {
  FinanceProfile profile({
    double income = 6000,
    double expenses = 2500,
    double savings = 900,
  }) => FinanceProfile(
    monthlyIncome: income,
    fixedMonthlyExpenses: expenses,
    monthlySavingsGoal: savings,
    riskPreference: RiskPreference.balanced,
    financialGoal: FinancialGoal.emergencyFund,
    spendingPressure: SpendingPressure.medium,
  );

  test('a healthy profile scores mid-to-high on every pillar', () {
    final p = FinancePillars.fromProfile(profile());
    for (final value in [
      p.profitability,
      p.liquidity,
      p.solvency,
      p.efficiency,
    ]) {
      expect(value, inInclusiveRange(0.0, 1.0));
      expect(value, greaterThan(0.3));
    }
  });

  test('profitability tracks the operating margin', () {
    final lean = FinancePillars.fromProfile(
      profile(income: 6000, expenses: 5000),
    ).profitability;
    final fat = FinancePillars.fromProfile(
      profile(income: 6000, expenses: 1000),
    ).profitability;
    expect(fat, greaterThan(lean));
  });

  test('solvency falls as fixed expenses take more of the income', () {
    final light = FinancePillars.fromProfile(
      profile(income: 6000, expenses: 600),
    ).solvency;
    final heavy = FinancePillars.fromProfile(
      profile(income: 6000, expenses: 5400),
    ).solvency;
    expect(light, greaterThan(heavy));
  });

  test('efficiency tracks the savings rate on disposable income', () {
    final low = FinancePillars.fromProfile(
      profile(income: 6000, expenses: 2000, savings: 200),
    ).efficiency;
    final high = FinancePillars.fromProfile(
      profile(income: 6000, expenses: 2000, savings: 3200),
    ).efficiency;
    expect(high, greaterThan(low));
  });

  test('every pillar stays within 0..1 even for absurd inputs', () {
    final broke = FinancePillars.fromProfile(
      profile(income: 1000, expenses: 9000, savings: 5000),
    );
    for (final value in [
      broke.profitability,
      broke.liquidity,
      broke.solvency,
      broke.efficiency,
    ]) {
      expect(value, inInclusiveRange(0.0, 1.0));
    }
  });

  test('zero income yields zeros rather than dividing by zero', () {
    final p = FinancePillars.fromProfile(
      profile(income: 0, expenses: 0, savings: 0),
    );
    expect(p.profitability, 0);
    expect(p.liquidity, 0);
    expect(p.solvency, 0);
    expect(p.efficiency, 0);
    expect(p.health, 0);
  });

  test('health is the mean of the four pillars', () {
    const p = FinancePillars(
      profitability: 0.2,
      liquidity: 0.4,
      solvency: 0.6,
      efficiency: 0.8,
    );
    expect(p.health, closeTo(0.5, 1e-9));
  });

  test('the withered gate fires below the threshold', () {
    const sick = FinancePillars(
      profitability: 0.1,
      liquidity: 0.1,
      solvency: 0.1,
      efficiency: 0.1,
    );
    expect(sick.isWithered, isTrue);
    expect(const FinancePillars.balanced().isWithered, isFalse);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/tree/finance_pillars_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/tree/finance_pillars.dart'`.

- [ ] **Step 3: Write the pillars**

Create `lib/tree/finance_pillars.dart`:

```dart
import '../models/finance_profile.dart';

double _clamp01(double v) => v.isNaN ? 0 : v.clamp(0.0, 1.0);

/// The four classic pillars of financial analysis, each normalized to [0, 1].
///
/// The formulas are deliberately rough stand-ins — each is directionally the
/// ratio it is named after, and each is easy to retune once the app tracks real
/// transactions.
class FinancePillars {
  const FinancePillars({
    required this.profitability,
    required this.liquidity,
    required this.solvency,
    required this.efficiency,
  });

  /// A neutral, healthy-looking default for previews and empty states.
  const FinancePillars.balanced()
    : profitability = 0.55,
      liquidity = 0.55,
      solvency = 0.55,
      efficiency = 0.55;

  factory FinancePillars.fromProfile(FinanceProfile profile) {
    final income = profile.monthlyIncome;
    if (income <= 0) {
      return const FinancePillars(
        profitability: 0,
        liquidity: 0,
        solvency: 0,
        efficiency: 0,
      );
    }

    final expenses = profile.fixedMonthlyExpenses;
    final disposable = income - expenses;
    final flexible = disposable - profile.monthlySavingsGoal;

    return FinancePillars(
      // Operating margin.
      profitability: _clamp01(disposable / income),
      // Buffer left over, against a 30%-of-income target.
      liquidity: _clamp01(flexible / (0.30 * income)),
      // How little of the month is already committed.
      solvency: _clamp01(1 - (expenses / income)),
      // Savings rate on what is actually available to save.
      efficiency: disposable <= 0
          ? 0
          : _clamp01(profile.monthlySavingsGoal / disposable),
    );
  }

  final double profitability;
  final double liquidity;
  final double solvency;
  final double efficiency;

  /// Below [witheredThreshold] the tree renders withered.
  static const double witheredThreshold = 0.25;

  double get health =>
      (profitability + liquidity + solvency + efficiency) / 4;

  bool get isWithered => health < witheredThreshold;
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/tree/finance_pillars_test.dart`
Expected: PASS, 8 tests.

- [ ] **Step 5: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/tree/finance_pillars.dart test/tree/finance_pillars_test.dart
git commit -m "feat(tree): derive four finance pillars from the profile"
```

---

### Task 2: Procedural Tree Generator

**Files:**
- Create: `lib/tree/tree_segment.dart`
- Create: `lib/tree/tree_generator.dart`
- Test: `test/tree/tree_generator_test.dart`

**Interfaces:**
- Consumes: `FinancePillars` from Task 1.
- Produces: `class TreeSegment { const TreeSegment({required Offset a, required Offset b, required double weight, required int depth, required bool isLeaf, required double growthAt}); }`
- Produces: `class TreeGenerator { const TreeGenerator(); List<TreeSegment> generate({required FinancePillars pillars, required Random random, Size canvasSize = const Size(200, 240)}); }`

**Algorithm note:** ported from the p5 reference. A branch advances in ten
steps; past 35% it may spawn a child on any step; on completion it spawns a
burst. Depth is capped by the pillars. Each segment records when it appears so
the tree can grow in.

- [ ] **Step 1: Write the failing generator tests**

Create `test/tree/tree_generator_test.dart`:

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/tree/finance_pillars.dart';
import 'package:moneymoneymoney/tree/tree_generator.dart';

void main() {
  const generator = TreeGenerator();

  List<dynamic> gen(FinancePillars pillars, {int seed = 7}) =>
      generator.generate(pillars: pillars, random: Random(seed));

  test('produces a tree for balanced pillars', () {
    expect(gen(const FinancePillars.balanced()), isNotEmpty);
  });

  test('is reproducible for a fixed seed', () {
    final a = gen(const FinancePillars.balanced());
    final b = gen(const FinancePillars.balanced());
    expect(a.length, b.length);
    for (var i = 0; i < a.length; i++) {
      expect(a[i].a, b[i].a, reason: 'segment $i start');
      expect(a[i].b, b[i].b, reason: 'segment $i end');
      expect(a[i].growthAt, closeTo(b[i].growthAt, 1e-12));
    }
  });

  test('different seeds give different trees', () {
    final a = gen(const FinancePillars.balanced(), seed: 1);
    final b = gen(const FinancePillars.balanced(), seed: 2);
    final sameLength = a.length == b.length;
    final sameFirstBranchEnd = a[9].b == b[9].b;
    expect(sameLength && sameFirstBranchEnd, isFalse);
  });

  test('every growthAt is within 0..1 and spans the range', () {
    final segments = gen(const FinancePillars.balanced());
    var maxGrowth = 0.0;
    var minGrowth = 1.0;
    for (final s in segments) {
      expect(s.growthAt, inInclusiveRange(0.0, 1.0));
      maxGrowth = s.growthAt > maxGrowth ? s.growthAt : maxGrowth;
      minGrowth = s.growthAt < minGrowth ? s.growthAt : minGrowth;
    }
    expect(maxGrowth, closeTo(1.0, 1e-9));
    expect(minGrowth, lessThan(0.2));
  });

  test('revealed segment count never decreases as progress rises', () {
    final segments = gen(const FinancePillars.balanced());
    var previous = 0;
    for (var i = 0; i <= 20; i++) {
      final progress = i / 20;
      final visible =
          segments.where((s) => s.growthAt <= progress).length;
      expect(visible, greaterThanOrEqualTo(previous));
      previous = visible;
    }
    expect(previous, segments.length);
  });

  test('higher profitability grows a taller tree', () {
    double topOf(double profitability) {
      final segments = generator.generate(
        pillars: FinancePillars(
          profitability: profitability,
          liquidity: 0.5,
          solvency: 0.5,
          efficiency: 0.5,
        ),
        random: Random(3),
      );
      return segments.map((s) => s.b.dy).reduce(min);
    }

    // Smaller dy is higher on screen.
    expect(topOf(0.9), lessThan(topOf(0.1)));
  });

  test('higher solvency thickens the trunk', () {
    double trunkWeight(double solvency) => generator
        .generate(
          pillars: FinancePillars(
            profitability: 0.5,
            liquidity: 0.5,
            solvency: solvency,
            efficiency: 0.5,
          ),
          random: Random(3),
        )
        .first
        .weight;

    expect(trunkWeight(0.9), greaterThan(trunkWeight(0.1)));
  });

  test('higher liquidity grows more leaves', () {
    int leaves(double liquidity) => generator
        .generate(
          pillars: FinancePillars(
            profitability: 0.5,
            liquidity: liquidity,
            solvency: 0.5,
            efficiency: 0.8,
          ),
          random: Random(11),
        )
        .where((s) => s.isLeaf)
        .length;

    expect(leaves(0.95), greaterThan(leaves(0.05)));
  });

  test('a withered tree grows no leaves at all', () {
    final segments = generator.generate(
      pillars: const FinancePillars(
        profitability: 0.05,
        liquidity: 0.05,
        solvency: 0.05,
        efficiency: 0.05,
      ),
      random: Random(5),
    );
    expect(segments.where((s) => s.isLeaf), isEmpty);
  });

  test('recursion never exceeds the pillar-derived cap', () {
    final segments = generator.generate(
      pillars: const FinancePillars(
        profitability: 0.9,
        liquidity: 0.9,
        solvency: 0.9,
        efficiency: 0.9,
      ),
      random: Random(2),
    );
    expect(segments.map((s) => s.depth).reduce(max), lessThanOrEqualTo(4));
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/tree/tree_generator_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/tree/tree_generator.dart'`.

- [ ] **Step 3: Write the segment type**

Create `lib/tree/tree_segment.dart`:

```dart
import 'dart:ui';

/// One drawn piece of the tree, in tree design space.
///
/// [growthAt] is when this segment appears during the grow-in, normalized to
/// [0, 1] across the whole tree.
class TreeSegment {
  const TreeSegment({
    required this.a,
    required this.b,
    required this.weight,
    required this.depth,
    required this.isLeaf,
    required this.growthAt,
  });

  final Offset a;
  final Offset b;

  /// Half-width of the drawn band, in design units.
  final double weight;

  /// Recursion level; 0 is the trunk.
  final int depth;

  final bool isLeaf;
  final double growthAt;
}
```

- [ ] **Step 4: Write the generator**

Create `lib/tree/tree_generator.dart`:

```dart
import 'dart:math';
import 'dart:ui';

import 'finance_pillars.dart';
import 'tree_segment.dart';

export 'tree_segment.dart';

/// Steps a branch is drawn in, matching the reference implementation's
/// `progress += 0.1`.
const int _stepsPerBranch = 10;

/// Builds a tree from four financial pillars.
///
/// Pure and seeded: the same pillars and the same [Random] seed always produce
/// the same tree, so a user's tree is stable rather than reshuffling on every
/// rebuild. Generation returns the complete segment list up front — nothing is
/// drawn here — which is what makes the whole thing unit-testable.
class TreeGenerator {
  const TreeGenerator();

  List<TreeSegment> generate({
    required FinancePillars pillars,
    required Random random,
    Size canvasSize = const Size(200, 240),
  }) {
    final withered = pillars.isWithered;

    // Pillar -> shape mapping.
    final trunkLength = 60 + 90 * pillars.profitability;
    final trunkWeight = 3 + 9 * pillars.solvency;
    final maxDepth = pillars.efficiency >= 0.5 ? 4 : 3;
    final branchBurst = 2 + (3 * pillars.efficiency).floor();
    final angleSpread = 0.55 - 0.20 * pillars.efficiency;
    final leafChance = withered ? 0.0 : 0.25 + 0.65 * pillars.liquidity;

    final segments = <TreeSegment>[];

    void grow({
      required Offset from,
      required double angle,
      required double weight,
      required double length,
      required int depth,
      required double startTime,
      required double duration,
    }) {
      if (depth > maxDepth || length < 4) {
        return;
      }

      var cursor = from;
      final children = <void Function()>[];

      for (var step = 0; step < _stepsPerBranch; step++) {
        // Per-step wobble, widening with depth as in the reference.
        final wobble =
            (random.nextDouble() - 0.5) * (0.4 + 0.1 * depth);
        final next = Offset(
          cursor.dx + cos(angle + wobble) * (length / _stepsPerBranch),
          cursor.dy + sin(angle) * (length / _stepsPerBranch),
        );
        final atTime =
            startTime + (step + 1) / _stepsPerBranch * duration;
        final isLeaf =
            depth >= 3 && !withered && random.nextDouble() < leafChance;

        segments.add(
          TreeSegment(
            a: cursor,
            b: next,
            weight: isLeaf ? weight * 1.6 : weight,
            depth: depth,
            isLeaf: isLeaf,
            growthAt: atTime,
          ),
        );
        cursor = next;

        // Mid-branch spawn, past 35% of the branch.
        if (step > _stepsPerBranch * 0.35 &&
            random.nextDouble() > 0.5 &&
            depth < maxDepth) {
          final origin = cursor;
          final spawnAt = atTime;
          children.add(
            () => grow(
              from: origin,
              angle: angle + _spread(random, angleSpread, depth),
              weight: weight * 0.5,
              length: length * (0.7 - depth * 0.15).clamp(0.25, 0.9),
              depth: depth + 1,
              startTime: spawnAt,
              duration: duration * 0.6,
            ),
          );
        }
      }

      // Completion burst.
      if (depth < maxDepth) {
        final count = depth >= 2 ? random.nextInt(branchBurst + 1) : branchBurst;
        for (var i = 0; i < count; i++) {
          final origin = cursor;
          children.add(
            () => grow(
              from: origin,
              angle: angle + _spread(random, angleSpread, depth),
              weight: weight * 0.5,
              length: length * (0.7 - depth * 0.15).clamp(0.25, 0.9),
              depth: depth + 1,
              startTime: startTime + duration,
              duration: duration * 0.6,
            ),
          );
        }
      }

      for (final child in children) {
        child();
      }
    }

    grow(
      from: Offset(canvasSize.width / 2, canvasSize.height),
      angle: -pi / 2,
      weight: trunkWeight,
      length: trunkLength,
      depth: 0,
      startTime: 0,
      duration: 1,
    );

    return _normalizeGrowth(segments);
  }

  /// Angle deviation, widening with depth as in the reference.
  double _spread(Random random, double base, int depth) {
    final range = base + 0.20 * depth;
    return (random.nextDouble() * 2 - 1) * range;
  }

  /// Rescales every growthAt so the tree always spans exactly [0, 1].
  List<TreeSegment> _normalizeGrowth(List<TreeSegment> segments) {
    if (segments.isEmpty) {
      return segments;
    }
    var maxTime = 0.0;
    for (final s in segments) {
      if (s.growthAt > maxTime) {
        maxTime = s.growthAt;
      }
    }
    if (maxTime <= 0) {
      return segments;
    }
    return [
      for (final s in segments)
        TreeSegment(
          a: s.a,
          b: s.b,
          weight: s.weight,
          depth: s.depth,
          isLeaf: s.isLeaf,
          growthAt: (s.growthAt / maxTime).clamp(0.0, 1.0),
        ),
    ];
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/tree/tree_generator_test.dart`
Expected: PASS, 10 tests.

If `higher liquidity grows more leaves` fails, do not weaken the assertion —
check that `leafChance` is actually consulted per step and that `withered`
zeroes it.

- [ ] **Step 6: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/tree/tree_segment.dart lib/tree/tree_generator.dart test/tree/tree_generator_test.dart
git commit -m "feat(tree): add pure seeded procedural tree generation"
```

---

### Task 3: Pixel Painter And Tree View

**Files:**
- Create: `lib/tree/pixel_tree_painter.dart`
- Create: `lib/tree/finance_tree_view.dart`
- Test: `test/tree/pixel_tree_painter_test.dart`
- Test: `test/tree/finance_tree_view_test.dart`

**Interfaces:**
- Consumes: `TreeSegment`, `TreeGenerator`, `FinancePillars`.
- Produces: `class TreePalette { const TreePalette({required Color bark, required Color leaf, required Color leafAlt}); const TreePalette.healthy(); const TreePalette.withered(); }`
- Produces: `Set<Point<int>> quantizeSegments(List<TreeSegment> segments, {required double progress, required double cell})`
- Produces: `class PixelTreePainter extends CustomPainter { PixelTreePainter({required List<TreeSegment> segments, required double progress, required TreePalette palette, required Size designSize, double cell = 4}); }`
- Produces: `class FinanceTreeView extends StatefulWidget { const FinanceTreeView({super.key, required FinancePillars pillars, int seed = 1, Duration growDuration = const Duration(seconds: 4)}); }`

- [ ] **Step 1: Write the failing painter and view tests**

Create `test/tree/pixel_tree_painter_test.dart`:

```dart
import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/tree/finance_pillars.dart';
import 'package:moneymoneymoney/tree/pixel_tree_painter.dart';
import 'package:moneymoneymoney/tree/tree_generator.dart';

void main() {
  final segments = const TreeGenerator().generate(
    pillars: const FinancePillars.balanced(),
    random: Random(7),
  );

  test('quantizes segments onto a grid with no duplicate cells', () {
    final cells = quantizeSegments(segments, progress: 1.0, cell: 4);
    expect(cells, isNotEmpty);
    // A Set cannot hold duplicates; assert the contract explicitly.
    expect(cells.length, cells.toSet().length);
  });

  test('reveals more cells as progress rises', () {
    final early = quantizeSegments(segments, progress: 0.2, cell: 4).length;
    final late = quantizeSegments(segments, progress: 1.0, cell: 4).length;
    expect(late, greaterThan(early));
  });

  test('draws nothing at zero progress', () {
    expect(quantizeSegments(segments, progress: 0.0, cell: 4), isEmpty);
  });

  test('a coarser grid yields fewer cells', () {
    final fine = quantizeSegments(segments, progress: 1.0, cell: 2).length;
    final coarse = quantizeSegments(segments, progress: 1.0, cell: 8).length;
    expect(coarse, lessThan(fine));
  });

  test('cells snap to the grid', () {
    for (final cell in quantizeSegments(segments, progress: 1.0, cell: 4)) {
      expect(cell.x, isA<int>());
      expect(cell.y, isA<int>());
    }
  });

  test('the withered palette differs from the healthy one', () {
    expect(
      const TreePalette.withered().leaf,
      isNot(const TreePalette.healthy().leaf),
    );
  });
}
```

Create `test/tree/finance_tree_view_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/tree/finance_pillars.dart';
import 'package:moneymoneymoney/tree/finance_tree_view.dart';
import 'package:moneymoneymoney/tree/pixel_tree_painter.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(width: 300, height: 360, child: child)),
  );

  PixelTreePainter painterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((p) => p.painter)
      .whereType<PixelTreePainter>()
      .first;

  testWidgets('grows in over time', (tester) async {
    await tester.pumpWidget(
      host(const FinanceTreeView(pillars: FinancePillars.balanced())),
    );
    final start = painterOf(tester).progress;
    await tester.pump(const Duration(seconds: 2));
    expect(painterOf(tester).progress, greaterThan(start));
    await tester.pump(const Duration(seconds: 5));
    expect(painterOf(tester).progress, 1.0);
  });

  testWidgets('ignores pointer events', (tester) async {
    await tester.pumpWidget(
      host(const FinanceTreeView(pillars: FinancePillars.balanced())),
    );
    expect(
      find.descendant(
        of: find.byType(FinanceTreeView),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
  });

  testWidgets('uses the withered palette for poor finances', (tester) async {
    await tester.pumpWidget(
      host(
        const FinanceTreeView(
          pillars: FinancePillars(
            profitability: 0.05,
            liquidity: 0.05,
            solvency: 0.05,
            efficiency: 0.05,
          ),
        ),
      ),
    );
    expect(
      painterOf(tester).palette.leaf,
      const TreePalette.withered().leaf,
    );
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/tree/`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/tree/pixel_tree_painter.dart'`.

- [ ] **Step 3: Write the pixel painter**

Create `lib/tree/pixel_tree_painter.dart`:

```dart
import 'dart:math';

import 'package:flutter/material.dart';

import 'tree_segment.dart';

/// Bark and leaf colours for one tree state.
class TreePalette {
  const TreePalette({
    required this.bark,
    required this.leaf,
    required this.leafAlt,
  });

  const TreePalette.healthy()
    : bark = const Color(0xff6b4a2f),
      leaf = const Color(0xff2f7d50),
      leafAlt = const Color(0xff3f9b64);

  const TreePalette.withered()
    : bark = const Color(0xff6a4f39),
      leaf = const Color(0xff8a6a4f),
      leafAlt = const Color(0xff9c8163);

  final Color bark;
  final Color leaf;
  final Color leafAlt;
}

/// Walks each visible segment and returns the set of grid cells it covers.
///
/// Deduping through a Set is what stops overlapping branches double-drawing,
/// which is what makes the result read as pixel art rather than stacked strokes.
Set<Point<int>> quantizeSegments(
  List<TreeSegment> segments, {
  required double progress,
  required double cell,
}) {
  final cells = <Point<int>>{};
  for (final segment in segments) {
    if (segment.growthAt > progress) {
      continue;
    }
    final dx = segment.b.dx - segment.a.dx;
    final dy = segment.b.dy - segment.a.dy;
    final length = sqrt(dx * dx + dy * dy);
    final steps = max(1, (length / (cell * 0.5)).ceil());
    final band = max(0, (segment.weight / cell / 2).round());

    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = segment.a.dx + dx * t;
      final y = segment.a.dy + dy * t;
      final cx = (x / cell).floor();
      final cy = (y / cell).floor();
      for (var ox = -band; ox <= band; ox++) {
        for (var oy = -band; oy <= band; oy++) {
          cells.add(Point<int>(cx + ox, cy + oy));
        }
      }
    }
  }
  return cells;
}

/// Draws the tree as snapped squares on a fixed grid.
class PixelTreePainter extends CustomPainter {
  PixelTreePainter({
    required this.segments,
    required this.progress,
    required this.palette,
    required this.designSize,
    this.cell = 4,
  });

  final List<TreeSegment> segments;

  /// Grow-in progress in [0, 1].
  final double progress;

  final TreePalette palette;

  /// The space the segments were generated in; letterboxed into the paint size.
  final Size designSize;

  /// Grid cell edge, in design units.
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final fit = min(
      size.width / designSize.width,
      size.height / designSize.height,
    );
    final dx = (size.width - designSize.width * fit) / 2;
    final dy = (size.height - designSize.height * fit) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(fit);

    // Bark first, then leaves on top, so foliage always reads in front.
    _paintLayer(canvas, leaves: false);
    _paintLayer(canvas, leaves: true);

    canvas.restore();
  }

  void _paintLayer(Canvas canvas, {required bool leaves}) {
    final subset = segments.where((s) => s.isLeaf == leaves).toList();
    final cells = quantizeSegments(
      subset,
      progress: progress,
      cell: cell,
    );
    final paint = Paint()..style = PaintingStyle.fill;
    for (final c in cells) {
      // Two leaf tones, chosen from position so the canopy is not flat.
      paint.color = leaves
          ? ((c.x + c.y).isEven ? palette.leaf : palette.leafAlt)
          : palette.bark;
      canvas.drawRect(
        Rect.fromLTWH(c.x * cell, c.y * cell, cell, cell),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(PixelTreePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.segments != segments ||
      oldDelegate.palette != palette ||
      oldDelegate.cell != cell;
}
```

- [ ] **Step 4: Write the tree view**

Create `lib/tree/finance_tree_view.dart`:

```dart
import 'dart:math';

import 'package:flutter/material.dart';

import 'finance_pillars.dart';
import 'pixel_tree_painter.dart';
import 'tree_generator.dart';

/// The central tree: generated from the pillars, grown in once on mount.
///
/// Draw-only; the subtree is wrapped in [IgnorePointer].
class FinanceTreeView extends StatefulWidget {
  const FinanceTreeView({
    super.key,
    required this.pillars,
    this.seed = 1,
    this.growDuration = const Duration(seconds: 4),
  });

  final FinancePillars pillars;

  /// Same seed plus same pillars gives the same tree, every time.
  final int seed;

  final Duration growDuration;

  @override
  State<FinanceTreeView> createState() => _FinanceTreeViewState();
}

class _FinanceTreeViewState extends State<FinanceTreeView>
    with SingleTickerProviderStateMixin {
  static const Size _design = Size(200, 240);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.growDuration,
  )..forward();

  late List<TreeSegment> _segments = _build();

  List<TreeSegment> _build() => const TreeGenerator().generate(
    pillars: widget.pillars,
    random: Random(widget.seed),
    canvasSize: _design,
  );

  @override
  void didUpdateWidget(FinanceTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Regrow only when the tree would actually differ.
    if (oldWidget.seed != widget.seed ||
        oldWidget.pillars.health != widget.pillars.health) {
      _segments = _build();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.pillars.isWithered
        ? const TreePalette.withered()
        : const TreePalette.healthy();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: PixelTreePainter(
            segments: _segments,
            progress: _controller.value,
            palette: palette,
            designSize: _design,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/tree/`
Expected: PASS.

- [ ] **Step 6: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/tree/pixel_tree_painter.dart lib/tree/finance_tree_view.dart test/tree
git commit -m "feat(tree): add pixel rasterisation and grow-in tree view"
```

---

### Task 4: Home Screen Integration

**Files:**
- Create: `lib/screens/forest_home_screen.dart`
- Modify: `lib/main.dart`
- Test: `test/tree/forest_home_test.dart`

**Interfaces:**
- Consumes: `FinancePillars.fromProfile`, `FinanceTreeView`, `ActorField`, `ActorCatalog` (from the placeholder-actors plan), `FinanceProfile`.
- Produces: `class ForestHomeScreen extends StatelessWidget { const ForestHomeScreen({super.key, required FinanceProfile profile, List<String> actorIds = const ['fox', 'deer']}); }`
- Produces: `const bool kHomeMode` in `lib/app_mode.dart` — when true, `MyApp` boots into `ForestHomeScreen`.

**Note:** this task depends on the placeholder-actors plan being complete.

- [ ] **Step 1: Write the failing home screen test**

Create `test/tree/forest_home_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/finance_profile.dart';
import 'package:moneymoneymoney/placeholder/actor_field.dart';
import 'package:moneymoneymoney/screens/forest_home_screen.dart';
import 'package:moneymoneymoney/tree/finance_tree_view.dart';

void main() {
  const profile = FinanceProfile(
    monthlyIncome: 6000,
    fixedMonthlyExpenses: 2500,
    monthlySavingsGoal: 900,
    riskPreference: RiskPreference.balanced,
    financialGoal: FinancialGoal.emergencyFund,
    spendingPressure: SpendingPressure.medium,
  );

  Widget host(Widget child) => MaterialApp(home: child);

  testWidgets('shows the tree and the actor field', (tester) async {
    await tester.pumpWidget(
      host(const ForestHomeScreen(profile: profile)),
    );
    expect(find.byType(FinanceTreeView), findsOneWidget);
    expect(find.byType(ActorField), findsOneWidget);
  });

  testWidgets('shows a readout for each of the four pillars', (tester) async {
    await tester.pumpWidget(
      host(const ForestHomeScreen(profile: profile)),
    );
    expect(find.text('Profitability'), findsOneWidget);
    expect(find.text('Liquidity'), findsOneWidget);
    expect(find.text('Solvency'), findsOneWidget);
    expect(find.text('Efficiency'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/tree/forest_home_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/screens/forest_home_screen.dart'`.

- [ ] **Step 3: Write the home screen**

Create `lib/screens/forest_home_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../models/finance_profile.dart';
import '../placeholder/actor_catalog.dart';
import '../placeholder/actor_field.dart';
import '../tree/finance_pillars.dart';
import '../tree/finance_tree_view.dart';

/// The main screen: the finance tree, wandering placeholder animals, and a
/// readout of the four pillars driving the tree's shape.
class ForestHomeScreen extends StatelessWidget {
  const ForestHomeScreen({
    super.key,
    required this.profile,
    this.actorIds = const ['fox', 'deer'],
  });

  final FinanceProfile profile;
  final List<String> actorIds;

  @override
  Widget build(BuildContext context) {
    final pillars = FinancePillars.fromProfile(profile);

    return Scaffold(
      appBar: AppBar(title: const Text('Wealth Forest')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: FinanceTreeView(pillars: pillars)),
                  Positioned.fill(
                    child: ActorField(
                      actors: [
                        for (final id in actorIds) ActorCatalog.byId(id),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _PillarBars(pillars: pillars),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillarBars extends StatelessWidget {
  const _PillarBars({required this.pillars});

  final FinancePillars pillars;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PillarBar(label: 'Profitability', value: pillars.profitability),
        _PillarBar(label: 'Liquidity', value: pillars.liquidity),
        _PillarBar(label: 'Solvency', value: pillars.solvency),
        _PillarBar(label: 'Efficiency', value: pillars.efficiency),
      ],
    );
  }
}

class _PillarBar extends StatelessWidget {
  const _PillarBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 104, child: Text(label)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: value, minHeight: 7),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${(value * 100).round()}%',
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Boot into the home screen**

In `lib/app_mode.dart`, add below the existing flag:

```dart
/// While true, the app boots straight into the forest home screen with a
/// demo profile, so the tree and actors can be reviewed without onboarding.
const bool kHomeMode = true;
```

In `lib/main.dart`, add the imports:

```dart
import 'screens/forest_home_screen.dart';
```

and in `_MyAppState.build`, replace the `home:` argument with:

```dart
      home: widget.vizMode
          ? const VizWorkbenchScreen()
          : kHomeMode
          ? const ForestHomeScreen(
              profile: FinanceProfile(
                monthlyIncome: 6000,
                fixedMonthlyExpenses: 2500,
                monthlySavingsGoal: 900,
                riskPreference: RiskPreference.balanced,
                financialGoal: FinancialGoal.emergencyFund,
                spendingPressure: SpendingPressure.medium,
              ),
            )
          : _buildCurrentView(),
```

Set `kVizMode` to `false` in `lib/app_mode.dart` so the home screen is what boots.

- [ ] **Step 5: Keep the existing flow tests on the flow**

In `test/widget_test.dart`, the `pumpApp` helper builds `MyApp(vizMode: false)`.
That would now land on the home screen rather than onboarding. Change the helper
to construct the app with both flags off by passing `homeMode: false`:

Add the parameter to `MyApp` in `lib/main.dart`:

```dart
  const MyApp({super.key, this.vizMode = kVizMode, this.homeMode = kHomeMode});

  final bool vizMode;
  final bool homeMode;
```

and use `widget.homeMode` in place of `kHomeMode` in `build`. Then in
`test/widget_test.dart`:

```dart
    await tester.pumpWidget(const MyApp(vizMode: false, homeMode: false));
```

- [ ] **Step 6: Run the whole suite**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 7: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/screens/forest_home_screen.dart lib/main.dart lib/app_mode.dart test/tree/forest_home_test.dart test/widget_test.dart
git commit -m "feat(tree): boot into the forest home screen with tree and actors"
```
