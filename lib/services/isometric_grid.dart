import 'dart:ui';

/// 2:1 isometric projection for a square grid of diamond tiles.
///
/// Cell (0, 0)'s center sits at the local origin (0, 0) — the topmost point
/// of the whole diamond board. Positive [col] moves right+down; positive
/// [row] moves left+down, matching standard isometric tile projection.
class IsoGridGeometry {
  const IsoGridGeometry({required this.tileWidth, required this.tileHeight});

  final double tileWidth;
  final double tileHeight;

  Offset cellCenter({required int row, required int col}) {
    return Offset(
      (col - row) * (tileWidth / 2),
      (col + row) * (tileHeight / 2),
    );
  }

  /// The four corners of the diamond tile for (row, col), in
  /// top/right/bottom/left order.
  List<Offset> tileCorners({required int row, required int col}) {
    final center = cellCenter(row: row, col: col);
    return [
      center + Offset(0, -tileHeight / 2),
      center + Offset(tileWidth / 2, 0),
      center + Offset(0, tileHeight / 2),
      center + Offset(-tileWidth / 2, 0),
    ];
  }

  /// Total width spanned by a [gridSize] x [gridSize] board.
  double boardWidth(int gridSize) => gridSize * tileWidth;

  /// Total height spanned by a [gridSize] x [gridSize] board.
  double boardHeight(int gridSize) => gridSize * tileHeight;
}
