# Viz Layer & Animal Rigs Design

## Goal

Build a pure-visual layer (`lib/viz/`) for the Wealth Forest app and use it to
replace the app's main screen with a **viz workbench**: a chooseable gallery of
animals (and the central tree) that loop simple breathe / walk / run
animations. The workbench exists so each creature's *look* can be refined one at
a time, reviewed, and signed off before the app's real screens consume it.

## Scope

In scope:

- A rig/paint foundation for procedural, code-authored creatures.
- Four animal rigs, built and reviewed one-by-one: **Fox, Deer, Hummingbird,
  Raccoon**.
- The central **Wealth Tree** as a viz object with four growth stages.
- A workbench screen that becomes the app's boot screen while art is in flight.

Out of scope (belongs to the collectables project — see
`docs/superpowers/collectables/spec.md`):

- XP, coins, skins, lootbox eggs, wallets, beta credit.
- Any change to `ReportGenerator`, `ForestEngine`, or the questionnaire.
- Persistence of any kind.

## Core Constraint: `lib/viz/` Has No Interactions

Everything under `lib/viz/` is **draw-only**. A viz object:

- Never handles a gesture, tap, drag, or focus.
- Never mutates app state, and never reads it — it is given what to draw.
- Never navigates.
- Never talks to a service.

The one widget that mounts a viz object (`VizStage`) wraps its subtree in
`IgnorePointer`, so this is enforced structurally rather than by convention.
All interaction lives in the workbench screen (`lib/viz/workbench/`), which is a
screen, not a viz object.

## Core Constraint: Separate Gameobjects

Each creature is one file, one class, self-contained: its own parts, its own
default palette, its own pose functions. Adding or refining an animal touches
exactly one file plus one line in the catalog. No animal knows another exists.

## Rendering Approach

Creatures are **procedural CustomPainter rigs**, not `.riv` files and not sprite
sheets. Rationale: a look revision must be a reviewable text diff that an agent
can make, and there is no artist in the loop. Binary art formats fail both
tests.

A rig is a flat list of `RigPart`s. Each part carries:

- A `Path` authored in **part-local space** with the part's pivot at `(0, 0)`.
- A `pivot` offset — in the parent's space when the part has a parent, otherwise
  in rig space.
- An optional `parent` part id, giving a transform hierarchy (a head can carry
  its own eyes and ears).
- A `ColorSlot` — a *semantic* colour name (`primary`, `secondary`, `belly`,
  `accent`, `eye`, `outline`), never a literal colour. This is what makes skins
  possible later: a skin is a `ColorSlot -> Color` map swapped at paint time.
- A `z` for draw order. **`z` is independent of the parent hierarchy** — an ear
  can be a child of the head but draw behind it. Every `z` in a rig must be
  unique, because `List.sort` in Dart is not stable.

Animation is a pure function `poseAt(clip, t) -> Map<partId, PartPose>` where
`t` is the normalized loop phase in `[0, 1)`. Because poses are pure functions
of phase, they are unit-testable with no rendering and no golden files.

**Every pose expression must be periodic over `t` in `[0, 1)`.** Use
`sin(2*pi*k*t)` with integer `k`. A term like `sin(pi*t)` does not close the
loop and will visibly pop.

## Clips

Three clips, universal across every rig:

| Clip | Loop period @ 1.0x | Meaning |
| --- | --- | --- |
| `breathe` | 3200 ms | Idle. Torso swell, small head bob, occasional ear/wing twitch. |
| `walk` | 900 ms | Steady locomotion. |
| `run` | 520 ms | Fast locomotion. |

A rig declares `supportedClips`. Non-locomoting creatures reinterpret rather
than omit: the hummingbird's `walk` is a hovering flit and its `run` is a
forward dart, so the workbench's clip control stays uniform. The tree supports
`breathe` only (a sway), and the workbench disables the other two for it.

## Testing Approach

**No golden files.** Goldens are binary, platform-sensitive, and would have to
be regenerated on every single look tweak — which is the exact operation this
project is optimized for. They would become pure noise.

Instead, two deterministic layers:

1. **Pose math tests.** `poseAt` is pure. Assert amplitudes, phase
   relationships (a walking quadruped's near foreleg is pi out of phase with its
   near hind leg), and — for every clip of every rig — that the pose at `t = 0`
   equals the pose at `t` approaching 1, proving the loop closes.
2. **Recording-canvas tests.** A hand-rolled `RecordingCanvas implements Canvas`
   captures `drawPath` calls. Assert the part count, the z-order, that every
   colour drawn came from the palette, and that a part actually moves between
   two phases.

Plus one widget smoke test per screen change.

## Screens

### Viz Workbench Screen

Becomes the app's boot screen while `kVizMode` is `true`.

- **Subject picker**: chips for Fox, Deer, Hummingbird, Raccoon, and the four
  tree stages. Selecting one swaps the rig.
- **Stage**: a large `VizStage` rendering the selected rig on a neutral ground,
  looping the selected clip.
- **Clip picker**: Breathe / Walk / Run, with unsupported clips disabled.
- **Speed slider**: 0.25x to 2.0x, for inspecting motion frame by frame.
- **Pivot overlay toggle**: draws each part's pivot as a dot, for rig debugging.

The existing onboarding -> report -> home -> achievements flow is not deleted.
`MyApp` takes a `vizMode` flag defaulting to `kVizMode`; the existing widget
tests construct `MyApp(vizMode: false)` and keep passing unchanged in substance.

## Visual Direction

Flat vector shapes with no gradients and no strokes — fills only, in the app's
existing calm palette family (green, gold, ink, warm neutrals). Creatures read
as friendly and slightly stylized, side-on, facing right. Legibility at 96 px
tall matters more than detail at 400 px.

## Build Order

Foundation, then Fox as the exemplar that sets the art bar, then the workbench
so everything after it can be reviewed visually the moment it lands, then Deer,
Hummingbird, Raccoon, then the tree. Each creature is a separate reviewable
deliverable.

## Future Extension Points

- Skins swap `VizPalette` per rig (collectables project).
- Additional clips (`eat`, `sleep`, `celebrate`) slot into `VizClip` without
  touching the painter.
- A rig's parts could later be authored in a data file rather than Dart.
