import 'package:flutter/material.dart';

import '../models/finance_profile.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onProfileSubmitted,
    this.onStartMoneyStyleQuiz,
  });

  final ValueChanged<FinanceProfile> onProfileSubmitted;
  final VoidCallback? onStartMoneyStyleQuiz;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController();
  final _expensesController = TextEditingController();
  final _savingsController = TextEditingController();
  RiskPreference _riskPreference = RiskPreference.balanced;
  FinancialGoal _financialGoal = FinancialGoal.emergencyFund;
  SpendingPressure _spendingPressure = SpendingPressure.medium;

  @override
  void dispose() {
    _incomeController.dispose();
    _expensesController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      'Money Profile',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xff173b2f),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Answer a short money questionnaire to generate your personal wealth report.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
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
                    _EnumDropdown<RiskPreference>(
                      label: 'Risk preference',
                      value: _riskPreference,
                      values: RiskPreference.values,
                      labelFor: _riskLabel,
                      onChanged: (value) =>
                          setState(() => _riskPreference = value),
                    ),
                    const SizedBox(height: 14),
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
        riskPreference: _riskPreference,
        financialGoal: _financialGoal,
        spendingPressure: _spendingPressure,
      ),
    );
  }

  String _riskLabel(RiskPreference value) {
    switch (value) {
      case RiskPreference.conservative:
        return 'Conservative';
      case RiskPreference.balanced:
        return 'Balanced';
      case RiskPreference.growth:
        return 'Growth';
    }
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
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(labelFor(item)),
            ),
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
