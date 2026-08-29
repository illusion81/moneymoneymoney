# Sprite modules

## Why this branch exists

Our art and simulation work grew on a branch that had diverged from `main` by
48 commits. A trial merge conflicted in exactly three files — `lib/main.dart`,
`test/widget_test.dart` and `.gitignore` — all of them *wiring*. Every module
itself merged cleanly, because the modules only add new directories.

So this branch carries the modules and nothing else. It is cut from `main` and
touches no upstream file except two additive config lines. Screen wiring is
deliberately left out; it belongs on a separate integration branch, where a
conflict is cheap to resolve because it is the only thing in the diff.

## What is here

| Module | Responsibility |
|--------|----------------|
| `lib/sprites/` | Asset paths, image decode cache, the unfiltered pixel-art draw path, sprite strips, egg clips |
| `lib/placeholder/` | Squash-stretch and seeded wander motion; the actor catalog and the field that hosts actors |
| `lib/tree/` | Four finance pillars, procedural tree generation, pixel rasterisation, the tree view |
| `lib/collect/` | Wallet and XP models, including the beta credit grant |
| `lib/ui/` | `MarketIcon` — market-sheet icons named by role |
| `assets/` | 25 animals, 30 market icons, 16 egg strips |
| `tool/` | The two offline slicers that derive icons and eggs from their source sheets |

## Isolation rules

These are what keep the branch conflict-free. Breaking one costs a merge
conflict later.

- A module may import other modules and `lib/models/`. Nothing else.
- No module imports from `lib/screens/`, `lib/services/`, `lib/data/` or
  `lib/widgets/`.
- Nothing here modifies an upstream file. The only exceptions are the
  `flutter: assets:` block and one `.gitignore` line, both pure additions.
- No new package dependencies.

`lib/tree/` has the single outward dependency, on `models/finance_profile.dart`,
which is byte-identical to ours upstream.

## Deliberately excluded

- **`lib/viz/`** — the procedural `CustomPainter` animal rigs and their
  workbench screen. Superseded by the real sprite packs, and the workbench
  needs a `main.dart` boot hook, which is exactly the wiring this branch
  avoids. Still on `feat/viz-collectables` if it is ever wanted.
- **`lib/app_mode.dart`** — the workbench boot flag, orphaned by the above.
- Everything upstream owns: `main.dart`, the screens, services, data layer and
  the widget test.

## What comes next

The integration branch wires modules into the isometric homestead:

- `lib/services/item_visuals.dart` currently maps shop items to Material
  `IconData`. Our market icons and animal sprites are the real art for it.
- `IsoGridGeometry` already gives tile centres and corners, which is the
  placement math isometric roaming needs — the wander motion currently moves
  actors in screen space and would move in grid space instead.
- The egg hatch clip is a one-shot that holds its last frame, ready for a
  lootbox flow.

## Provenance and credits

Per-pack provenance, licensing notes and re-slicing commands live in
`docs/superpowers/sprite-assets/`. The egg pack is credited to **VIERGACHT**.
