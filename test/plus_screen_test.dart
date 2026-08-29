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
  }) {
    return MaterialApp(
      home: PlusScreen(
        isPlusMember: isPlusMember,
        onSubscribe: onSubscribe ?? () {},
        onCancelMembership: onCancel ?? () {},
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
}
