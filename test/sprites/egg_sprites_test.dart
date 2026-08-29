import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/sprites/egg_sprites.dart';

Future<ui.Image> decode(String path) async {
  final data = await rootBundle.load(path);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  return (await codec.getNextFrame()).image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('four variants times four clips', () {
    expect(EggVariant.values, hasLength(4));
    expect(EggClip.values, hasLength(4));
    expect(EggSprites.allPaths, hasLength(16));
    expect(EggSprites.allPaths.toSet(), hasLength(16));
  });

  test('only the hatch is a one-shot', () {
    expect(EggClip.hatch.loops, isFalse);
    expect(EggClip.idle.loops, isTrue);
    expect(EggClip.rock.loops, isTrue);
    expect(EggClip.bounce.loops, isTrue);
  });

  test('paths follow the variant_clip convention', () {
    expect(
      EggSprites.path(EggVariant.purple, EggClip.hatch),
      'assets/eggs/purple_hatch.png',
    );
  });

  test('every strip is registered and as wide as its frame count', () async {
    for (final variant in EggVariant.values) {
      for (final clip in EggClip.values) {
        final path = EggSprites.path(variant, clip);
        final image = await decode(path);
        expect(image.height, 32, reason: path);
        expect(image.width, clip.frameCount * 32, reason: path);
      }
    }
  });

  test('a strip knows its own frame count', () {
    final hatch = EggSprites.strip(EggVariant.cream, EggClip.hatch);
    expect(hatch.frameCount, 12);
    expect(hatch.isAnimated, isTrue);
    expect(hatch.assetPath, 'assets/eggs/cream_hatch.png');
  });

  test('the hatch runs about as long as the source animation', () {
    final hatch = EggSprites.strip(EggVariant.cream, EggClip.hatch);
    expect(hatch.duration.inMilliseconds, closeTo(1791, 5));
  });
}
