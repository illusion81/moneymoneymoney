import 'dart:math';

import '../models/tool_outputs.dart';
import '../models/user_profile.dart';
import 'mock_slm.dart';
import 'slm_interface.dart';

String fillNarrative(String slotProse, ToolOutputs toolOutputs) {
  final replacements = <String, String>{
    '{SURPLUS}': _money(toolOutputs.budget.surplus),
    '{SAVINGS_RATE}': _percent(toolOutputs.budget.savingsRate),
    '{NET_WORTH}': _money(toolOutputs.netWorth.netWorth),
    '{FUTURE_VALUE}': _money(toolOutputs.savings.futureValue),
    '{TOTAL_INTEREST}': _money(toolOutputs.savings.totalInterest),
    '{OVERSPEND}': toolOutputs.benchmark.overspendFlags.isEmpty
        ? 'none'
        : toolOutputs.benchmark.overspendFlags.join(', '),
  };

  var result = slotProse;
  for (final entry in replacements.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result;
}

String _money(double value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final dot = fixed.indexOf('.');
  final intPart = fixed.substring(0, dot);
  final decPart = fixed.substring(dot + 1);

  final buffer = StringBuffer();
  final firstGroup = intPart.length % 3 == 0 ? 3 : intPart.length % 3;
  buffer.write(intPart.substring(0, firstGroup));
  for (var i = firstGroup; i < intPart.length; i += 3) {
    buffer.write(',');
    buffer.write(intPart.substring(i, i + 3));
  }

  return '${negative ? '-' : ''}\$$buffer.$decPart';
}

String _percent(double rate) => '${(rate * 100).toStringAsFixed(1)}%';

abstract class SlotModel {
  String generateSlotProse({
    required ToolOutputs toolOutputs,
    required UserProfile userProfile,
  });
}

class TemplateSlotModel implements SlotModel {
  TemplateSlotModel({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const List<String> _surplusOpeners = [
    'Your budget shows a healthy surplus of {SURPLUS} this month.',
    'This month you came out ahead, keeping a surplus of {SURPLUS}.',
    'You are living within your means, with {SURPLUS} left over.',
  ];

  static const List<String> _deficitOpeners = [
    'Your budget ran a shortfall of {SURPLUS} this month.',
    'This month spending exceeded income, leaving a shortfall of {SURPLUS}.',
  ];

  static const List<String> _savingsRateSentences = [
    'That works out to a savings rate of {SAVINGS_RATE}.',
    'Your savings rate sits at {SAVINGS_RATE} of your income.',
  ];

  static const List<String> _netWorthSentences = [
    'Your current net worth is {NET_WORTH}.',
    'Across all assets and liabilities, your net worth stands at {NET_WORTH}.',
  ];

  static const List<String> _growthSentences = [
    'Projecting forward, your savings could reach {FUTURE_VALUE}, including {TOTAL_INTEREST} in interest.',
    'Over time your savings may grow to {FUTURE_VALUE}, with {TOTAL_INTEREST} earned in interest.',
  ];

  static const List<String> _overspendSentences = [
    'You are overspending on {OVERSPEND} compared with typical benchmarks.',
    'Watch your spending on {OVERSPEND}, which runs above typical benchmarks.',
  ];

  @override
  String generateSlotProse({
    required ToolOutputs toolOutputs,
    required UserProfile userProfile,
  }) {
    final sentences = <String>[];

    sentences.add(toolOutputs.budget.surplus < 0
        ? _pick(_deficitOpeners)
        : _pick(_surplusOpeners));
    sentences.add(_pick(_savingsRateSentences));

    if (toolOutputs.benchmark.overspendFlags.isNotEmpty) {
      sentences.add(_pick(_overspendSentences));
    } else {
      sentences.add(_pick(_growthSentences));
    }

    sentences.add(_pick(_netWorthSentences));

    return sentences.join(' ');
  }

  String _pick(List<String> pool) => pool[_random.nextInt(pool.length)];
}

class SlotSlm implements SlmInterface {
  SlotSlm({SlotModel? slotModel}) : _slotModel = slotModel ?? TemplateSlotModel();

  final SlotModel _slotModel;

  @override
  String generateReportNarrative({
    required ToolOutputs toolOutputs,
    required UserProfile userProfile,
  }) {
    final slotProse = _slotModel.generateSlotProse(
      toolOutputs: toolOutputs,
      userProfile: userProfile,
    );
    return fillNarrative(slotProse, toolOutputs);
  }

  @override
  ExtractedData parseFreeText(String answer) {
    return MockSlm().parseFreeText(answer);
  }
}
