import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/hive_colors.dart';

/// A row of flex-1 bars, radius 2, each coloured from [barColors] (design.md §6).
///
/// Bar heights are proportional to [values], normalised so the largest value
/// fills [height]. [barColors] should hold one colour per bar; missing colours
/// fall back to the last supplied colour (honey if none).
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.barColors,
    this.height = 30,
  });

  /// One value per bar (non-negative; bars are normalised to the max).
  final List<double> values;

  /// One colour per bar.
  final List<Color> barColors;

  /// Full-height of the tallest bar.
  final double height;

  Color _colorFor(int index) {
    if (barColors.isEmpty) {
      return HiveColors.light.honey;
    }
    return barColors[index < barColors.length ? index : barColors.length - 1];
  }

  @override
  Widget build(BuildContext context) {
    final double maxValue = values.isEmpty
        ? 1
        : values.reduce(math.max);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (int i = 0; i < values.length; i++)
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: maxValue <= 0
                      ? 0
                      : (math.max(0, values[i]) / maxValue) * height,
                  decoration: BoxDecoration(
                    color: _colorFor(i),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
