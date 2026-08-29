// Diamond purchases.
//
// READ THIS BEFORE WIRING ANYTHING REAL.
//
// Apple Pay and Google Pay are NOT the mechanism for selling in-app currency.
// They are for physical goods and real-world services. Selling diamonds — a
// digital good consumed inside the app — has to go through Apple's StoreKit
// (In-App Purchase) and Google Play Billing. Shipping an app that sells
// currency via Apple Pay gets it rejected under App Review 3.1.1 and Google
// Play's Payments policy.
//
// So the real implementation is the `in_app_purchase` Flutter plugin talking to
// StoreKit / Play Billing, with product IDs registered in App Store Connect and
// the Play Console, and receipt validation on our server. None of that can
// exist without paid developer accounts and signed builds, so this file ships a
// mock gateway instead — it runs the same interface, takes no money, and says
// so on screen.
//
// To go live, implement RealPaymentGateway against `in_app_purchase` and swap
// which gateway the app constructs. Nothing else has to change.

import 'dart:async';

class DiamondPack {
  const DiamondPack({
    required this.id,
    required this.diamonds,
    required this.priceLabel,
    required this.bonus,
  });

  final String id;
  final int diamonds;
  final String priceLabel;

  /// Extra diamonds over the base rate, for the "best value" badge.
  final int bonus;
}

/// Product IDs would be registered under these names in App Store Connect and
/// the Play Console.
const List<DiamondPack> kDiamondPacks = [
  DiamondPack(id: 'diamonds_100', diamonds: 100, priceLabel: r'$1.49', bonus: 0),
  DiamondPack(id: 'diamonds_550', diamonds: 550, priceLabel: r'$6.99', bonus: 50),
  DiamondPack(id: 'diamonds_1200', diamonds: 1200, priceLabel: r'$13.99', bonus: 200),
];

enum PaymentOutcome { success, cancelled, failed, unavailable }

class PaymentResult {
  const PaymentResult({required this.outcome, this.diamonds = 0, this.message = ''});

  final PaymentOutcome outcome;
  final int diamonds;
  final String message;

  bool get ok => outcome == PaymentOutcome.success;
}

abstract class PaymentGateway {
  /// Whether real store billing is available on this device/build.
  bool get isLive;

  /// Human label for where the charge would go.
  String get storeName;

  Future<PaymentResult> buy(DiamondPack pack);
}

/// Demo gateway. Takes no money, never touches a card, and is the only
/// gateway wired up right now.
class MockPaymentGateway implements PaymentGateway {
  @override
  bool get isLive => false;

  @override
  String get storeName => 'Demo (no payment taken)';

  @override
  Future<PaymentResult> buy(DiamondPack pack) async {
    // Simulate the round trip to a store so the UI's loading state is real.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return PaymentResult(
      outcome: PaymentOutcome.success,
      diamonds: pack.diamonds + pack.bonus,
      message: 'Demo purchase — no payment was taken.',
    );
  }
}

/// Sketch of the real thing, deliberately not wired up.
///
///   final iap = InAppPurchase.instance;
///   final response = await iap.queryProductDetails({'diamonds_100', ...});
///   await iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: p));
///   // then verify the receipt SERVER-SIDE before granting diamonds —
///   // never trust the client's word that a purchase happened.
class RealPaymentGateway implements PaymentGateway {
  @override
  bool get isLive => false; // flip once StoreKit/Play products exist

  @override
  String get storeName => 'App Store / Google Play';

  @override
  Future<PaymentResult> buy(DiamondPack pack) async => const PaymentResult(
        outcome: PaymentOutcome.unavailable,
        message: 'Store billing is not configured in this build.',
      );
}
