import 'dart:ui';

import 'value_noise.dart';

/// Slow, seeded drift inside a rectangle.
///
/// Position is a pure function of time, so it is reproducible and unit-testable,
/// and an actor resumes exactly where it should after a rebuild.
class WanderMotion {
  const WanderMotion({
    required this.seed,
    required this.bounds,
    required this.actorSize,
    this.period = 8.0,
  });

  final int seed;
  final Size bounds;
  final Size actorSize;

  /// Seconds per noise lattice step. Larger is slower and calmer.
  final double period;

  double get _maxX =>
      (bounds.width - actorSize.width).clamp(0.0, double.infinity);

  double get _maxY =>
      (bounds.height - actorSize.height).clamp(0.0, double.infinity);

  /// Top-left of the actor at [seconds].
  Offset positionAt(double seconds) {
    final t = seconds / period;
    return Offset(noise1(seed, t) * _maxX, noise1(seed ^ 0x5f3759df, t) * _maxY);
  }

  /// True when the actor is drifting rightwards, sampled just ahead in time.
  bool facingRightAt(double seconds) {
    const lookahead = 0.15;
    return positionAt(seconds + lookahead).dx >= positionAt(seconds).dx;
  }
}