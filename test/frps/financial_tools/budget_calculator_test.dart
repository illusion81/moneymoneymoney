import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/financial_tools/budget_calculator.dart';

void main() {
  group('budgetCalculator', () {
    test('totals expenses, surplus, savings rate, and category percentages', () {
      final result = budgetCalculator(6000, {
        'housing': 1500,
        'food': 800,
        'transport': 300,
      });

      expect(result.totalIncome, 6000);
      expect(result.totalExpenses, 2600);
      expect(result.surplus, 3400);
      expect(result.savingsRate, closeTo(3400 / 6000, 1e-9));
      expect(result.categoryPercentages['housing'], closeTo(1500 / 2600 * 100, 1e-9));
      expect(result.categoryPercentages['food'], closeTo(800 / 2600 * 100, 1e-9));
    });

    test('negative surplus is a deficit and savings rate floors at zero', () {
      final result = budgetCalculator(2000, {'rent': 2500});
      expect(result.surplus, -500);
      expect(result.savingsRate, 0);
    });

    test('empty expenses and zero income are safe', () {
      final result = budgetCalculator(0, {});
      expect(result.totalExpenses, 0);
      expect(result.surplus, 0);
      expect(result.savingsRate, 0);
      expect(result.categoryPercentages, isEmpty);
    });
  });
}
