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