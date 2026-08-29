import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/services/category_breakdown.dart';
import 'package:moneymoneymoney/widgets/category_pie_chart.dart';

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

  testWidgets('shows an empty-state message when there are no slices', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CategoryPieChart(slices: [], total: 0)),
      ),
    );

    expect(find.textContaining('No spending'), findsOneWidget);
  });

  testWidgets('renders the donut and a legend entry per slice', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryPieChart(
            total: 200,
            slices: [
              CategorySlice(label: 'groceries', amount: 120, share: 0.6),
              CategorySlice(label: 'transport', amount: 80, share: 0.4),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('category-pie-canvas')), findsOneWidget);
    // Every slice is directly labelled — the palette's contrast warning
    // requires visible labels rather than colour alone.
    expect(find.text('groceries'), findsOneWidget);
    expect(find.text('transport'), findsOneWidget);
    expect(find.textContaining('60%'), findsOneWidget);
    expect(find.textContaining('40%'), findsOneWidget);
  });

  testWidgets('shows the total spend in the middle of the donut', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryPieChart(
            total: 200,
            slices: [CategorySlice(label: 'groceries', amount: 200, share: 1)],
          ),
        ),
      ),
    );

    expect(find.textContaining('200'), findsWidgets);
  });

  test('the palette provides a distinct colour for every slot', () {
    final colours = {
      for (var i = 0; i < kCategoryPalette.length; i++) kCategoryPalette[i],
    };

    expect(colours, hasLength(kCategoryPalette.length));
    expect(kCategoryPalette.length, greaterThanOrEqualTo(7));
  });
}
