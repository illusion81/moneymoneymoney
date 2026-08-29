import 'package:flutter/material.dart';

import '../../theme/hive_colors.dart';

/// The tiny honey-jar glyph used in pills and price buttons (design.md §4.4, §6).
///
/// Authored at 13×15: lid 8×3 r2 `#7A5230`, body gradient `#FFD972→#E8A11B`
/// with radius 3 3 6 6. Pass [width]/[height] to scale it for other call sites
/// (e.g. the 10×12 invite-pill jar).
class JarGlyph extends StatelessWidget {
  const JarGlyph({super.key, this.width = 13, this.height = 15});

  /// Total glyph width (13 at the authored size).
  final double width;

  /// Total glyph height (15 at the authored size).
  final double height;

  @override
  Widget build(BuildContext context) {
    // Lid occupies 8/13 of the width and 3/15 of the height (design.md §4.4);
    // the body fills the remaining width and height beneath it.
    final double lidWidth = width * (8 / 13);
    final double lidHeight = height * (3 / 15);
    final double bodyHeight = height - lidHeight;
    final double radiusScale = width / 13;

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: lidWidth,
            height: lidHeight,
            decoration: BoxDecoration(
              // #7A5230 — brownDeep alternate (jar rim/body stroke, design.md §1.1).
              color: const Color(0xFF7A5230),
              borderRadius: BorderRadius.circular(2 * radiusScale),
            ),
          ),
          Container(
            width: width,
            height: bodyHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  HiveColors.light.honeyLight, // #FFD972
                  const Color(0xFFE8A11B), // honeyDeep alternate (income-cell bottom)
                ],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(3 * radiusScale),
                bottom: Radius.circular(6 * radiusScale),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
