import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/hive_colors.dart';

/// A pill-style segmented control (design.md §6).
///
/// surfaceSunk `#F1EADB` track r12 p4 gap6; 30 dp segments r9. The active
/// segment is white with ink 11.5/700 text; inactive segments are transparent
/// with 45% ink text.
class SegmentedControl extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  /// Segment labels, left to right.
  final List<String> options;

  /// Index of the currently selected segment.
  final int selectedIndex;

  /// Called with the tapped segment index.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: HiveColors.light.surfaceSunk, // #F1EADB
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: _segment(context, i)),
          ],
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, int index) {
    final bool selected = index == selectedIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(index),
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? HiveColors.light.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          options[index],
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            // Inactive label is 45% ink (design.md §6).
            color: selected ? HiveColors.light.ink : const Color(0x7333251A),
          ),
        ),
      ),
    );
  }
}
