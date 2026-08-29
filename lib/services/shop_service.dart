import '../models/progression.dart';
import '../models/shop_item.dart';

class ShopService {
  List<ShopItem> catalog() => kShopCatalog;

  List<ShopItem> itemsFor(ShopItemCategory category) {
    return kShopCatalog.where((item) => item.category == category).toList();
  }

  ShopState initialState() {
    final defaults = kShopCatalog.where((item) => item.isDefault);
    return ShopState(
      ownedItemIds: {for (final item in defaults) item.id},
      equippedItemIds: {for (final item in defaults) item.category: item.id},
    );
  }

  PurchaseResult purchase({
    required String itemId,
    required ShopState state,
    required ProgressionState progression,
    bool isPlusMember = false,
  }) {
    final item = _findItem(itemId);
    if (item == null) {
      return PurchaseResult(
        success: false,
        failure: PurchaseFailure.unknownItem,
        state: state,
        progression: progression,
        message: 'That item does not exist.',
      );
    }
    if (state.ownedItemIds.contains(itemId)) {
      return PurchaseResult(
        success: false,
        failure: PurchaseFailure.alreadyOwned,
        state: state,
        progression: progression,
        message: '${item.name} is already owned.',
      );
    }
    if (item.plusOnly && !isPlusMember) {
      return PurchaseResult(
        success: false,
        failure: PurchaseFailure.plusRequired,
        state: state,
        progression: progression,
        message: '${item.name} is a Plus member exclusive.',
      );
    }
    if (progression.level.level < item.requiredLevel) {
      return PurchaseResult(
        success: false,
        failure: PurchaseFailure.levelTooLow,
        state: state,
        progression: progression,
        message: 'Reach level ${item.requiredLevel} to unlock ${item.name}.',
      );
    }
    if (progression.coinBalance < item.price) {
      return PurchaseResult(
        success: false,
        failure: PurchaseFailure.insufficientCoins,
        state: state,
        progression: progression,
        message: 'Not enough coins. ${item.name} costs ${item.price} coins.',
      );
    }

    final updatedState = ShopState(
      ownedItemIds: {...state.ownedItemIds, itemId},
      equippedItemIds: state.equippedItemIds,
    );
    final spendEvent = RewardEvent(
      date: DateTime.now(),
      type: RewardEventType.purchaseSpend,
      xp: 0,
      coins: -item.price,
      description: 'Purchased ${item.name}',
    );
    final updatedProgression = ProgressionState(
      totalXp: progression.totalXp,
      level: progression.level,
      coinBalance: progression.coinBalance - item.price,
      lifetimeCoinsEarned: progression.lifetimeCoinsEarned,
      lifetimeCoinsSpent: progression.lifetimeCoinsSpent + item.price,
      ledger: [...progression.ledger, spendEvent],
    );

    return PurchaseResult(
      success: true,
      failure: null,
      state: updatedState,
      progression: updatedProgression,
      message: '${item.name} purchased.',
    );
  }

  ShopState equip({required String itemId, required ShopState state}) {
    final item = _findItem(itemId);
    if (item == null || !state.ownedItemIds.contains(itemId)) {
      return state;
    }

    return ShopState(
      ownedItemIds: state.ownedItemIds,
      equippedItemIds: {...state.equippedItemIds, item.category: itemId},
    );
  }

  ShopItem? _findItem(String itemId) {
    for (final item in kShopCatalog) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }
}
