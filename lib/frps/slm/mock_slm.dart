import '../models/tool_outputs.dart';
import '../models/user_profile.dart';
import 'slm_interface.dart';

class MockSlm implements SlmInterface {
  static final RegExp _amountPattern = RegExp(r'\$?\s*(\d+(?:\.\d+)?)');
  static final RegExp _frequencyPattern =
      RegExp(r'/month|per month|monthly|a month');

  static const Map<String, String> _keywordCategories = {
    'coffee': 'dining',
    'dining': 'dining',
    'restaurant': 'dining',
    'food': 'dining',
    'grocery': 'dining',
    'eat': 'dining',
    'rent': 'housing',
    'mortgage': 'housing',
    'housing': 'housing',
    'transport': 'transport',
    'car': 'transport',
    'fuel': 'transport',
    'gas': 'transport',
    'commute': 'transport',
    'gym': 'health',
    'fitness': 'health',
    'health': 'health',
    'shopping': 'shopping',
    'clothes': 'shopping',
  };

  @override
  String generateReportNarrative({
    required ToolOutputs toolOutputs,
    required UserProfile userProfile,
  }) {
    final budget = toolOutputs.budget;
    final netWorth = toolOutputs.netWorth;
    return 'Your monthly income is '
        '\$${userProfile.monthlyIncome.toStringAsFixed(2)}, with a budget '
        'surplus of \$${budget.surplus.toStringAsFixed(2)} and a savings rate '
        'of ${budget.savingsRate.toStringAsFixed(2)}. Your current net worth '
        'is \$${netWorth.netWorth.toStringAsFixed(2)}.';
  }

  @override
  ExtractedData parseFreeText(String answer) {
    _frequencyPattern.hasMatch(answer);

    final match = _amountPattern.firstMatch(answer);
    if (match == null) {
      return ExtractedData(category: 'unknown', amount: 0, raw: answer);
    }

    final amount = double.parse(match.group(1)!);
    final category = _categorize(answer);
    return ExtractedData(category: category, amount: amount, raw: answer);
  }

  String _categorize(String answer) {
    final lower = answer.toLowerCase();
    for (final entry in _keywordCategories.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'unknown';
  }
}
