import '../models/home_layout.dart';

class HomeLayoutService {
  HomeLayoutState initialState() => const HomeLayoutState(placements: []);

  /// Places [itemId] at ([row], [col]), clamped to the grid bounds. If the
  /// item is already placed, its cell is replaced rather than duplicated.
  HomeLayoutState place({
    required HomeLayoutState state,
    required String itemId,
    required int row,
    required int col,
  }) {
    final remaining = state.placements
        .where((placement) => placement.itemId != itemId)
        .toList();
    remaining.add(
      DecorationPlacement(
        itemId: itemId,
        row: row.clamp(0, kHomeGridSize - 1),
        col: col.clamp(0, kHomeGridSize - 1),
      ),
    );
    return HomeLayoutState(placements: remaining);
  }

  HomeLayoutState remove({
    required HomeLayoutState state,
    required String itemId,
  }) {
    return HomeLayoutState(
      placements: state.placements
          .where((placement) => placement.itemId != itemId)
          .toList(),
    );
  }
}
