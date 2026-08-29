import 'dart:ui';

import 'color_slot.dart';

/// Resolves a rig's semantic colour slots to real colours.
class VizPalette {
  const VizPalette({
    required this.id,
    required this.label,
    required this.colors,
  });

  final String id;
  final String label;
  final Map<ColorSlot, Color> colors;

  Color of(ColorSlot slot) => colors[slot] ?? const Color(0xff000000);
}
