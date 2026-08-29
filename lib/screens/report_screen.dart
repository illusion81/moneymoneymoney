import 'package:flutter/material.dart';

import '../theme/hive_colors.dart';

/// Report screen stub — the real Report UI is built by later tasks.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HiveColors.light.canvas,
      body: const Center(child: Text('Report')),
    );
  }
}
