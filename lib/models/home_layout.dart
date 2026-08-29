class DecorationPlacement {
  const DecorationPlacement({
    required this.itemId,
    required this.dx,
    required this.dy,
  });

  final String itemId;

  /// Fraction of the homestead canvas width, in [0, 1].
  final double dx;

  /// Fraction of the homestead canvas height, in [0, 1].
  final double dy;
}

class HomeLayoutState {
  const HomeLayoutState({required this.placements});

  final List<DecorationPlacement> placements;
}
