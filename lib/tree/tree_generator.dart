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