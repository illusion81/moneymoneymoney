import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/hive_theme.dart';

void main() => runApp(const ProviderScope(child: TallyHiveApp()));

/// Root widget: wires the TallyHive theme and router into a MaterialApp.
class TallyHiveApp extends ConsumerWidget {
  const TallyHiveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      theme: buildHiveTheme(),
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
      title: 'TallyHive',
    );
  }
}
