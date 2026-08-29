import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/sprites/asset_paths.dart';
import 'package:moneymoneymoney/ui/market_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every role maps to a registered icon', () async {
    for (final icon in MarketIcon.values) {
      expect(SpriteAssets.iconNames, contains(icon.iconName), reason: icon.name);
      final data = await rootBundle.load(icon.assetPath);
      expect(data.lengthInBytes, greaterThan(0), reason: icon.name);
    }
  });

  test('roles the collectables screens need are present', () {
    final names = MarketIcon.values.map((i) => i.name).toSet();
    expect(names, containsAll(<String>[
      'coin',
      'xp',
      'wallet',
      'achievement',
      'lootbox',
    ]));
  });

  testWidgets('renders at the requested size without smoothing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MarketIconImage(icon: MarketIcon.coin, size: 32)),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 32);
    expect(image.height, 32);
    expect(image.filterQuality, FilterQuality.none);
    expect(image.isAntiAlias, isFalse);
  });

  test('the egg stand-in is gone now that eggs have their own pack', () {
    expect(MarketIcon.values.map((i) => i.name), isNot(contains('egg')));
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
