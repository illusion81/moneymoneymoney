// Entry point.
//
// Two apps live in this repo right now:
//
//   * legacy_app.dart — Wealth Forest. Talks to the backend: statement upload,
//     spending, plan, goals, circle, streaks. This is what we demo.
//   * The Hivewise UI (router.dart + screens/hive_screen.dart and friends) —
//     John's visual direction, merged by Alan. Beautiful, and currently
//     rendering from static data: none of its six screens call ApiClient.
//
// The deployed app has to be the one that can read a real bank statement, so
// this boots Wealth Forest. Hivewise ships from `alanbranch` as its own site
// (see hivewise-web in render.yaml) so the design work is still shown and can
// keep moving independently.
//
// To boot Hivewise here instead, swap the import and runApp for:
//   import 'package:flutter_riverpod/flutter_riverpod.dart';
//   import 'router.dart';
//   import 'theme/hive_theme.dart';
//   void main() => runApp(const ProviderScope(child: HivewiseApp()));
import 'legacy_app.dart' as forest;

void main() => forest.runLegacyApp();
