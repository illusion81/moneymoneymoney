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
// We ship Hivewise. Its Settings screen now routes to the two screens that
// talk to the backend — connect-bank / statement upload, and live spending —
// so the design shell and the real data path are in the same build. The
// Forest app stays in the repo and its tests still run against it.
//
// To ship Forest instead, replace the two lines below with:
//   import 'legacy_app.dart' as forest;
//   void main() => forest.runLegacyApp();
import 'hivewise_app.dart' as hivewise;

void main() => hivewise.runHivewiseApp();
