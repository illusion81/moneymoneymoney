import 'package:flutter/material.dart';

import '../theme/hive_colors.dart';

/// Home screen stub — the real Hive UI is built by later tasks.
class HiveScreen extends StatelessWidget {
  const HiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HiveColors.light.canvas,
      body: const Center(child: Text('Hive')),
    );
  }
}
