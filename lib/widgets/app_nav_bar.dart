import 'package:flutter/material.dart';

/// The persistent bottom navigation shared by the four main tabs:
/// Forest, Calendar, Home, and Awards.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.selectedIndex,
    required this.onShowForest,
    required this.onShowCalendar,
    required this.onShowHomestead,
    required this.onShowAchievements,
  });

  final int selectedIndex;
  final VoidCallback onShowForest;
  final VoidCallback onShowCalendar;
  final VoidCallback onShowHomestead;
  final VoidCallback onShowAchievements;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            onShowForest();
            break;
          case 1:
            onShowCalendar();
            break;
          case 2:
            onShowHomestead();
            break;
          case 3:
            onShowAchievements();
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.park_outlined),
          selectedIcon: Icon(Icons.park),
          label: 'Forest',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Calendar',
        ),
        NavigationDestination(
          icon: Icon(Icons.cottage_outlined),
          selectedIcon: Icon(Icons.cottage),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.emoji_events_outlined),
          selectedIcon: Icon(Icons.emoji_events),
          label: 'Awards',
        ),
      ],
    );
  }
}
