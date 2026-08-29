import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/main.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/services/money_style_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory store standing in for SharedPreferences.
class _Store implements MoneyStyleStore {
  MoneyStyleCompletion? value;
  bool deferred = false;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<MoneyStyleCompletion?> load() async => value;

  @override
  Future<void> save(MoneyStyleCompletion completion) async =>
      value = completion;

  @override
  Future<void> deferQuestionnaire() async => deferred = true;

  @override
  Future<bool> isQuestionnaireDeferred() async => deferred;

  @override
  Future<void> clearDeferral() async => deferred = false;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1000,
      2600,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  testWidgets('skipping from the entry screen lands on the manual form', (
    tester,
  ) async {
    final store = _Store();
    await tester.pumpWidget(MyApp(moneyStyleStore: store));
    await tester.pumpAndSettle();

    expect(find.text('Discover Your Money Style'), findsOneWidget);

    await tester.tap(find.byKey(const Key('skip-questionnaire-button')));
    await tester.pumpAndSettle();

    // Skipping goes FORWARD to the tree, not back to a form. A starter plan is
    // seeded so the Forest has something to draw; the user can replace it from
    // Retake questionnaire whenever they want.
    expect(find.text('Wealth Forest'), findsOneWidget);
    expect(find.byKey(const Key('income-field')), findsNothing);
    expect(store.deferred, isTrue);
  });

  testWidgets('skipping mid-quiz lands on the manual form too', (tester) async {
    final store = _Store();
    await tester.pumpWidget(MyApp(moneyStyleStore: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Find My Style'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 12'), findsOneWidget);

    // Answer one, move on, then bail from the middle of the questionnaire.
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 12'), findsOneWidget);

    await tester.tap(find.byKey(const Key('skip-questionnaire-footer-button')));
    await tester.pumpAndSettle();

    expect(find.text('Wealth Forest'), findsOneWidget);
    expect(store.deferred, isTrue);
  });

  testWidgets('the manual form reminds the user they can still take it', (
    tester,
  ) async {
    final store = _Store();
    await tester.pumpWidget(MyApp(moneyStyleStore: store));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('skip-questionnaire-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('money-style-reminder')), findsOneWidget);

    // And it leads straight back into the questionnaire.
    await tester.tap(find.byKey(const Key('money-style-reminder-resume')));
    await tester.pumpAndSettle();
    expect(find.text('Discover Your Money Style'), findsOneWidget);
  });

  testWidgets('dismissing the reminder clears the persisted deferral', (
    tester,
  ) async {
    final store = _Store();
    await tester.pumpWidget(MyApp(moneyStyleStore: store));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('skip-questionnaire-button')));
    await tester.pumpAndSettle();
    expect(store.deferred, isTrue);

    await tester.tap(find.byKey(const Key('money-style-reminder-dismiss')));
    await tester.pumpAndSettle();

    expect(store.deferred, isFalse);
    expect(find.byKey(const Key('money-style-reminder')), findsNothing);
  });

  testWidgets(
    'the manual form is itself skippable — the hand-off is not a trap',
    (tester) async {
      final store = _Store();
      await tester.pumpWidget(MyApp(moneyStyleStore: store));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('skip-questionnaire-button')));
      await tester.pumpAndSettle();

      // Skipping now lands on the tree with a starter plan, so the manual
      // form is no longer the hand-off — there is nothing left to escape.
      expect(find.text('Wealth Forest'), findsOneWidget);
      expect(find.byKey(const Key('income-field')), findsNothing);
    },
  );

  testWidgets('a persisted deferral is restored on next launch', (
    tester,
  ) async {
    final store = _Store()..deferred = true;
    await tester.pumpWidget(MyApp(moneyStyleStore: store));
    await tester.pumpAndSettle();

    expect(find.text('Build an exact-number plan'), findsOneWidget);
    expect(find.byKey(const Key('money-style-reminder')), findsOneWidget);
  });

  testWidgets('the reminder follows the user onto the home screen', (
    tester,
  ) async {
    final store = _Store()..deferred = true;
    await tester.pumpWidget(MyApp(moneyStyleStore: store));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('income-field')), '6000');
    await tester.enterText(find.byKey(const Key('expenses-field')), '2500');
    await tester.enterText(find.byKey(const Key('savings-field')), '900');
    await tester.tap(find.text('Generate Report'));
    await tester.pumpAndSettle();

    expect(find.text('Wealth Forest'), findsOneWidget);
    expect(find.byKey(const Key('money-style-reminder')), findsOneWidget);

    await tester.tap(find.byKey(const Key('money-style-reminder-resume')));
    await tester.pumpAndSettle();
    expect(find.text('Discover Your Money Style'), findsOneWidget);
  });
}
