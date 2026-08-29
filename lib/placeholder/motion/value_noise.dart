import 'dart:math' as math;

/// Deterministic hash of a lattice point to [0, 1).
///
/// Integer mixing rather than `Random`, so the same (seed, i) always gives the
/// same value with no object to carry around.
double hash01(int seed, int i) {
  var h = (seed * 374761393 + i * 668265263) & 0x7fffffff;
  h = (h ^ (h >> 13)) * 1274126177 & 0x7fffffff;
  h = h ^ (h >> 16);
  return (h & 0xffffff) / 0x1000000;
}

/// Smooth 1-D value noise: a hashed lattice with smoothstep interpolation.
///
/// Pure and testable like a sine sum, but without a sine sum's visible loop, so
/// wander never repeats a path the eye can learn.
double noise1(int seed, double t) {
  final i = t.floor();
  final f = t - i;
  final a = hash01(seed, i);
  final b = hash01(seed, i + 1);
  final smooth = f * f * (3 - 2 * f);
  return a + (b - a) * smooth;
}

/// Value noise mapped to [-1, 1].
double noiseSigned(int seed, double t) => noise1(seed, t) * 2 - 1;

/// Kept for callers that want a quick angle from a noise channel.
double noiseAngle(int seed, double t) => noise1(seed, t) * 2 * math.pi;