# Placeholder Actors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all in-game art with coloured labelled boxes that squash, stretch, and wander, so mechanics can be built and judged before real assets exist.

**Architecture:** `PlaceholderActor` is a small data class (id, label, colour, size, kind). `SquashStretch` and `WanderMotion` are pure functions of phase/time — no state, no `Random` at paint time. `PlaceholderBoxPainter` draws a rounded rect plus a `TextPainter` label. `ActorField` hosts several actors, drives one ticker, and wraps everything in `IgnorePointer`.

**Tech Stack:** Flutter Material, Dart, `dart:math`, `CustomPainter`, `TextPainter`, `flutter_test`. No new package dependencies.

**Spec:** `docs/superpowers/placeholder-actors/spec.md`

## Global Constraints

- **No new package dependencies.** `pubspec.yaml` must not change.
- **Draw-only.** Nothing in `lib/placeholder/` handles a gesture, mutates app state, reads app state, navigates, or calls a service. `ActorField` wraps its subtree in `IgnorePointer`.
- **Squash and stretch must preserve volume**: `scaleX * scaleY == 1` at every phase, within 1e-9.
- **Wander must be a pure function of `(seed, t)`** — never `Random()` at paint time, and never a sum of integer-frequency sines (those visibly loop).
- **No golden-file tests.**
- `flutter analyze` must print exactly `No issues found!` and `flutter test` must pass before every commit.
- Do not modify anything under `lib/viz/` — those rigs stay committed and green.

---

## File Structure

- `lib/placeholder/placeholder_actor.dart` — the actor data class and `ActorKind`.
- `lib/placeholder/motion/squash_stretch.dart` — volume-preserving scale pair.
- `lib/placeholder/motion/value_noise.dart` — seeded 1-D value noise.
- `lib/placeholder/motion/wander_motion.dart` — noise-driven position in bounds.
- `lib/placeholder/placeholder_box_painter.dart` — box + label painter.
- `lib/placeholder/actor_field.dart` — ticker-driven multi-actor host.
- `lib/placeholder/actor_catalog.dart` — the seven placeholder actors.
- `test/placeholder/motion_test.dart`, `actor_catalog_test.dart`, `actor_field_test.dart`.

---

### Task 1: Motion Primitives

**Files:**
- Create: `lib/placeholder/motion/squash_stretch.dart`
- Create: `lib/placeholder/motion/value_noise.dart`
- Create: `lib/placeholder/motion/wander_motion.dart`
- Test: `test/placeholder/motion_test.dart`

**Interfaces:**
- Produces: `class ScalePair { const ScalePair(double x, double y); final double x, y; }`
- Produces: `ScalePair squashStretch(double t, {double amplitude = 0.08})`
- Produces: `double hash01(int seed, int i)`
- Produces: `double noise1(int seed, double t)`
- Produces: `class WanderMotion { const WanderMotion({required int seed, required Size bounds, required Size actorSize, double period = 8.0}); Offset positionAt(double seconds); bool facingRightAt(double seconds); }`

- [ ] **Step 1: Write the failing motion tests**

Create `test/placeholder/motion_test.dart`:

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/placeholder/motion/squash_stretch.dart';
import 'package:moneymoneymoney/placeholder/motion/value_noise.dart';
import 'package:moneymoneymoney/placeholder/motion/wander_motion.dart';

void main() {
  group('squashStretch', () {
    test('preserves volume at every phase', () {
      for (var i = 0; i <= 100; i++) {
        final s = squashStretch(i / 100);
        expect(s.x * s.y, closeTo(1.0, 1e-9), reason: 'phase ${i / 100}');
      }
    });

    test('both squashes and stretches across a cycle', () {
      var minY = double.infinity;
      var maxY = double.negativeInfinity;
      for (var i = 0; i < 200; i++) {
        final y = squashStretch(i / 200).y;
        minY = y < minY ? y : minY;
        maxY = y > maxY ? y : maxY;
      }
      expect(minY, lessThan(1.0));
      expect(maxY, greaterThan(1.0));
    });

    test('closes its loop', () {
      final a = squashStretch(0);
      final b = squashStretch(0.9999);
      expect(b.y, closeTo(a.y, 0.001));
    });

    test('amplitude scales the effect', () {
      final small = squashStretch(0.25, amplitude: 0.05).y;
      final large = squashStretch(0.25, amplitude: 0.20).y;
      expect((large - 1).abs(), greaterThan((small - 1).abs()));
    });
  });

  group('value noise', () {
    test('hash01 is deterministic and in range', () {
      for (var i = 0; i < 50; i++) {
        final a = hash01(7, i);
        expect(a, hash01(7, i));
        expect(a, inInclusiveRange(0.0, 1.0));
      }
    });

    test('hash01 differs across seeds and indices', () {
      expect(hash01(1, 0), isNot(closeTo(hash01(2, 0), 1e-6)));
      expect(hash01(1, 0), isNot(closeTo(hash01(1, 1), 1e-6)));
    });

    test('noise1 is deterministic', () {
      expect(noise1(3, 1.75), noise1(3, 1.75));
    });

    test('noise1 stays in range', () {
      for (var i = 0; i < 300; i++) {
        expect(noise1(5, i * 0.13), inInclusiveRange(0.0, 1.0));
      }
    });

    test('noise1 drifts rather than teleporting', () {
      // Continuity: tiny steps in t must give tiny changes in value.
      var previous = noise1(9, 0);
      for (var i = 1; i < 500; i++) {
        final current = noise1(9, i * 0.01);
        expect((current - previous).abs(), lessThan(0.06), reason: 'step $i');
        previous = current;
      }
    });

    test('noise1 does not simply repeat each lattice step', () {
      // A looping implementation would give identical values one unit apart.
      var identical = 0;
      for (var i = 0; i < 40; i++) {
        if ((noise1(11, i + 0.5) - noise1(11, i + 1.5)).abs() < 1e-9) {
          identical++;
        }
      }
      expect(identical, lessThan(3));
    });
  });

  group('WanderMotion', () {
    const bounds = Size(400, 300);
    const actorSize = Size(60, 40);
    const motion = WanderMotion(seed: 42, bounds: bounds, actorSize: actorSize);

    test('keeps the actor fully inside the bounds', () {
      for (var i = 0; i < 400; i++) {
        final p = motion.positionAt(i * 0.25);
        expect(p.dx, greaterThanOrEqualTo(0));
        expect(p.dy, greaterThanOrEqualTo(0));
        expect(p.dx + actorSize.width, lessThanOrEqualTo(bounds.width));
        expect(p.dy + actorSize.height, lessThanOrEqualTo(bounds.height));
      }
    });

    test('is deterministic for a seed', () {
      expect(motion.positionAt(3.3), motion.positionAt(3.3));
    });

    test('different seeds wander differently', () {
      const other = WanderMotion(
        seed: 43,
        bounds: bounds,
        actorSize: actorSize,
      );
      expect(motion.positionAt(3.3), isNot(other.positionAt(3.3)));
    });

    test('actually moves', () {
      expect(motion.positionAt(0), isNot(motion.positionAt(9.0)));
    });

    test('reports a facing direction', () {
      expect(motion.facingRightAt(1.0), isA<bool>());
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/placeholder/motion_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/placeholder/motion/squash_stretch.dart'`.

- [ ] **Step 3: Write the motion primitives**

Create `lib/placeholder/motion/squash_stretch.dart`:

```dart
import 'dart:math' as math;

/// A non-uniform scale whose components multiply to 1.
class ScalePair {
  const ScalePair(this.x, this.y);

  final double x;
  final double y;
}

/// Volume-preserving squash and stretch at loop phase [t] in [0, 1).
///
/// A squashed shape must get wider as it gets shorter, or it reads as a rubber
/// blob instead of a solid object under load. Keeping x * y == 1 is what sells
/// it. [amplitude] above about 0.15 starts to look comical.
ScalePair squashStretch(double t, {double amplitude = 0.08}) {
  final k = 1 + amplitude * math.sin(2 * math.pi * t);
  return ScalePair(1 / k, k);
}
```

Create `lib/placeholder/motion/value_noise.dart`:

```dart
import 'dart:math' as math;

/// Deterministic hash of a lattice point to [0, 1).
///
/// Integer mixing rather than `Random`, so the same (seed, i) always gives the
/// same value with no object to carry around.
double hash01(int seed, int i) {
  var h = (seed * 374761393 + i * 668265263) & 0x7fffffff;
  h = (h ^ (h >> 13)) * 1274126177 & 0x7fffffff;
  h = h ^ (h >> 16);
  return (h & 0xffffff) / 0x1000000;
}

/// Smooth 1-D value noise: a hashed lattice with smoothstep interpolation.
///
/// Pure and testable like a sine sum, but without a sine sum's visible loop, so
/// wander never repeats a path the eye can learn.
double noise1(int seed, double t) {
  final i = t.floor();
  final f = t - i;
  final a = hash01(seed, i);
  final b = hash01(seed, i + 1);
  final smooth = f * f * (3 - 2 * f);
  return a + (b - a) * smooth;
}

/// Value noise mapped to [-1, 1].
double noiseSigned(int seed, double t) => noise1(seed, t) * 2 - 1;

/// Kept for callers that want a quick angle from a noise channel.
double noiseAngle(int seed, double t) => noise1(seed, t) * 2 * math.pi;
```

Create `lib/placeholder/motion/wander_motion.dart`:

```dart
import 'dart:ui';

import 'value_noise.dart';

/// Slow, seeded drift inside a rectangle.
///
/// Position is a pure function of time, so it is reproducible and unit-testable,
/// and an actor resumes exactly where it should after a rebuild.
class WanderMotion {
  const WanderMotion({
    required this.seed,
    required this.bounds,
    required this.actorSize,
    this.period = 8.0,
  });

  final int seed;
  final Size bounds;
  final Size actorSize;

  /// Seconds per noise lattice step. Larger is slower and calmer.
  final double period;

  double get _maxX =>
      (bounds.width - actorSize.width).clamp(0.0, double.infinity);

  double get _maxY =>
      (bounds.height - actorSize.height).clamp(0.0, double.infinity);

  /// Top-left of the actor at [seconds].
  Offset positionAt(double seconds) {
    final t = seconds / period;
    return Offset(noise1(seed, t) * _maxX, noise1(seed ^ 0x5f3759df, t) * _maxY);
  }

  /// True when the actor is drifting rightwards, sampled just ahead in time.
  bool facingRightAt(double seconds) {
    const lookahead = 0.15;
    return positionAt(seconds + lookahead).dx >= positionAt(seconds).dx;
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/placeholder/motion_test.dart`
Expected: PASS, 15 tests.

- [ ] **Step 5: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/placeholder/motion test/placeholder/motion_test.dart
git commit -m "feat(placeholder): add squash-stretch and seeded wander motion"
```

---

### Task 2: Actor, Painter, Field And Catalog

**Files:**
- Create: `lib/placeholder/placeholder_actor.dart`
- Create: `lib/placeholder/placeholder_box_painter.dart`
- Create: `lib/placeholder/actor_field.dart`
- Create: `lib/placeholder/actor_catalog.dart`
- Test: `test/placeholder/actor_catalog_test.dart`
- Test: `test/placeholder/actor_field_test.dart`

**Interfaces:**
- Consumes: `squashStretch`, `ScalePair`, `WanderMotion` from Task 1.
- Produces: `enum ActorKind { animal, item }`
- Produces: `class PlaceholderActor { const PlaceholderActor({required String id, required String label, required Color color, required Size size, required ActorKind kind}); }`
- Produces: `class PlaceholderBoxPainter extends CustomPainter { PlaceholderBoxPainter({required PlaceholderActor actor, required Offset position, required ScalePair scale}); }`
- Produces: `class ActorField extends StatefulWidget { const ActorField({super.key, required List<PlaceholderActor> actors, double speed = 1.0}); }`
- Produces: `class ActorCatalog { static List<PlaceholderActor> get all; static PlaceholderActor byId(String id); static List<PlaceholderActor> get animals; }`

- [ ] **Step 1: Write the failing catalog and field tests**

Create `test/placeholder/actor_catalog_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/placeholder/actor_catalog.dart';
import 'package:moneymoneymoney/placeholder/placeholder_actor.dart';

void main() {
  test('every actor has a unique id', () {
    final ids = ActorCatalog.all.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('holds the seven placeholder subjects', () {
    expect(ActorCatalog.all.length, 7);
    final ids = ActorCatalog.all.map((a) => a.id).toSet();
    expect(ids, containsAll(<String>[
      'fox',
      'deer',
      'hummingbird',
      'raccoon',
      'coin',
      'egg',
      'xp_orb',
    ]));
  });

  test('every actor has a non-empty label and a positive size', () {
    for (final actor in ActorCatalog.all) {
      expect(actor.label, isNotEmpty, reason: actor.id);
      expect(actor.size.width, greaterThan(0), reason: actor.id);
      expect(actor.size.height, greaterThan(0), reason: actor.id);
    }
  });

  test('the four animals are the animal-kind actors', () {
    expect(ActorCatalog.animals.length, 4);
    for (final actor in ActorCatalog.animals) {
      expect(actor.kind, ActorKind.animal);
    }
  });

  test('byId throws for an unknown actor', () {
    expect(() => ActorCatalog.byId('nope'), throwsStateError);
  });
}
```

Create `test/placeholder/actor_field_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/placeholder/actor_catalog.dart';
import 'package:moneymoneymoney/placeholder/actor_field.dart';
import 'package:moneymoneymoney/placeholder/placeholder_box_painter.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(width: 400, height: 300, child: child)),
  );

  testWidgets('paints one box per actor', (tester) async {
    await tester.pumpWidget(host(ActorField(actors: ActorCatalog.animals)));
    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((p) => p.painter is PlaceholderBoxPainter);
    expect(painters.length, ActorCatalog.animals.length);
  });

  testWidgets('ignores pointer events', (tester) async {
    await tester.pumpWidget(host(ActorField(actors: ActorCatalog.animals)));
    expect(
      find.descendant(
        of: find.byType(ActorField),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
  });

  testWidgets('actors move as time advances', (tester) async {
    await tester.pumpWidget(host(ActorField(actors: ActorCatalog.animals)));

    PlaceholderBoxPainter first() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<PlaceholderBoxPainter>()
        .first;

    final before = first().position;
    await tester.pump(const Duration(seconds: 2));
    expect(first().position, isNot(before));
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/placeholder/`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/placeholder/actor_catalog.dart'`.

- [ ] **Step 3: Write the actor and the painter**

Create `lib/placeholder/placeholder_actor.dart`:

```dart
import 'dart:ui';

/// Animals wander their field; items hold station and only pulse.
enum ActorKind { animal, item }

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

  final String id;

  /// Drawn centred in the box, e.g. 'FOX'.
  final String label;

  final Color color;

  /// Design-space size before squash and stretch.
  final Size size;

  final ActorKind kind;
}
```

Create `lib/placeholder/placeholder_box_painter.dart`:

```dart
import 'package:flutter/material.dart';

import 'motion/squash_stretch.dart';
import 'placeholder_actor.dart';

/// Draws one placeholder actor: a rounded rect plus its label.
class PlaceholderBoxPainter extends CustomPainter {
  PlaceholderBoxPainter({
    required this.actor,
    required this.position,
    required this.scale,
  });

  final PlaceholderActor actor;

  /// Top-left of the unscaled box.
  final Offset position;

  final ScalePair scale;

  @override
  void paint(Canvas canvas, Size size) {
    final w = actor.size.width * scale.x;
    final h = actor.size.height * scale.y;
    // Scale about the bottom centre so a squash reads as weight on the ground.
    final left = position.dx + (actor.size.width - w) / 2;
    final top = position.dy + (actor.size.height - h);
    final rect = Rect.fromLTWH(left, top, w, h);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = actor.color,
    );

    final luminance = actor.color.computeLuminance();
    final painter = TextPainter(
      text: TextSpan(
        text: actor.label,
        style: TextStyle(
          color: luminance > 0.5 ? const Color(0xff20201e) : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);

    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(PlaceholderBoxPainter oldDelegate) =>
      oldDelegate.position != position ||
      oldDelegate.scale.x != scale.x ||
      oldDelegate.scale.y != scale.y ||
      oldDelegate.actor != actor;
}
```

- [ ] **Step 4: Write the field and the catalog**

Create `lib/placeholder/actor_field.dart`:

```dart
import 'package:flutter/material.dart';

import 'motion/squash_stretch.dart';
import 'motion/wander_motion.dart';
import 'placeholder_actor.dart';
import 'placeholder_box_painter.dart';

/// Hosts several placeholder actors on one ticker.
///
/// Draw-only: the subtree is wrapped in [IgnorePointer].
class ActorField extends StatefulWidget {
  const ActorField({super.key, required this.actors, this.speed = 1.0});

  final List<PlaceholderActor> actors;

  /// Playback multiplier for both wander and pulse.
  final double speed;

  @override
  State<ActorField> createState() => _ActorFieldState();
}

class _ActorFieldState extends State<ActorField>
    with SingleTickerProviderStateMixin {
  /// One long cycle; wander reads elapsed seconds, not loop phase.
  static const Duration _cycle = Duration(seconds: 60);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _cycle,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounds = Size(constraints.maxWidth, constraints.maxHeight);
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final seconds =
                  _controller.value * _cycle.inSeconds * widget.speed;
              return Stack(
                children: [
                  for (var i = 0; i < widget.actors.length; i++)
                    _actorLayer(widget.actors[i], i, seconds, bounds),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _actorLayer(
    PlaceholderActor actor,
    int index,
    double seconds,
    Size bounds,
  ) {
    final isAnimal = actor.kind == ActorKind.animal;
    final motion = WanderMotion(
      seed: actor.id.hashCode ^ (index * 7919),
      bounds: bounds,
      actorSize: actor.size,
    );
    final position = isAnimal
        ? motion.positionAt(seconds)
        : Offset(
            (bounds.width - actor.size.width) / 2,
            (bounds.height - actor.size.height) / 2,
          );
    // Stagger phases so a row of actors does not pulse in lockstep.
    final phase = (seconds / 2.2 + index * 0.37) % 1.0;
    return Positioned.fill(
      child: CustomPaint(
        painter: PlaceholderBoxPainter(
          actor: actor,
          position: position,
          scale: squashStretch(phase, amplitude: isAnimal ? 0.10 : 0.05),
        ),
      ),
    );
  }
}
```

Create `lib/placeholder/actor_catalog.dart`:

```dart
import 'package:flutter/material.dart';

import 'placeholder_actor.dart';

/// Every placeholder subject in the app.
///
/// These stand in for art that does not exist yet; real assets replace the
/// painter, not this table.
class ActorCatalog {
  const ActorCatalog._();

  static final List<PlaceholderActor> all =
      List<PlaceholderActor>.unmodifiable(<PlaceholderActor>[
        const PlaceholderActor(
          id: 'fox',
          label: 'FOX',
          color: Color(0xffd96a2e),
          size: Size(78, 52),
          kind: ActorKind.animal,
        ),
        const PlaceholderActor(
          id: 'deer',
          label: 'DEER',
          color: Color(0xffb8814f),
          size: Size(80, 62),
          kind: ActorKind.animal,
        ),
        const PlaceholderActor(
          id: 'hummingbird',
          label: 'HUMMER',
          color: Color(0xff2f9e7a),
          size: Size(64, 40),
          kind: ActorKind.animal,
        ),
        const PlaceholderActor(
          id: 'raccoon',
          label: 'RACOON',
          color: Color(0xff8d8f96),
          size: Size(76, 50),
          kind: ActorKind.animal,
        ),
        const PlaceholderActor(
          id: 'coin',
          label: 'COIN',
          color: Color(0xffe0b33c),
          size: Size(48, 48),
          kind: ActorKind.item,
        ),
        const PlaceholderActor(
          id: 'egg',
          label: 'EGG',
          color: Color(0xffefe3cd),
          size: Size(46, 56),
          kind: ActorKind.item,
        ),
        const PlaceholderActor(
          id: 'xp_orb',
          label: 'XP',
          color: Color(0xff4fb8ff),
          size: Size(44, 44),
          kind: ActorKind.item,
        ),
      ]);

  static List<PlaceholderActor> get animals =>
      all.where((a) => a.kind == ActorKind.animal).toList();

  static PlaceholderActor byId(String id) => all.firstWhere((a) => a.id == id);
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/placeholder/`
Expected: PASS.

- [ ] **Step 6: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/placeholder test/placeholder
git commit -m "feat(placeholder): add labelled box actors, painter, field and catalog"
```
