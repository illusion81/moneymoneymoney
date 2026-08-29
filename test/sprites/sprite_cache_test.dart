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
