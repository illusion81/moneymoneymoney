import '../financial_tools/budget_calculator.dart';
import '../financial_tools/savings_projector.dart';
import '../financial_tools/debt_payoff_planner.dart';
import '../financial_tools/net_worth_tracker.dart';
import '../financial_tools/cash_flow_analyzer.dart';
import '../financial_tools/benchmark_comparator.dart';

class ToolOutputs {
  const ToolOutputs({
    required this.budget,
    required this.savings,
    required this.debtPlan,
    required this.netWorth,
    required this.cashFlow,
    required this.benchmark,
  });
  final BudgetResult budget;
  final SavingsProjection savings;
  final DebtPayoffPlan debtPlan;
  final NetWorth netWorth;
  final CashFlowAnalysis cashFlow;
  final BenchmarkComparison benchmark;
}
