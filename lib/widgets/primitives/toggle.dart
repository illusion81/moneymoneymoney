import 'package:flutter/material.dart';

import '../../theme/hive_colors.dart';
import '../../theme/hive_shadows.dart';

/// A 44×26 rounded toggle switch (design.md §6).
///
/// Track is honey when on, `#E2DAC9` when off; the Ø20 white knob slides on a
/// 200 ms ease curve and carries [HiveShadows.toggleKnob].
class Toggle extends StatelessWidget {
  const Toggle({super.key, required this.value, required this.onChanged});

  /// Whether the toggle is on.
  final bool value;

  /// Called with the new (toggled) value when tapped.
  final ValueChanged<bool> onChanged;

  static const Duration _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.ease,
          width: 44,
          height: 26,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? HiveColors.light.honey : const Color(0xFFE2DAC9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: AnimatedAlign(
            duration: _duration,
            curve: Curves.ease,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: HiveColors.light.surface,
                shape: BoxShape.circle,
                boxShadow: HiveShadows.toggleKnob,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
