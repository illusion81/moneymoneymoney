import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/services/isometric_grid.dart';

void main() {
  const geometry = IsoGridGeometry(tileWidth: 60, tileHeight: 30);

  group('IsoGridGeometry.cellCenter', () {
    test('cell (0, 0) sits at the topmost point of the diamond', () {
      final center = geometry.cellCenter(row: 0, col: 0);

      expect(center.dx, 0);
      expect(center.dy, 0);
    });

    test('moving one column right shifts right and down by half a tile', () {
      final center = geometry.cellCenter(row: 0, col: 1);

      expect(center.dx, 30); // tileWidth / 2
      expect(center.dy, 15); // tileHeight / 2
    });

    test('moving one row down shifts left and down by half a tile', () {
      final center = geometry.cellCenter(row: 1, col: 0);

      expect(center.dx, -30);
      expect(center.dy, 15);
    });
  });

  group('IsoGridGeometry.tileCorners', () {
    test('returns the four corners of the diamond centered on the cell', () {
      final corners = geometry.tileCorners(row: 0, col: 0);

      expect(corners, hasLength(4));
      // top, right, bottom, left of a diamond centered at (0, 0).
      expect(corners[0].dx, 0);
      expect(corners[0].dy, -15);
      expect(corners[1].dx, 30);
      expect(corners[1].dy, 0);
      expect(corners[2].dx, 0);
      expect(corners[2].dy, 15);
      expect(corners[3].dx, -30);
      expect(corners[3].dy, 0);
    });
  });

  group('IsoGridGeometry bounds', () {
    test('boardWidth spans the full diamond for a given grid size', () {
      expect(geometry.boardWidth(6), 6 * 60);
    });

    test('boardHeight spans the full diamond for a given grid size', () {
      expect(geometry.boardHeight(6), 6 * 30);
    });
  });
}
