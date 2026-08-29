import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/screens/onboarding_screen.dart';
import 'package:moneymoneymoney/services/profile_suggestions.dart';

void main() {
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1000,
      3000,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  Widget harness({Future<ProfileSuggestion?> Function()? fetch}) {
    return MaterialApp(
      home: OnboardingScreen(
        onProfileSubmitted: (_) {},
        onFetchSuggestion: fetch,
      ),
    );
  }

  testWidgets('without a bank feed the fields start empty', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    final income = tester.widget<TextFormField>(
      find.byKey(const Key('income-field')),
    );
    expect(income.controller?.text, isEmpty);
    expect(find.byKey(const Key('prefill-banner')), findsNothing);
  });

  testWidgets('a bank suggestion pre-fills income and fixed expenses', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        fetch: () async => const ProfileSuggestion(
          monthlyIncome: 4200,
          fixedMonthlyExpenses: 1350,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('prefill-banner')), findsOneWidget);
    expect(find.text('4200'), findsOneWidget);
    expect(find.text('1350'), findsOneWidget);
  });

  testWidgets('the user can still overwrite a pre-filled value', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        fetch: () async => const ProfileSuggestion(
          monthlyIncome: 4200,
          fixedMonthlyExpenses: 1350,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('income-field')), '5000');
    await tester.pump();

    expect(find.text('5000'), findsOneWidget);
  });

  testWidgets('a failing bank fetch leaves a usable empty form', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(fetch: () async => throw Exception('offline')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('prefill-banner')), findsNothing);
    expect(find.byKey(const Key('income-field')), findsOneWidget);
  });
}
