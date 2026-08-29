import 'package:flutter/material.dart';

import '../theme/hive_colors.dart';

/// Settings screen stub — the real Settings UI is built by later tasks.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HiveColors.light.canvas,
      body: const Center(child: Text('Settings')),
    );
  }
}
