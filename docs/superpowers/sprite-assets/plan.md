# Sprite Assets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vendor the 25-animal pixel pack and 30 market icons into the repo and draw them as real sprites, replacing the coloured placeholder boxes while keeping the existing squash-stretch and wander motion.

**Architecture:** A checked-in Python tool rasterises the market SVG sheet into 30 transparent PNGs once; both packs live under `assets/` and are registered in `pubspec.yaml`. `SpriteCache` decodes asset PNGs into `ui.Image` so a `CustomPainter` can look one up synchronously. `SpriteActorPainter` draws that image bottom-centre anchored under the same `ScalePair` the box painter used, so motion code is untouched. `ActorField` prefers the sprite painter and falls back to `PlaceholderBoxPainter` until the image is decoded.

**Tech Stack:** Flutter 3.41.1 / Dart `^3.11.0`, `dart:ui`, `flutter_lints ^6.0.0`. Tooling: `rsvg-convert`, Python 3 with Pillow and numpy (dev-machine only, not app dependencies).

**Spec:** `docs/superpowers/sprite-assets/spec.md`

## Global Constraints

- **No new package dependencies.** `flutter_svg` is explicitly out of scope.
- `pubspec.yaml` changes are limited to adding a `flutter: assets:` section. This
  relaxes the "pubspec.yaml must not change" rule carried by earlier plans in
  this repo — that rule was about package dependencies.
- Every sprite draw uses `FilterQuality.none` and `isAntiAlias = false`.
- Draw-only: no new interaction surfaces, `ActorField` stays wrapped in `IgnorePointer`.
- `flutter analyze` must stay clean; `flutter test` must stay green.
- Do not modify `lib/placeholder/motion/**` — the motion primitives are final.
- Commit at the end of each task with the message given in that task's last step.

## Verified environment facts

These were checked empirically against this repo before the plan was written.
Do not re-litigate them; do not "fix" tests that rely on them.

1. `rootBundle.load('assets/...')` **works** inside a plain `test()` once
   `TestWidgetsFlutterBinding.ensureInitialized()` has run, provided the asset
   is registered in `pubspec.yaml`.
2. `AssetImage(...).resolve(...)` **never completes** under `tester.pump()` /
   `pumpAndSettle()`. Any test that decodes a real asset through `AssetImage`
   must wrap it in `await tester.runAsync(() async { ... })`.
3. A synthetic image from `ui.PictureRecorder().endRecording().toImage(w, h)`
   **does** complete without `runAsync`. Painter tests use this.
4. `paints..drawImageRect(image:, source:, destination:)` exists and asserts
   draw geometry. It has **no** `filterQuality` parameter — assert filtering
   through the pure `spritePaint()` helper instead.

## File Structure

| File | Responsibility |
|------|----------------|
| `tool/extract_market_icons.py` | One-shot, re-runnable SVG sheet → 30 transparent PNGs |
| `assets/animals/*.png` | 25 verbatim animal sprites (32×32 RGBA) |
| `assets/icons/*.png` | 30 extracted market icons |
| `lib/sprites/asset_paths.dart` | The two name lists + path builders |
| `lib/sprites/sprite_cache.dart` | Asset path → decoded `ui.Image`, synchronous `peek` |
| `lib/sprites/sprite_painter.dart` | `spritePaint()`, `spriteDestRect()`, `SpriteActorPainter` |
| `lib/ui/market_icon.dart` | `MarketIcon` role enum + `MarketIconImage` widget |
| `lib/placeholder/placeholder_actor.dart` | gains `spriteAsset` |
| `lib/placeholder/actor_catalog.dart` | 25 animals + 3 sprite-backed items |
| `lib/placeholder/actor_field.dart` | sprite-or-box painter selection, preloading |

---

### Task 1: Vendor both asset packs

**Files:**
- Create: `tool/extract_market_icons.py`
- Create: `assets/animals/*.png` (25 files, copied verbatim)
- Create: `assets/icons/*.png` (30 files, produced by the tool)
- Create: `lib/sprites/asset_paths.dart`
- Create: `docs/superpowers/sprite-assets/asset-provenance.md`
- Modify: `pubspec.yaml` (add `flutter: assets:`)
- Test: `test/sprites/asset_paths_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `SpriteAssets.animalIds` (`List<String>`, 25), `SpriteAssets.iconNames`
  (`List<String>`, 30), `SpriteAssets.animal(String id) -> String`,
  `SpriteAssets.icon(String name) -> String`, `SpriteAssets.allPaths -> List<String>`.

- [ ] **Step 1: Write the extraction tool**

Create `tool/extract_market_icons.py`:

```python
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
```

- [ ] **Step 2: Copy the animal pack and run the tool**

```bash
mkdir -p assets/animals
cp ~/Documents/animals/"25 Micro Pixel Art Animals"/images/*.png assets/animals/
python3 tool/extract_market_icons.py \
  --svg ~/Documents/market-itch/vector_twenty_price_96dpi.svg \
  --out assets/icons
ls assets/animals | wc -l   # expect 25
ls assets/icons | wc -l     # expect 30
```

Expected: `wrote 30 icons to assets/icons`, then `25` and `30`.

If the tool exits with "expected 30 icons, segmented N", stop and report — do
not tune the thresholds to force a match.

- [ ] **Step 3: Register the assets**

In `pubspec.yaml`, replace the line `  uses-material-design: true` and the
blank line after it with:

```yaml
  uses-material-design: true

  assets:
    - assets/animals/
    - assets/icons/
```

Leave the commented-out example block that follows it alone.

- [ ] **Step 4: Write the path table**

Create `lib/sprites/asset_paths.dart`:

```dart
/// Paths into the two vendored sprite packs.
///
/// Ids are the on-disk filenames, including the animal pack's own spelling of
/// `chiken`. See `docs/superpowers/sprite-assets/spec.md` for provenance.
class SpriteAssets {
  const SpriteAssets._();

  static const String animalDir = 'assets/animals';
  static const String iconDir = 'assets/icons';

  /// The 25 animals in the pixel pack. No raccoon, deer or hummingbird.
  static const List<String> animalIds = <String>[
    'bear',
    'cat',
    'chiken',
    'cow',
    'crocodile',
    'dog',
    'elephant',
    'fox',
    'frog',
    'giraffe',
    'goat',
    'gorilla',
    'hippo',
    'lion',
    'monkey',
    'moose',
    'mouse',
    'panda',
    'penguin',
    'pig',
    'rabbit',
    'snake',
    'tiger',
    'turtle',
    'zebra',
  ];

  /// The 30 market icons, in sheet reading order.
  static const List<String> iconNames = <String>[
    'badge_rosette',
    'bank',
    'stamp',
    'coin',
    'tag_framed',
    'tag_rounded',
    'note_dashed',
    'note_dashed_wide',
    'banner_ribbon',
    'banner_ribbon_wide',
    'banner_ribbon_flat',
    'sparkle_six',
    'sparkle_eight',
    'cross_badge',
    'cross_badge_notched',
    'cross_badge_bevel',
    'seal_capsule',
    'seal_ellipse',
    'ribbon_zigzag',
    'tag_tall',
    'tag_tall_round',
    'padlock',
    'tag_hanging',
    'envelope',
    'card',
    'ticket',
    'ticket_wide',
    'ticket_alt',
    'note_cash',
    'vault',
  ];

  static String animal(String id) => '$animalDir/$id.png';

  static String icon(String name) => '$iconDir/$name.png';

  static List<String> get allPaths => <String>[
    ...animalIds.map(animal),
    ...iconNames.map(icon),
  ];
}
```

- [ ] **Step 5: Write the failing test**

Create `test/sprites/asset_paths_test.dart`:

```dart
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/sprites/asset_paths.dart';

Future<ui.Image> decode(String path) async {
  final data = await rootBundle.load(path);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  return (await codec.getNextFrame()).image;
}

void main() {
  // rootBundle only serves registered assets once the binding is up.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('holds 25 animals and 30 icons, all uniquely named', () {
    expect(SpriteAssets.animalIds, hasLength(25));
    expect(SpriteAssets.iconNames, hasLength(30));
    expect(SpriteAssets.animalIds.toSet(), hasLength(25));
    expect(SpriteAssets.iconNames.toSet(), hasLength(30));
    expect(SpriteAssets.allPaths, hasLength(55));
  });

  test('builds paths under the pack directories', () {
    expect(SpriteAssets.animal('fox'), 'assets/animals/fox.png');
    expect(SpriteAssets.icon('coin'), 'assets/icons/coin.png');
  });

  test('every animal is a registered 32x32 sprite', () async {
    for (final id in SpriteAssets.animalIds) {
      final image = await decode(SpriteAssets.animal(id));
      expect(image.width, 32, reason: id);
      expect(image.height, 32, reason: id);
    }
  });

  test('every icon is registered and decodes', () async {
    for (final name in SpriteAssets.iconNames) {
      final image = await decode(SpriteAssets.icon(name));
      expect(image.width, greaterThan(0), reason: name);
      expect(image.height, greaterThan(0), reason: name);
    }
  });
}
```

- [ ] **Step 6: Run the tests**

Run: `flutter test test/sprites/asset_paths_test.dart`
Expected: PASS, 4 tests.

If an asset fails to load with "Unable to load asset", the `pubspec.yaml`
section from Step 3 is wrong or `flutter pub get` has not re-run.

- [ ] **Step 7: Write the provenance note**

Create `docs/superpowers/sprite-assets/asset-provenance.md`:

```markdown
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
```

- [ ] **Step 8: Verify and commit**

```bash
flutter analyze
flutter test
git add assets tool lib/sprites docs/superpowers/sprite-assets pubspec.yaml test/sprites
git commit -m "feat(sprites): vendor the animal and market icon packs"
```

Expected: analyze clean, all tests pass.

---

### Task 2: Decode sprites and draw them

**Files:**
- Create: `lib/sprites/sprite_cache.dart`
- Create: `lib/sprites/sprite_painter.dart`
- Test: `test/sprites/sprite_cache_test.dart`
- Test: `test/sprites/sprite_painter_test.dart`

**Interfaces:**
- Consumes: `SpriteAssets` (Task 1); `ScalePair` from
  `lib/placeholder/motion/squash_stretch.dart` — `const ScalePair(double x, double y)`
  with fields `x` and `y`.
- Produces:
  - `SpriteCache.instance` (singleton), `ui.Image? peek(String)`,
    `Future<ui.Image> load(String)`, `Future<void> loadAll(Iterable<String>)`,
    `void put(String, ui.Image)`, `void clear()`.
  - `Paint spritePaint()`
  - `Rect spriteDestRect({required Offset position, required Size designSize, required ScalePair scale})`
  - `SpriteActorPainter({required ui.Image image, required Offset position, required Size designSize, required ScalePair scale})`

- [ ] **Step 1: Write the failing cache test**

Create `test/sprites/sprite_cache_test.dart`:

```dart
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/sprites/asset_paths.dart';
import 'package:moneymoneymoney/sprites/sprite_cache.dart';

Future<ui.Image> stubImage(int w, int h) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xffff0000),
  );
  return recorder.endRecording().toImage(w, h);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(SpriteCache.instance.clear);

  testWidgets('peek is null until the image is loaded', (tester) async {
    expect(SpriteCache.instance.peek(SpriteAssets.animal('fox')), isNull);
  });

  testWidgets('load decodes a real asset and peek then returns it', (
    tester,
  ) async {
    // Asset decoding never completes inside the test's fake async zone.
    await tester.runAsync(() async {
      final image = await SpriteCache.instance.load(SpriteAssets.animal('fox'));
      expect(image.width, 32);
    });
    expect(SpriteCache.instance.peek(SpriteAssets.animal('fox')), isNotNull);
  });

  testWidgets('load is idempotent and returns the same instance', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final path = SpriteAssets.animal('bear');
      final first = await SpriteCache.instance.load(path);
      final second = await SpriteCache.instance.load(path);
      expect(identical(first, second), isTrue);
    });
  });

  testWidgets('put injects an image without touching the bundle', (
    tester,
  ) async {
    final image = await stubImage(8, 8);
    SpriteCache.instance.put('fake/path.png', image);
    expect(SpriteCache.instance.peek('fake/path.png'), same(image));
  });

  testWidgets('clear empties the cache', (tester) async {
    final image = await stubImage(8, 8);
    SpriteCache.instance.put('fake/path.png', image);
    SpriteCache.instance.clear();
    expect(SpriteCache.instance.peek('fake/path.png'), isNull);
  });

  testWidgets('loadAll resolves every path', (tester) async {
    await tester.runAsync(() async {
      await SpriteCache.instance.loadAll(<String>[
        SpriteAssets.animal('cat'),
        SpriteAssets.icon('coin'),
      ]);
    });
    expect(SpriteCache.instance.peek(SpriteAssets.animal('cat')), isNotNull);
    expect(SpriteCache.instance.peek(SpriteAssets.icon('coin')), isNotNull);
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `flutter test test/sprites/sprite_cache_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'moneymoneymoney' ... sprite_cache.dart` / "Undefined name 'SpriteCache'".

- [ ] **Step 3: Implement the cache**

Create `lib/sprites/sprite_cache.dart`:

```dart
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Decoded sprite frames, keyed by asset path.
///
/// A [CustomPainter] must produce pixels synchronously, but [AssetImage] only
/// offers a stream. This holds the decoded frame so a repaint can look one up
/// with [peek] and fall back to a placeholder until it arrives.
class SpriteCache {
  SpriteCache._();

  static final SpriteCache instance = SpriteCache._();

  final Map<String, ui.Image> _images = <String, ui.Image>{};

  /// The decoded image for [assetPath], or null if it is not loaded yet.
  ui.Image? peek(String assetPath) => _images[assetPath];

  /// Decodes [assetPath] and keeps it. Repeat calls return the same image.
  Future<ui.Image> load(String assetPath) async {
    final cached = _images[assetPath];
    if (cached != null) return cached;

    final completer = Completer<ui.Image>();
    final stream = AssetImage(assetPath).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(info.image);
      },
      onError: (error, stack) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.completeError(error, stack);
      },
    );
    stream.addListener(listener);

    final image = await completer.future;
    _images[assetPath] = image;
    return image;
  }

  Future<void> loadAll(Iterable<String> assetPaths) =>
      Future.wait(assetPaths.map(load));

  /// Test seam: seed a decoded image without reading the asset bundle.
  void put(String assetPath, ui.Image image) => _images[assetPath] = image;

  void clear() => _images.clear();
}
```

- [ ] **Step 4: Run the cache test**

Run: `flutter test test/sprites/sprite_cache_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Write the failing painter test**

Create `test/sprites/sprite_painter_test.dart`:

```dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/placeholder/motion/squash_stretch.dart';
import 'package:moneymoneymoney/sprites/sprite_painter.dart';

Future<ui.Image> stubImage(int w, int h) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xffff0000),
  );
  return recorder.endRecording().toImage(w, h);
}

void main() {
  test('sprite paint never resamples pixel art', () {
    final paint = spritePaint();
    expect(paint.filterQuality, FilterQuality.none);
    expect(paint.isAntiAlias, isFalse);
  });

  test('an unscaled sprite fills its design box', () {
    final rect = spriteDestRect(
      position: const Offset(10, 20),
      designSize: const Size(64, 64),
      scale: const ScalePair(1, 1),
    );
    expect(rect, const Rect.fromLTWH(10, 20, 64, 64));
  });

  test('a squashed sprite keeps its feet on the ground', () {
    const position = Offset(10, 20);
    const designSize = Size(64, 64);
    // Squash: half as tall, twice as wide.
    final rect = spriteDestRect(
      position: position,
      designSize: designSize,
      scale: const ScalePair(2, 0.5),
    );
    expect(rect.width, 128);
    expect(rect.height, 32);
    // Bottom edge is pinned, horizontal centre is preserved.
    expect(rect.bottom, position.dy + designSize.height);
    expect(rect.center.dx, position.dx + designSize.width / 2);
  });

  test('a stretched sprite grows upward from the same feet', () {
    final rect = spriteDestRect(
      position: const Offset(0, 0),
      designSize: const Size(50, 50),
      scale: const ScalePair(0.5, 2),
    );
    expect(rect.bottom, 50);
    expect(rect.top, -50);
    expect(rect.width, 25);
  });

  testWidgets('draws the whole source image into the destination rect', (
    tester,
  ) async {
    final image = await stubImage(32, 32);
    await tester.pumpWidget(
      CustomPaint(
        painter: SpriteActorPainter(
          image: image,
          position: const Offset(4, 6),
          designSize: const Size(64, 64),
          scale: const ScalePair(1, 1),
        ),
        size: const Size(200, 200),
      ),
    );
    expect(
      find.byType(CustomPaint).first,
      paints
        ..drawImageRect(
          image: image,
          source: const Rect.fromLTWH(0, 0, 32, 32),
          destination: const Rect.fromLTWH(4, 6, 64, 64),
        ),
    );
  });

  testWidgets('repaints when the pose changes but not when it is identical', (
    tester,
  ) async {
    final image = await stubImage(32, 32);
    SpriteActorPainter at(Offset position) => SpriteActorPainter(
      image: image,
      position: position,
      designSize: const Size(64, 64),
      scale: const ScalePair(1, 1),
    );
    expect(at(const Offset(0, 0)).shouldRepaint(at(const Offset(0, 0))), isFalse);
    expect(at(const Offset(1, 0)).shouldRepaint(at(const Offset(0, 0))), isTrue);
  });
}
```

- [ ] **Step 6: Run it to confirm it fails**

Run: `flutter test test/sprites/sprite_painter_test.dart`
Expected: FAIL — "Undefined name 'spritePaint'".

- [ ] **Step 7: Implement the painter**

Create `lib/sprites/sprite_painter.dart`:

```dart
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../placeholder/motion/squash_stretch.dart';

/// The paint every sprite draw uses.
///
/// Pixel art must land on whole pixels: any resampling or antialiasing turns a
/// 32x32 sprite scaled up into a blurry smear.
Paint spritePaint() => Paint()
  ..filterQuality = FilterQuality.none
  ..isAntiAlias = false;

/// Where a sprite of [designSize] at [position] lands once [scale] is applied.
///
/// Anchored bottom-centre so a squash reads as weight pressing into the ground
/// rather than the whole body shrinking. This matches `PlaceholderBoxPainter`,
/// so swapping painters does not shift an actor.
Rect spriteDestRect({
  required Offset position,
  required Size designSize,
  required ScalePair scale,
}) {
  final width = designSize.width * scale.x;
  final height = designSize.height * scale.y;
  return Rect.fromLTWH(
    position.dx + (designSize.width - width) / 2,
    position.dy + (designSize.height - height),
    width,
    height,
  );
}

/// Draws one sprite under squash and stretch.
class SpriteActorPainter extends CustomPainter {
  SpriteActorPainter({
    required this.image,
    required this.position,
    required this.designSize,
    required this.scale,
  });

  final ui.Image image;

  /// Top-left of the unscaled design box.
  final Offset position;

  /// Design-space size before squash and stretch, not the source pixel size.
  final Size designSize;

  final ScalePair scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      spriteDestRect(
        position: position,
        designSize: designSize,
        scale: scale,
      ),
      spritePaint(),
    );
  }

  @override
  bool shouldRepaint(SpriteActorPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.position != position ||
      oldDelegate.designSize != designSize ||
      oldDelegate.scale.x != scale.x ||
      oldDelegate.scale.y != scale.y;
}
```

- [ ] **Step 8: Run the painter test**

Run: `flutter test test/sprites/sprite_painter_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 9: Verify and commit**

```bash
flutter analyze
flutter test
git add lib/sprites test/sprites
git commit -m "feat(sprites): decode sprite assets and draw them unfiltered"
```

---

### Task 3: Put the real animals on the field

**Files:**
- Modify: `lib/placeholder/placeholder_actor.dart` (add `spriteAsset`)
- Modify: `lib/placeholder/actor_catalog.dart` (rewrite the table)
- Modify: `lib/placeholder/actor_field.dart` (painter selection + preload)
- Test: `test/placeholder/actor_catalog_test.dart` (rewrite expectations)
- Test: `test/placeholder/actor_field_test.dart` (add sprite cases)

**Interfaces:**
- Consumes: `SpriteAssets`, `SpriteCache`, `SpriteActorPainter` (Tasks 1–2).
- Produces: `PlaceholderActor.spriteAsset` (`String?`),
  `ActorCatalog.all` (28 entries), `ActorCatalog.animals` (25),
  `ActorCatalog.items` (3), `ActorCatalog.spritePaths` (`List<String>`).

- [ ] **Step 1: Rewrite the catalog test**

Replace the body of `test/placeholder/actor_catalog_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/placeholder/actor_catalog.dart';
import 'package:moneymoneymoney/placeholder/placeholder_actor.dart';
import 'package:moneymoneymoney/sprites/asset_paths.dart';

void main() {
  test('every actor has a unique id', () {
    final ids = ActorCatalog.all.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('holds the 25 pack animals plus three items', () {
    expect(ActorCatalog.animals, hasLength(25));
    expect(ActorCatalog.items, hasLength(3));
    expect(ActorCatalog.all, hasLength(28));
    expect(
      ActorCatalog.animals.map((a) => a.id).toList(),
      SpriteAssets.animalIds,
    );
    expect(
      ActorCatalog.items.map((a) => a.id).toSet(),
      <String>{'coin', 'egg', 'xp_orb'},
    );
  });

  test('the dropped placeholders are gone', () {
    final ids = ActorCatalog.all.map((a) => a.id).toSet();
    // The pack has no sprite for these three.
    expect(ids, isNot(contains('deer')));
    expect(ids, isNot(contains('hummingbird')));
    expect(ids, isNot(contains('raccoon')));
  });

  test('every actor has a label, a positive size and a sprite', () {
    for (final actor in ActorCatalog.all) {
      expect(actor.label, isNotEmpty, reason: actor.id);
      expect(actor.size.width, greaterThan(0), reason: actor.id);
      expect(actor.size.height, greaterThan(0), reason: actor.id);
      expect(actor.spriteAsset, isNotNull, reason: actor.id);
    }
  });

  test('animals are animal-kind and point at the animal pack', () {
    for (final actor in ActorCatalog.animals) {
      expect(actor.kind, ActorKind.animal);
      expect(actor.spriteAsset, SpriteAssets.animal(actor.id));
    }
  });

  test('spritePaths lists one registered path per actor', () {
    expect(ActorCatalog.spritePaths, hasLength(28));
    for (final path in ActorCatalog.spritePaths) {
      expect(SpriteAssets.allPaths, contains(path));
    }
  });

  test('byId throws for an unknown actor', () {
    expect(() => ActorCatalog.byId('nope'), throwsStateError);
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `flutter test test/placeholder/actor_catalog_test.dart`
Expected: FAIL — "No named parameter with the name 'spriteAsset'" is not yet
the error; expect "The getter 'items' isn't defined" and length mismatches.

- [ ] **Step 3: Add the sprite field to the actor**

In `lib/placeholder/placeholder_actor.dart`, change the class doc and add the
field. Replace:

```dart
/// A stand-in for real art: a coloured box with a text label.
///
/// Swapping in real assets later means changing the painter, not this type.
class PlaceholderActor {
  const PlaceholderActor({
    required this.id,
    required this.label,
    required this.color,
    required this.size,
    required this.kind,
  });
```

with:

```dart
/// One drawable subject on the field.
///
/// [spriteAsset] is the real art. [color] and [label] stay as the fallback the
/// box painter uses while the sprite is still decoding.
class PlaceholderActor {
  const PlaceholderActor({
    required this.id,
    required this.label,
    required this.color,
    required this.size,
    required this.kind,
    this.spriteAsset,
  });
```

Then add this field after `kind`:

```dart
  /// Asset path of this subject's sprite, or null if it has no art yet.
  final String? spriteAsset;
```

- [ ] **Step 4: Rewrite the catalog**

Replace the whole of `lib/placeholder/actor_catalog.dart`:

```dart
import 'package:flutter/material.dart';

import '../sprites/asset_paths.dart';
import 'placeholder_actor.dart';

/// Every drawable subject in the app.
///
/// Animals come straight from the 25-sprite pixel pack, so the table is
/// generated from [SpriteAssets.animalIds] rather than hand-written. Items
/// borrow the closest icon from the market sheet.
class ActorCatalog {
  const ActorCatalog._();

  /// Sprites are 32x32; drawn at 2x so they read on a phone without blurring.
  static const Size _animalSize = Size(64, 64);

  /// Fallback box colours, cycled so a still-decoding field is legible.
  static const List<Color> _fallbackColors = <Color>[
    Color(0xffd96a2e),
    Color(0xffb8814f),
    Color(0xff2f9e7a),
    Color(0xff8d8f96),
    Color(0xff7d6bb0),
  ];

  static final List<PlaceholderActor> animals =
      List<PlaceholderActor>.unmodifiable(<PlaceholderActor>[
        for (var i = 0; i < SpriteAssets.animalIds.length; i++)
          PlaceholderActor(
            id: SpriteAssets.animalIds[i],
            label: SpriteAssets.animalIds[i].toUpperCase(),
            color: _fallbackColors[i % _fallbackColors.length],
            size: _animalSize,
            kind: ActorKind.animal,
            spriteAsset: SpriteAssets.animal(SpriteAssets.animalIds[i]),
          ),
      ]);

  static final List<PlaceholderActor> items =
      List<PlaceholderActor>.unmodifiable(<PlaceholderActor>[
        PlaceholderActor(
          id: 'coin',
          label: 'COIN',
          color: const Color(0xffe0b33c),
          size: const Size(48, 48),
          kind: ActorKind.item,
          spriteAsset: SpriteAssets.icon('coin'),
        ),
        PlaceholderActor(
          id: 'egg',
          label: 'EGG',
          color: const Color(0xffefe3cd),
          size: const Size(46, 56),
          kind: ActorKind.item,
          // The sheet has no egg; the capsule seal is the closest silhouette.
          spriteAsset: SpriteAssets.icon('seal_capsule'),
        ),
        PlaceholderActor(
          id: 'xp_orb',
          label: 'XP',
          color: const Color(0xff4fb8ff),
          size: const Size(44, 44),
          kind: ActorKind.item,
          spriteAsset: SpriteAssets.icon('sparkle_eight'),
        ),
      ]);

  static final List<PlaceholderActor> all = List<PlaceholderActor>.unmodifiable(
    <PlaceholderActor>[...animals, ...items],
  );

  /// Every sprite the field needs, for preloading in one pass.
  static List<String> get spritePaths => <String>[
    for (final actor in all)
      if (actor.spriteAsset != null) actor.spriteAsset!,
  ];

  static PlaceholderActor byId(String id) => all.firstWhere((a) => a.id == id);
}
```

- [ ] **Step 5: Run the catalog test**

Run: `flutter test test/placeholder/actor_catalog_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 6: Add the failing field tests**

In `test/placeholder/actor_field_test.dart`, add these imports at the top:

```dart
import 'dart:ui' as ui;

import 'package:moneymoneymoney/placeholder/placeholder_actor.dart';
import 'package:moneymoneymoney/sprites/sprite_cache.dart';
import 'package:moneymoneymoney/sprites/sprite_painter.dart';
```

Then, inside `main()` and after the existing `host` helper, add:

```dart
  Future<ui.Image> stubImage() {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 32, 32),
      Paint()..color = const Color(0xffff0000),
    );
    return recorder.endRecording().toImage(32, 32);
  }

  setUp(SpriteCache.instance.clear);
  tearDown(SpriteCache.instance.clear);

  testWidgets('draws sprites once their images are cached', (tester) async {
    final image = await stubImage();
    final actors = ActorCatalog.animals.take(3).toList();
    for (final actor in actors) {
      SpriteCache.instance.put(actor.spriteAsset!, image);
    }

    await tester.pumpWidget(host(ActorField(actors: actors)));

    final sprites = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((p) => p.painter is SpriteActorPainter);
    expect(sprites, hasLength(3));
  });

  testWidgets('falls back to a box while a sprite is still decoding', (
    tester,
  ) async {
    final actors = ActorCatalog.animals.take(2).toList();
    await tester.pumpWidget(host(ActorField(actors: actors)));

    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter);
    expect(painters.whereType<PlaceholderBoxPainter>(), hasLength(2));
    expect(painters.whereType<SpriteActorPainter>(), isEmpty);
  });

  testWidgets('an actor with no sprite always uses a box', (tester) async {
    const bare = PlaceholderActor(
      id: 'bare',
      label: 'BARE',
      color: Color(0xff333333),
      size: Size(40, 40),
      kind: ActorKind.animal,
    );
    await tester.pumpWidget(host(const ActorField(actors: <PlaceholderActor>[bare])));

    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter);
    expect(painters.whereType<PlaceholderBoxPainter>(), hasLength(1));
  });
```

Finally, update the three existing tests: each passes
`ActorCatalog.animals` and now gets 25 actors. Change all three to use
`ActorCatalog.animals.take(4).toList()` so the tests stay fast and the
positions stay distinguishable.

**Defect found during execution (fixed in place):** the plan originally said
these three keep asserting on `PlaceholderBoxPainter`. That holds for the two
that only call `pumpWidget`, but not for "actors move as time advances" —
`tester.pump(Duration(seconds: 2))` advances real time far enough for the
preload to complete, so the actor is drawn by `SpriteActorPainter` on the
second read and `.whereType<PlaceholderBoxPainter>().first` throws
`Bad state: No element`. That test must read the position off whichever
painter is present:

```dart
    Offset firstPosition() {
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .firstWhere(
            (p) => p is PlaceholderBoxPainter || p is SpriteActorPainter,
          );
      return switch (painter) {
        PlaceholderBoxPainter(:final position) => position,
        SpriteActorPainter(:final position) => position,
        _ => throw StateError('no actor painter'),
      };
    }
```

- [ ] **Step 7: Run it to confirm it fails**

Run: `flutter test test/placeholder/actor_field_test.dart`
Expected: FAIL — no `SpriteActorPainter` is ever produced (3 sprites expected, 0 found).

- [ ] **Step 8: Teach the field to prefer sprites**

In `lib/placeholder/actor_field.dart`, add these imports after the existing ones:

```dart
import '../sprites/sprite_cache.dart';
import '../sprites/sprite_painter.dart';
```

Add sprite preloading to the state class, immediately after the `_controller`
field:

```dart
  @override
  void initState() {
    super.initState();
    _preloadSprites();
  }

  /// Sprites arrive asynchronously; repaint once they do so the boxes give way.
  Future<void> _preloadSprites() async {
    final paths = <String>[
      for (final actor in widget.actors)
        if (actor.spriteAsset != null) actor.spriteAsset!,
    ];
    if (paths.isEmpty) return;
    await SpriteCache.instance.loadAll(paths);
    if (mounted) setState(() {});
  }
```

Then replace the `return Positioned.fill(...)` block at the end of
`_actorLayer` with:

```dart
    final scale = squashStretch(phase, amplitude: isAnimal ? 0.10 : 0.05);
    final sprite = actor.spriteAsset == null
        ? null
        : SpriteCache.instance.peek(actor.spriteAsset!);

    return Positioned.fill(
      child: CustomPaint(
        painter: sprite == null
            ? PlaceholderBoxPainter(
                actor: actor,
                position: position,
                scale: scale,
              )
            : SpriteActorPainter(
                image: sprite,
                position: position,
                designSize: actor.size,
                scale: scale,
              ),
      ),
    );
```

- [ ] **Step 9: Run the field tests**

Run: `flutter test test/placeholder/actor_field_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 10: Verify and commit**

```bash
flutter analyze
flutter test
git add lib/placeholder test/placeholder
git commit -m "feat(placeholder): draw the real animal pack instead of boxes"
```

---

### Task 4: A market icon for the wallet and XP UI

**Files:**
- Create: `lib/ui/market_icon.dart`
- Test: `test/ui/market_icon_test.dart`

**Interfaces:**
- Consumes: `SpriteAssets` (Task 1).
- Produces: `enum MarketIcon` with `String get assetPath`, and
  `MarketIconImage({required MarketIcon icon, double size, Color? tint})`.

- [ ] **Step 1: Write the failing test**

Create `test/ui/market_icon_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/sprites/asset_paths.dart';
import 'package:moneymoneymoney/ui/market_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every role maps to a registered icon', () async {
    for (final icon in MarketIcon.values) {
      expect(
        SpriteAssets.iconNames,
        contains(icon.iconName),
        reason: icon.name,
      );
      final data = await rootBundle.load(icon.assetPath);
      expect(data.lengthInBytes, greaterThan(0), reason: icon.name);
    }
  });

  test('roles the collectables screens need are present', () {
    final names = MarketIcon.values.map((i) => i.name).toSet();
    expect(
      names,
      containsAll(<String>['coin', 'xp', 'wallet', 'achievement', 'lootbox']),
    );
  });

  testWidgets('renders at the requested size without smoothing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MarketIconImage(icon: MarketIcon.coin, size: 32),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 32);
    expect(image.height, 32);
    expect(image.filterQuality, FilterQuality.none);
    expect(image.isAntiAlias, isFalse);
  });

  testWidgets('a tint is applied as a colour blend', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MarketIconImage(
          icon: MarketIcon.xp,
          size: 24,
          tint: Color(0xff4fb8ff),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.color, const Color(0xff4fb8ff));
    expect(image.colorBlendMode, BlendMode.srcATop);
  });

  testWidgets('an untinted icon keeps its own colours', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MarketIconImage(icon: MarketIcon.coin)),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.color, isNull);
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `flutter test test/ui/market_icon_test.dart`
Expected: FAIL — "Error when reading 'lib/ui/market_icon.dart': No such file".

- [ ] **Step 3: Implement the icon**

Create `lib/ui/market_icon.dart`:

```dart
import 'package:flutter/widgets.dart';

import '../sprites/asset_paths.dart';

/// The market-sheet icons the app uses, named by role rather than by the
/// shape they happen to be, so swapping the art is a one-line change here.
enum MarketIcon {
  coin('coin'),
  xp('sparkle_eight'),
  streak('sparkle_six'),
  achievement('badge_rosette'),
  wallet('bank'),
  receipt('note_cash'),

  /// The sheet has no egg; the capsule seal is the closest silhouette.
  egg('seal_capsule'),
  lockedSkin('padlock'),
  lootbox('ticket'),
  vault('vault');

  const MarketIcon(this.iconName);

  /// Name of the underlying sheet icon, as listed in [SpriteAssets.iconNames].
  final String iconName;

  String get assetPath => SpriteAssets.icon(iconName);
}

/// Draws a [MarketIcon] at a fixed square size.
///
/// The icons are rasterised line art, so they are drawn unfiltered to keep
/// their outlines crisp at small sizes.
class MarketIconImage extends StatelessWidget {
  const MarketIconImage({
    super.key,
    required this.icon,
    this.size = 24,
    this.tint,
  });

  final MarketIcon icon;

  /// Width and height in logical pixels.
  final double size;

  /// Recolours the icon's opaque pixels. Null keeps the sheet's own two-tone.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      icon.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      color: tint,
      colorBlendMode: tint == null ? null : BlendMode.srcATop,
    );
  }
}
```

- [ ] **Step 4: Run the test**

Run: `flutter test test/ui/market_icon_test.dart`
Expected: PASS, 5 tests.

Note: the widget tests never wait for the image to decode — they only inspect
the configured `Image` widget — so `runAsync` is not needed here.

- [ ] **Step 5: Verify and commit**

```bash
flutter analyze
flutter test
git add lib/ui test/ui
git commit -m "feat(ui): add market icons for the wallet and XP surfaces"
```

---

## Self-review notes

- **Spec coverage:** vendoring + tool (T1), no-SVG-dependency (T1), unfiltered
  drawing (T2, T4), bottom-centre anchoring (T2), motion untouched (T3 changes
  only painter selection), dropped animals (T3), semantic aliases (T4).
- **Deferred:** wiring `MarketIconImage` into the beta-credit HUD and the
  finance-tree home screen belongs to those plans, not this one.
- **Known follow-up:** `lib/placeholder/` is now a misleading directory name,
  since it holds real sprites plus the motion primitives. Renaming it is pure
  churn against the open collectables tasks; do it once those land.
