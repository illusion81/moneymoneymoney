import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/hexagon.dart';

/// The unified home hive (design.md §6 "HoneycombView"): a procedural
/// income/expense hexagon tessellation (design.md §5) painted by a single
/// [CustomPainter], with tappable cells routed to income/expense sheets via
/// [onCellTap].
///
/// Rows fill greedily: the first row holds 3 cells, then rows alternate 4 and
/// 3 until [totalCells] are placed. Rows are centre-aligned horizontally, and
/// every row after the first is shifted up by [rowOverlap] so rows interlock.
/// A cell is *income* iff its horizontal centre in cell-units across the
/// widest row — `(widestRow - rowCount) / 2 + colIndex + 0.5` — is less than
/// `(incomeCells / totalCells) * widestRow` (a left/right split, never
/// top/bottom). Income cells use a 158° `#FFD972 → #E8A11B` gradient; expense
/// cells a 158° `#8B6039 → #553519` gradient. No ghost/dimmed cells and no
/// text inside cells.
class HoneycombView extends StatelessWidget {
  const HoneycombView({
    super.key,
    required this.incomeCells,
    required this.totalCells,
    required this.cellWidth,
    required this.cellHeight,
    required this.onCellTap,
    this.gap = 1,
    this.rowOverlap = 15,
  });

  /// Count of income cells (painted with the honey gradient).
  final int incomeCells;

  /// Total cell count; cells fill greedily from the first row.
  final int totalCells;

  /// Cell box width (52 at the authored home-hive size, design.md §5).
  final double cellWidth;

  /// Cell box height (58 at the authored home-hive size, design.md §5).
  final double cellHeight;

  /// Invoked with `true` when an income cell is tapped and `false` when an
  /// expense cell is tapped.
  final void Function(bool isIncome) onCellTap;

  /// Horizontal gap between cells within a row (1 px at the authored size).
  final double gap;

  /// Vertical overlap between consecutive rows (15 px at the authored size):
  /// every row after the first is shifted up by this amount.
  final double rowOverlap;

  @override
  Widget build(BuildContext context) {
    if (totalCells <= 0) {
      return const SizedBox.shrink();
    }
    final _HoneycombLayout layout = _HoneycombLayout(
      incomeCells: incomeCells,
      totalCells: totalCells,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      gap: gap,
      rowOverlap: rowOverlap,
    );
    return GestureDetector(
      // A bare CustomPaint does not hit-test itself (its painter's default
      // hitTest returns null), so treat the whole hive canvas as opaque.
      behavior: HitTestBehavior.opaque,
      onTapUp: (TapUpDetails details) {
        final _HoneycombCell? cell = layout.cellAt(details.localPosition);
        if (cell != null) {
          onCellTap(cell.isIncome);
        }
      },
      child: SizedBox(
        width: layout.canvasSize.width,
        height: layout.canvasSize.height,
        child: CustomPaint(painter: _HoneycombPainter(layout.cells)),
      ),
    );
  }
}

/// One placed hexagon cell.
class _HoneycombCell {
  const _HoneycombCell({required this.rect, required this.isIncome});

  /// The cell's box in canvas coordinates.
  final Rect rect;

  /// Whether this cell is an income (honey) cell.
  final bool isIncome;
}

/// Computes the greedy 3-4-3-2… tessellation once so the painter and the tap
/// handler share identical cell rects.
class _HoneycombLayout {
  _HoneycombLayout({
    required int incomeCells,
    required int totalCells,
    required double cellWidth,
    required double cellHeight,
    required double gap,
    required double rowOverlap,
  }) {
    // Row capacities: the first row holds 3, then rows alternate 4 and 3
    // (design.md §5); the final row may be partially filled.
    final List<int> rows = <int>[];
    int remaining = totalCells;
    int rowIndex = 0;
    while (remaining > 0) {
      final int capacity = rowIndex == 0 || rowIndex.isEven ? 3 : 4;
      final int count = remaining < capacity ? remaining : capacity;
      rows.add(count);
      remaining -= count;
      rowIndex += 1;
    }

    final int widestRow = rows.reduce((int a, int b) => a > b ? a : b);
    final double widestWidth = widestRow * cellWidth + (widestRow - 1) * gap;
    final double rowStep = cellHeight - rowOverlap;
    final double totalHeight = (rows.length - 1) * rowStep + cellHeight;
    // Income threshold in cell-units across the widest row (design.md §5).
    final double incomeThreshold = (incomeCells / totalCells) * widestRow;

    final List<_HoneycombCell> result = <_HoneycombCell>[];
    for (int i = 0; i < rows.length; i++) {
      final int rowCount = rows[i];
      final double rowWidth = rowCount * cellWidth + (rowCount - 1) * gap;
      final double xStart = (widestWidth - rowWidth) / 2;
      final double yTop = i * rowStep;
      for (int colIndex = 0; colIndex < rowCount; colIndex++) {
        // Horizontal centre in cell-units across the widest row: rows are
        // centre-aligned, cells are one cell-unit wide, and 0.5 lands on the
        // centre of each cell.
        final double centre = (widestRow - rowCount) / 2 + colIndex + 0.5;
        result.add(_HoneycombCell(
          rect: Rect.fromLTWH(
            xStart + colIndex * (cellWidth + gap),
            yTop,
            cellWidth,
            cellHeight,
          ),
          isIncome: centre < incomeThreshold,
        ));
      }
    }

    cells = result;
    canvasSize = Size(widestWidth, totalHeight);
  }

  /// All cells in paint order (row-major).
  late final List<_HoneycombCell> cells;

  /// The canvas needed to draw every cell.
  late final Size canvasSize;

  /// The topmost cell under [position], or `null` if the point is not inside
  /// any cell's hexagon.
  ///
  /// Rows interlock — each row paints over the bottom edge of the row above
  /// it — so cells are tested in reverse paint order and the point must lie
  /// inside the hexagon itself, not merely its bounding box.
  _HoneycombCell? cellAt(Offset position) {
    for (int i = cells.length - 1; i >= 0; i--) {
      final _HoneycombCell cell = cells[i];
      if (!cell.rect.contains(position)) {
        continue;
      }
      if (_hexPath(cell.rect).contains(position)) {
        return cell;
      }
    }
    return null;
  }
}

/// Pointy-top hexagon path for [rect], from [HexPointyClipper] (design.md §5)
/// shifted into canvas coordinates.
Path _hexPath(Rect rect) {
  return const HexPointyClipper().getClip(rect.size).shift(rect.topLeft);
}

/// Gradient travel direction for the 158° cell fills (design.md §5): CSS
/// gradient angles are measured clockwise from 12 o'clock in screen space, so
/// a 158° gradient travels toward `(sin 158°, -cos 158°)` — down-right. The
/// lighter "top" colour starts at the begin alignment, the darker "bottom"
/// colour ends at the end alignment.
final double _gradientDx = math.sin(158 * math.pi / 180); // ≈ 0.375
final double _gradientDy = -math.cos(158 * math.pi / 180); // ≈ 0.927
final Alignment _gradientBegin = Alignment(-_gradientDx, -_gradientDy);
final Alignment _gradientEnd = Alignment(_gradientDx, _gradientDy);

/// Paints every cell once per frame (design.md §6: a single CustomPainter is
/// cheaper than a Column/Row of ClipPaths).
class _HoneycombPainter extends CustomPainter {
  _HoneycombPainter(this.cells);

  final List<_HoneycombCell> cells;

  @override
  void paint(Canvas canvas, Size size) {
    for (final _HoneycombCell cell in cells) {
      final Paint fill = Paint()
        ..shader = LinearGradient(
          begin: _gradientBegin,
          end: _gradientEnd,
          colors: cell.isIncome
              ? const <Color>[Color(0xFFFFD972), Color(0xFFE8A11B)]
              : const <Color>[Color(0xFF8B6039), Color(0xFF553519)],
        ).createShader(cell.rect);
      canvas.drawPath(_hexPath(cell.rect), fill);
    }
  }

  @override
  bool shouldRepaint(covariant _HoneycombPainter oldDelegate) {
    return oldDelegate.cells != cells;
  }
}