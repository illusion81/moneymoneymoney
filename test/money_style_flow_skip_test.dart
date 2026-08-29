import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/screens/money_style_flow.dart';

void main() {
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1000,
      2400,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  Widget harness({VoidCallback? onSkipAll}) {
    return MaterialApp(
      home: MoneyStyleFlow(
        userId: 'u1',
        onComplete: (_) {},
        onSkipAll: onSkipAll,
      ),
    );
  }

  testWidgets('a skip option sits under Find My Style', (tester) async {
    await tester.pumpWidget(harness(onSkipAll: () {}));

    expect(find.text('Find My Style'), findsOneWidget);
    expect(find.byKey(const Key('skip-questionnaire-button')), findsOneWidget);
  });

  testWidgets('tapping skip calls onSkip without starting the quiz', (
    tester,
  ) async {
    var skipped = false;
    await tester.pumpWidget(harness(onSkipAll: () => skipped = true));

    final skip = find.byKey(const Key('skip-questionnaire-button'));
    await tester.ensureVisible(skip);
    await tester.pump();
    await tester.tap(skip);
    await tester.pumpAndSettle();

    expect(skipped, isTrue);
    // The quiz must not have started underneath.
    expect(find.text('Find My Style'), findsOneWidget);
  });

  testWidgets('no skip button when the caller offers no destination', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    expect(find.byKey(const Key('skip-questionnaire-button')), findsNothing);
  });
}
