# Placeholder Actors Design

## Goal

Replace every piece of in-game art with a **coloured labelled box** so the app's
mechanics can be built and reviewed now, with real assets dropped in later. The
boxes are not static: animals squash, stretch, and wander, so motion quality can
be judged before any art exists.

## Scope

In scope:

- One placeholder primitive: a tinted rounded rect with a centred text label.
- Volume-preserving squash-and-stretch driven by a normalized phase.
- Seeded wander motion for animals — deterministic, testable, non-looping.
- A field widget that hosts several wandering actors at once.
- A catalog of the placeholder actors the app needs (animals, coin, egg, XP orb).

Out of scope:

- Real art of any kind. This spec exists precisely to defer that.
- Deleting the existing `lib/viz/` rig layer. Fox, Deer and Hummingbird rigs are
  committed, green, and cost nothing to keep; the workbench can still show them.
  The app's own screens use placeholders.
- Interaction. Actors are draw-only, exactly like the rig layer.

## Why Not Reuse `VizRig`

A `VizRig` is a hierarchy of `Path` parts with per-part poses. A placeholder is
one box and one string. Forcing it through the rig contract would mean inventing
a path for a rectangle and a `ColorSlot` for a label, and would still not give us
text — `RigPainter` draws paths, not glyphs. `PlaceholderActor` is its own small
type that shares the layer's rules (draw-only, pure motion functions) without
sharing its geometry machinery.

## The Placeholder Primitive

```
PlaceholderActor
  id        stable key, e.g. 'fox'
  label     the text drawn in the box, e.g. 'FOX'
  color     box fill
  size      design-space size before squash/stretch
  kind      animal | item      (animals wander, items hold station)
```

Rendered as a filled rounded rect with the label centred in a contrasting
colour. Label text is drawn with `TextPainter`, laid out once per paint.

## Squash And Stretch

The animation principle, applied honestly: **a squashed shape must preserve
volume**, or it reads as a rubber blob rather than a solid object under force.

For a scale factor `k`:

```
scaleY = k
scaleX = 1 / k
```

so `scaleX * scaleY == 1` at every phase. `k > 1` is a stretch (tall, narrow),
`k < 1` is a squash (short, wide).

Animals use `k = 1 + amplitude * sin(2*pi*t)`, so they breathe between squash and
stretch. The amplitude is small (0.06–0.12); large values look comical.

Items (coin, egg, XP orb) use a gentler pulse at half amplitude.

## Wander Motion

Animals drift around their field. Requirements that rule out the obvious
approaches:

- `Random()` sampled per frame is untestable and jitters rather than drifts.
- A sum of sines with integer frequencies is testable but **loops**, and a
  visible repeat is exactly what "random movement" must not do.

So: **seeded 1-D value noise**. A hash function maps `(seed, latticeIndex)` to a
value in [0, 1); positions between lattice points are smoothstep-interpolated.
The result is a pure function of `(seed, t)` — deterministic, unit-testable,
and non-repeating over any practical run.

```
noise1(seed, t):
  i = floor(t)
  f = t - i
  a = hash01(seed, i)
  b = hash01(seed, i + 1)
  return lerp(a, b, f * f * (3 - 2 * f))     // smoothstep
```

An actor's position is two noise channels on different seed offsets, mapped into
the field's bounds with an inset margin so boxes never clip the edge. Its
horizontal facing follows the sign of its x velocity, approximated by sampling
the noise slightly ahead.

Wander speed is slow — the noise input is `t / wanderPeriod`, with
`wanderPeriod` around 6–10 seconds per lattice step.

## Catalog

| id | label | kind | tint |
| --- | --- | --- | --- |
| `fox` | FOX | animal | orange |
| `deer` | DEER | animal | tan |
| `hummingbird` | HUMMER | animal | teal |
| `raccoon` | RACOON | animal | grey |
| `coin` | COIN | item | gold |
| `egg` | EGG | item | cream |
| `xp_orb` | XP | item | blue |

`raccoon` appears here even though its rig was never built — a placeholder costs
one table row, and it keeps the skin catalog's four-animal roster intact.

## Testing Requirements

- Volume preservation: `scaleX * scaleY` is 1.0 (within 1e-9) at many phases.
- Squash and stretch both occur: `scaleY` goes above and below 1 across a cycle.
- `noise1` is deterministic: same `(seed, t)` gives the same value, always.
- `noise1` is continuous: no jump greater than a small bound between adjacent
  samples (this is what makes it drift rather than teleport).
- Different seeds give different paths.
- Wander positions stay inside the field bounds at every sampled time.
- The catalog has unique ids and a label for every entry.
- A widget test that the field renders one box per actor and ignores pointers.

## Future Extension Points

- Swap `PlaceholderBoxPainter` for a real sprite/asset painter; nothing else
  needs to change.
- Per-actor wander parameters (some animals skittish, some slow).
- Skins recolour the box tint, so the collectables economy works against
  placeholders unchanged.
