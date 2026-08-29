import 'package:flutter/material.dart';

import '../theme/hive_colors.dart';

/// Market screen stub — the real Market UI is built by later tasks.
class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HiveColors.light.canvas,
      body: const Center(child: Text('Market')),
    );
  }
}
