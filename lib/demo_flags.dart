import 'package:flutter/foundation.dart' show kDebugMode;

/// Whether the PIN-gated demo shortcuts are compiled in.
///
/// They are always present in debug. A release build strips them by default —
/// you do not want a stranger finding a "fill everything in" button in a
/// finance app. For the hackathon web build we want them on stage, so the
/// build opts in explicitly:
///
///   flutter build web --release --dart-define=DEMO_TOOLS=true
///
/// Even then every shortcut sits behind [DevGate]'s PIN, so someone poking at
/// the deployed site cannot skip their own answers by accident.
const bool kDemoTools =
    bool.fromEnvironment('DEMO_TOOLS', defaultValue: kDebugMode);
