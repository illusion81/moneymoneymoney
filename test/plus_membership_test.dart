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

  group('Plus-only catalog', () {
    test('the last item of every category is Plus-only', () {
      for (final category in ShopItemCategory.values) {
        final items = service.itemsFor(category);
        expect(
          items.last.plusOnly,
          isTrue,
          reason: '${category.name} last item',
        );
      }
    });

    test('no other item in a category is Plus-only', () {
      for (final category in ShopItemCategory.values) {
        final items = service.itemsFor(category);
        final allButLast = items.sublist(0, items.length - 1);
        expect(
          allButLast.every((item) => !item.plusOnly),
          isTrue,
          reason: '${category.name} non-last items',
        );
      }
    });

    test('no default (free starter) item is Plus-only', () {
      expect(
        kShopCatalog.where((i) => i.isDefault).every((i) => !i.plusOnly),
        isTrue,
      );
    });
  });

  group('purchasing a Plus-only item', () {
    test('is refused for a non-member even with coins and level', () {
      final result = service.purchase(
        itemId: 'tree-crystal-pine',
        state: service.initialState(),
        progression: _progressionAt(level: 50, coinBalance: 99999),
        isPlusMember: false,
      );

      expect(result.success, isFalse);
      expect(result.failure, PurchaseFailure.plusRequired);
      expect(result.progression.coinBalance, 99999);
    });

    test('succeeds for a Plus member who can afford it', () {
      final result = service.purchase(
        itemId: 'tree-crystal-pine',
        state: service.initialState(),
        progression: _progressionAt(level: 50, coinBalance: 99999),
        isPlusMember: true,
      );

      expect(result.success, isTrue);
      expect(result.state.ownedItemIds, contains('tree-crystal-pine'));
    });

    test('a Plus member still needs enough coins', () {
      final result = service.purchase(
        itemId: 'tree-crystal-pine',
        state: service.initialState(),
        progression: _progressionAt(level: 50, coinBalance: 10),
        isPlusMember: true,
      );

      expect(result.success, isFalse);
      expect(result.failure, PurchaseFailure.insufficientCoins);
    });

    test('a non-Plus item is unaffected by membership', () {
      final result = service.purchase(
        itemId: 'tree-golden-ginkgo',
        state: service.initialState(),
        progression: _progressionAt(level: 50, coinBalance: 500),
        isPlusMember: false,
      );

      expect(result.success, isTrue);
    });
  });
}
