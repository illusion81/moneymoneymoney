import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/services/home_layout_service.dart';

void main() {
  final service = HomeLayoutService();

  group('HomeLayoutService', () {
    test('initialState starts with no placements', () {
      final state = service.initialState();

      expect(state.placements, isEmpty);
    });

    test('place adds a new placement with the given fractional position', () {
      final state = service.initialState();

      final result = service.place(
        state: state,
        itemId: 'deco-garden-lantern',
        dx: 0.4,
        dy: 0.6,
      );

      expect(result.placements, hasLength(1));
      expect(result.placements.single.itemId, 'deco-garden-lantern');
      expect(result.placements.single.dx, 0.4);
      expect(result.placements.single.dy, 0.6);
    });

    test('place clamps dx and dy to the [0, 1] range', () {
      final state = service.initialState();

      final result = service.place(
        state: state,
        itemId: 'deco-garden-lantern',
        dx: -0.2,
        dy: 1.5,
      );

      expect(result.placements.single.dx, 0.0);
      expect(result.placements.single.dy, 1.0);
    });

    test('placing an already-placed item replaces its position instead of duplicating it', () {
      var state = service.initialState();
      state = service.place(
        state: state,
        itemId: 'deco-garden-lantern',
        dx: 0.1,
        dy: 0.1,
      );

      final result = service.place(
        state: state,
        itemId: 'deco-garden-lantern',
        dx: 0.9,
        dy: 0.8,
      );

      expect(result.placements, hasLength(1));
      expect(result.placements.single.dx, 0.9);
      expect(result.placements.single.dy, 0.8);
    });

    test('remove drops the placement for the given item', () {
      var state = service.initialState();
      state = service.place(
        state: state,
        itemId: 'deco-garden-lantern',
        dx: 0.1,
        dy: 0.1,
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
