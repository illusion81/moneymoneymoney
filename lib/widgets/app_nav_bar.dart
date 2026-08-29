import 'package:flutter/material.dart';

/// The persistent bottom navigation shared by the four main tabs:
/// Forest, Spending, Calendar, and Home.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.selectedIndex,
    required this.onShowForest,
    required this.onShowSpending,
    required this.onShowCalendar,
    required this.onShowHomestead,
  });

  final int selectedIndex;
  final VoidCallback onShowForest;
  final VoidCallback onShowSpending;
  final VoidCallback onShowCalendar;
  final VoidCallback onShowHomestead;

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
            onShowSpending();
            break;
          case 2:
            onShowCalendar();
            break;
          case 3:
            onShowHomestead();
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
          icon: Icon(Icons.pie_chart_outline),
          selectedIcon: Icon(Icons.pie_chart),
          label: 'Spending',
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
      ],
    );
  }
}
