import 'financial_tools/benchmark_comparator.dart';
import 'financial_tools/budget_calculator.dart';
import 'financial_tools/cash_flow_analyzer.dart';
import 'financial_tools/debt_payoff_planner.dart';
import 'financial_tools/net_worth_tracker.dart';
import 'financial_tools/savings_projector.dart';
import 'models/report.dart';
import 'models/tool_outputs.dart';
import 'reporting/report_assembler.dart';
import 'slm/slm_interface.dart';
import 'storage/repository.dart';

class ReportPlanner {
  ReportPlanner({required FrpsRepository repository, required SlmInterface slm})
      : _repository = repository,
        _slm = slm;

  final FrpsRepository _repository;
  final SlmInterface _slm;

  Future<Report> generateReport(String userId) async {
    final user = await _repository.getUser(userId);
    if (user == null) {
      throw StateError('User not found: $userId');
    }

    final snapshot = await _repository.latestSnapshot(userId);
    if (snapshot == null) {
      throw StateError('No financial snapshot found for user: $userId');
    }

    final budget = budgetCalculator(snapshot.income, snapshot.expenses);
    final netWorth = netWorthTracker(snapshot.assets, snapshot.liabilities);
    final cashFlow = cashFlowAnalyzer(
      [snapshot.income],
      [snapshot.expenses.values.fold(0.0, (sum, value) => sum + value)],
    );
    final savings = savingsProjector(
      currentSavings: snapshot.assets['savings'] ?? 0.0,
      monthlyContribution: snapshot.monthlySavingsGoal,
      annualRate: 0.05,
      years: 10,
    );
    final benchmark = benchmarkComparator(budget.categoryPercentages, nationalBenchmark);
    final debtPlan = debtPayoffPlanner(const [], startDate: snapshot.date);

    final toolOutputs = ToolOutputs(
      budget: budget,
      savings: savings,
      debtPlan: debtPlan,
      netWorth: netWorth,
      cashFlow: cashFlow,
      benchmark: benchmark,
    );

    final narrative = _slm.generateReportNarrative(
      toolOutputs: toolOutputs,
      userProfile: user.profile,
    );

    final report = ReportAssembler().assemble(
      toolOutputs: toolOutputs,
      narrative: narrative,
      userId: userId,
      date: snapshot.date,
    );

    await _repository.saveReport(report);
    return report;
  }
}
