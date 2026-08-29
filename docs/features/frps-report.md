# FRPS Deep Financial Report

The on-demand deep report, built on top of the FRPS module in `lib/frps/`.

## What it does

`ReportScreen` (`lib/screens/report_screen.dart`) already shows a *quick*
post-onboarding report from `ReportGenerator`. This feature adds a separate,
richer report that runs the FRPS planner — the six financial tools, the
adaptive question data in SQLite, and the slot SLM narrative — over the same
user, on demand.

The screen:

1. Optionally seeds the on-device `FinanceProfile` into the FRPS store, so the
   report always reflects the latest answers.
2. Runs `ReportPlanner.generateReport`, which assembles and persists a
   four-section report.
3. Renders the result readably: the SLM narrative up front, the structured tool
   outputs as cards, and the assembled sections as a written report.

It never touches `ReportGenerator` or `report_screen.dart` — the two reports
are complementary, not competing.

## Public API

| Symbol | File | Role |
| --- | --- | --- |
| `FrpsReportScreen` | `lib/screens/frps_report_screen.dart` | The screen. Public widget, navigation-free. |
| `FrpsReportController` | `lib/frps_ui/frps_report_controller.dart` | Runs the planner, returns a `FrpsReportOutcome`. |
| `FrpsReportView` | `lib/frps_ui/frps_report_view.dart` | Pure rendering of a finished report. |
| `FrpsReportData` | `lib/frps_ui/frps_report_controller.dart` | Report + tool outputs + narrative. |
| `FrpsProfileBridge` | `lib/frps_ui/frps_profile_bridge.dart` | Maps `FinanceProfile` into FRPS `User`/`FinancialSnapshot`. |

### `FrpsReportScreen`

```
FrpsReportScreen({
  required FrpsRepository repository,
  required String userId,
  FinanceProfile? seedProfile,
  SlmInterface? slm,          // defaults to SlotSlm
  VoidCallback? onBack,       // hides the back button when null
})
```

### `FrpsReportController.generate`

```
Future<FrpsReportOutcome> generate({
  required String userId,
  FinanceProfile? seedProfile,
})
```

Returns a `FrpsReportOutcome` whose `status` is one of `loading`, `loaded`,
`empty`, or `error`. Missing user or snapshot maps to `empty`; any planner
failure maps to `error`; zero/partial input still produces a `loaded` outcome
(the tools return zeros rather than throwing).

## Where it plugs in

The orchestrator owns navigation. To route to it, build a `FrpsReportScreen`
and give it:

- a `FrpsRepository` (a `SqliteStore` instance the orchestrator already holds),
- the app's user id (`'user-1'`, matching `main.dart`),
- the on-device `FinanceProfile` as `seedProfile`, and
- an `onBack` callback returning to the previous view.

For example, alongside the existing `AppView` entries in `main.dart`:

```
FrpsReportScreen(
  repository: frpsStore,
  userId: 'user-1',
  seedProfile: profile,
  onBack: () => setState(() => _view = AppView.report),
)
```

## Degradation and storage notes

- **Empty**: no user or no snapshot in the repository renders a "Nothing to
  report yet" panel with a retry button, never an exception.
- **Partial**: zero income, empty expense/asset maps, or no debts still render
  a valid report (the tools are total over empty maps and no-op on empty debt
  lists).
- **Storage**: `SqliteStore` is the real backing store. `ReportPlanner` needs
  `sqflite`, which requires the `sqflite_common_ffi` shim under `flutter test`;
  it is already a dev dependency. The screen and controller tests avoid a real
  database entirely by injecting an in-memory `FakeFrpsRepository`.

## Deliberately left out

- **Navigation**: exposed and documented here; the orchestrator wires the
  route.
- **Richer financial detail**: the on-device `FinanceProfile` only carries
  income, fixed expenses and a savings goal, so `FrpsProfileBridge` produces a
  minimal snapshot (one expense category, no assets/liabilities). Categorised
  expenses, real asset/liability values and debt come from the FRPS question
  flow and bank data, which write the same repository from other lanes.
- **No new dependencies, art, or assets**: the screen reuses the existing
  `MarketIcon` pixel art.
