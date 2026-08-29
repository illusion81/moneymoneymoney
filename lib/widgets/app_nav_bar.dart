import 'package:flutter/material.dart';

/// The persistent bottom navigation shared by the five main tabs:
/// Forest, Spending, Calendar, Home, and Investment.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.selectedIndex,
    required this.onShowForest,
    required this.onShowSpending,
    required this.onShowCalendar,
    required this.onShowHomestead,
    required this.onShowInvestment,
  });

  final int selectedIndex;
  final VoidCallback onShowForest;
  final VoidCallback onShowSpending;
  final VoidCallback onShowCalendar;
  final VoidCallback onShowHomestead;
  final VoidCallback onShowInvestment;

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
          case 4:
            onShowInvestment();
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
        NavigationDestination(
          icon: Icon(Icons.trending_up_outlined),
          selectedIcon: Icon(Icons.trending_up),
          label: 'Investment',
        ),
      ],
    );
  }
}
