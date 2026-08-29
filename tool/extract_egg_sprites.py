#!/usr/bin/env python3
"""Slice the egg sprite sheet into one transparent horizontal strip per clip.

The sheet is a strict 32x32 grid on a solid #669966 field, holding four colour
variants in quadrants. Each quadrant repeats the same five rows:

    row 0  a single resting egg          ->  idle,   1 frame
    row 1  rocking back and forth        ->  rock,   4 frames
    row 2  bouncing                      ->  bounce, 3 frames
    row 3  the bounce row played twice   ->  skipped, it is byte-identical
    row 4  cracking and hatching         ->  hatch, 12 frames

Frames keep their position inside the cell, because the rock and bounce clips
animate by moving the egg within the frame. Never re-centre them.

The pack ships as `~/Documents/animals/Egg.zip`. Unzip it somewhere, then run
from the repo root:

    unzip -d /tmp/egg "$HOME/Documents/animals/Egg.zip"
    python3 tool/extract_egg_sprites.py \
        --sheet "/tmp/egg/Egg/egg sprite sheet.png" \
        --out assets/eggs

Requires Pillow and numpy. Developer tooling only; the app loads the strips.
"""

import argparse
import os
import sys

import numpy as np
from PIL import Image

CELL = 32
BACKGROUND = np.array([102, 153, 102])  # #669966
COLOUR_DISTANCE = 60

# Quadrant origins in grid cells, keyed by the variant's colour.
VARIANTS = {
    "cream": (0, 0),
    "brown": (0, 13),
    "purple": (6, 0),
    "grey": (6, 13),
}

# Row offset inside a quadrant -> clip name and frame count. Row 3 is omitted
# on purpose: it is the bounce row concatenated with itself.
CLIPS = [
    (0, "idle", 1),
    (1, "rock", 4),
    (2, "bounce", 3),
    (4, "hatch", 12),
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sheet", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    sheet = Image.open(os.path.expanduser(args.sheet)).convert("RGBA")
    pixels = np.array(sheet).astype(int)
    ink = np.abs(pixels[:, :, :3] - BACKGROUND).sum(2) > COLOUR_DISTANCE

    keyed = np.array(sheet).copy()
    keyed[..., 3] = np.where(ink, 255, 0)
    keyed_image = Image.fromarray(keyed)

    os.makedirs(args.out, exist_ok=True)
    written = 0
    for variant, (row0, col0) in VARIANTS.items():
        for row_offset, clip, frames in CLIPS:
            row = row0 + row_offset
            strip = Image.new("RGBA", (CELL * frames, CELL), (0, 0, 0, 0))
            for frame in range(frames):
                col = col0 + frame
                box = (col * CELL, row * CELL, (col + 1) * CELL, (row + 1) * CELL)
                cell = keyed_image.crop(box)
                if not cell.getbbox():
                    sys.exit(
                        f"{variant}/{clip} frame {frame} is empty at grid "
                        f"({row}, {col}); the sheet layout changed"
                    )
                strip.paste(cell, (frame * CELL, 0))
            strip.save(os.path.join(args.out, f"{variant}_{clip}.png"))
            written += 1

    print(f"wrote {written} strips to {args.out}")


if __name__ == "__main__":
    main()
