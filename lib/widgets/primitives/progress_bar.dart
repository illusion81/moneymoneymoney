import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/hive_colors.dart';

/// A fully-rounded progress track with a fully-rounded fill (design.md §4.1, §6).
///
/// The track is [track] (surfaceSunk by default) and the fill is [fill]
/// (honey by default). When [gradient] is true the fill is a 90° honey
/// gradient `#F5B322→#E08C1B` instead of a flat colour. [value] is clamped
/// to 0..1.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.fill,
    this.track,
    this.height = 8,
    this.gradient = false,
  });

  /// Progress in the range 0..1 (clamped).
  final double value;

  /// Fill colour; defaults to honey when [gradient] is false.
  final Color? fill;

  /// Track colour; null means surfaceSunk `#F1EADB` (design.md §6).
  final Color? track;

  /// Bar height; also drives the fully-rounded corner radius (height/2).
  final double height;

  /// When true, the fill uses the 90° honey gradient `#F5B322→#E08C1B`.
  final bool gradient;

  /// The 90° honey gradient fill. (Not `const` — `HiveColors` tokens are
  /// instance fields and so are only available at runtime.)
  static final LinearGradient _honeyGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[
      HiveColors.light.honey, // #F5B322
      HiveColors.light.honeyDeep, // #E08C1B
    ],
  );

  @override
  Widget build(BuildContext context) {
    final double v = value.clamp(0.0, 1.0);
    final double radius = height / 2;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double fillWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth * v
            : 0;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: track ?? HiveColors.light.surfaceSunk,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: fillWidth,
              height: height,
              decoration: BoxDecoration(
                color: gradient ? null : (fill ?? HiveColors.light.honey),
                gradient: gradient ? _honeyGradient : null,
                borderRadius: BorderRadius.circular(
                  math.min(radius, fillWidth / 2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
