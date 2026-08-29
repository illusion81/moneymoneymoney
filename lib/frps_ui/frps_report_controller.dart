import 'package:moneymoneymoney/frps/financial_tools/benchmark_comparator.dart';
import 'package:moneymoneymoney/frps/financial_tools/budget_calculator.dart';
import 'package:moneymoneymoney/frps/financial_tools/cash_flow_analyzer.dart';
import 'package:moneymoneymoney/frps/financial_tools/debt_payoff_planner.dart';
import 'package:moneymoneymoney/frps/financial_tools/net_worth_tracker.dart';
import 'package:moneymoneymoney/frps/financial_tools/savings_projector.dart';
import 'package:moneymoneymoney/frps/models/financial_snapshot.dart';
import 'package:moneymoneymoney/frps/models/report.dart';
import 'package:moneymoneymoney/frps/models/tool_outputs.dart';
import 'package:moneymoneymoney/frps/report_planner.dart';
import 'package:moneymoneymoney/frps/slm/slm_interface.dart';
import 'package:moneymoneymoney/frps/slm/slot_slm.dart';
import 'package:moneymoneymoney/frps/storage/repository.dart';
import 'package:moneymoneymoney/models/finance_profile.dart';

import 'frps_profile_bridge.dart';

/// Everything the screen needs to render a finished report.
///
/// [report] is the module's assembled, persisted output; [toolOutputs] and
/// [narrative] are the structured pieces that [ReportPlanner] flattens into
/// the report's section prose, surfaced separately so the UI can lay them out
/// as numbers and a story rather than one blob of text.
class FrpsReportData {
  const FrpsReportData({
    required this.report,
    required this.toolOutputs,
    required this.narrative,
  });

  final Report report;
  final ToolOutputs toolOutputs;
  final String narrative;
}

enum FrpsReportStatus { loading, loaded, empty, error }

/// The outcome of a report run. Exactly one of [data] or [message] is set,
/// depending on [status].
class FrpsReportOutcome {
  const FrpsReportOutcome._({required this.status, this.data, this.message});

  const FrpsReportOutcome.loading() : this._(status: FrpsReportStatus.loading);

  const FrpsReportOutcome.loaded(FrpsReportData data)
    : this._(status: FrpsReportStatus.loaded, data: data);

  const FrpsReportOutcome.empty(String message)
    : this._(status: FrpsReportStatus.empty, message: message);

  const FrpsReportOutcome.error(String message)
    : this._(status: FrpsReportStatus.error, message: message);

  final FrpsReportStatus status;
  final FrpsReportData? data;
  final String? message;
}

/// Runs the FRPS planner over a stored user profile and turns the result into
/// something a screen can render, degrading to a friendly [FrpsReportStatus]
/// instead of throwing when the data is missing or partial.
class FrpsReportController {
  FrpsReportController({required FrpsRepository repository, SlmInterface? slm})
    : _repository = repository,
      _slm = slm ?? SlotSlm();

  final FrpsRepository _repository;
  final SlmInterface _slm;

  Future<FrpsReportOutcome> generate({
    required String userId,
    FinanceProfile? seedProfile,
  }) async {
    try {
      // When the caller passes the on-device profile, write it into the FRPS
      // store first so the report always reflects the latest answers. When it
      // is null, the repository is assumed to already hold FRPS data (seeded
      // by the question flow or an earlier run).
      if (seedProfile != null) {
        await _repository.saveUser(
          FrpsProfileBridge.userFrom(seedProfile, id: userId),
        );
        await _repository.saveSnapshot(
          FrpsProfileBridge.snapshotFrom(seedProfile, userId: userId),
        );
      }

      final user = await _repository.getUser(userId);
      if (user == null) {
        return const FrpsReportOutcome.empty(
          'There is no profile on file yet. Answer a few questions first.',
        );
      }

      final snapshot = await _repository.latestSnapshot(userId);
      if (snapshot == null) {
        return const FrpsReportOutcome.empty(
          'There is no financial snapshot yet. Answer a few questions first.',
        );
      }

      final toolOutputs = _toolOutputs(snapshot);
      final narrative = _slm.generateReportNarrative(
        toolOutputs: toolOutputs,
        userProfile: user.profile,
      );

      final report = await ReportPlanner(
        repository: _repository,
        slm: _slm,
      ).generateReport(userId);

      return FrpsReportOutcome.loaded(
        FrpsReportData(
          report: report,
          toolOutputs: toolOutputs,
          narrative: narrative,
        ),
      );
    } catch (_) {
      return const FrpsReportOutcome.error(
        'The report could not be assembled. Check your inputs and try again.',
      );
    }
  }

  /// Mirrors the tool calls [ReportPlanner] makes, so the UI can show the
  /// structured numbers the report's prose is built from.
  ToolOutputs _toolOutputs(FinancialSnapshot s) {
    final budget = budgetCalculator(s.income, s.expenses);
    return ToolOutputs(
      budget: budget,
      savings: savingsProjector(
        currentSavings: s.assets['savings'] ?? 0.0,
        monthlyContribution: s.monthlySavingsGoal,
        annualRate: 0.05,
        years: 10,
      ),
      debtPlan: debtPayoffPlanner(const [], startDate: s.date),
      netWorth: netWorthTracker(s.assets, s.liabilities),
      cashFlow: cashFlowAnalyzer(
        [s.income],
        [s.expenses.values.fold(0.0, (sum, value) => sum + value)],
      ),
      benchmark: benchmarkComparator(
        budget.categoryPercentages,
        nationalBenchmark,
      ),
    );
  }
}
