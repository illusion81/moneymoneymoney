import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/hive_theme.dart';

void main() => runApp(const ProviderScope(child: HivewiseApp()));

/// Minimal placeholder app — replaced once the real screens land.
class HivewiseApp extends StatelessWidget {
  const HivewiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildHiveTheme(),
      home: const Scaffold(
        body: Center(child: Text('Hivewise')),
      ),
    );
  }
}
