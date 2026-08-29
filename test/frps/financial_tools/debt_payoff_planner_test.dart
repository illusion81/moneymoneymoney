import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/financial_tools/debt_payoff_planner.dart';

void main() {
  group('debtPayoffPlanner', () {
    test('pays off a zero-interest single debt in full', () {
      final plan = debtPayoffPlanner(
        const [Debt(name: 'card', balance: 1000, annualRate: 0, minPayment: 250)],
        startDate: DateTime(2026, 1, 1),
      );

      expect(plan.totalInterest, 0);
      expect(plan.totalPaid, closeTo(1000, 0.01));
      expect(plan.monthsToPayoff, 4);
      expect(plan.payoffDate, DateTime(2026, 5, 1));
      expect(plan.schedule, hasLength(4));
      expect(plan.schedule.last.remainingBalances['card'], closeTo(0, 0.01));
    });

    test('avalanche targets the higher-rate debt; snowball the smaller balance', () {
      const debts = [
        Debt(name: 'A', balance: 300, annualRate: 0.20, minPayment: 10),
        Debt(name: 'B', balance: 100, annualRate: 0.10, minPayment: 10),
      ];

      final avalanche = debtPayoffPlanner(
        debts,
        strategy: DebtStrategy.avalanche,
        extraPayment: 50,
        startDate: DateTime(2026, 1, 1),
      );
      final snowball = debtPayoffPlanner(
        debts,
        strategy: DebtStrategy.snowball,
        extraPayment: 50,
        startDate: DateTime(2026, 1, 1),
      );

      // Avalanche targets A (20% > 10%): A shrinks by 60 in month 1.
      expect(avalanche.schedule.first.remainingBalances['A'], closeTo(245, 0.01));
      // Snowball targets B (100 < 300): B shrinks by 60 in month 1.
      expect(snowball.schedule.first.remainingBalances['B'], closeTo(40.83, 0.01));
    });

    test('empty debts produce an empty plan with zero months', () {
      final plan = debtPayoffPlanner(const [], startDate: DateTime(2026, 1, 1));
      expect(plan.monthsToPayoff, 0);
      expect(plan.schedule, isEmpty);
      expect(plan.totalInterest, 0);
      expect(plan.totalPaid, 0);
      expect(plan.payoffDate, DateTime(2026, 1, 1));
    });

    test('rejects a debt with non-positive minimum payment', () {
      expect(
        () => debtPayoffPlanner(
          const [Debt(name: 'bad', balance: 100, annualRate: 0.1, minPayment: 0)],
        ),
        throwsArgumentError,
      );
    });
  });
}
