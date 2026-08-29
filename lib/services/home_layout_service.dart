import '../models/home_layout.dart';

class HomeLayoutService {
  HomeLayoutState initialState() => const HomeLayoutState(placements: []);

  /// Places [itemId] at ([dx], [dy]), clamped to [0, 1]. If the item is
  /// already placed, its position is replaced rather than duplicated.
  HomeLayoutState place({
    required HomeLayoutState state,
    required String itemId,
    required double dx,
    required double dy,
  }) {
    final remaining = state.placements
        .where((placement) => placement.itemId != itemId)
        .toList();
    remaining.add(
      DecorationPlacement(
        itemId: itemId,
        dx: dx.clamp(0.0, 1.0),
        dy: dy.clamp(0.0, 1.0),
      ),
    );
    return HomeLayoutState(placements: remaining);
  }

  HomeLayoutState remove({required HomeLayoutState state, required String itemId}) {
    return HomeLayoutState(
      placements: state.placements
          .where((placement) => placement.itemId != itemId)
          .toList(),
    );
  }
}
