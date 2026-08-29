/// Homestead yard grid is a square [kHomeGridSize] x [kHomeGridSize] of
/// isometric cells, indexed 0..kHomeGridSize - 1 on each axis.
const int kHomeGridSize = 6;

class DecorationPlacement {
  const DecorationPlacement({
    required this.itemId,
    required this.row,
    required this.col,
  });

  final String itemId;
  final int row;
  final int col;
}

class HomeLayoutState {
  const HomeLayoutState({required this.placements});

  final List<DecorationPlacement> placements;
}
