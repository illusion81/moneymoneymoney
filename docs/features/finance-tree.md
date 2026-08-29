# Finance Tree

## What it does

Shows the procedural pixel finance tree driven by the user's real finances. The
tree's shape — trunk height, trunk thickness, branching density, and foliage —
comes from four financial pillars derived from the finance profile
(profitability, liquidity, solvency, efficiency). Whether the tree is lush or
withered comes from two independent signals combined into one.

## The two health signals

The app already had two competing ideas of "tree health", and both survive:

| Signal | Owner | Meaning |
| --- | --- | --- |
| Check-in health | `ForestEngine` | Daily check-ins. A missed or over-budget day withers the tree; a run of healthy days builds a streak. |
| Finance vigour | `FinancePillars` | The finance profile. A profile whose income is swallowed by expenses scores low on the pillars and renders withered. |

`ForestEngine` remains the sole authority on check-in-driven health, streaks,
and withering. `FinancePillars` remains the sole source of the tree's shape and
vigour. Neither is modified.

## How they combine

`FinanceTreeViewModel` (pure, no dependencies) takes a `FinanceProfile` and a
`ForestSummary` and produces a `FinanceTreeState`:

- `pillars` — the shape/vigour, straight from `FinancePillars.fromProfile`.
  Check-in health never changes these.
- `withered` — the only meeting point. It is true when the pillars are withered
  **or** the latest check-in withered. The signals are OR-ed, never blended, so
  one cannot mask the other.
- `streak` / `checkInStatus` — pass-throughs of the check-in signal, for any
  readout that wants them.

A missed check-in withers the canopy (no leaves, brown palette) but does not
shrink the trunk, so the finance-profile shape stays visible through the
withering.

## Public API

- `FinanceTreeState` and `FinanceTreeViewModel` in `lib/tree/finance_tree_view_model.dart`.
- `FinanceTree` in `lib/tree/finance_tree.dart` — the drop-in widget. Give it a
  profile and a summary and it renders the combined tree:

  ```
  FinanceTree(profile: profile, summary: summary)
  ```

  It accepts an optional `seed` (stability), `height`, and `growDuration`.
- `FinanceTreeView` gained an optional `withered` override and
  `TreeGenerator.generate` gained `witheredOverride`, so a caller can force the
  withered state on top of otherwise-healthy pillars without losing the shape.

## Where it plugs in

`HomeScreen` gained an optional `financeProfile` parameter. When it is set, the
tree card renders a `FinanceTree` instead of the legacy status icon; when null
(the current default), the icon fallback is unchanged. To light it up for a real
user, the orchestrator wires `main.dart`:

- Store the `FinanceProfile` submitted in `_handleProfileSubmitted` (it is
  currently consumed and dropped).
- Pass `financeProfile: _profile` into the `HomeScreen` constructor in the
  `AppView.forest` case.

No navigation was added; the tree is just a widget in the existing home screen.

## Deliberately left out

- Wiring in `main.dart` (orchestrator-owned file).
- A per-user seed. The tree defaults to seed 1, so all users currently get the
  same shape for the same pillars. A stable per-user seed can be threaded in via
  `FinanceTree.seed` once the orchestrator has a user id.
- Any readout of the four pillars or the streak on the home screen — the tree
  itself is the only visualisation for now.

## Testing

`test/tree/finance_tree_view_model_test.dart` covers the combining logic,
including a healthy case and a withered case driven by each signal.
`test/tree/finance_tree_widget_test.dart` verifies the `FinanceTree` widget
renders and that a check-in wither overrides a healthy profile.
