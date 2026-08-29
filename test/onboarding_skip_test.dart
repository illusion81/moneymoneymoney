import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/finance_profile.dart';
import 'package:moneymoneymoney/screens/onboarding_screen.dart';

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

  testWidgets('tapping Skip for now never submits fabricated financial facts', (
    tester,
  ) async {
    FinanceProfile? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onProfileSubmitted: (profile) => submitted = profile,
        ),
      ),
    );

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(submitted, isNull);
  });
}
