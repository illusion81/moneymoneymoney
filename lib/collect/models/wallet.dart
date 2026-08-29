/// Soft-currency balance. Coins are whole numbers; the app never touches real
/// money. The beta grant is displayed as currency because that reads as a gift
/// rather than a score.
class Wallet {
  const Wallet({required this.coins});

  /// Every new beta player starts here.
  const Wallet.beta() : coins = betaGrantCoins;

  static const int betaGrantCoins = 20;

  final int coins;

  bool canAfford(int amount) => coins >= amount;

  Wallet earn(int amount) {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must not be negative');
    }
    return Wallet(coins: coins + amount);
  }

  Wallet spend(int amount) {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must not be negative');
    }
    if (!canAfford(amount)) {
      throw StateError('Cannot spend $amount coins from a balance of $coins');
    }
    return Wallet(coins: coins - amount);
  }

  /// e.g. '$20.00' — used for the beta credit line.
  String get creditLabel => '\$${coins.toStringAsFixed(2)}';
}