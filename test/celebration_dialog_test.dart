import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/widgets/celebration_dialog.dart';

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

  testWidgets('shows the earned XP, coins and streak', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    showCelebrationDialog(context: ctx, earnedXp: 15, earnedCoins: 8, streak: 3);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('celebration-dialog')), findsOneWidget);
    expect(find.textContaining('15'), findsWidgets);
    expect(find.textContaining('8'), findsWidgets);
    expect(find.textContaining('3'), findsWidgets);
  });

  testWidgets('the Continue button dismisses the dialog', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    showCelebrationDialog(context: ctx, earnedXp: 10, earnedCoins: 5, streak: 1);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('celebration-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('celebration-continue-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('celebration-dialog')), findsNothing);
  });

  testWidgets('the encouragement line varies with the streak length', (
    tester,
  ) async {
    expect(
      encouragementForStreak(1),
      isNot(equals(encouragementForStreak(30))),
    );
    expect(encouragementForStreak(1), isNotEmpty);
    expect(encouragementForStreak(100), isNotEmpty);
  });
}
