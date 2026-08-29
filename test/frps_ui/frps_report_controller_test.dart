import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/models/report.dart';
import 'package:moneymoneymoney/frps/models/user.dart';
import 'package:moneymoneymoney/frps/models/user_profile.dart';
import 'package:moneymoneymoney/frps/slm/mock_slm.dart';
import 'package:moneymoneymoney/frps_ui/frps_report_controller.dart';
import 'package:moneymoneymoney/models/finance_profile.dart';

import 'fake_frps_repository.dart';

const _profile = FinanceProfile(
  monthlyIncome: 6000,
  fixedMonthlyExpenses: 2600,
  monthlySavingsGoal: 900,
  riskPreference: RiskPreference.balanced,
  financialGoal: FinancialGoal.invest,
  spendingPressure: SpendingPressure.medium,
);

void main() {
  test('runs the planner over a seeded profile and returns a loaded outcome',
      () async {
    final repo = FakeFrpsRepository();
    final controller = FrpsReportController(repository: repo, slm: MockSlm());

    final outcome = await controller.generate(
      userId: 'user-1',
      seedProfile: _profile,
    );

    expect(outcome.status, FrpsReportStatus.loaded);
    expect(outcome.data, isNotNull);
    expect(outcome.data!.report.sections, hasLength(4));
    expect(outcome.data!.narrative, isNotEmpty);
    expect(outcome.data!.toolOutputs.budget.surplus, closeTo(3400, 0.001));
    expect((await repo.latestReport('user-1'))!.sections, hasLength(4));
  });

  test('degrades to empty when there is no user and no seed', () async {
    final controller = FrpsReportController(
      repository: FakeFrpsRepository(),
      slm: MockSlm(),
    );

    final outcome = await controller.generate(userId: 'nobody');

    expect(outcome.status, FrpsReportStatus.empty);
    expect(outcome.message, isNotNull);
  });

  test('degrades to empty when a user exists but has no snapshot', () async {
    final repo = FakeFrpsRepository();
    await repo.saveUser(const User(
      id: 'u1',
      name: 'Ada',
      profile: UserProfile(monthlyIncome: 6000, age: 30),
    ));
    final controller = FrpsReportController(repository: repo, slm: MockSlm());

    final outcome = await controller.generate(userId: 'u1');

    expect(outcome.status, FrpsReportStatus.empty);
  });

  test('partial (zero) input produces a loaded report instead of throwing',
      () async {
    final controller = FrpsReportController(
      repository: FakeFrpsRepository(),
      slm: MockSlm(),
    );

    final outcome = await controller.generate(
      userId: 'user-1',
      seedProfile: const FinanceProfile(
        monthlyIncome: 0,
        fixedMonthlyExpenses: 0,
        monthlySavingsGoal: 0,
        riskPreference: RiskPreference.conservative,
        financialGoal: FinancialGoal.emergencyFund,
        spendingPressure: SpendingPressure.low,
      ),
    );

    expect(outcome.status, FrpsReportStatus.loaded);
    expect(outcome.data!.report.sections, hasLength(4));
  });

  test('degrades to error when the planner throws', () async {
    final controller = FrpsReportController(
      repository: _ThrowingRepository(),
      slm: MockSlm(),
    );

    final outcome = await controller.generate(
      userId: 'user-1',
      seedProfile: _profile,
    );

    expect(outcome.status, FrpsReportStatus.error);
    expect(outcome.message, isNotNull);
  });
}

class _ThrowingRepository extends FakeFrpsRepository {
  @override
  Future<void> saveReport(Report report) async {
    throw Exception('boom');
  }
}
