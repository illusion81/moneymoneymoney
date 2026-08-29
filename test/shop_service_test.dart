import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/progression.dart';
import 'package:moneymoneymoney/models/shop_item.dart';
import 'package:moneymoneymoney/services/shop_service.dart';

ProgressionState _progressionAt({
  required int level,
  required int coinBalance,
}) {
  return ProgressionState(
    totalXp: 0,
    level: LevelProgress(
      level: level,
      xpIntoLevel: 0,
      xpForNextLevel: 100,
      fraction: 0,
    ),
    coinBalance: coinBalance,
    lifetimeCoinsEarned: coinBalance,
    lifetimeCoinsSpent: 0,
    ledger: const [],
  );
}

void main() {
  final service = ShopService();

  group('ShopService', () {
    test('default items are owned and equipped in initialState', () {
      final state = service.initialState();

      expect(state.ownedItemIds, contains('tree-classic-oak'));
      expect(state.ownedItemIds, contains('ground-meadow'));
      expect(state.ownedItemIds, contains('sky-clear-day'));
      expect(
        state.equippedItemIds[ShopItemCategory.treeSkin],
        'tree-classic-oak',
      );
      expect(state.equippedItemIds[ShopItemCategory.ground], 'ground-meadow');
      expect(state.equippedItemIds[ShopItemCategory.sky], 'sky-clear-day');
    });

    test(
      'purchase succeeds and deducts coins when balance and level both suffice',
      () {
        final state = service.initialState();
        final progression = _progressionAt(level: 2, coinBalance: 200);

        final result = service.purchase(
          itemId: 'tree-golden-ginkgo',
          state: state,
          progression: progression,
        );

        expect(result.success, isTrue);
        expect(result.state.ownedItemIds, contains('tree-golden-ginkgo'));
        expect(result.progression.coinBalance, 80);
      },
    );

    test(
      'purchase fails with insufficientCoins and leaves the balance untouched',
      () {
        final state = service.initialState();
        final progression = _progressionAt(level: 2, coinBalance: 10);

        final result = service.purchase(
          itemId: 'tree-golden-ginkgo',
          state: state,
          progression: progression,
        );

        expect(result.success, isFalse);
        expect(result.failure, PurchaseFailure.insufficientCoins);
        expect(result.progression.coinBalance, 10);
        expect(
          result.state.ownedItemIds,
          isNot(contains('tree-golden-ginkgo')),
        );
      },
    );

    test('purchase fails with levelTooLow for a level-gated item', () {
      final state = service.initialState();
      final progression = _progressionAt(level: 1, coinBalance: 500);

      final result = service.purchase(
        itemId: 'tree-golden-ginkgo',
        state: state,
        progression: progression,
      );

      expect(result.success, isFalse);
      expect(result.failure, PurchaseFailure.levelTooLow);
      expect(result.progression.coinBalance, 500);
    });

    test(
      're-purchasing an owned item fails with alreadyOwned and does not deduct',
      () {
        final state = service.initialState();
        final progression = _progressionAt(level: 5, coinBalance: 500);

        final result = service.purchase(
          itemId: 'tree-classic-oak',
          state: state,
          progression: progression,
        );

        expect(result.success, isFalse);
        expect(result.failure, PurchaseFailure.alreadyOwned);
        expect(result.progression.coinBalance, 500);
      },
    );

    test(
      'decoration items purchase like any other category, without an equip slot',
      () {
        final state = service.initialState();
        final progression = _progressionAt(level: 1, coinBalance: 200);

        final result = service.purchase(
          itemId: 'deco-garden-lantern',
          state: state,
          progression: progression,
        );

        expect(result.success, isTrue);
        expect(result.state.ownedItemIds, contains('deco-garden-lantern'));
        expect(result.progression.coinBalance, 200 - 80);
        expect(
          result.state.equippedItemIds.containsKey(ShopItemCategory.decoration),
          isFalse,
        );
      },
    );

    test('no decoration item is owned by default', () {
      final state = service.initialState();

      final ownedDecorations = state.ownedItemIds.where(
        (id) =>
            kShopCatalog.firstWhere((item) => item.id == id).category ==
            ShopItemCategory.decoration,
      );

      expect(ownedDecorations, isEmpty);
    });

    test('equipping replaces the previous item in the same category only', () {
      var state = service.initialState();
      state = ShopState(
        ownedItemIds: {...state.ownedItemIds, 'tree-golden-ginkgo'},
        equippedItemIds: state.equippedItemIds,
      );

      final equipped = service.equip(
        itemId: 'tree-golden-ginkgo',
        state: state,
      );

      expect(
        equipped.equippedItemIds[ShopItemCategory.treeSkin],
        'tree-golden-ginkgo',
      );
      expect(
        equipped.equippedItemIds[ShopItemCategory.ground],
        'ground-meadow',
      );
      expect(equipped.equippedItemIds[ShopItemCategory.sky], 'sky-clear-day');
    });
  });
}
