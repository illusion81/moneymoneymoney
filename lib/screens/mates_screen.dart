import 'package:flutter/material.dart';

import '../theme/hive_colors.dart';

/// Hive-mates screen stub — the real Mates UI is built by later tasks.
class MatesScreen extends StatelessWidget {
  const MatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HiveColors.light.canvas,
      body: const Center(child: Text('Mates')),
    );
  }
}
