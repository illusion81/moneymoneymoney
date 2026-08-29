# Sprite Assets Spec

## Problem

The app draws every subject as a coloured labelled box (`PlaceholderBoxPainter`).
Two real asset packs are now available on disk and should replace those boxes:

- `~/Documents/animals/25 Micro Pixel Art Animals/` — 25 pixel-art animal
  sprites, PNG, **32×32 RGBA with alpha**, front-facing seated chibi style.
- `~/Documents/market-itch/` — two SVG sheets of finance/market icons. The
  useful one is `vector_twenty_price_96dpi.svg`: **30 white-fill/black-outline
  icons** laid out on a solid `#414D9B` field (4 rows of 6 / 7 / 9 / 8).

## Goal

Vendor both packs into the repo, expose them through a small typed API, and
have `ActorField` draw real sprites instead of boxes — keeping the existing
squash-stretch and wander motion untouched.

## Constraints

- **No new package dependencies.** In particular `flutter_svg` is out of scope;
  the SVG sheet is rasterised offline into transparent PNGs by a checked-in
  tool, so the app only ever loads PNG.
- `pubspec.yaml` changes are limited to adding a `flutter: assets:` section.
  (Previous plans in this repo said "pubspec.yaml must not change"; that rule
  was about package dependencies and is relaxed here for asset registration.)
- Pixel art must never be smoothed: every draw uses `FilterQuality.none` and
  `isAntiAlias = false`.
- Draw-only. No new interaction surfaces.

## Assets in scope

### Animals — 25, verbatim copies

`bear cat chiken cow crocodile dog elephant fox frog giraffe goat gorilla
hippo lion monkey moose mouse panda penguin pig rabbit snake tiger turtle
zebra`

Filenames are the ids (note the pack's own spelling, `chiken.png`). All are
32×32; the pack contains **no raccoon, deer, or hummingbird**, so those three
placeholder actors lose their box and are dropped from the animal catalog.

### Market icons — 30, extracted offline

Segmentation is deterministic: key out the `#414D9B` field, then split by
horizontal/vertical projection gaps. Verified stable for gap thresholds 2–12,
yielding 6 / 7 / 9 / 8 icons per row. Reading order (left→right, top→bottom):

| # | name | # | name | # | name |
|---|------|---|------|---|------|
| 00 | `badge_rosette` | 10 | `banner_ribbon_flat` | 20 | `tag_tall_round` |
| 01 | `bank` | 11 | `sparkle_six` | 21 | `padlock` |
| 02 | `stamp` | 12 | `sparkle_eight` | 22 | `tag_hanging` |
| 03 | `coin` | 13 | `cross_badge` | 23 | `envelope` |
| 04 | `tag_framed` | 14 | `cross_badge_notched` | 24 | `card` |
| 05 | `tag_rounded` | 15 | `cross_badge_bevel` | 25 | `ticket` |
| 06 | `note_dashed` | 16 | `seal_capsule` | 26 | `ticket_wide` |
| 07 | `note_dashed_wide` | 17 | `seal_ellipse` | 27 | `ticket_alt` |
| 08 | `banner_ribbon` | 18 | `ribbon_zigzag` | 28 | `note_cash` |
| 09 | `banner_ribbon_wide` | 19 | `tag_tall` | 29 | `vault` |

Icons are rasterised from the SVG at 2400px sheet width, so each is roughly
82–258px on its longest side — ample for a 48dp UI icon at 3× density.

### Semantic aliases

The app refers to icons by role, not by sheet position:

| role | icon |
|------|------|
| `coin` | `coin` |
| `xp` | `sparkle_eight` |
| `streak` | `sparkle_six` |
| `achievement` | `badge_rosette` |
| `wallet` | `bank` |
| `receipt` | `note_cash` |
| `egg` | `seal_capsule` |
| `lockedSkin` | `padlock` |
| `lootbox` | `ticket` |
| `vault` | `vault` |

`egg` is a stand-in: the pack has no egg, and `seal_capsule` is the closest
rounded silhouette.

## Motion

The animal sprites are **single-frame and front-facing**, so a walk or run
cycle cannot be built from this pack. Motion stays exactly what it is today:
volume-preserving squash-and-stretch plus seeded wander. `WanderMotion` and
`squashStretch` are unchanged; only the painter swaps.

Sprites are drawn bottom-centre anchored, matching the box painter, so a
squash still reads as weight on the ground.

## Test strategy

Empirically verified against Flutter 3.41.1 before this spec was written:

- `rootBundle.load` **does** serve registered assets under `flutter test`.
- `AssetImage.resolve` never completes under a plain `pumpAndSettle`; decoding
  requires `tester.runAsync()`. Asset-loading tests must use it.
- A synthetic `ui.Image` from `PictureRecorder().endRecording().toImage()`
  resolves **without** `runAsync`, so painter tests stay fast and synchronous.
- `paints..drawImageRect(image:, source:, destination:)` asserts draw geometry.
  It has **no** `filterQuality` argument, so filtering must be asserted through
  a pure `Paint`-building helper rather than through the paint matcher.

## Out of scope

- Animating the sprites (no frames exist).
- Recolouring animals per skin (deferred to the skins task).
- The unused `twentyprice_96dpi.svg`, which is a marketing preview card.
