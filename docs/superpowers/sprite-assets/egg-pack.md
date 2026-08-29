# Egg sprite pack

## `assets/eggs/` — animated egg sprites

Art & animation by **VIERGACHT** (credit required; it appears on the source
sheet).

## Source

`~/Documents/animals/Egg.zip`, which contains three files:

| file | contents |
|------|----------|
| `egg sprite sheet.png` | the master sheet, **828×468** |
| `egg-hatching.gif` | the hatch animation, **17 frames**, 32×32 |
| `egg-sprite-sheet-GIF.gif` | the sheet re-exported as a (single-frame) GIF |

## Sheet layout

The sheet is a strict 32×32 grid on a solid `#669966` background, holding four
colour variants in quadrants:

| | |
|---|---|
| cream — top-left | brown — top-right |
| purple — bottom-left | grey — bottom-right |

Each quadrant repeats the same five rows:

| row | content | clip |
|-----|---------|------|
| 0 | a single resting egg | `idle`, 1 frame |
| 1 | rocking back and forth | `rock`, 4 frames |
| 2 | bouncing | `bounce`, 3 frames |
| 3 | the bounce row played twice | skipped |
| 4 | cracking and hatching | `hatch`, 12 frames |

Row 3 is skipped on purpose: it is byte-identical to row 2 concatenated with
itself.

Frames keep their position inside the cell, because the rock and bounce clips
animate by moving the egg within the frame. The slicer never re-centres them.

## Slicing

The pack ships only the sliced transparent PNG strips. No GIF and no sheet is
vendored into the app; the app loads the strips at runtime.

Re-run the slicer from the repo root after replacing the zip:

    unzip -d /tmp/egg "$HOME/Documents/animals/Egg.zip"
    python3 tool/extract_egg_sprites.py \
        --sheet "/tmp/egg/Egg/egg sprite sheet.png" \
        --out assets/eggs

The tool keys out the `#669966` field, crops one transparent strip per clip,
and exits non-zero if any frame comes out empty — which means the sheet layout
changed. Requires Pillow and numpy; developer tooling only.

## Clips

| clip | frames | loops | notes |
|------|--------|-------|-------|
| `idle` | 1 | yes | a still egg (a one-frame strip) |
| `rock` | 4 | yes | rocks back and forth |
| `bounce` | 3 | yes | hops in place |
| `hatch` | 12 | **no** | cracks open, plays once and holds the last frame |

Playback runs at the sheet's own 15/100s per frame (`EggSprites.fps = 6.7`), so
the 12-frame hatch runs for ~1.8s.

## API

`EggSprites` in `lib/sprites/egg_sprites.dart` maps `EggVariant × EggClip` to a
`SpriteStrip`: `EggSprites.strip(EggVariant.cream, EggClip.rock)` is the rock
clip, `EggSprites.path(...)` the raw asset path, `EggSprites.allPaths` the
preload list. The field plays the rock clip; the egg screens play the hatch.