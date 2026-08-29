import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:moneymoneymoney/models/shop_item.dart';
import 'package:moneymoneymoney/services/item_visuals.dart';
import 'package:moneymoneymoney/services/shop_service.dart';

ShopItem _item(String id) =>
    kShopCatalog.firstWhere((item) => item.id == id);

void main() {
  group('treeSkinIcon', () {
    test('classic oak escalates icon with level when no other skin equipped', () {
      expect(
        treeSkinIcon(equippedId: 'tree-classic-oak', level: 1),
        Icons.eco,
      );
      expect(
        treeSkinIcon(equippedId: 'tree-classic-oak', level: 2),
        Icons.park,
      );
      expect(
        treeSkinIcon(equippedId: 'tree-classic-oak', level: 3),
        Icons.forest,
      );
    });

    test('a distinct skin overrides the level-based icon', () {
      expect(
        treeSkinIcon(equippedId: 'tree-cherry-blossom', level: 1),
        Icons.local_florist,
      );
    });
  });

  group('groundColor / skyColor', () {
    test('default ground and sky use the meadow/clear-day colors', () {
      final state = ShopService().initialState();

      expect(groundColor(state), const Color(0xffdcefd9));
      expect(skyColor(state), Colors.white);
    });

    test('equipping riverbank ground changes the ground color', () {
      final state = ShopService().equip(
        itemId: 'ground-riverbank',
        state: ShopState(
          ownedItemIds: {
            ...ShopService().initialState().ownedItemIds,
            'ground-riverbank',
          },
          equippedItemIds: ShopService().initialState().equippedItemIds,
        ),
      );

      expect(groundColor(state), const Color(0xffcfe8ea));
    });
  });

  group('shopItemVisual', () {
    test('every catalog item resolves to a visual', () {
      for (final item in kShopCatalog) {
        final visual = shopItemVisual(item);
        expect(visual.icon, isNotNull);
      }
    });

    test('a decoration item resolves to its dedicated icon', () {
      final visual = shopItemVisual(_item('deco-beehive'));

      expect(visual.icon, Icons.hive);
    });
  });
}
