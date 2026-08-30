# Hivewise — Build Plan

Goal: high-fidelity Flutter frontend prototype of the Hivewise bee-themed finance app, in this repo, with mocked state (no backend/bank/LLM). Old `lib/`/`docs/` deleted by the user; old `test/` and `assets/` are stale and will be cleared.

**Spec:** `design.md` (root) — authoritative for tokens, type, spacing, shadows, hexagon geometry, primitives, motion. Per-screen layout in the handoff `README.md` at `/home/jostev/Projects/Hivewise financial app design/design_handoff_hivewise/README.md`.

**Stack:** `flutter_riverpod` (state) · `go_router` (nav) · `google_fonts` (Caveat / Plus Jakarta Sans / JetBrains Mono) · `flutter_animate` (motion helper). No image assets, no icon fonts — everything CustomPainter/shape-drawn.

## Tasks (sequential; each agent reads design.md first)

1. **Foundation & theme** — pubspec deps, clear stale `test/` + `assets/`, `pub get`, `lib/theme/*` (HiveColors extension, shadows, ThemeData/ColorScheme/TextTheme), `lib/core/hexagon.dart`, placeholder `lib/main.dart`.
2. **Primitives & painters** — `lib/widgets/primitives/*`: honeycomb, honey jar, bee swarm, breathing hive, market art tile, tab-bar icons, jar glyph, sparkline, progress bar, toggle, segmented control (+ motion scaffolding).
3. **State, data, router, shell** — `lib/models/*`, `lib/data/*` (mock catalog/badges/members/tasks), `lib/state/hive_state.dart` (Notifier per design.md state model), `lib/router.dart` (StatefulShellRoute + sheet modal), `lib/widgets/hive_tab_bar.dart`, real `lib/main.dart`.
4. **Hive home + DetailSheet** — `lib/screens/hive_screen.dart`, `lib/screens/detail_sheet.dart`.
5. **Report + Market** — `lib/screens/report_screen.dart`, `lib/screens/market_screen.dart`.
6. **Comb + Hive-mates + Settings** — `lib/screens/comb_screen.dart`, `mates_screen.dart`, `settings_screen.dart`.

## Rules

- Agents do **not** commit; they write code + run `flutter analyze` and report. Orchestrator verifies (analyze + tests) and commits at checkpoints.
- Agents must not touch `backend,dataAPI/`, `android/`, `ios/`, `web/`, platform dirs, or `.git`.
- Every color/font/spacing/shadow must reference `design.md` tokens, not raw invented values.
