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
