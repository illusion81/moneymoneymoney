import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/shop_item.dart';
import 'package:moneymoneymoney/services/item_visuals.dart';
import 'package:moneymoneymoney/ui/market_icon.dart';
import 'package:moneymoneymoney/ui/shop_item_icon.dart';

void main() {
  test('shop catalog items do not yet have a market-icon match', () {
    for (final item in kShopCatalog) {
      expect(
        shopItemVisual(item).marketIcon,
        isNull,
        reason: '${item.id} has no genuine market-sheet match yet',
      );
    }
  });

  testWidgets('falls back to the Material icon when no market icon maps', (
    tester,
  ) async {
    final visual = shopItemVisual(
      kShopCatalog.firstWhere((i) => i.id == 'deco-beehive'),
    );

    await tester.pumpWidget(
      MaterialApp(home: ShopItemIcon(visual: visual)),
    );

    expect(find.byType(MarketIconImage), findsNothing);
    expect(find.byType(Icon), findsOneWidget);
    expect(tester.widget<Icon>(find.byType(Icon)).icon, Icons.hive);
  });

  testWidgets('renders the pixel-art icon when a visual carries one', (
    tester,
  ) async {
    const visual = ShopItemVisual(
      icon: Icons.lock,
      color: Color(0xffc79a33),
      marketIcon: MarketIcon.lockedSkin,
    );

    await tester.pumpWidget(
      MaterialApp(home: ShopItemIcon(visual: visual, size: 16)),
    );

    expect(find.byType(MarketIconImage), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 16);
    expect(image.height, 16);
    expect(image.filterQuality, FilterQuality.none);
    expect(image.isAntiAlias, isFalse);
  });
}
