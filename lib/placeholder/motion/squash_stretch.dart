import 'dart:math' as math;

/// A non-uniform scale whose components multiply to 1.
class ScalePair {
  const ScalePair(this.x, this.y);

  final double x;
  final double y;
}

/// Volume-preserving squash and stretch at loop phase [t] in [0, 1).
///
/// A squashed shape must get wider as it gets shorter, or it reads as a rubber
/// blob instead of a solid object under load. Keeping x * y == 1 is what sells
/// it. [amplitude] above about 0.15 starts to look comical.
ScalePair squashStretch(double t, {double amplitude = 0.08}) {
  final k = 1 + amplitude * math.sin(2 * math.pi * t);
  return ScalePair(1 / k, k);
}