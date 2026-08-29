import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/hive_theme.dart';

void main() => runApp(const ProviderScope(child: HivewiseApp()));

/// Root widget: wires the Hivewise theme and router into a MaterialApp.
class HivewiseApp extends ConsumerWidget {
  const HivewiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      theme: buildHiveTheme(),
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
      title: 'Hivewise',
    );
  }
}
