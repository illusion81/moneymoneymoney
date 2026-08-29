import '../models/report.dart';
import '../models/tool_outputs.dart';

class ReportAssembler {
  Report assemble({
    required ToolOutputs toolOutputs,
    required String narrative,
    required String userId,
    required DateTime date,
  }) {
    return Report(
      userId: userId,
      date: date,
      sections: [
        _executiveSummary(toolOutputs, narrative),
        _expenseOverview(toolOutputs),
        _opportunitiesAndOptions(toolOutputs),
        _progressAndMotivation(toolOutputs),
      ],
    );
  }

  ReportSection _executiveSummary(ToolOutputs outputs, String narrative) {
    final budget = outputs.budget;
    final netWorth = outputs.netWorth;
    final buffer = StringBuffer()
      ..writeln(narrative)
      ..writeln()
      ..writeln('Surplus: ${_money(budget.surplus)}')
      ..writeln('Savings rate: ${_ratioPercent(budget.savingsRate)}')
      ..writeln('Net worth: ${_money(netWorth.netWorth)}');
    return ReportSection(
      title: 'Executive Summary',
      content: buffer.toString().trim(),
    );
  }

  ReportSection _expenseOverview(ToolOutputs outputs) {
    final buffer = StringBuffer()
      ..writeln('Category spend (share of expenses):');
    outputs.budget.categoryPercentages.forEach((category, percentage) {
      buffer.writeln('- $category: ${_percent(percentage)}');
    });
    final flags = outputs.benchmark.overspendFlags;
    buffer.writeln();
    buffer.writeln(flags.isEmpty
        ? 'No categories flagged for overspending.'
        : 'Overspend flags: ${flags.join(', ')}');
    return ReportSection(
      title: 'Expense Overview',
      content: buffer.toString().trim(),
    );
  }

  ReportSection _opportunitiesAndOptions(ToolOutputs outputs) {
    final buffer = StringBuffer()
      ..writeln('Projected savings value: '
          '${_money(outputs.savings.futureValue)}')
      ..writeln('Projected savings interest: '
          '${_money(outputs.savings.totalInterest)}')
      ..writeln('Projected debt interest: '
          '${_money(outputs.debtPlan.totalInterest)}');
    return ReportSection(
      title: 'Opportunities & Options',
      content: buffer.toString().trim(),
    );
  }

  ReportSection _progressAndMotivation(ToolOutputs outputs) {
    final freeMoney = outputs.savings.totalInterest;
    final momentum = outputs.cashFlow.averageSurplus;
    final buffer = StringBuffer()
      ..writeln('Your savings could earn ${_money(freeMoney)} in '
          'interest - free money.')
      ..writeln('Average monthly surplus momentum: ${_money(momentum)}');
    return ReportSection(
      title: 'Progress & Motivation',
      content: buffer.toString().trim(),
    );
  }

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  String _percent(double value) => '${value.toStringAsFixed(1)}%';

  String _ratioPercent(double value) =>
      '${(value * 100).toStringAsFixed(1)}%';
}
