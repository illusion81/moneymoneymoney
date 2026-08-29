import 'package:flutter/material.dart';

import '../theme/hive_colors.dart';

/// Comb screen stub — the real Comb UI is built by later tasks.
class CombScreen extends StatelessWidget {
  const CombScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HiveColors.light.canvas,
      body: const Center(child: Text('Comb')),
    );
  }
}
