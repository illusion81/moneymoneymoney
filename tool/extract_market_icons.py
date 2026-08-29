#!/usr/bin/env python3
"""Rasterise the market SVG sheet into one transparent PNG per icon.

The source sheet draws 30 white-fill/black-outline icons on a solid #414D9B
field with no groups and no usable element ids, so icons are located by keying
out the background and splitting on projection gaps. The segmentation is stable
for gap thresholds between 2 and 12 px at the render width used here.

Run from the repo root:

    python3 tool/extract_market_icons.py \
        --svg ~/Documents/market-itch/vector_twenty_price_96dpi.svg \
        --out assets/icons

Requires `rsvg-convert` on PATH plus Pillow and numpy. These are developer
tools only; the app itself never reads the SVG.
"""

import argparse
import os
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image

# Reading order: left to right, top to bottom. Rows hold 6, 7, 9 and 8 icons.
ICON_NAMES = [
    "badge_rosette", "bank", "stamp", "coin", "tag_framed", "tag_rounded",
    "note_dashed", "note_dashed_wide", "banner_ribbon", "banner_ribbon_wide",
    "banner_ribbon_flat", "sparkle_six", "sparkle_eight",
    "cross_badge", "cross_badge_notched", "cross_badge_bevel", "seal_capsule",
    "seal_ellipse", "ribbon_zigzag", "tag_tall", "tag_tall_round", "padlock",
    "tag_hanging", "envelope", "card", "ticket", "ticket_wide", "ticket_alt",
    "note_cash", "vault",
]

BACKGROUND = np.array([65, 77, 155])  # #414D9B
COLOUR_DISTANCE = 90                  # sum of per-channel deltas
GAP = 6                               # blank px that separate two icons
RENDER_WIDTH = 2400


def runs(mask, gap):
    """Start/end indices of True stretches separated by more than `gap`."""
    out, start, last = [], None, None
    for i, value in enumerate(mask):
        if value:
            if start is None:
                start = i
            last = i
        elif start is not None and i - last > gap:
            out.append((start, last + 1))
            start = None
    if start is not None:
        out.append((start, last + 1))
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--svg", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    with tempfile.TemporaryDirectory() as tmp:
        sheet_path = os.path.join(tmp, "sheet.png")
        subprocess.run(
            ["rsvg-convert", "-w", str(RENDER_WIDTH),
             os.path.expanduser(args.svg), "-o", sheet_path],
            check=True,
        )
        sheet = Image.open(sheet_path).convert("RGBA")

    pixels = np.array(sheet).astype(int)
    ink = (np.abs(pixels[:, :, :3] - BACKGROUND).sum(2) > COLOUR_DISTANCE) & (
        pixels[:, :, 3] > 8
    )

    keyed = np.array(sheet).copy()
    keyed[..., 3] = np.where(ink, 255, 0)
    keyed_image = Image.fromarray(keyed)

    boxes = []
    for y0, y1 in runs(ink.any(1), GAP):
        for x0, x1 in runs(ink[y0:y1].any(0), GAP):
            rows_with_ink = np.where(ink[y0:y1, x0:x1].any(1))[0]
            boxes.append((x0, y0 + rows_with_ink[0], x1, y0 + rows_with_ink[-1] + 1))

    if len(boxes) != len(ICON_NAMES):
        sys.exit(
            f"expected {len(ICON_NAMES)} icons, segmented {len(boxes)}; "
            "the sheet or the render width changed"
        )

    os.makedirs(args.out, exist_ok=True)
    for name, box in zip(ICON_NAMES, boxes):
        keyed_image.crop(box).save(os.path.join(args.out, f"{name}.png"))
    print(f"wrote {len(boxes)} icons to {args.out}")


if __name__ == "__main__":
    main()
