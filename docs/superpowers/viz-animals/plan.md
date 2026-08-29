# Viz Layer & Animal Rigs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a draw-only `lib/viz/` layer and replace the app's main screen with a workbench that shows chooseable Fox / Deer / Hummingbird / Raccoon / Tree gameobjects looping breathe, walk, and run animations.

**Architecture:** A creature is a `VizRig`: a flat list of `RigPart`s (local-space `Path` + pivot + optional parent + semantic `ColorSlot` + unique `z`) plus a pure `poseAt(clip, phase)` function returning per-part transforms. `RigPainter` walks the parent hierarchy into world matrices and fills each path with the palette colour for its slot. `VizStage` drives phase from an `AnimationController` and wraps everything in `IgnorePointer`. Interaction lives only in `lib/viz/workbench/`.

**Tech Stack:** Flutter Material, Dart 3 records, `dart:math`, `CustomPainter`, `Matrix4` (via `package:flutter/material.dart`), `flutter_test`. No new package dependencies.

**Spec:** `docs/superpowers/viz-animals/spec.md`

## Global Constraints

- **No new package dependencies.** `pubspec.yaml` dependencies stay exactly as they are.
- **Nothing under `lib/viz/` may handle a gesture, mutate state, read app state, navigate, or call a service** — except `lib/viz/workbench/`, which is a screen.
- **Every `z` value within a single rig must be unique.** `List.sort` is not stable in Dart.
- **Every pose expression must be periodic over `t` in `[0, 1)`** — use `sin(2 * pi * k * t)` with integer `k`. `sin(pi * t)` does not close the loop.
- **Part paths are authored in part-local space with the pivot at `(0, 0)`.**
- **Rigs name `ColorSlot` values, never literal `Color`s.** Literal colours live only in palette files.
- **No golden files.** Tests are pose math plus `RecordingCanvas`.
- **`flutter analyze` must report no issues before every commit**, and `flutter test` must pass. Task 0 establishes that baseline; it does not hold before Task 0.
- Existing files `lib/models/`, `lib/services/`, `lib/screens/` are not modified by this plan except `lib/main.dart` in Task 4.

## Execution Roles

| Task | Executor | Why |
| --- | --- | --- |
| 0. Green the baseline | **Haiku** | Two small, fully specified repairs to pre-existing breakage. |
| 1. Rig core | **Sonnet** | Sets every type the other tasks consume. |
| 2. VizStage + catalog | **Sonnet** | Ticker lifecycle is the one subtle bit of Flutter here. |
| 3. Fox | **Sonnet** | Exemplar rig; sets the art bar the others copy. |
| 4. Workbench screen | **Sonnet** | Touches `main.dart` and the existing test suite. |
| 5. Deer | **Haiku** | Mechanical: follow the Fox pattern with given geometry. |
| 6. Hummingbird | **Haiku** | Mechanical, with the wing-beat formula supplied. |
| 7. Raccoon | **opencode MiMo V2.5** (`opencode run -m opencode/mimo-v2.5-free --dir /home/jostev/Projects/moneymoneymoney`) | Fully isolated single file with an explicit part table. |
| 8. Wealth tree | **Haiku** | Mechanical, one file plus one catalog line. |

Opus orchestrates and runs the review gate between every task. A task is only
signed off after `flutter analyze` is clean, `flutter test` is green, and — for
Tasks 3, 5, 6, 7, 8 — the creature has been looked at in the workbench.

---

## File Structure

- `lib/viz/rig/color_slot.dart` — the six semantic colour slots.
- `lib/viz/rig/shapes.dart` — `Path` helpers (`ovalPath`, `capsulePath`, `trianglePath`, `curvedPath`).
- `lib/viz/rig/rig_part.dart` — `RigPart`, `PartPose`, `Pose` typedef.
- `lib/viz/rig/viz_clip.dart` — `VizClip` enum and its label/period extension.
- `lib/viz/rig/viz_palette.dart` — `VizPalette`.
- `lib/viz/rig/viz_rig.dart` — the `VizRig` contract.
- `lib/viz/rig/rig_painter.dart` — hierarchy-aware `CustomPainter`.
- `lib/viz/viz_stage.dart` — ticker-driven, pointer-ignoring host widget.
- `lib/viz/viz_catalog.dart` — id -> rig registry.
- `lib/viz/animals/fox.dart`, `deer.dart`, `hummingbird.dart`, `raccoon.dart` — one gameobject each.
- `lib/viz/tree/wealth_tree.dart` — the central tree, four growth stages.
- `lib/viz/workbench/viz_workbench_screen.dart` — the workbench (the only interactive file under `lib/viz/`).
- `lib/app_mode.dart` — `const bool kVizMode`.
- Modified in Task 0: `test/widget_test.dart` (taller test surface), `lib/screens/onboarding_screen.dart` (deprecated parameter).
- `test/viz/support/recording_canvas.dart` — `Canvas` capture harness.
- `test/viz/support/stub_rig.dart` — two-part rig used only by foundation tests.
- `test/viz/rig_core_test.dart`, `rig_painter_test.dart`, `viz_stage_test.dart`, `fox_test.dart`, `deer_test.dart`, `hummingbird_test.dart`, `raccoon_test.dart`, `wealth_tree_test.dart`, `viz_workbench_test.dart`.

---

### Task 0: Green The Baseline

The suite is currently **red on `main`**, and `flutter analyze` reports one
issue. Every later task gates on a green suite, so fix the baseline first. Both
problems are pre-existing and unrelated to the viz work.

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `lib/screens/onboarding_screen.dart:238`

**Interfaces:**
- Consumes: nothing.
- Produces: `Future<void> pumpApp(WidgetTester tester)` inside
  `test/widget_test.dart`'s `main()`, used by every test in that file.

- [ ] **Step 1: Confirm the baseline is red**

Run: `flutter test`
Expected: FAIL — 4 of the 5 tests in `test/widget_test.dart` fail with
`Found 0 widgets with text "Start Plan"` and a `tap()` hit-test warning saying
`Offset(409.0, 614.0) is outside the bounds of the root of the render tree,
Size(800.0, 600.0)`. The onboarding and report screens are taller than the
default 800x600 test surface, so their buttons are never built.

Run: `flutter analyze`
Expected: 1 issue — `'value' is deprecated and shouldn't be used. Use
initialValue instead` at `lib/screens/onboarding_screen.dart:238:7`.

- [ ] **Step 2: Give the widget tests a taller surface**

In `test/widget_test.dart`, add this helper as the first thing inside `main()`:

```dart
  // The onboarding and report screens are taller than the 800x600 default test
  // surface, so their buttons are never built and cannot be tapped.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
  }
```

Then replace all five occurrences of
`await tester.pumpWidget(const MyApp());` in the test bodies with:

```dart
    await pumpApp(tester);
```

Take care not to replace the one inside `pumpApp` itself — that would recurse
and the tests would hang rather than fail.

- [ ] **Step 3: Run the tests to verify they pass**

Run: `flutter test`
Expected: PASS, 12 tests.

- [ ] **Step 4: Fix the deprecated dropdown parameter**

In `lib/screens/onboarding_screen.dart`, in the `DropdownButtonFormField<T>`
inside `build`, rename the parameter:

```dart
    return DropdownButtonFormField<T>(
      initialValue: value,
```

- [ ] **Step 5: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Run the tests once more**

Run: `flutter test`
Expected: PASS, 12 tests.

- [ ] **Step 7: Commit**

```bash
git add test/widget_test.dart lib/screens/onboarding_screen.dart
git commit -m "fix: green the test baseline and drop a deprecated dropdown parameter"
```

---

### Task 1: Rig Core

**Files:**
- Create: `lib/viz/rig/color_slot.dart`
- Create: `lib/viz/rig/shapes.dart`
- Create: `lib/viz/rig/rig_part.dart`
- Create: `lib/viz/rig/viz_clip.dart`
- Create: `lib/viz/rig/viz_palette.dart`
- Create: `lib/viz/rig/viz_rig.dart`
- Create: `lib/viz/rig/rig_painter.dart`
- Create: `test/viz/support/recording_canvas.dart`
- Create: `test/viz/support/stub_rig.dart`
- Test: `test/viz/rig_core_test.dart`
- Test: `test/viz/rig_painter_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `enum ColorSlot { primary, secondary, belly, accent, eye, outline }`
- Produces: `Path ovalPath(double cx, double cy, double rx, double ry)`
- Produces: `Path capsulePath(double cx, double cy, double w, double h)`
- Produces: `Path trianglePath(Offset a, Offset b, Offset c)`
- Produces: `Path curvedPath(Offset start, List<(Offset, Offset, Offset)> cubics)`
- Produces: `class RigPart { const RigPart({required String id, String? parent, required Path path, required ColorSlot slot, required Offset pivot, required int z}); }`
- Produces: `class PartPose { const PartPose({double rotation = 0, Offset offset = Offset.zero, double scaleX = 1, double scaleY = 1}); }`
- Produces: `typedef Pose = Map<String, PartPose>;`
- Produces: `enum VizClip { breathe, walk, run }` with `String get label` and `Duration get period` on extension `VizClipInfo`
- Produces: `class VizPalette { const VizPalette({required String id, required String label, required Map<ColorSlot, Color> colors}); Color of(ColorSlot slot); }`
- Produces: `abstract class VizRig { String get id; String get displayName; Size get canvasSize; List<RigPart> get parts; VizPalette get defaultPalette; Set<VizClip> get supportedClips; Pose poseAt(VizClip clip, double t); }`
- Produces: `class RigPainter extends CustomPainter { RigPainter({required VizRig rig, required VizClip clip, required double phase, required VizPalette palette, bool showPivots = false}); }`
- Produces (test-only): `class RecordingCanvas implements Canvas { List<Path> paths; List<Paint> paints; List<Float64List> transforms; }`
- Produces (test-only): `class StubRig extends VizRig` with parts `'base'` (z 0, no parent) and `'tip'` (z 1, parent `'base'`).

- [ ] **Step 1: Write the failing core tests**

Create `test/viz/support/recording_canvas.dart`:

```dart
import 'dart:typed_data';
import 'dart:ui';

/// Captures the draw calls a [CustomPainter] makes, so painter behaviour can be
/// asserted without golden files.
class RecordingCanvas implements Canvas {
  final List<Path> paths = <Path>[];
  final List<Paint> paints = <Paint>[];
  final List<Float64List> transforms = <Float64List>[];

  @override
  void drawPath(Path path, Paint paint) {
    paths.add(path);
    paints.add(paint);
  }

  @override
  void transform(Float64List matrix4) {
    transforms.add(Float64List.fromList(matrix4));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
```

Create `test/viz/support/stub_rig.dart`:

```dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:moneymoneymoney/viz/rig/color_slot.dart';
import 'package:moneymoneymoney/viz/rig/shapes.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/rig/viz_palette.dart';
import 'package:moneymoneymoney/viz/rig/viz_rig.dart';

/// Minimal two-part rig used only by foundation tests.
class StubRig extends VizRig {
  @override
  String get id => 'stub';

  @override
  String get displayName => 'Stub';

  @override
  Size get canvasSize => const Size(100, 100);

  @override
  Set<VizClip> get supportedClips => const {VizClip.breathe};

  @override
  VizPalette get defaultPalette => const VizPalette(
    id: 'stub_default',
    label: 'Stub',
    colors: {
      ColorSlot.primary: Color(0xff112233),
      ColorSlot.secondary: Color(0xff445566),
      ColorSlot.belly: Color(0xff778899),
      ColorSlot.accent: Color(0xffaabbcc),
      ColorSlot.eye: Color(0xff000000),
      ColorSlot.outline: Color(0xff111111),
    },
  );

  @override
  List<RigPart> get parts => [
    RigPart(
      id: 'base',
      path: ovalPath(0, 0, 20, 20),
      slot: ColorSlot.primary,
      pivot: const Offset(50, 50),
      z: 0,
    ),
    RigPart(
      id: 'tip',
      parent: 'base',
      path: ovalPath(0, 0, 5, 5),
      slot: ColorSlot.accent,
      pivot: const Offset(20, 0),
      z: 1,
    ),
  ];

  @override
  Pose poseAt(VizClip clip, double t) {
    final theta = 2 * math.pi * t;
    return {'base': PartPose(rotation: 0.5 * math.sin(theta))};
  }
}
```

Create `test/viz/rig_core_test.dart`:

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/rig/color_slot.dart';
import 'package:moneymoneymoney/viz/rig/shapes.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/rig/viz_palette.dart';

void main() {
  test('ovalPath is centred on its local coordinates', () {
    expect(ovalPath(0, 0, 10, 5).getBounds(), const Rect.fromLTRB(-10, -5, 10, 5));
  });

  test('capsulePath spans the requested width and height', () {
    final bounds = capsulePath(0, 10, 8, 40).getBounds();
    expect(bounds.width, closeTo(8, 0.001));
    expect(bounds.height, closeTo(40, 0.001));
    expect(bounds.center.dy, closeTo(10, 0.001));
  });

  test('trianglePath closes over its three points', () {
    final path = trianglePath(Offset.zero, const Offset(10, 0), const Offset(0, 10));
    expect(path.getBounds(), const Rect.fromLTRB(0, 0, 10, 10));
  });

  test('curvedPath starts at the given point', () {
    final path = curvedPath(const Offset(0, 0), [
      (const Offset(5, -10), const Offset(15, -10), const Offset(20, 0)),
    ]);
    expect(path.getBounds().left, closeTo(0, 0.001));
    expect(path.getBounds().right, closeTo(20, 0.001));
  });

  test('every clip has a positive loop period and a label', () {
    for (final clip in VizClip.values) {
      expect(clip.period.inMilliseconds, greaterThan(0));
      expect(clip.label, isNotEmpty);
    }
  });

  test('palette resolves every slot it defines', () {
    const palette = VizPalette(
      id: 'p',
      label: 'P',
      colors: {ColorSlot.primary: Color(0xff123456)},
    );
    expect(palette.of(ColorSlot.primary), const Color(0xff123456));
  });

  test('palette falls back to opaque black for an undefined slot', () {
    const palette = VizPalette(id: 'p', label: 'P', colors: {});
    expect(palette.of(ColorSlot.eye), const Color(0xff000000));
  });
}
```

Create `test/viz/rig_painter_test.dart`:

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/rig/rig_painter.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';

import 'support/recording_canvas.dart';
import 'support/stub_rig.dart';

void main() {
  final rig = StubRig();

  RecordingCanvas paintAt(double phase) {
    final canvas = RecordingCanvas();
    RigPainter(
      rig: rig,
      clip: VizClip.breathe,
      phase: phase,
      palette: rig.defaultPalette,
    ).paint(canvas, const Size(200, 200));
    return canvas;
  }

  test('paints one path per part', () {
    expect(paintAt(0).paths.length, 2);
  });

  test('paints parts in ascending z order using their slot colours', () {
    final canvas = paintAt(0);
    // Compare packed ARGB: Color == also compares colour space and float
    // components, which round-trip unequal through Paint.
    expect(canvas.paints[0].color.toARGB32(), 0xff112233); // base, primary
    expect(canvas.paints[1].color.toARGB32(), 0xffaabbcc); // tip, accent
  });

  test('a child part inherits its parent transform', () {
    // At phase 0.25 the base is rotated by 0.5 rad, which must move the tip.
    final still = paintAt(0.0).transforms[1];
    final rotated = paintAt(0.25).transforms[1];
    expect(rotated[12], isNot(closeTo(still[12], 0.01)));
  });

  test('shouldRepaint is true when the phase advances', () {
    final a = RigPainter(
      rig: rig,
      clip: VizClip.breathe,
      phase: 0.0,
      palette: rig.defaultPalette,
    );
    final b = RigPainter(
      rig: rig,
      clip: VizClip.breathe,
      phase: 0.5,
      palette: rig.defaultPalette,
    );
    expect(b.shouldRepaint(a), isTrue);
    expect(b.shouldRepaint(b), isFalse);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/viz/`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/viz/rig/color_slot.dart'` and similar for each missing file.

- [ ] **Step 3: Write the core types**

Create `lib/viz/rig/color_slot.dart`:

```dart
/// Semantic colour names. Rigs reference slots; palettes (and later, skins)
/// decide what colour each slot actually is.
enum ColorSlot { primary, secondary, belly, accent, eye, outline }
```

Create `lib/viz/rig/shapes.dart`:

```dart
import 'dart:ui';

/// Path helpers for rig parts. Every path is authored in part-local space with
/// the part's pivot at (0, 0).

Path ovalPath(double cx, double cy, double rx, double ry) => Path()
  ..addOval(
    Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
  );

Path capsulePath(double cx, double cy, double w, double h) => Path()
  ..addRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
      Radius.circular(w / 2),
    ),
  );

Path trianglePath(Offset a, Offset b, Offset c) => Path()
  ..moveTo(a.dx, a.dy)
  ..lineTo(b.dx, b.dy)
  ..lineTo(c.dx, c.dy)
  ..close();

/// Builds a closed path from [start] through a list of
/// (control1, control2, endPoint) cubic segments.
Path curvedPath(Offset start, List<(Offset, Offset, Offset)> cubics) {
  final path = Path()..moveTo(start.dx, start.dy);
  for (final (c1, c2, end) in cubics) {
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
  }
  return path..close();
}
```

Create `lib/viz/rig/rig_part.dart`:

```dart
import 'dart:ui';

import 'color_slot.dart';

/// One drawable piece of a rig.
///
/// [path] is in part-local space with the pivot at (0, 0). [pivot] positions
/// the part in its parent's space, or in rig space when [parent] is null.
/// [z] is the global draw order and must be unique within a rig, because
/// Dart's List.sort is not stable.
class RigPart {
  const RigPart({
    required this.id,
    required this.path,
    required this.slot,
    required this.pivot,
    required this.z,
    this.parent,
  });

  final String id;
  final String? parent;
  final Path path;
  final ColorSlot slot;
  final Offset pivot;
  final int z;
}

/// A per-frame transform applied to one part, about its pivot.
class PartPose {
  const PartPose({
    this.rotation = 0,
    this.offset = Offset.zero,
    this.scaleX = 1,
    this.scaleY = 1,
  });

  /// Radians, clockwise in screen space.
  final double rotation;

  /// Extra translation, added to the part's pivot.
  final Offset offset;

  final double scaleX;
  final double scaleY;
}

/// Part id -> transform for a single animation frame. Parts absent from the map
/// are drawn at rest.
typedef Pose = Map<String, PartPose>;
```

Create `lib/viz/rig/viz_clip.dart`:

```dart
/// The animation clips every rig speaks. Non-locomoting rigs reinterpret walk
/// and run rather than omitting them, so UI controls stay uniform.
enum VizClip { breathe, walk, run }

extension VizClipInfo on VizClip {
  String get label => switch (this) {
    VizClip.breathe => 'Breathe',
    VizClip.walk => 'Walk',
    VizClip.run => 'Run',
  };

  /// One full loop at 1.0x speed.
  Duration get period => switch (this) {
    VizClip.breathe => const Duration(milliseconds: 3200),
    VizClip.walk => const Duration(milliseconds: 900),
    VizClip.run => const Duration(milliseconds: 520),
  };
}
```

Create `lib/viz/rig/viz_palette.dart`:

```dart
import 'dart:ui';

import 'color_slot.dart';

/// Resolves a rig's semantic colour slots to real colours.
class VizPalette {
  const VizPalette({
    required this.id,
    required this.label,
    required this.colors,
  });

  final String id;
  final String label;
  final Map<ColorSlot, Color> colors;

  Color of(ColorSlot slot) => colors[slot] ?? const Color(0xff000000);
}
```

Create `lib/viz/rig/viz_rig.dart`:

```dart
import 'dart:ui';

import 'rig_part.dart';
import 'viz_clip.dart';
import 'viz_palette.dart';

export 'rig_part.dart';

/// A drawable gameobject: a set of parts plus pure pose functions.
///
/// Implementations must not hold mutable state, read app state, or perform I/O.
abstract class VizRig {
  /// Stable identifier, e.g. 'fox'.
  String get id;

  /// Human label for pickers, e.g. 'Fox'.
  String get displayName;

  /// The design-space box the parts are authored in. The painter letterboxes
  /// this into whatever size it is given.
  Size get canvasSize;

  /// Parts in any order; the painter sorts by [RigPart.z].
  List<RigPart> get parts;

  VizPalette get defaultPalette;

  Set<VizClip> get supportedClips;

  /// Pure function of the loop phase [t] in [0, 1).
  ///
  /// Every term must be periodic over that range: use sin(2 * pi * k * t) with
  /// integer k, never sin(pi * t).
  Pose poseAt(VizClip clip, double t);
}
```

Create `lib/viz/rig/rig_painter.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'viz_clip.dart';
import 'viz_palette.dart';
import 'viz_rig.dart';

/// Draws a [VizRig] at a single animation phase.
class RigPainter extends CustomPainter {
  RigPainter({
    required this.rig,
    required this.clip,
    required this.phase,
    required this.palette,
    this.showPivots = false,
  });

  final VizRig rig;
  final VizClip clip;

  /// Loop phase in [0, 1).
  final double phase;

  final VizPalette palette;

  /// Debug aid for the workbench: marks each part's pivot.
  final bool showPivots;

  @override
  void paint(Canvas canvas, Size size) {
    final pose = rig.poseAt(clip, phase);
    final byId = {for (final part in rig.parts) part.id: part};
    final world = <String, Matrix4>{};

    final fit = math.min(
      size.width / rig.canvasSize.width,
      size.height / rig.canvasSize.height,
    );
    final dx = (size.width - rig.canvasSize.width * fit) / 2;
    final dy = (size.height - rig.canvasSize.height * fit) / 2;
    final root = _translation(dx, dy).multiplied(_scale(fit, fit));

    final ordered = [...rig.parts]..sort((a, b) => a.z.compareTo(b.z));
    for (final part in ordered) {
      final matrix = root.multiplied(_worldOf(part.id, byId, pose, world));
      canvas.save();
      canvas.transform(matrix.storage);
      canvas.drawPath(
        part.path,
        Paint()
          ..color = palette.of(part.slot)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      if (showPivots) {
        canvas.drawCircle(
          Offset.zero,
          1.6,
          Paint()..color = const Color(0xffff2d55),
        );
      }
      canvas.restore();
    }
  }

  Matrix4 _worldOf(
    String id,
    Map<String, RigPart> byId,
    Pose pose,
    Map<String, Matrix4> memo,
  ) {
    final cached = memo[id];
    if (cached != null) {
      return cached;
    }
    final part = byId[id]!;
    final p = pose[id] ?? const PartPose();
    final local = _translation(
      part.pivot.dx + p.offset.dx,
      part.pivot.dy + p.offset.dy,
    ).multiplied(Matrix4.rotationZ(p.rotation)).multiplied(
      _scale(p.scaleX, p.scaleY),
    );
    final parentId = part.parent;
    final result = parentId == null
        ? local
        : _worldOf(parentId, byId, pose, memo).multiplied(local);
    memo[id] = result;
    return result;
  }

  static Matrix4 _translation(double x, double y) => Matrix4.identity()
    ..setEntry(0, 3, x)
    ..setEntry(1, 3, y);

  static Matrix4 _scale(double x, double y) => Matrix4.identity()
    ..setEntry(0, 0, x)
    ..setEntry(1, 1, y);

  @override
  bool shouldRepaint(RigPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.clip != clip ||
      oldDelegate.rig != rig ||
      oldDelegate.palette != palette ||
      oldDelegate.showPivots != showPivots;
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/viz/`
Expected: PASS, 11 tests.

- [ ] **Step 5: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/viz/rig test/viz
git commit -m "feat(viz): add rig core, shapes, palette and hierarchy painter"
```

---

### Task 2: VizStage And Catalog

**Files:**
- Create: `lib/viz/viz_stage.dart`
- Create: `lib/viz/viz_catalog.dart`
- Test: `test/viz/viz_stage_test.dart`

**Interfaces:**
- Consumes: `VizRig`, `VizClip`, `VizClipInfo.period`, `VizPalette`, `RigPainter` from Task 1; `StubRig` from `test/viz/support/stub_rig.dart`.
- Produces: `class VizStage extends StatefulWidget { const VizStage({super.key, required VizRig rig, required VizClip clip, VizPalette? palette, double speed = 1.0, bool showPivots = false}); }`
- Produces: `class VizCatalog { static List<VizRig> get all; static VizRig byId(String id); }`

- [ ] **Step 1: Write the failing stage tests**

Create `test/viz/viz_stage_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/rig/rig_painter.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/viz_catalog.dart';
import 'package:moneymoneymoney/viz/viz_stage.dart';

import 'support/stub_rig.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(width: 300, height: 300, child: child)),
  );

  RigPainter painterOf(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(VizStage),
        matching: find.byType(CustomPaint),
      ).first,
    );
    return paint.painter! as RigPainter;
  }

  testWidgets('advances the phase as time passes', (tester) async {
    await tester.pumpWidget(
      host(VizStage(rig: StubRig(), clip: VizClip.breathe)),
    );
    final first = painterOf(tester).phase;
    await tester.pump(const Duration(milliseconds: 800));
    expect(painterOf(tester).phase, isNot(equals(first)));
  });

  testWidgets('ignores pointer events', (tester) async {
    await tester.pumpWidget(
      host(VizStage(rig: StubRig(), clip: VizClip.breathe)),
    );
    expect(
      find.descendant(
        of: find.byType(VizStage),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
  });

  testWidgets('uses the rig default palette when none is given', (
    tester,
  ) async {
    final rig = StubRig();
    await tester.pumpWidget(host(VizStage(rig: rig, clip: VizClip.breathe)));
    expect(painterOf(tester).palette.id, rig.defaultPalette.id);
  });

  test('catalog starts empty and reports unknown ids', () {
    expect(VizCatalog.all, isEmpty);
    expect(() => VizCatalog.byId('nope'), throwsStateError);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/viz/viz_stage_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/viz/viz_stage.dart'`.

- [ ] **Step 3: Write the stage and the catalog**

Create `lib/viz/viz_stage.dart`:

```dart
import 'package:flutter/material.dart';

import 'rig/rig_painter.dart';
import 'rig/viz_clip.dart';
import 'rig/viz_palette.dart';
import 'rig/viz_rig.dart';

/// Mounts a [VizRig] and loops one clip.
///
/// The subtree is wrapped in [IgnorePointer]: viz objects never take input.
class VizStage extends StatefulWidget {
  const VizStage({
    super.key,
    required this.rig,
    required this.clip,
    this.palette,
    this.speed = 1.0,
    this.showPivots = false,
  });

  final VizRig rig;
  final VizClip clip;

  /// Defaults to [VizRig.defaultPalette].
  final VizPalette? palette;

  /// Playback multiplier; 0.5 is half speed.
  final double speed;

  final bool showPivots;

  @override
  State<VizStage> createState() => _VizStageState();
}

class _VizStageState extends State<VizStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _durationFor(widget.clip, widget.speed),
  )..repeat();

  static Duration _durationFor(VizClip clip, double speed) {
    final safeSpeed = speed <= 0 ? 1.0 : speed;
    final micros = (clip.period.inMicroseconds / safeSpeed).round();
    return Duration(microseconds: micros.clamp(16000, 60000000));
  }

  @override
  void didUpdateWidget(VizStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip != widget.clip || oldWidget.speed != widget.speed) {
      _controller
        ..stop()
        ..duration = _durationFor(widget.clip, widget.speed)
        ..forward(from: 0)
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: RigPainter(
            rig: widget.rig,
            clip: widget.clip,
            phase: _controller.value,
            palette: widget.palette ?? widget.rig.defaultPalette,
            showPivots: widget.showPivots,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
```

Create `lib/viz/viz_catalog.dart`:

```dart
import 'rig/viz_rig.dart';

/// Registry of every viz gameobject the workbench can show.
///
/// Each gameobject adds exactly one line here and nothing else.
class VizCatalog {
  const VizCatalog._();

  static List<VizRig> get all => List<VizRig>.unmodifiable(<VizRig>[]);

  static VizRig byId(String id) => all.firstWhere((rig) => rig.id == id);
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/viz/`
Expected: PASS, 15 tests.

- [ ] **Step 5: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/viz/viz_stage.dart lib/viz/viz_catalog.dart test/viz/viz_stage_test.dart
git commit -m "feat(viz): add looping VizStage host and gameobject catalog"
```

---

### Task 3: Fox Gameobject

**Files:**
- Create: `lib/viz/animals/fox.dart`
- Modify: `lib/viz/viz_catalog.dart`
- Test: `test/viz/fox_test.dart`

**Interfaces:**
- Consumes: `VizRig`, `RigPart`, `PartPose`, `Pose`, `ColorSlot`, `VizPalette`, `VizClip`, `ovalPath`, `capsulePath`, `trianglePath`, `curvedPath`.
- Produces: `class Fox extends VizRig` with `id == 'fox'`, canvas `Size(200, 140)`, and part ids `tail`, `tailTip`, `hindLegFar`, `foreLegFar`, `body`, `chest`, `hindLegNear`, `foreLegNear`, `earFar`, `neck`, `head`, `earNear`, `snout`, `eye`.
- Produces: `const VizPalette foxDefaultPalette`.

**Art notes for the reviewer:** side-on, facing right. Ground line at y = 130 in
design space. Legs pivot at the shoulder/hip and swing as rigid capsules — no
knee joint in this pass.

- [ ] **Step 1: Write the failing fox tests**

Create `test/viz/fox_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/animals/fox.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/rig/viz_rig.dart';
import 'package:moneymoneymoney/viz/viz_catalog.dart';

void main() {
  final fox = Fox();

  test('declares a stable identity and all three clips', () {
    expect(fox.id, 'fox');
    expect(fox.displayName, 'Fox');
    expect(fox.supportedClips, VizClip.values.toSet());
  });

  test('every part has a unique z', () {
    final zs = fox.parts.map((p) => p.z).toList();
    expect(zs.toSet().length, zs.length);
  });

  test('every parent reference resolves to a real part', () {
    final ids = fox.parts.map((p) => p.id).toSet();
    for (final part in fox.parts) {
      if (part.parent != null) {
        expect(ids, contains(part.parent), reason: '${part.id} parent');
      }
    }
  });

  test('every clip loops: pose at t=0 matches pose at t->1', () {
    for (final clip in fox.supportedClips) {
      final start = fox.poseAt(clip, 0);
      final end = fox.poseAt(clip, 0.9999);
      for (final id in start.keys) {
        expect(end[id]!.rotation, closeTo(start[id]!.rotation, 0.01),
            reason: '$clip / $id rotation');
        expect(end[id]!.offset.dx, closeTo(start[id]!.offset.dx, 0.05),
            reason: '$clip / $id offset.dx');
        expect(end[id]!.offset.dy, closeTo(start[id]!.offset.dy, 0.05),
            reason: '$clip / $id offset.dy');
        expect(end[id]!.scaleX, closeTo(start[id]!.scaleX, 0.02),
            reason: '$clip / $id scaleX');
        expect(end[id]!.scaleY, closeTo(start[id]!.scaleY, 0.02),
            reason: '$clip / $id scaleY');
      }
    }
  });

  test('breathing swells the body without moving the legs', () {
    final pose = fox.poseAt(VizClip.breathe, 0.25);
    expect(pose['body']!.scaleY, greaterThan(1.0));
    expect(pose['hindLegNear'], isNull);
  });

  test('walking puts the near fore and hind legs in opposite phase', () {
    final pose = fox.poseAt(VizClip.walk, 0.125);
    expect(pose['hindLegNear']!.rotation * pose['foreLegNear']!.rotation,
        lessThan(0));
  });

  test('running swings the legs harder than walking', () {
    final walk = fox.poseAt(VizClip.walk, 0.25)['hindLegNear']!.rotation.abs();
    final run = fox.poseAt(VizClip.run, 0.25)['hindLegNear']!.rotation.abs();
    expect(run, greaterThan(walk));
  });

  test('is registered in the catalog', () {
    expect(VizCatalog.byId('fox'), isA<VizRig>());
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/viz/fox_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/viz/animals/fox.dart'`.

- [ ] **Step 3: Write the fox gameobject**

Create `lib/viz/animals/fox.dart`:

```dart
import 'dart:math' as math;
import 'dart:ui';

import '../rig/color_slot.dart';
import '../rig/shapes.dart';
import '../rig/viz_clip.dart';
import '../rig/viz_palette.dart';
import '../rig/viz_rig.dart';

const VizPalette foxDefaultPalette = VizPalette(
  id: 'fox_default',
  label: 'Fox',
  colors: {
    ColorSlot.primary: Color(0xffd96a2e),
    ColorSlot.secondary: Color(0xffb04f20),
    ColorSlot.belly: Color(0xfff5e9d8),
    ColorSlot.accent: Color(0xfff2a65a),
    ColorSlot.eye: Color(0xff2a2320),
    ColorSlot.outline: Color(0xff2a2320),
  },
);

/// Side-on fox facing right. Design space 200x140, ground line at y = 130.
class Fox extends VizRig {
  @override
  String get id => 'fox';

  @override
  String get displayName => 'Fox';

  @override
  Size get canvasSize => const Size(200, 140);

  @override
  VizPalette get defaultPalette => foxDefaultPalette;

  @override
  Set<VizClip> get supportedClips => VizClip.values.toSet();

  @override
  List<RigPart> get parts => [
    RigPart(
      id: 'tail',
      path: curvedPath(const Offset(0, 0), [
        (const Offset(-22, -4), const Offset(-40, -18), const Offset(-46, -40)),
        (const Offset(-30, -46), const Offset(-8, -30), const Offset(0, -12)),
      ]),
      slot: ColorSlot.primary,
      pivot: const Offset(58, 78),
      z: 0,
    ),
    RigPart(
      id: 'tailTip',
      parent: 'tail',
      path: ovalPath(0, 0, 11, 10),
      slot: ColorSlot.belly,
      pivot: const Offset(-44, -40),
      z: 1,
    ),
    RigPart(
      id: 'hindLegFar',
      path: capsulePath(0, 19, 11, 38),
      slot: ColorSlot.secondary,
      pivot: const Offset(78, 92),
      z: 2,
    ),
    RigPart(
      id: 'foreLegFar',
      path: capsulePath(0, 19, 10, 38),
      slot: ColorSlot.secondary,
      pivot: const Offset(132, 92),
      z: 3,
    ),
    RigPart(
      id: 'body',
      path: ovalPath(0, 0, 44, 26),
      slot: ColorSlot.primary,
      pivot: const Offset(104, 80),
      z: 4,
    ),
    RigPart(
      id: 'chest',
      parent: 'body',
      path: ovalPath(0, 0, 20, 17),
      slot: ColorSlot.belly,
      pivot: const Offset(30, 8),
      z: 5,
    ),
    RigPart(
      id: 'hindLegNear',
      path: capsulePath(0, 18, 11, 36),
      slot: ColorSlot.primary,
      pivot: const Offset(88, 94),
      z: 6,
    ),
    RigPart(
      id: 'foreLegNear',
      path: capsulePath(0, 18, 10, 36),
      slot: ColorSlot.primary,
      pivot: const Offset(142, 94),
      z: 7,
    ),
    RigPart(
      id: 'earFar',
      parent: 'head',
      path: trianglePath(
        const Offset(0, 4),
        const Offset(-11, -23),
        const Offset(7, -10),
      ),
      slot: ColorSlot.secondary,
      pivot: const Offset(-7, -14),
      z: 8,
    ),
    RigPart(
      id: 'neck',
      path: capsulePath(0, 0, 24, 28),
      slot: ColorSlot.primary,
      pivot: const Offset(140, 68),
      z: 9,
    ),
    RigPart(
      id: 'head',
      parent: 'neck',
      path: ovalPath(0, 0, 22, 19),
      slot: ColorSlot.primary,
      pivot: const Offset(12, -18),
      z: 10,
    ),
    RigPart(
      id: 'earNear',
      parent: 'head',
      path: trianglePath(
        const Offset(0, 4),
        const Offset(6, -24),
        const Offset(14, -6),
      ),
      slot: ColorSlot.secondary,
      pivot: const Offset(6, -15),
      z: 11,
    ),
    RigPart(
      id: 'snout',
      parent: 'head',
      path: curvedPath(const Offset(0, -4), [
        (const Offset(14, -3), const Offset(22, 2), const Offset(24, 5)),
        (const Offset(16, 9), const Offset(6, 8), const Offset(0, 6)),
      ]),
      slot: ColorSlot.belly,
      pivot: const Offset(12, 4),
      z: 12,
    ),
    RigPart(
      id: 'eye',
      parent: 'head',
      path: ovalPath(0, 0, 2.8, 3.2),
      slot: ColorSlot.eye,
      pivot: const Offset(8, -3),
      z: 13,
    ),
  ];

  @override
  Pose poseAt(VizClip clip, double t) => switch (clip) {
    VizClip.breathe => _breathe(t),
    VizClip.walk => _walk(t),
    VizClip.run => _run(t),
  };

  Pose _breathe(double t) {
    final theta = 2 * math.pi * t;
    return {
      'body': PartPose(
        scaleX: 1 + 0.012 * math.sin(theta),
        scaleY: 1 + 0.035 * math.sin(theta),
      ),
      'chest': PartPose(scaleY: 1 + 0.05 * math.sin(theta)),
      'neck': PartPose(offset: Offset(0, 1.6 * math.sin(theta + 0.6))),
      'tail': PartPose(rotation: 0.09 * math.sin(theta)),
      'earNear': PartPose(rotation: 0.14 * math.max(0, math.sin(3 * theta))),
    };
  }

  Pose _walk(double t) {
    final theta = 2 * math.pi * t;
    final bounce = -2.0 * math.sin(2 * theta).abs();
    return {
      'body': PartPose(
        offset: Offset(0, bounce),
        scaleY: 1 + 0.01 * math.sin(theta),
      ),
      'neck': PartPose(
        offset: Offset(0, bounce),
        rotation: 0.06 * math.sin(theta + 0.4),
      ),
      'tail': PartPose(rotation: 0.18 * math.sin(theta + 0.9)),
      'hindLegNear': PartPose(rotation: 0.55 * math.sin(theta)),
      'foreLegNear': PartPose(rotation: 0.55 * math.sin(theta + math.pi)),
      'hindLegFar': PartPose(rotation: 0.55 * math.sin(theta + math.pi)),
      'foreLegFar': PartPose(rotation: 0.55 * math.sin(theta)),
    };
  }

  Pose _run(double t) {
    final theta = 2 * math.pi * t;
    final bound = -6.0 * math.sin(theta).abs();
    return {
      'body': PartPose(
        offset: Offset(0, bound),
        rotation: 0.10 * math.sin(theta),
      ),
      'neck': PartPose(
        offset: Offset(0, bound),
        rotation: 0.10 * math.sin(theta) + 0.08,
      ),
      'tail': PartPose(rotation: 0.30 * math.sin(theta + 0.6) - 0.18),
      'hindLegNear': PartPose(rotation: 0.95 * math.sin(theta)),
      'hindLegFar': PartPose(rotation: 0.95 * math.sin(theta + 0.35)),
      'foreLegNear': PartPose(rotation: 0.95 * math.sin(theta + math.pi)),
      'foreLegFar': PartPose(
        rotation: 0.95 * math.sin(theta + math.pi + 0.35),
      ),
    };
  }
}
```

- [ ] **Step 4: Register the fox in the catalog**

Replace the whole body of `lib/viz/viz_catalog.dart` with:

```dart
import 'animals/fox.dart';
import 'rig/viz_rig.dart';

/// Registry of every viz gameobject the workbench can show.
///
/// Each gameobject adds exactly one line here and nothing else.
class VizCatalog {
  const VizCatalog._();

  static List<VizRig> get all => List<VizRig>.unmodifiable(<VizRig>[Fox()]);

  static VizRig byId(String id) => all.firstWhere((rig) => rig.id == id);
}
```

Then update the catalog test in `test/viz/viz_stage_test.dart` — replace the
`'catalog starts empty and reports unknown ids'` test with:

```dart
  test('catalog exposes registered rigs and rejects unknown ids', () {
    expect(VizCatalog.all, isNotEmpty);
    expect(() => VizCatalog.byId('nope'), throwsStateError);
  });
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/viz/`
Expected: PASS, 23 tests.

- [ ] **Step 6: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/viz/animals/fox.dart lib/viz/viz_catalog.dart test/viz
git commit -m "feat(viz): add fox gameobject with breathe, walk and run clips"
```

---

### Task 4: Viz Workbench Screen

**Files:**
- Create: `lib/app_mode.dart`
- Create: `lib/viz/workbench/viz_workbench_screen.dart`
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Test: `test/viz/viz_workbench_test.dart`

**Interfaces:**
- Consumes: `VizCatalog.all`, `VizStage`, `VizClip`, `VizClipInfo.label`, `VizRig.displayName`, `VizRig.supportedClips`.
- Produces: `const bool kVizMode` in `lib/app_mode.dart`.
- Produces: `class VizWorkbenchScreen extends StatefulWidget { const VizWorkbenchScreen({super.key}); }`
- Produces: `MyApp({super.key, bool vizMode = kVizMode})` — the existing app flow is preserved behind `vizMode: false`.
- Produces: widget keys `Key('viz-subject-<rigId>')`, `Key('viz-clip-<clipName>')`, `Key('viz-speed-slider')`, `Key('viz-pivots-toggle')`, `Key('viz-stage')`.

- [ ] **Step 1: Write the failing workbench tests**

Create `test/viz/viz_workbench_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/main.dart';
import 'package:moneymoneymoney/viz/viz_stage.dart';
import 'package:moneymoneymoney/viz/workbench/viz_workbench_screen.dart';

void main() {
  testWidgets('the app boots into the workbench in viz mode', (tester) async {
    await tester.pumpWidget(const MyApp(vizMode: true));
    expect(find.byType(VizWorkbenchScreen), findsOneWidget);
    expect(find.text('Viz Workbench'), findsOneWidget);
  });

  testWidgets('shows a stage and a chip for every catalog subject', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp(vizMode: true));
    expect(find.byKey(const Key('viz-stage')), findsOneWidget);
    expect(find.byKey(const Key('viz-subject-fox')), findsOneWidget);
  });

  testWidgets('selecting a clip changes what the stage plays', (tester) async {
    await tester.pumpWidget(const MyApp(vizMode: true));
    await tester.tap(find.byKey(const Key('viz-clip-run')));
    await tester.pump();
    final stage = tester.widget<VizStage>(find.byType(VizStage));
    expect(stage.clip.name, 'run');
  });

  testWidgets('the speed slider changes playback speed', (tester) async {
    await tester.pumpWidget(const MyApp(vizMode: true));
    final before = tester.widget<VizStage>(find.byType(VizStage)).speed;
    await tester.drag(
      find.byKey(const Key('viz-speed-slider')),
      const Offset(-120, 0),
    );
    await tester.pump();
    expect(tester.widget<VizStage>(find.byType(VizStage)).speed,
        lessThan(before));
  });

  testWidgets('the pivot toggle reaches the stage', (tester) async {
    await tester.pumpWidget(const MyApp(vizMode: true));
    await tester.tap(find.byKey(const Key('viz-pivots-toggle')));
    await tester.pump();
    expect(tester.widget<VizStage>(find.byType(VizStage)).showPivots, isTrue);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/viz/viz_workbench_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/viz/workbench/viz_workbench_screen.dart'`.

- [ ] **Step 3: Write the mode flag and the workbench screen**

Create `lib/app_mode.dart`:

```dart
/// While true, the app boots into the viz workbench instead of the
/// questionnaire, so creature art can be refined in isolation.
///
/// Set to false to run the normal onboarding -> report -> forest flow.
const bool kVizMode = true;
```

Create `lib/viz/workbench/viz_workbench_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../rig/viz_clip.dart';
import '../rig/viz_rig.dart';
import '../viz_catalog.dart';
import '../viz_stage.dart';

/// The one interactive file under lib/viz. Lets a reviewer pick a gameobject
/// and a clip and watch it loop while its look is being refined.
class VizWorkbenchScreen extends StatefulWidget {
  const VizWorkbenchScreen({super.key});

  @override
  State<VizWorkbenchScreen> createState() => _VizWorkbenchScreenState();
}

class _VizWorkbenchScreenState extends State<VizWorkbenchScreen> {
  late VizRig _rig = VizCatalog.all.first;
  VizClip _clip = VizClip.breathe;
  double _speed = 1.0;
  bool _showPivots = false;

  void _selectRig(VizRig rig) {
    setState(() {
      _rig = rig;
      if (!rig.supportedClips.contains(_clip)) {
        _clip = rig.supportedClips.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viz Workbench'),
        actions: [
          IconButton(
            key: const Key('viz-pivots-toggle'),
            tooltip: 'Show pivots',
            icon: Icon(
              _showPivots
                  ? Icons.center_focus_strong
                  : Icons.center_focus_weak_outlined,
            ),
            onPressed: () => setState(() => _showPivots = !_showPivots),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                // Bounded and scrollable so adding gameobjects can never
                // overflow the column as the catalog grows.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final rig in VizCatalog.all)
                          ChoiceChip(
                            key: Key('viz-subject-${rig.id}'),
                            label: Text(rig.displayName),
                            selected: rig.id == _rig.id,
                            onSelected: (_) => _selectRig(rig),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    key: const Key('viz-stage'),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xfffaf7ef),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffe3dcc9)),
                    ),
                    child: VizStage(
                      rig: _rig,
                      clip: _clip,
                      speed: _speed,
                      showPivots: _showPivots,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final clip in VizClip.values)
                              ChoiceChip(
                                key: Key('viz-clip-${clip.name}'),
                                label: Text(clip.label),
                                selected: clip == _clip,
                                onSelected: _rig.supportedClips.contains(clip)
                                    ? (_) => setState(() => _clip = clip)
                                    : null,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Speed'),
                            Expanded(
                              child: Slider(
                                key: const Key('viz-speed-slider'),
                                min: 0.25,
                                max: 2.0,
                                divisions: 7,
                                value: _speed,
                                label: '${_speed.toStringAsFixed(2)}x',
                                onChanged: (value) =>
                                    setState(() => _speed = value),
                              ),
                            ),
                            Text('${_speed.toStringAsFixed(2)}x'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Wire the flag into `lib/main.dart`**

In `lib/main.dart`, add these imports below the existing ones:

```dart
import 'app_mode.dart';
import 'viz/workbench/viz_workbench_screen.dart';
```

Replace the `MyApp` class declaration and constructor:

```dart
class MyApp extends StatefulWidget {
  const MyApp({super.key, this.vizMode = kVizMode});

  /// When true the app boots into the viz workbench instead of onboarding.
  final bool vizMode;

  @override
  State<MyApp> createState() => _MyAppState();
}
```

In `_MyAppState.build`, replace `home: _buildCurrentView(),` with:

```dart
      home: widget.vizMode
          ? const VizWorkbenchScreen()
          : _buildCurrentView(),
```

- [ ] **Step 5: Keep the existing flow tests running against the flow**

In `test/widget_test.dart`, change the single `pumpWidget` call inside the
`pumpApp` helper added in Task 0 so the flow tests bypass viz mode:

```dart
    await tester.pumpWidget(const MyApp(vizMode: false));
```

The five test bodies already call `pumpApp(tester)` and need no change.

- [ ] **Step 6: Run the whole suite to verify it passes**

Run: `flutter test`
Expected: PASS — all existing forest and report tests plus the new viz tests.

- [ ] **Step 7: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 8: Look at it**

Run: `flutter run -d linux` (or any available device) and confirm the fox
breathes, walks and runs, that the speed slider and pivot overlay work, and
that nothing on the stage responds to taps.

- [ ] **Step 9: Commit**

```bash
git add lib/app_mode.dart lib/viz/workbench lib/main.dart test/widget_test.dart test/viz/viz_workbench_test.dart
git commit -m "feat(viz): boot into the viz workbench behind kVizMode"
```

---

### Task 5: Deer Gameobject

**Files:**
- Create: `lib/viz/animals/deer.dart`
- Modify: `lib/viz/viz_catalog.dart`
- Test: `test/viz/deer_test.dart`

**Interfaces:**
- Consumes: `VizRig`, `RigPart`, `PartPose`, `Pose`, `ColorSlot`, `VizPalette`, `VizClip`, `ovalPath`, `capsulePath`, `trianglePath`, `curvedPath`.
- Produces: `class Deer extends VizRig` with `id == 'deer'`, canvas `Size(200, 160)`, part ids `antlerFar`, `hindLegFar`, `foreLegFar`, `tail`, `body`, `belly`, `hindLegNear`, `foreLegNear`, `neck`, `ear`, `head`, `antlerNear`, `muzzle`, `eye`.
- Produces: `const VizPalette deerDefaultPalette`.

**Art notes:** taller and leggier than the fox, ground line at y = 148. The run
clip is a *bound* — both fore legs move together, both hind legs move together —
not the fox's alternating gallop.

- [ ] **Step 1: Write the failing deer tests**

Create `test/viz/deer_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/animals/deer.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/rig/viz_rig.dart';
import 'package:moneymoneymoney/viz/viz_catalog.dart';

void main() {
  final deer = Deer();

  test('declares a stable identity and all three clips', () {
    expect(deer.id, 'deer');
    expect(deer.displayName, 'Deer');
    expect(deer.supportedClips, VizClip.values.toSet());
  });

  test('every part has a unique z', () {
    final zs = deer.parts.map((p) => p.z).toList();
    expect(zs.toSet().length, zs.length);
  });

  test('every parent reference resolves to a real part', () {
    final ids = deer.parts.map((p) => p.id).toSet();
    for (final part in deer.parts) {
      if (part.parent != null) {
        expect(ids, contains(part.parent), reason: '${part.id} parent');
      }
    }
  });

  test('both antlers hang off the head', () {
    final byId = {for (final p in deer.parts) p.id: p};
    expect(byId['antlerFar']!.parent, 'head');
    expect(byId['antlerNear']!.parent, 'head');
  });

  test('every clip loops: pose at t=0 matches pose at t->1', () {
    for (final clip in deer.supportedClips) {
      final start = deer.poseAt(clip, 0);
      final end = deer.poseAt(clip, 0.9999);
      for (final id in start.keys) {
        expect(end[id]!.rotation, closeTo(start[id]!.rotation, 0.01),
            reason: '$clip / $id rotation');
        expect(end[id]!.offset.dx, closeTo(start[id]!.offset.dx, 0.05),
            reason: '$clip / $id offset.dx');
        expect(end[id]!.offset.dy, closeTo(start[id]!.offset.dy, 0.05),
            reason: '$clip / $id offset.dy');
        expect(end[id]!.scaleX, closeTo(start[id]!.scaleX, 0.02),
            reason: '$clip / $id scaleX');
        expect(end[id]!.scaleY, closeTo(start[id]!.scaleY, 0.02),
            reason: '$clip / $id scaleY');
      }
    }
  });

  test('walking alternates the near fore and hind legs', () {
    final pose = deer.poseAt(VizClip.walk, 0.125);
    expect(pose['hindLegNear']!.rotation * pose['foreLegNear']!.rotation,
        lessThan(0));
  });

  test('running bounds: near and far fore legs move together', () {
    final pose = deer.poseAt(VizClip.run, 0.125);
    expect(pose['foreLegNear']!.rotation * pose['foreLegFar']!.rotation,
        greaterThan(0));
  });

  test('is registered in the catalog', () {
    expect(VizCatalog.byId('deer'), isA<VizRig>());
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/viz/deer_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/viz/animals/deer.dart'`.

- [ ] **Step 3: Write the deer gameobject**

Create `lib/viz/animals/deer.dart`:

```dart
import 'dart:math' as math;
import 'dart:ui';

import '../rig/color_slot.dart';
import '../rig/shapes.dart';
import '../rig/viz_clip.dart';
import '../rig/viz_palette.dart';
import '../rig/viz_rig.dart';

const VizPalette deerDefaultPalette = VizPalette(
  id: 'deer_default',
  label: 'Deer',
  colors: {
    ColorSlot.primary: Color(0xffb8814f),
    ColorSlot.secondary: Color(0xff8f5f38),
    ColorSlot.belly: Color(0xfff1e2cd),
    ColorSlot.accent: Color(0xffd9b98a),
    ColorSlot.eye: Color(0xff2a2320),
    ColorSlot.outline: Color(0xff3a2d22),
  },
);

/// A two-spike antler branch. [dir] is 1 for the near antler, -1 for the far.
Path _antler(double dir) => Path()
  ..moveTo(0, 0)
  ..cubicTo(2 * dir, -12, 6 * dir, -20, 4 * dir, -30)
  ..cubicTo(10 * dir, -22, 9 * dir, -12, 3 * dir, 0)
  ..close()
  ..addPath(
    trianglePath(
      const Offset(0, -16),
      Offset(12 * dir, -26),
      Offset(6 * dir, -14),
    ),
    Offset.zero,
  );

/// Side-on deer facing right. Design space 200x160, ground line at y = 148.
class Deer extends VizRig {
  @override
  String get id => 'deer';

  @override
  String get displayName => 'Deer';

  @override
  Size get canvasSize => const Size(200, 160);

  @override
  VizPalette get defaultPalette => deerDefaultPalette;

  @override
  Set<VizClip> get supportedClips => VizClip.values.toSet();

  @override
  List<RigPart> get parts => [
    RigPart(
      id: 'antlerFar',
      parent: 'head',
      path: _antler(-1),
      slot: ColorSlot.secondary,
      pivot: const Offset(-4, -11),
      z: 0,
    ),
    RigPart(
      id: 'hindLegFar',
      path: capsulePath(0, 24, 8, 50),
      slot: ColorSlot.secondary,
      pivot: const Offset(74, 100),
      z: 1,
    ),
    RigPart(
      id: 'foreLegFar',
      path: capsulePath(0, 24, 8, 50),
      slot: ColorSlot.secondary,
      pivot: const Offset(128, 100),
      z: 2,
    ),
    RigPart(
      id: 'tail',
      path: ovalPath(0, 6, 7, 10),
      slot: ColorSlot.belly,
      pivot: const Offset(64, 80),
      z: 3,
    ),
    RigPart(
      id: 'body',
      path: ovalPath(0, 0, 40, 24),
      slot: ColorSlot.primary,
      pivot: const Offset(100, 84),
      z: 4,
    ),
    RigPart(
      id: 'belly',
      parent: 'body',
      path: ovalPath(0, 0, 28, 10),
      slot: ColorSlot.belly,
      pivot: const Offset(0, 12),
      z: 5,
    ),
    RigPart(
      id: 'hindLegNear',
      path: capsulePath(0, 24, 8, 50),
      slot: ColorSlot.primary,
      pivot: const Offset(82, 102),
      z: 6,
    ),
    RigPart(
      id: 'foreLegNear',
      path: capsulePath(0, 24, 8, 50),
      slot: ColorSlot.primary,
      pivot: const Offset(136, 102),
      z: 7,
    ),
    RigPart(
      id: 'neck',
      path: capsulePath(6, -16, 20, 44),
      slot: ColorSlot.primary,
      pivot: const Offset(134, 72),
      z: 8,
    ),
    RigPart(
      id: 'ear',
      parent: 'head',
      path: trianglePath(
        const Offset(0, 0),
        const Offset(-15, -9),
        const Offset(-4, 8),
      ),
      slot: ColorSlot.secondary,
      pivot: const Offset(-8, -5),
      z: 9,
    ),
    RigPart(
      id: 'head',
      parent: 'neck',
      path: ovalPath(0, 0, 17, 13),
      slot: ColorSlot.primary,
      pivot: const Offset(14, -38),
      z: 10,
    ),
    RigPart(
      id: 'antlerNear',
      parent: 'head',
      path: _antler(1),
      slot: ColorSlot.secondary,
      pivot: const Offset(4, -12),
      z: 11,
    ),
    RigPart(
      id: 'muzzle',
      parent: 'head',
      path: ovalPath(0, 0, 9, 7),
      slot: ColorSlot.belly,
      pivot: const Offset(15, 4),
      z: 12,
    ),
    RigPart(
      id: 'eye',
      parent: 'head',
      path: ovalPath(0, 0, 2.6, 2.8),
      slot: ColorSlot.eye,
      pivot: const Offset(6, -2),
      z: 13,
    ),
  ];

  @override
  Pose poseAt(VizClip clip, double t) => switch (clip) {
    VizClip.breathe => _breathe(t),
    VizClip.walk => _walk(t),
    VizClip.run => _run(t),
  };

  Pose _breathe(double t) {
    final theta = 2 * math.pi * t;
    return {
      'body': PartPose(
        scaleX: 1 + 0.010 * math.sin(theta),
        scaleY: 1 + 0.030 * math.sin(theta),
      ),
      'belly': PartPose(scaleY: 1 + 0.045 * math.sin(theta)),
      'neck': PartPose(rotation: 0.035 * math.sin(theta + 0.5)),
      'ear': PartPose(rotation: 0.20 * math.max(0, math.sin(4 * theta))),
      'tail': PartPose(rotation: 0.16 * math.sin(2 * theta)),
    };
  }

  Pose _walk(double t) {
    final theta = 2 * math.pi * t;
    final bounce = -1.8 * math.sin(2 * theta).abs();
    return {
      'body': PartPose(offset: Offset(0, bounce)),
      'neck': PartPose(
        offset: Offset(0, bounce),
        rotation: 0.05 * math.sin(theta + 0.3),
      ),
      'tail': PartPose(rotation: 0.14 * math.sin(2 * theta)),
      'hindLegNear': PartPose(rotation: 0.45 * math.sin(theta)),
      'foreLegNear': PartPose(rotation: 0.45 * math.sin(theta + math.pi)),
      'hindLegFar': PartPose(rotation: 0.45 * math.sin(theta + math.pi)),
      'foreLegFar': PartPose(rotation: 0.45 * math.sin(theta)),
    };
  }

  Pose _run(double t) {
    final theta = 2 * math.pi * t;
    final bound = -9.0 * math.sin(theta).abs();
    return {
      'body': PartPose(
        offset: Offset(0, bound),
        rotation: 0.12 * math.sin(theta),
      ),
      'neck': PartPose(
        offset: Offset(0, bound),
        rotation: 0.14 * math.sin(theta) + 0.06,
      ),
      'tail': PartPose(rotation: 0.28 * math.sin(theta) - 0.20),
      'foreLegNear': PartPose(rotation: 0.90 * math.sin(theta)),
      'foreLegFar': PartPose(rotation: 0.82 * math.sin(theta)),
      'hindLegNear': PartPose(rotation: 0.90 * math.sin(theta + math.pi)),
      'hindLegFar': PartPose(rotation: 0.82 * math.sin(theta + math.pi)),
    };
  }
}
```

- [ ] **Step 4: Register the deer in the catalog**

In `lib/viz/viz_catalog.dart`, add `import 'animals/deer.dart';` above the fox
import and change the list to:

```dart
  static List<VizRig> get all =>
      List<VizRig>.unmodifiable(<VizRig>[Fox(), Deer()]);
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 6: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Look at it**

Run the app and select the Deer chip. Check all three clips.

- [ ] **Step 8: Commit**

```bash
git add lib/viz/animals/deer.dart lib/viz/viz_catalog.dart test/viz/deer_test.dart
git commit -m "feat(viz): add deer gameobject with bounding run"
```

---

### Task 6: Hummingbird Gameobject

**Files:**
- Create: `lib/viz/animals/hummingbird.dart`
- Modify: `lib/viz/viz_catalog.dart`
- Test: `test/viz/hummingbird_test.dart`

**Interfaces:**
- Consumes: `VizRig`, `RigPart`, `PartPose`, `Pose`, `ColorSlot`, `VizPalette`, `VizClip`, `ovalPath`, `capsulePath`, `trianglePath`.
- Produces: `class Hummingbird extends VizRig` with `id == 'hummingbird'`, canvas `Size(160, 140)`, part ids `tailFan`, `wingFar`, `body`, `belly`, `legNear`, `head`, `crest`, `throat`, `beak`, `eye`, `wingNear`.
- Produces: `const VizPalette hummingbirdDefaultPalette`.

**Art notes:** the bird never touches the ground. It reinterprets the shared
clips: `breathe` is a slow hover, `walk` is a hovering flit, `run` is a forward
dart. The wing beat frequency multiplier `k` must be an **integer** so the clip
still loops, and wing `scaleX` squash fakes foreshortening at the top and bottom
of the beat.

- [ ] **Step 1: Write the failing hummingbird tests**

Create `test/viz/hummingbird_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/animals/hummingbird.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/rig/viz_rig.dart';
import 'package:moneymoneymoney/viz/viz_catalog.dart';

void main() {
  final bird = Hummingbird();

  test('declares a stable identity and all three clips', () {
    expect(bird.id, 'hummingbird');
    expect(bird.displayName, 'Hummingbird');
    expect(bird.supportedClips, VizClip.values.toSet());
  });

  test('every part has a unique z', () {
    final zs = bird.parts.map((p) => p.z).toList();
    expect(zs.toSet().length, zs.length);
  });

  test('every parent reference resolves to a real part', () {
    final ids = bird.parts.map((p) => p.id).toSet();
    for (final part in bird.parts) {
      if (part.parent != null) {
        expect(ids, contains(part.parent), reason: '${part.id} parent');
      }
    }
  });

  test('both wings hang off the body', () {
    final byId = {for (final p in bird.parts) p.id: p};
    expect(byId['wingNear']!.parent, 'body');
    expect(byId['wingFar']!.parent, 'body');
  });

  test('every clip loops: pose at t=0 matches pose at t->1', () {
    for (final clip in bird.supportedClips) {
      final start = bird.poseAt(clip, 0);
      final end = bird.poseAt(clip, 0.9999);
      for (final id in start.keys) {
        expect(end[id]!.rotation, closeTo(start[id]!.rotation, 0.02),
            reason: '$clip / $id rotation');
        expect(end[id]!.offset.dx, closeTo(start[id]!.offset.dx, 0.05),
            reason: '$clip / $id offset.dx');
        expect(end[id]!.offset.dy, closeTo(start[id]!.offset.dy, 0.05),
            reason: '$clip / $id offset.dy');
        expect(end[id]!.scaleX, closeTo(start[id]!.scaleX, 0.02),
            reason: '$clip / $id scaleX');
        expect(end[id]!.scaleY, closeTo(start[id]!.scaleY, 0.02),
            reason: '$clip / $id scaleY');
      }
    }
  });

  test('wings squash horizontally during the beat', () {
    // At t = 0.025 the 10-beat wing is at the top of its stroke (wing = pi/2),
    // where the squash is deepest. At t = 0.05 it is broadside and scaleX is
    // exactly 1.0.
    final pose = bird.poseAt(VizClip.walk, 0.025);
    expect(pose['wingNear']!.scaleX, lessThan(1.0));
    expect(pose['wingNear']!.scaleX, greaterThan(0.0));
  });

  test('the dart beats the wings harder than the hover', () {
    var hoverPeak = 0.0;
    var dartPeak = 0.0;
    for (var i = 0; i < 200; i++) {
      final t = i / 200;
      hoverPeak = hoverPeak > bird.poseAt(VizClip.walk, t)['wingNear']!
              .rotation.abs()
          ? hoverPeak
          : bird.poseAt(VizClip.walk, t)['wingNear']!.rotation.abs();
      dartPeak = dartPeak > bird.poseAt(VizClip.run, t)['wingNear']!
              .rotation.abs()
          ? dartPeak
          : bird.poseAt(VizClip.run, t)['wingNear']!.rotation.abs();
    }
    expect(dartPeak, greaterThan(hoverPeak));
  });

  test('is registered in the catalog', () {
    expect(VizCatalog.byId('hummingbird'), isA<VizRig>());
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/viz/hummingbird_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/viz/animals/hummingbird.dart'`.

- [ ] **Step 3: Write the hummingbird gameobject**

Create `lib/viz/animals/hummingbird.dart`:

```dart
import 'dart:math' as math;
import 'dart:ui';

import '../rig/color_slot.dart';
import '../rig/shapes.dart';
import '../rig/viz_clip.dart';
import '../rig/viz_palette.dart';
import '../rig/viz_rig.dart';

const VizPalette hummingbirdDefaultPalette = VizPalette(
  id: 'hummingbird_default',
  label: 'Hummingbird',
  colors: {
    ColorSlot.primary: Color(0xff2f9e7a),
    ColorSlot.secondary: Color(0xff1f7a5e),
    ColorSlot.belly: Color(0xfff3efe3),
    ColorSlot.accent: Color(0xffd94f5c),
    ColorSlot.eye: Color(0xff20201e),
    ColorSlot.outline: Color(0xff2a2320),
  },
);

/// Hovering hummingbird facing right. Design space 160x140; it never lands, so
/// there is no ground line.
///
/// Clip reinterpretation: breathe = slow hover, walk = hovering flit,
/// run = forward dart.
class Hummingbird extends VizRig {
  @override
  String get id => 'hummingbird';

  @override
  String get displayName => 'Hummingbird';

  @override
  Size get canvasSize => const Size(160, 140);

  @override
  VizPalette get defaultPalette => hummingbirdDefaultPalette;

  @override
  Set<VizClip> get supportedClips => VizClip.values.toSet();

  @override
  List<RigPart> get parts => [
    RigPart(
      id: 'tailFan',
      path: trianglePath(
        const Offset(0, 0),
        const Offset(-36, -9),
        const Offset(-32, 15),
      ),
      slot: ColorSlot.secondary,
      pivot: const Offset(70, 72),
      z: 0,
    ),
    RigPart(
      id: 'wingFar',
      parent: 'body',
      path: capsulePath(-26, -4, 13, 52),
      slot: ColorSlot.secondary,
      pivot: const Offset(-4, -8),
      z: 1,
    ),
    RigPart(
      id: 'body',
      path: ovalPath(0, 0, 24, 18),
      slot: ColorSlot.primary,
      pivot: const Offset(88, 68),
      z: 2,
    ),
    RigPart(
      id: 'belly',
      parent: 'body',
      path: ovalPath(0, 0, 15, 9),
      slot: ColorSlot.belly,
      pivot: const Offset(-2, 8),
      z: 3,
    ),
    RigPart(
      id: 'legNear',
      parent: 'body',
      path: capsulePath(0, 7, 3.5, 14),
      slot: ColorSlot.outline,
      pivot: const Offset(0, 16),
      z: 4,
    ),
    RigPart(
      id: 'head',
      parent: 'body',
      path: ovalPath(0, 0, 13, 12),
      slot: ColorSlot.primary,
      pivot: const Offset(18, -12),
      z: 5,
    ),
    RigPart(
      id: 'crest',
      parent: 'head',
      path: trianglePath(
        const Offset(0, 0),
        const Offset(-9, -9),
        const Offset(2, -10),
      ),
      slot: ColorSlot.accent,
      pivot: const Offset(-2, -10),
      z: 6,
    ),
    RigPart(
      id: 'throat',
      parent: 'head',
      path: ovalPath(0, 0, 8, 6),
      slot: ColorSlot.accent,
      pivot: const Offset(2, 8),
      z: 7,
    ),
    RigPart(
      id: 'beak',
      parent: 'head',
      path: trianglePath(
        const Offset(0, -2),
        const Offset(32, 1),
        const Offset(0, 4),
      ),
      slot: ColorSlot.outline,
      pivot: const Offset(11, 2),
      z: 8,
    ),
    RigPart(
      id: 'eye',
      parent: 'head',
      path: ovalPath(0, 0, 2.4, 2.6),
      slot: ColorSlot.eye,
      pivot: const Offset(4, -2),
      z: 9,
    ),
    RigPart(
      id: 'wingNear',
      parent: 'body',
      path: capsulePath(-26, -2, 14, 52),
      slot: ColorSlot.primary,
      pivot: const Offset(2, -6),
      z: 10,
    ),
  ];

  @override
  Pose poseAt(VizClip clip, double t) => switch (clip) {
    VizClip.breathe => _beat(t, beats: 6, amplitude: 0.45, bob: 1.5, pitch: 0),
    VizClip.walk => _beat(t, beats: 10, amplitude: 1.00, bob: 3.0, pitch: 0),
    VizClip.run => _beat(t, beats: 14, amplitude: 1.25, bob: 2.0, pitch: -0.18),
  };

  /// [beats] must be an integer so the clip closes its loop.
  Pose _beat(
    double t, {
    required int beats,
    required double amplitude,
    required double bob,
    required double pitch,
  }) {
    final theta = 2 * math.pi * t;
    final wing = beats * theta;
    // The wing is broadside as it sweeps through the middle of the stroke and
    // foreshortens at the top and bottom, so a flat capsule reads as a wing
    // rather than a spinning stick.
    final squash = 0.55 + 0.45 * math.cos(wing).abs();
    return {
      'body': PartPose(
        offset: Offset(0, -bob * math.sin(2 * theta)),
        rotation: pitch,
      ),
      'wingNear': PartPose(
        rotation: amplitude * math.sin(wing),
        scaleX: squash,
      ),
      'wingFar': PartPose(
        rotation: amplitude * 0.9 * math.sin(wing + 0.4),
        scaleX: squash,
      ),
      'head': PartPose(rotation: 0.06 * math.sin(theta)),
      'tailFan': PartPose(rotation: 0.12 * math.sin(2 * theta) - pitch),
      'legNear': PartPose(rotation: 0.10 * math.sin(2 * theta)),
    };
  }
}
```

- [ ] **Step 4: Register the hummingbird in the catalog**

In `lib/viz/viz_catalog.dart`, add `import 'animals/hummingbird.dart';` and
change the list to:

```dart
  static List<VizRig> get all =>
      List<VizRig>.unmodifiable(<VizRig>[Fox(), Deer(), Hummingbird()]);
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 6: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Look at it**

Run the app, select Hummingbird, and check the wing beat at 0.25x speed — the
squash should make the stroke read as a wing rather than a spinning stick.

- [ ] **Step 8: Commit**

```bash
git add lib/viz/animals/hummingbird.dart lib/viz/viz_catalog.dart test/viz/hummingbird_test.dart
git commit -m "feat(viz): add hummingbird gameobject with squashed wing beat"
```

---

### Task 7: Raccoon Gameobject

**Executor:** opencode MiMo V2.5. Invoke with:

```bash
opencode run -m opencode/mimo-v2.5-free \
  --dir /home/jostev/Projects/moneymoneymoney \
  "Implement Task 7 of docs/superpowers/viz-animals/plan.md exactly as written. Read docs/superpowers/viz-animals/spec.md first. Do not modify any file outside the ones the task lists."
```

**Files:**
- Create: `lib/viz/animals/raccoon.dart`
- Modify: `lib/viz/viz_catalog.dart`
- Test: `test/viz/raccoon_test.dart`

**Interfaces:**
- Consumes: `VizRig`, `RigPart`, `PartPose`, `Pose`, `ColorSlot`, `VizPalette`, `VizClip`, `ovalPath`, `capsulePath`, `trianglePath`.
- Produces: `class Raccoon extends VizRig` with `id == 'raccoon'`, canvas `Size(200, 140)`, part ids `tail`, `tailRing1`, `tailRing2`, `tailRing3`, `hindLegFar`, `foreLegFar`, `body`, `belly`, `hindLegNear`, `foreLegNear`, `earFar`, `head`, `earNear`, `mask`, `snout`, `nose`, `eyeFar`, `eyeNear`.
- Produces: `const VizPalette raccoonDefaultPalette`.

**Art notes:** low, broad body; ground line at y = 130. The ringed tail is three
dark bands parented to the tail so they follow its sway. The face mask is a dark
band across the eyes, drawn under the snout and eyes.

- [ ] **Step 1: Write the failing raccoon tests**

Create `test/viz/raccoon_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/animals/raccoon.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/rig/viz_rig.dart';
import 'package:moneymoneymoney/viz/viz_catalog.dart';

void main() {
  final raccoon = Raccoon();

  test('declares a stable identity and all three clips', () {
    expect(raccoon.id, 'raccoon');
    expect(raccoon.displayName, 'Raccoon');
    expect(raccoon.supportedClips, VizClip.values.toSet());
  });

  test('every part has a unique z', () {
    final zs = raccoon.parts.map((p) => p.z).toList();
    expect(zs.toSet().length, zs.length);
  });

  test('every parent reference resolves to a real part', () {
    final ids = raccoon.parts.map((p) => p.id).toSet();
    for (final part in raccoon.parts) {
      if (part.parent != null) {
        expect(ids, contains(part.parent), reason: '${part.id} parent');
      }
    }
  });

  test('all three tail rings are parented to the tail', () {
    final byId = {for (final p in raccoon.parts) p.id: p};
    for (final ring in ['tailRing1', 'tailRing2', 'tailRing3']) {
      expect(byId[ring]!.parent, 'tail');
    }
  });

  test('the mask draws behind the snout and the eyes', () {
    final byId = {for (final p in raccoon.parts) p.id: p};
    expect(byId['mask']!.z, lessThan(byId['snout']!.z));
    expect(byId['mask']!.z, lessThan(byId['eyeNear']!.z));
  });

  test('every clip loops: pose at t=0 matches pose at t->1', () {
    for (final clip in raccoon.supportedClips) {
      final start = raccoon.poseAt(clip, 0);
      final end = raccoon.poseAt(clip, 0.9999);
      for (final id in start.keys) {
        expect(end[id]!.rotation, closeTo(start[id]!.rotation, 0.01),
            reason: '$clip / $id rotation');
        expect(end[id]!.offset.dx, closeTo(start[id]!.offset.dx, 0.05),
            reason: '$clip / $id offset.dx');
        expect(end[id]!.offset.dy, closeTo(start[id]!.offset.dy, 0.05),
            reason: '$clip / $id offset.dy');
        expect(end[id]!.scaleX, closeTo(start[id]!.scaleX, 0.02),
            reason: '$clip / $id scaleX');
        expect(end[id]!.scaleY, closeTo(start[id]!.scaleY, 0.02),
            reason: '$clip / $id scaleY');
      }
    }
  });

  test('walking alternates the near fore and hind legs', () {
    final pose = raccoon.poseAt(VizClip.walk, 0.125);
    expect(pose['hindLegNear']!.rotation * pose['foreLegNear']!.rotation,
        lessThan(0));
  });

  test('running swings the legs harder than walking', () {
    final walk =
        raccoon.poseAt(VizClip.walk, 0.25)['hindLegNear']!.rotation.abs();
    final run =
        raccoon.poseAt(VizClip.run, 0.25)['hindLegNear']!.rotation.abs();
    expect(run, greaterThan(walk));
  });

  test('is registered in the catalog', () {
    expect(VizCatalog.byId('raccoon'), isA<VizRig>());
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/viz/raccoon_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/viz/animals/raccoon.dart'`.

- [ ] **Step 3: Write the raccoon gameobject**

Create `lib/viz/animals/raccoon.dart`:

```dart
import 'dart:math' as math;
import 'dart:ui';

import '../rig/color_slot.dart';
import '../rig/shapes.dart';
import '../rig/viz_clip.dart';
import '../rig/viz_palette.dart';
import '../rig/viz_rig.dart';

const VizPalette raccoonDefaultPalette = VizPalette(
  id: 'raccoon_default',
  label: 'Raccoon',
  colors: {
    ColorSlot.primary: Color(0xff8d8f96),
    ColorSlot.secondary: Color(0xff6d6f77),
    ColorSlot.belly: Color(0xffe6e3da),
    ColorSlot.accent: Color(0xffb9bcc4),
    ColorSlot.eye: Color(0xfff2efe6),
    ColorSlot.outline: Color(0xff2f3136),
  },
);

/// Side-on raccoon facing right. Design space 200x140, ground line at y = 130.
class Raccoon extends VizRig {
  @override
  String get id => 'raccoon';

  @override
  String get displayName => 'Raccoon';

  @override
  Size get canvasSize => const Size(200, 140);

  @override
  VizPalette get defaultPalette => raccoonDefaultPalette;

  @override
  Set<VizClip> get supportedClips => VizClip.values.toSet();

  @override
  List<RigPart> get parts => [
    RigPart(
      id: 'tail',
      path: capsulePath(-24, -6, 64, 22),
      slot: ColorSlot.secondary,
      pivot: const Offset(58, 80),
      z: 0,
    ),
    RigPart(
      id: 'tailRing1',
      parent: 'tail',
      path: capsulePath(0, 0, 10, 21),
      slot: ColorSlot.outline,
      pivot: const Offset(-10, -3),
      z: 1,
    ),
    RigPart(
      id: 'tailRing2',
      parent: 'tail',
      path: capsulePath(0, 0, 10, 20),
      slot: ColorSlot.outline,
      pivot: const Offset(-25, -5),
      z: 2,
    ),
    RigPart(
      id: 'tailRing3',
      parent: 'tail',
      path: capsulePath(0, 0, 10, 18),
      slot: ColorSlot.outline,
      pivot: const Offset(-40, -7),
      z: 3,
    ),
    RigPart(
      id: 'hindLegFar',
      path: capsulePath(0, 17, 11, 34),
      slot: ColorSlot.secondary,
      pivot: const Offset(80, 96),
      z: 4,
    ),
    RigPart(
      id: 'foreLegFar',
      path: capsulePath(0, 16, 10, 32),
      slot: ColorSlot.secondary,
      pivot: const Offset(130, 98),
      z: 5,
    ),
    RigPart(
      id: 'body',
      path: ovalPath(0, 0, 42, 28),
      slot: ColorSlot.primary,
      pivot: const Offset(102, 80),
      z: 6,
    ),
    RigPart(
      id: 'belly',
      parent: 'body',
      path: ovalPath(0, 0, 26, 12),
      slot: ColorSlot.belly,
      pivot: const Offset(0, 12),
      z: 7,
    ),
    RigPart(
      id: 'hindLegNear',
      path: capsulePath(0, 17, 11, 34),
      slot: ColorSlot.primary,
      pivot: const Offset(90, 98),
      z: 8,
    ),
    RigPart(
      id: 'foreLegNear',
      path: capsulePath(0, 16, 10, 32),
      slot: ColorSlot.primary,
      pivot: const Offset(138, 100),
      z: 9,
    ),
    RigPart(
      id: 'earFar',
      parent: 'head',
      path: trianglePath(
        const Offset(0, 6),
        const Offset(-7, -13),
        const Offset(9, -4),
      ),
      slot: ColorSlot.primary,
      pivot: const Offset(-12, -14),
      z: 10,
    ),
    RigPart(
      id: 'head',
      path: ovalPath(0, 0, 24, 21),
      slot: ColorSlot.primary,
      pivot: const Offset(146, 62),
      z: 11,
    ),
    RigPart(
      id: 'earNear',
      parent: 'head',
      path: trianglePath(
        const Offset(0, 6),
        const Offset(4, -14),
        const Offset(13, -2),
      ),
      slot: ColorSlot.primary,
      pivot: const Offset(10, -16),
      z: 12,
    ),
    RigPart(
      id: 'mask',
      parent: 'head',
      path: ovalPath(0, 0, 19, 8),
      slot: ColorSlot.outline,
      pivot: const Offset(2, -1),
      z: 13,
    ),
    RigPart(
      id: 'snout',
      parent: 'head',
      path: ovalPath(0, 0, 11, 8),
      slot: ColorSlot.belly,
      pivot: const Offset(14, 7),
      z: 14,
    ),
    RigPart(
      id: 'nose',
      parent: 'head',
      path: ovalPath(0, 0, 3.4, 2.8),
      slot: ColorSlot.outline,
      pivot: const Offset(22, 6),
      z: 15,
    ),
    RigPart(
      id: 'eyeFar',
      parent: 'head',
      path: ovalPath(0, 0, 2.8, 3),
      slot: ColorSlot.eye,
      pivot: const Offset(-5, -2),
      z: 16,
    ),
    RigPart(
      id: 'eyeNear',
      parent: 'head',
      path: ovalPath(0, 0, 2.8, 3),
      slot: ColorSlot.eye,
      pivot: const Offset(9, -2),
      z: 17,
    ),
  ];

  @override
  Pose poseAt(VizClip clip, double t) => switch (clip) {
    VizClip.breathe => _breathe(t),
    VizClip.walk => _walk(t),
    VizClip.run => _run(t),
  };

  Pose _breathe(double t) {
    final theta = 2 * math.pi * t;
    return {
      'body': PartPose(
        scaleX: 1 + 0.014 * math.sin(theta),
        scaleY: 1 + 0.038 * math.sin(theta),
      ),
      'belly': PartPose(scaleY: 1 + 0.05 * math.sin(theta)),
      'head': PartPose(offset: Offset(0, 1.8 * math.sin(theta + 0.6))),
      'tail': PartPose(rotation: 0.12 * math.sin(theta)),
      'earNear': PartPose(rotation: 0.16 * math.max(0, math.sin(3 * theta))),
    };
  }

  Pose _walk(double t) {
    final theta = 2 * math.pi * t;
    final bounce = -1.6 * math.sin(2 * theta).abs();
    return {
      'body': PartPose(offset: Offset(0, bounce)),
      'head': PartPose(
        offset: Offset(0, bounce),
        rotation: 0.05 * math.sin(theta + 0.4),
      ),
      'tail': PartPose(rotation: 0.20 * math.sin(theta + 0.8)),
      'hindLegNear': PartPose(rotation: 0.50 * math.sin(theta)),
      'foreLegNear': PartPose(rotation: 0.50 * math.sin(theta + math.pi)),
      'hindLegFar': PartPose(rotation: 0.50 * math.sin(theta + math.pi)),
      'foreLegFar': PartPose(rotation: 0.50 * math.sin(theta)),
    };
  }

  Pose _run(double t) {
    final theta = 2 * math.pi * t;
    final bound = -5.0 * math.sin(theta).abs();
    return {
      'body': PartPose(
        offset: Offset(0, bound),
        rotation: 0.09 * math.sin(theta),
      ),
      'head': PartPose(
        offset: Offset(0, bound),
        rotation: 0.09 * math.sin(theta) + 0.06,
      ),
      'tail': PartPose(rotation: 0.34 * math.sin(theta + 0.5) - 0.14),
      'hindLegNear': PartPose(rotation: 0.88 * math.sin(theta)),
      'hindLegFar': PartPose(rotation: 0.88 * math.sin(theta + 0.35)),
      'foreLegNear': PartPose(rotation: 0.88 * math.sin(theta + math.pi)),
      'foreLegFar': PartPose(
        rotation: 0.88 * math.sin(theta + math.pi + 0.35),
      ),
    };
  }
}
```

- [ ] **Step 4: Register the raccoon in the catalog**

In `lib/viz/viz_catalog.dart`, add `import 'animals/raccoon.dart';` and change
the list to:

```dart
  static List<VizRig> get all => List<VizRig>.unmodifiable(<VizRig>[
    Fox(),
    Deer(),
    Hummingbird(),
    Raccoon(),
  ]);
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 6: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Look at it**

Run the app and select Raccoon. Confirm the tail rings sway with the tail and
the mask sits under the eyes.

- [ ] **Step 8: Commit**

```bash
git add lib/viz/animals/raccoon.dart lib/viz/viz_catalog.dart test/viz/raccoon_test.dart
git commit -m "feat(viz): add raccoon gameobject with ringed tail and face mask"
```

---

### Task 8: Wealth Tree Gameobject

**Files:**
- Create: `lib/viz/tree/wealth_tree.dart`
- Modify: `lib/viz/viz_catalog.dart`
- Test: `test/viz/wealth_tree_test.dart`

**Interfaces:**
- Consumes: `VizRig`, `RigPart`, `PartPose`, `Pose`, `ColorSlot`, `VizPalette`, `VizClip`, `ovalPath`, `capsulePath`, `curvedPath`.
- Produces: `class WealthTree extends VizRig { WealthTree({required int stage}); final int stage; }` — `stage` 0 is withered, 1 is a sapling, 2 is a medium tree, 3 is a mature tree. `id` is `'tree_$stage'`; `displayName` is `'Tree · Withered'`, `'Tree · L1'`, `'Tree · L2'`, `'Tree · L3'`.
- Produces: `const VizPalette wealthTreeDefaultPalette` and `const VizPalette witheredTreePalette`.
- Produces: `class TreeCatalog { static List<WealthTree> get stages; }` returning stages 0, 1, 2, 3.

**Art notes:** the tree only supports `breathe`, which is a slow canopy sway.
The stage controls how many canopy blobs are present and how tall the trunk is;
the withered stage uses a separate brown palette and drops the canopy to bare
branches.

- [ ] **Step 1: Write the failing tree tests**

Create `test/viz/wealth_tree_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/rig/viz_rig.dart';
import 'package:moneymoneymoney/viz/tree/wealth_tree.dart';
import 'package:moneymoneymoney/viz/viz_catalog.dart';

void main() {
  test('exposes four stages with distinct ids and labels', () {
    final ids = TreeCatalog.stages.map((t) => t.id).toList();
    expect(ids, ['tree_0', 'tree_1', 'tree_2', 'tree_3']);
    expect(TreeCatalog.stages.first.displayName, 'Tree · Withered');
    expect(TreeCatalog.stages.last.displayName, 'Tree · L3');
  });

  test('supports breathe only', () {
    expect(WealthTree(stage: 3).supportedClips, {VizClip.breathe});
  });

  test('canopy grows with the stage', () {
    int canopyCount(int stage) => WealthTree(stage: stage)
        .parts
        .where((p) => p.id.startsWith('canopy'))
        .length;
    expect(canopyCount(0), 0);
    expect(canopyCount(1), lessThan(canopyCount(2)));
    expect(canopyCount(2), lessThan(canopyCount(3)));
  });

  test('the withered stage uses the withered palette', () {
    expect(WealthTree(stage: 0).defaultPalette.id, 'tree_withered');
    expect(WealthTree(stage: 2).defaultPalette.id, 'tree_default');
  });

  test('every stage has unique z values and resolvable parents', () {
    for (final tree in TreeCatalog.stages) {
      final zs = tree.parts.map((p) => p.z).toList();
      expect(zs.toSet().length, zs.length, reason: tree.id);
      final ids = tree.parts.map((p) => p.id).toSet();
      for (final part in tree.parts) {
        if (part.parent != null) {
          expect(ids, contains(part.parent), reason: '${tree.id}/${part.id}');
        }
      }
    }
  });

  test('the sway loops', () {
    for (final tree in TreeCatalog.stages) {
      final start = tree.poseAt(VizClip.breathe, 0);
      final end = tree.poseAt(VizClip.breathe, 0.9999);
      for (final id in start.keys) {
        expect(end[id]!.rotation, closeTo(start[id]!.rotation, 0.01),
            reason: '${tree.id} / $id rotation');
        expect(end[id]!.offset.dx, closeTo(start[id]!.offset.dx, 0.05),
            reason: '${tree.id} / $id offset.dx');
        expect(end[id]!.offset.dy, closeTo(start[id]!.offset.dy, 0.05),
            reason: '${tree.id} / $id offset.dy');
        expect(end[id]!.scaleX, closeTo(start[id]!.scaleX, 0.02),
            reason: '${tree.id} / $id scaleX');
        expect(end[id]!.scaleY, closeTo(start[id]!.scaleY, 0.02),
            reason: '${tree.id} / $id scaleY');
      }
    }
  });

  test('every stage is registered in the catalog', () {
    for (final stage in [0, 1, 2, 3]) {
      expect(VizCatalog.byId('tree_$stage'), isA<VizRig>());
    }
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/viz/wealth_tree_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/viz/tree/wealth_tree.dart'`.

- [ ] **Step 3: Write the tree gameobject**

Create `lib/viz/tree/wealth_tree.dart`:

```dart
import 'dart:math' as math;
import 'dart:ui';

import '../rig/color_slot.dart';
import '../rig/shapes.dart';
import '../rig/viz_clip.dart';
import '../rig/viz_palette.dart';
import '../rig/viz_rig.dart';

const VizPalette wealthTreeDefaultPalette = VizPalette(
  id: 'tree_default',
  label: 'Wealth Tree',
  colors: {
    ColorSlot.primary: Color(0xff2f7d50),
    ColorSlot.secondary: Color(0xff6b4a2f),
    ColorSlot.belly: Color(0xff3f9b64),
    ColorSlot.accent: Color(0xffc79a33),
    ColorSlot.eye: Color(0xff2a2320),
    ColorSlot.outline: Color(0xff24402f),
  },
);

const VizPalette witheredTreePalette = VizPalette(
  id: 'tree_withered',
  label: 'Withered Tree',
  colors: {
    ColorSlot.primary: Color(0xff8a6a4f),
    ColorSlot.secondary: Color(0xff6a4f39),
    ColorSlot.belly: Color(0xff9c8163),
    ColorSlot.accent: Color(0xffb59a6f),
    ColorSlot.eye: Color(0xff2a2320),
    ColorSlot.outline: Color(0xff4a3626),
  },
);

/// The central tree of the Wealth Forest, at one of four growth stages.
///
/// Stage 0 is withered (bare branches, brown palette); stages 1 to 3 are a
/// sapling, a medium tree and a mature tree.
class WealthTree extends VizRig {
  WealthTree({required this.stage}) : assert(stage >= 0 && stage <= 3);

  final int stage;

  @override
  String get id => 'tree_$stage';

  @override
  String get displayName => switch (stage) {
    0 => 'Tree · Withered',
    1 => 'Tree · L1',
    2 => 'Tree · L2',
    _ => 'Tree · L3',
  };

  @override
  Size get canvasSize => const Size(200, 200);

  @override
  VizPalette get defaultPalette =>
      stage == 0 ? witheredTreePalette : wealthTreeDefaultPalette;

  @override
  Set<VizClip> get supportedClips => const {VizClip.breathe};

  double get _trunkHeight => switch (stage) {
    0 => 70,
    1 => 52,
    2 => 78,
    _ => 96,
  };

  /// Canopy blobs as (dx, dy, radiusX, radiusY, slot) in trunk-top space.
  List<(double, double, double, double, ColorSlot)> get _canopy =>
      switch (stage) {
        0 => const [],
        1 => const [(0, -14, 26, 22, ColorSlot.primary)],
        2 => const [
          (-20, -10, 26, 22, ColorSlot.primary),
          (20, -12, 26, 22, ColorSlot.primary),
          (0, -30, 30, 26, ColorSlot.belly),
        ],
        _ => const [
          (-34, -8, 28, 24, ColorSlot.primary),
          (34, -10, 28, 24, ColorSlot.primary),
          (-14, -34, 32, 28, ColorSlot.belly),
          (18, -36, 32, 28, ColorSlot.belly),
          (0, -58, 30, 26, ColorSlot.primary),
        ],
      };

  @override
  List<RigPart> get parts {
    final parts = <RigPart>[
      RigPart(
        id: 'mound',
        path: ovalPath(0, 6, 52, 12),
        slot: ColorSlot.outline,
        pivot: const Offset(100, 176),
        z: 0,
      ),
      RigPart(
        id: 'trunk',
        path: capsulePath(0, -_trunkHeight / 2, 18, _trunkHeight),
        slot: ColorSlot.secondary,
        pivot: const Offset(100, 176),
        z: 1,
      ),
      RigPart(
        id: 'branchLeft',
        parent: 'trunk',
        path: capsulePath(-14, -8, 9, 34),
        slot: ColorSlot.secondary,
        pivot: Offset(0, -_trunkHeight + 12),
        z: 2,
      ),
      RigPart(
        id: 'branchRight',
        parent: 'trunk',
        path: capsulePath(14, -8, 9, 34),
        slot: ColorSlot.secondary,
        pivot: Offset(0, -_trunkHeight + 20),
        z: 3,
      ),
    ];

    var z = 4;
    for (var i = 0; i < _canopy.length; i++) {
      final (dx, dy, rx, ry, slot) = _canopy[i];
      parts.add(
        RigPart(
          id: 'canopy$i',
          parent: 'trunk',
          path: ovalPath(0, 0, rx, ry),
          slot: slot,
          pivot: Offset(dx, -_trunkHeight + dy),
          z: z++,
        ),
      );
    }

    if (stage == 3) {
      parts.add(
        RigPart(
          id: 'fruit',
          parent: 'trunk',
          path: ovalPath(0, 0, 6, 6),
          slot: ColorSlot.accent,
          pivot: Offset(22, -_trunkHeight - 18),
          z: z++,
        ),
      );
    }

    return parts;
  }

  @override
  Pose poseAt(VizClip clip, double t) {
    final theta = 2 * math.pi * t;
    final sway = 0.030 * math.sin(theta);
    final pose = <String, PartPose>{
      'trunk': PartPose(rotation: sway * 0.4),
      'branchLeft': PartPose(rotation: sway * 1.4),
      'branchRight': PartPose(rotation: -sway * 1.2),
    };
    for (var i = 0; i < _canopy.length; i++) {
      pose['canopy$i'] = PartPose(
        rotation: sway * (1.0 + 0.3 * i),
        scaleX: 1 + 0.012 * math.sin(theta + i),
        scaleY: 1 + 0.012 * math.sin(theta + i),
      );
    }
    if (stage == 3) {
      pose['fruit'] = PartPose(rotation: sway * 2.0);
    }
    return pose;
  }
}

/// The four tree stages, in growth order.
class TreeCatalog {
  const TreeCatalog._();

  static List<WealthTree> get stages =>
      [for (var stage = 0; stage <= 3; stage++) WealthTree(stage: stage)];
}
```

- [ ] **Step 4: Register the tree stages in the catalog**

Replace the whole body of `lib/viz/viz_catalog.dart` with:

```dart
import 'animals/deer.dart';
import 'animals/fox.dart';
import 'animals/hummingbird.dart';
import 'animals/raccoon.dart';
import 'rig/viz_rig.dart';
import 'tree/wealth_tree.dart';

/// Registry of every viz gameobject the workbench can show.
///
/// Each gameobject adds exactly one line here and nothing else.
class VizCatalog {
  const VizCatalog._();

  static List<VizRig> get all => List<VizRig>.unmodifiable(<VizRig>[
    Fox(),
    Deer(),
    Hummingbird(),
    Raccoon(),
    ...TreeCatalog.stages,
  ]);

  static VizRig byId(String id) => all.firstWhere((rig) => rig.id == id);
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 6: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Look at it**

Run the app and step through all four tree chips. The Walk and Run chips must be
disabled while a tree is selected.

- [ ] **Step 8: Commit**

```bash
git add lib/viz/tree lib/viz/viz_catalog.dart test/viz/wealth_tree_test.dart
git commit -m "feat(viz): add wealth tree gameobject with four growth stages"
```
