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