import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/screens/plus_screen.dart';

void main() {
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1000,
      2600,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  Widget harness({
    bool isPlusMember = false,
    VoidCallback? onSubscribe,
    VoidCallback? onCancel,
    VoidCallback? onBuyFreeze,
  }) {
    return MaterialApp(
      home: PlusScreen(
        isPlusMember: isPlusMember,
        onSubscribe: onSubscribe ?? () {},
        onCancelMembership: onCancel ?? () {},
        onBuyFreezeTicket: onBuyFreeze ?? () {},
        onBack: () {},
      ),
    );
  }

  testWidgets('always shows a prominent demo notice', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.byKey(const Key('plus-demo-banner')), findsOneWidget);
    expect(find.textContaining('Demo'), findsWidgets);
  });

  testWidgets('a non-member sees the subscribe call to action', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.byKey(const Key('plus-subscribe-button')), findsOneWidget);
    expect(find.byKey(const Key('plus-cancel-button')), findsNothing);
  });

  testWidgets('the checkout sheet never asks for card details', (tester) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.byKey(const Key('plus-subscribe-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plus-checkout-sheet')), findsOneWidget);
    // A demo must not present anything that invites real payment details.
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('confirming the demo checkout activates membership', (
    tester,
  ) async {
    var subscribed = false;
    await tester.pumpWidget(harness(onSubscribe: () => subscribed = true));

    await tester.tap(find.byKey(const Key('plus-subscribe-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('plus-confirm-button')));
    await tester.pumpAndSettle();

    expect(subscribed, isTrue);
  });

  testWidgets('a member sees membership as active and can cancel', (
    tester,
  ) async {
    var cancelled = false;
    await tester.pumpWidget(
      harness(isPlusMember: true, onCancel: () => cancelled = true),
    );

    expect(find.byKey(const Key('plus-active-badge')), findsOneWidget);
    expect(find.byKey(const Key('plus-subscribe-button')), findsNothing);

    await tester.tap(find.byKey(const Key('plus-cancel-button')));
    await tester.pumpAndSettle();

    expect(cancelled, isTrue);
  });

  testWidgets('a freeze streak ticket is offered at 99 cents', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.byKey(const Key('freeze-ticket-card')), findsOneWidget);
    expect(find.textContaining('Freeze'), findsWidgets);
    expect(find.text('\$0.99'), findsWidgets);
  });

  testWidgets('members can buy a ticket too', (tester) async {
    await tester.pumpWidget(harness(isPlusMember: true));

    expect(find.byKey(const Key('freeze-ticket-card')), findsOneWidget);
  });

  testWidgets('buying a ticket goes through the demo checkout first', (
    tester,
  ) async {
    var bought = false;
    await tester.pumpWidget(harness(onBuyFreeze: () => bought = true));

    final card = find.byKey(const Key('freeze-ticket-card'));
    await tester.ensureVisible(card);
    await tester.pump();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plus-checkout-sheet')), findsOneWidget);
    // Still a demo: never a card field anywhere.
    expect(find.byType(TextField), findsNothing);
    expect(bought, isFalse);

    await tester.tap(find.byKey(const Key('plus-confirm-button')));
    await tester.pumpAndSettle();

    expect(bought, isTrue);
  });

  testWidgets('shows a partner investment offer', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.byKey(const Key('partner-offer-card')), findsOneWidget);
    expect(find.textContaining('Harbour Invest'), findsWidgets);
    expect(find.textContaining('3 months'), findsWidgets);
  });

  testWidgets('the offer never claims to be a real bank or product', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    final card = find.byKey(const Key('partner-offer-card'));
    await tester.ensureVisible(card);
    await tester.pump();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('partner-offer-dialog')), findsOneWidget);
    // A fictional partner must say so — an investment offer that looks real
    // is the exact shape of an investment scam.
    expect(find.textContaining('fictional'), findsWidgets);
    expect(find.textContaining('Demo'), findsWidgets);
  });

  testWidgets('the offer dialog can be dismissed', (tester) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.byKey(const Key('partner-offer-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('partner-offer-close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('partner-offer-dialog')), findsNothing);
  });
}
