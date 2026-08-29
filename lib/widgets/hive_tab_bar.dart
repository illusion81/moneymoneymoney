import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/hive_colors.dart';
import '../theme/hive_shadows.dart';
import 'primitives/tab_bar_icons.dart';

/// The fixed bottom tab bar (design.md §4.5): a blurred canvas @ 92% sheet
/// with a lift shadow and five equal-flex items (Hive, Report, Market, Comb,
/// Mates).
class HiveTabBar extends StatelessWidget {
  const HiveTabBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// Index of the active tab (matches `StatefulNavigationShell.currentIndex`).
  final int selectedIndex;

  /// Called with the tapped tab's index.
  final ValueChanged<int> onSelected;

  static const List<HiveTabIcon> _icons = <HiveTabIcon>[
    HiveTabIcon.hive,
    HiveTabIcon.report,
    HiveTabIcon.market,
    HiveTabIcon.comb,
    HiveTabIcon.mates,
  ];

  static const List<String> _labels = <String>[
    'Hive',
    'Report',
    'Market',
    'Comb',
    'Mates',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 26),
      decoration: const BoxDecoration(
        color: Color(0xEBFBF7EF),
        boxShadow: HiveShadows.tabBar,
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < _icons.length; i++)
                Expanded(
                  child: _TabBarItem(
                    icon: _icons[i],
                    label: _labels[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarItem extends StatelessWidget {
  const _TabBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final HiveTabIcon icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor =
        selected ? const Color(0xFFE08C1B) : const Color(0x3333251A);
    final Color labelColor =
        selected ? HiveColors.light.ink : const Color(0x6633251A);

    return InkWell(
      onTap: onTap,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            HiveTabIconView(icon: icon, color: iconColor, size: 20),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
