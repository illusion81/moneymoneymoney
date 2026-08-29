# Asset provenance

## `assets/animals/` — 25 Micro Pixel Art Animals

Purchased asset pack. Copied verbatim from
`~/Documents/animals/25 Micro Pixel Art Animals/images/`. 25 PNGs, 32×32 RGBA,
front-facing seated sprites, single frame each.

The pack ships a layered `.psd`/`.pxd` source and an unfinished
`racoon drawing.kra`; neither is vendored. There is no raccoon, deer or
hummingbird sprite, so those three placeholder actors were dropped.

Because each animal is one front-facing frame, walk and run cycles are not
possible from this pack. Animals move by squash-and-stretch plus seeded wander.

## `assets/icons/` — market icon sheet

Derived from `~/Documents/market-itch/vector_twenty_price_96dpi.svg` by
`tool/extract_market_icons.py`. The tool rasterises the sheet at 2400px wide,
keys out the `#414D9B` background, and splits the result on projection gaps
into 30 transparent PNGs named in sheet reading order.

Re-run it after replacing the SVG:

    python3 tool/extract_market_icons.py \
      --svg ~/Documents/market-itch/vector_twenty_price_96dpi.svg \
      --out assets/icons

It exits non-zero if segmentation does not find exactly 30 icons, which means
the sheet layout changed and `ICON_NAMES` needs revisiting.

The pack's other file, `twentyprice_96dpi.svg`, is a marketing preview card
rather than an asset sheet, and is not vendored.

No SVG ships in the app and no SVG library is a dependency; only PNG is loaded
at runtime.
