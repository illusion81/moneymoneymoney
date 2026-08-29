import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/home_layout.dart';
import 'package:moneymoneymoney/services/home_layout_service.dart';

void main() {
  final service = HomeLayoutService();

  group('HomeLayoutService', () {
    test('initialState starts with no placements', () {
      final state = service.initialState();

      expect(state.placements, isEmpty);
    });

    test('place adds a new placement at the given grid cell', () {
      final state = service.initialState();

      final result = service.place(
        state: state,
        itemId: 'deco-garden-lantern',
        row: 2,
        col: 3,
      );

      expect(result.placements, hasLength(1));
      expect(result.placements.single.itemId, 'deco-garden-lantern');
      expect(result.placements.single.row, 2);
      expect(result.placements.single.col, 3);
    });

    test('place clamps row and col to the grid bounds', () {
      final state = service.initialState();

      final result = service.place(
        state: state,
        itemId: 'deco-garden-lantern',
        row: -2,
        col: 99,
      );

      expect(result.placements.single.row, 0);
      expect(result.placements.single.col, kHomeGridSize - 1);
    });

    test('placing an already-placed item moves it instead of duplicating it', () {
      var state = service.initialState();
      state = service.place(
        state: state,
        itemId: 'deco-garden-lantern',
        row: 0,
        col: 0,
      );

      final result = service.place(
        state: state,
        itemId: 'deco-garden-lantern',
        row: 5,
        col: 4,
      );

      expect(result.placements, hasLength(1));
      expect(result.placements.single.row, 5);
      expect(result.placements.single.col, 4);
    });

    test('remove drops the placement for the given item', () {
      var state = service.initialState();
      state = service.place(
        state: state,
        itemId: 'deco-garden-lantern',
        row: 0,
        col: 0,
      );

      final result = service.remove(state: state, itemId: 'deco-garden-lantern');

      expect(result.placements, isEmpty);
    });

    test('remove is a no-op for an item that is not placed', () {
      final state = service.initialState();

      final result = service.remove(state: state, itemId: 'unknown-item');

      expect(result.placements, isEmpty);
    });
  });
}
