import 'package:flutter/material.dart';

import '../demo_flags.dart';
import '../models/finance_profile.dart';
import '../services/profile_suggestions.dart';
import '../services/risk_assessment.dart';
import '../widgets/dev_gate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onProfileSubmitted,
    this.onStartMoneyStyleQuiz,
    this.onCancel,
    this.onFetchSuggestion,
  });

  final ValueChanged<FinanceProfile> onProfileSubmitted;
  final VoidCallback? onStartMoneyStyleQuiz;
  final VoidCallback? onCancel;

  /// Pulls suggested figures from the bank feed so the user confirms numbers
  /// rather than recalling them. Null when no backend is available; a
  /// failure here must leave a perfectly usable blank form.
  final Future<ProfileSuggestion?> Function()? onFetchSuggestion;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController();
  final _expensesController = TextEditingController();
  final _savingsController = TextEditingController();

  bool _prefilledFromBank = false;

  @override
  void initState() {
    super.initState();
    _tryPrefill();
  }

  Future<void> _tryPrefill() async {
    final fetch = widget.onFetchSuggestion;
    if (fetch == null) {
      return;
    }
    try {
      final suggestion = await fetch();
      if (!mounted || suggestion == null) {
        return;
      }
      setState(() {
        _incomeController.text = suggestion.monthlyIncome.toStringAsFixed(0);
        _expensesController.text = suggestion.fixedMonthlyExpenses
            .toStringAsFixed(0);
        _prefilledFromBank = true;
      });
    } catch (_) {
      // Offline or no linked bank — the blank form still works.
    }
  }

  FinancialGoal _financialGoal = FinancialGoal.emergencyFund;
  SpendingPressure _spendingPressure = SpendingPressure.medium;

  @override
  void dispose() {
    _incomeController.dispose();
    _expensesController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  /// A believable student profile: enough income to have choices, enough
  /// fixed cost to make the budget bite, and a savings goal that is reachable
  /// but not automatic. Deliberately not round numbers — round numbers look
  /// like placeholder data to anyone paying attention.
  static const _demoProfile = FinanceProfile(
    monthlyIncome: 3200,
    fixedMonthlyExpenses: 1450,
    monthlySavingsGoal: 450,
    riskLevel: RiskLevel.steady,
    financialGoal: FinancialGoal.saveForPurchase,
    spendingPressure: SpendingPressure.medium,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Demo aid: the questionnaire is six fields and three dropdowns, which is
      // thirty seconds you do not have on stage. PIN-gated like the other dev
      // shortcuts so a judge poking at the app can't skip their own answers.
      floatingActionButton: !kDemoTools
          ? null
          : FloatingActionButton.extended(
              heroTag: 'demo-profile',
              onPressed: () async {
                if (!await DevGate.ensureUnlocked(context)) return;
                widget.onProfileSubmitted(_demoProfile);
              },
              icon: Icon(
                  DevGate.isUnlocked ? Icons.bolt : Icons.lock_outline),
              label: const Text('Fill survey'),
            ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Build an exact-number plan',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xff173b2f),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Optional: these amounts are used to calculate a daily budget. You can go back and keep using your Money Style result without sharing them.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    if (_prefilledFromBank) ...[
                      Container(
                        key: const Key('prefill-banner'),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xffedf8ed),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance,
                              size: 20,
                              color: Color(0xff2f7d50),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Filled in from your bank activity — check the '
                                'numbers and edit anything that looks wrong.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _MoneyNumberField(
                      fieldKey: const Key('income-field'),
                      controller: _incomeController,
                      label: 'Monthly income',
                      mustBePositive: true,
                    ),
                    const SizedBox(height: 14),
                    _MoneyNumberField(
                      fieldKey: const Key('expenses-field'),
                      controller: _expensesController,
                      label: 'Fixed monthly expenses',
                    ),
                    const SizedBox(height: 14),
                    _MoneyNumberField(
                      fieldKey: const Key('savings-field'),
                      controller: _savingsController,
                      label: 'Monthly savings goal',
                    ),
                    const SizedBox(height: 18),
                    _EnumDropdown<FinancialGoal>(
                      label: 'Main financial goal',
                      value: _financialGoal,
                      values: FinancialGoal.values,
                      labelFor: _goalLabel,
                      onChanged: (value) =>
                          setState(() => _financialGoal = value),
                    ),
                    const SizedBox(height: 14),
                    _EnumDropdown<SpendingPressure>(
                      label: 'Recent spending pressure',
                      value: _spendingPressure,
                      values: SpendingPressure.values,
                      labelFor: _pressureLabel,
                      onChanged: (value) =>
                          setState(() => _spendingPressure = value),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate Report'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: widget.onStartMoneyStyleQuiz,
                      icon: const Icon(Icons.psychology),
                      label: const Text('Discover Your Money Style'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _skip,
                      child: const Text('Skip for now'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.onProfileSubmitted(
      FinanceProfile(
        monthlyIncome: double.parse(_incomeController.text),
        fixedMonthlyExpenses: double.parse(_expensesController.text),
        monthlySavingsGoal: double.parse(_savingsController.text),
        riskLevel: RiskLevel.balanced,
        financialGoal: _financialGoal,
        spendingPressure: _spendingPressure,
      ),
    );
  }

  void _skip() {
    widget.onCancel?.call();
  }

  String _goalLabel(FinancialGoal value) {
    switch (value) {
      case FinancialGoal.emergencyFund:
        return 'Emergency fund';
      case FinancialGoal.reduceSpending:
        return 'Reduce spending';
      case FinancialGoal.saveForPurchase:
        return 'Save for purchase';
      case FinancialGoal.invest:
        return 'Invest';
      case FinancialGoal.debtControl:
        return 'Debt control';
    }
  }

  String _pressureLabel(SpendingPressure value) {
    switch (value) {
      case SpendingPressure.low:
        return 'Low';
      case SpendingPressure.medium:
        return 'Medium';
      case SpendingPressure.high:
        return 'High';
    }
  }
}

class _MoneyNumberField extends StatelessWidget {
  const _MoneyNumberField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    this.mustBePositive = false,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final bool mustBePositive;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.attach_money),
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        final number = double.tryParse(value ?? '');
        if (number == null) {
          return 'Enter a valid amount';
        }
        if (mustBePositive && number <= 0) {
          return 'Amount must be greater than zero';
        }
        if (!mustBePositive && number < 0) {
          return 'Amount cannot be negative';
        }
        return null;
      },
    );
  }
}

class _EnumDropdown<T> extends StatelessWidget {
  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: values
          .map(
            (item) =>
                DropdownMenuItem<T>(value: item, child: Text(labelFor(item))),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
