import 'package:flutter/material.dart';

import '../state/hive_state.dart';
import '../theme/hive_colors.dart';

/// Shared detail sheet stub — the real §4.6 composition is built by later
/// tasks.
class DetailSheet extends StatelessWidget {
  const DetailSheet({super.key, required this.kind});

  final SheetKind kind;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HiveColors.light.canvas,
      body: Center(child: Text(kind.name)),
    );
  }
}
