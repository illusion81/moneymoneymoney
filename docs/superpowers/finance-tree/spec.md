# Finance Tree Design

## Goal

A central, procedurally generated, **pixelated** tree that grows in on screen and
whose shape is driven by the user's finances, expressed as the four classic
pillars of financial analysis: **profitability, liquidity, solvency,
efficiency**.

## Reference

Modelled on `julienduranleau-sandbox/procedural-2d-tree` (recursive branching in
p5.js). Its algorithm, from source:

- A `Branch` holds `drawStart`, `angle`, `lineWeight`, `length`, `recurseLevel`.
- It draws in ten increments (`progress += 0.1`), each step advancing
  `cos(angle + jitter) * length * 0.1` horizontally and `sin(angle) * length * 0.1`
  vertically, with the jitter widening at deeper levels.
- Past `progress > 0.35` it may spawn a branch on any step (coin flip).
- On completion it spawns a burst: `2 + rand(0..3)` branches at shallow levels,
  `rand(0..8)` at level ≥ 2.
- Recursion stops at `recurseLevel >= 4`.
- Per level: `angleChange = pi*0.3 + pi*0.2*level`, `length *= 0.7 - 0.15*level`,
  `lineWeight *= 0.5`.
- At `recurseLevel >= 3` it switches to leaf colouring with a random stroke
  weight, tinted by screen position.

## Two Deliberate Departures

**1. Generate first, animate second.** The reference mutates branch state inside
`draw()`, so the structure only exists as a side effect of rendering. Here a pure
generator returns the complete `List<TreeSegment>` up front, each segment
stamped with a `growthAt` in [0, 1]. Rendering reveals every segment whose
`growthAt <= progress`. This makes the whole tree unit-testable with no canvas,
makes growth deterministic, and lets the same tree be re-rendered at any
progress without regenerating.

**2. Pixelated rasterisation.** Segments are not stroked as lines. Each is walked
in steps and quantised onto a fixed cell grid; every touched cell is emitted once
(deduped through a `Set`) and drawn as a filled square. Overlapping branches
therefore never double-draw, and the result reads as pixel art rather than
vector line work.

## The Four Pillars

```
FinancePillars
  profitability   0..1
  liquidity       0..1
  solvency        0..1
  efficiency      0..1
```

Derived from the existing `FinanceProfile`. The formulas are deliberately rough —
the spec's own instruction is that vague numbers are fine for now — but each is
directionally the real ratio it is named after:

| Pillar | Formula | Reading |
| --- | --- | --- |
| profitability | `(income - fixedExpenses) / income` | operating margin |
| liquidity | `monthlyFlexible / (0.30 * income)` | buffer against a 30% target |
| solvency | `1 - (fixedExpenses / income)` | how unleveraged the month is |
| efficiency | `savingsGoal / (income - fixedExpenses)` | savings rate on disposable |

Every result is clamped to [0, 1]. Income of zero yields all zeros rather than a
division by zero.

## Pillar To Tree Mapping

| Pillar | Drives | Low | High |
| --- | --- | --- | --- |
| profitability | trunk length | stunted | tall |
| solvency | trunk thickness | spindly | sturdy |
| efficiency | branches per node, angle discipline | sprawling, few | dense, orderly |
| liquidity | leaf density and colour | sparse, pale | lush, vivid |

Concretely:

```
trunkLength  = 60 + 90 * profitability
trunkWeight  = 3 + 9 * solvency
maxDepth     = efficiency >= 0.5 ? 4 : 3
branchBurst  = 2 + floor(3 * efficiency)
angleSpread  = 0.55 - 0.20 * efficiency        // radians, before per-level widening
leafChance   = 0.25 + 0.65 * liquidity
```

**Health gate.** When the mean of the four pillars is below 0.25 the tree renders
withered: the brown/grey palette, and leaves suppressed entirely. This reuses the
app's existing healthy/withered vocabulary from the forest engine.

## Determinism

Generation takes an injected `Random`. The same seed and the same pillars always
produce the same tree, so a user's tree is stable across rebuilds rather than
reshuffling on every frame or navigation. The service never constructs its own
`Random`.

## Growth Animation

`growthAt` is assigned during generation: a branch occupying the time window
`[start, start + duration]` gives its `i`-th of ten segments a `growthAt` of
`start + (i + 1) / 10 * duration`. A child spawned partway along its parent
starts at the parent's time for that step; a child in the completion burst
starts at the parent's end. All values are normalized to [0, 1] once generation
finishes, so progress always spans the whole tree regardless of depth.

## Testing Requirements

- Each pillar formula at representative and boundary inputs, including zero
  income and expenses exceeding income.
- Pillars always land within [0, 1].
- Generation with a fixed seed is reproducible segment-for-segment.
- Higher profitability yields a taller tree; higher solvency a thicker trunk;
  higher efficiency more segments; higher liquidity more leaf segments.
- Recursion never exceeds `maxDepth`.
- Every `growthAt` is within [0, 1], the first segment starts at approximately 0,
  and some segment reaches 1.
- Progress monotonicity: the count of revealed segments never decreases as
  progress rises.
- The withered gate fires below the health threshold and suppresses leaves.
- Pixel quantisation emits no duplicate cells for overlapping segments.
- A widget test that the tree renders and ignores pointer events.

## Future Extension Points

- Seasonal palettes; fruit for milestone achievements.
- Per-pillar visual callouts ("your liquidity is why the leaves are sparse").
- Replace the placeholder pillar formulas with real accounting ratios once the
  app tracks actual transactions.
