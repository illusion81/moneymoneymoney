import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/category_breakdown.dart';
import '../services/money_format.dart';

/// Categorical palette, assigned in fixed slot order and never cycled.
///
/// These are the validated default data-viz hues (light mode). The order is
/// deliberate: adjacent slots keep enough separation to stay distinguishable
/// under colour-vision deficiency. Because several slots fall below 3:1
/// contrast against a white surface, every wedge is also directly labelled in
/// the legend — colour is never the only encoding.
const List<Color> kCategoryPalette = [
  Color(0xff2a78d6), // blue
  Color(0xffeb6834), // orange
  Color(0xff1baf7a), // aqua
  Color(0xffeda100), // yellow
  Color(0xffe87ba4), // magenta
  Color(0xff008300), // green
  Color(0xff4a3aa7), // violet
  Color(0xffe34948), // red
];

/// The colour for slot [index]; the folded "Other" wedge always renders
/// neutral grey so it never reads as a real category.
Color categoryColor(int index, {bool isOther = false}) {
  if (isOther) {
    return const Color(0xff8b8b85);
  }
  return kCategoryPalette[index % kCategoryPalette.length];
}

/// A donut of spending by category, with a directly-labelled legend.
class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    super.key,
    required this.slices,
    required this.total,
  });

  final List<CategorySlice> slices;
  final double total;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('No spending in this period.')),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Side-by-side when there's room, stacked on a narrow window.
        final wide = constraints.maxWidth >= 520;
        final donut = SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                key: const Key('category-pie-canvas'),
                size: const Size(180, 180),
                painter: _DonutPainter(slices: slices),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatMoney(total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text('spent', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        );

        final legend = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < slices.length; i++)
              _LegendRow(
                slice: slices[i],
                color: categoryColor(i, isOther: slices[i].isOther),
              ),
          ],
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              donut,
              const SizedBox(width: 24),
              Expanded(child: legend),
            ],
          );
        }
        return Column(children: [donut, const SizedBox(height: 16), legend]);
      },
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.slice, required this.color});

  final CategorySlice slice;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(slice.label)),
          Text(
            formatMoney(slice.amount),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(
            width: 46,
            child: Text(
              '${(slice.share * 100).round()}%',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.slices});

  final List<CategorySlice> slices;

  /// A 2px surface-coloured gap between wedges, so neighbouring colours
  /// never touch and read as one block.
  static const double _gapRadians = 0.02;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2;
    final strokeWidth = outerRadius * 0.38;
    final radius = outerRadius - strokeWidth / 2;

    var startAngle = -math.pi / 2; // 12 o'clock
    for (var i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweep = slice.share * 2 * math.pi;
      // A lone 100% wedge has no neighbour to separate from.
      final gap = slices.length == 1 ? 0.0 : _gapRadians;
      final drawnSweep = math.max(sweep - gap, 0.001);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + gap / 2,
        drawnSweep,
        false,
        Paint()
          ..color = categoryColor(i, isOther: slice.isOther)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.slices != slices;
}
