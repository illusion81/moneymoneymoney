import 'package:flutter/material.dart';

import '../models/wealth_report.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({
    super.key,
    required this.report,
    required this.onStartPlan,
    this.onShowForest,
  });

  final WealthReport report;
  final VoidCallback onStartPlan;
  final VoidCallback? onShowForest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'AI Wealth Report',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff173b2f),
                  ),
                ),
                const SizedBox(height: 8),
                Text(report.profileSummary),
                const SizedBox(height: 18),
                _ReportTile(
                  icon: Icons.account_balance_wallet,
                  title: 'Daily flexible budget',
                  body:
                      '\$${report.dailyBudget.toStringAsFixed(2)} per day after fixed expenses and savings.',
                ),
                _ReportTile(
                  icon: Icons.savings,
                  title: 'Savings guidance',
                  body: report.savingsAdvice,
                ),
                _ReportTile(
                  icon: Icons.trending_up,
                  title: 'Risk guidance',
                  body: report.riskAdvice,
                ),
                if (report.warning != null)
                  _ReportTile(
                    icon: Icons.warning_amber,
                    title: 'Budget warning',
                    body: report.warning!,
                  ),
                const SizedBox(height: 10),
                Text(
                  'Daily actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final action in report.dailyActions)
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(action),
                  ),
                const SizedBox(height: 16),
                if (onShowForest == null)
                  FilledButton.icon(
                    onPressed: onStartPlan,
                    icon: const Icon(Icons.park),
                    label: const Text('Start Plan'),
                  )
                else
                  FilledButton.icon(
                    onPressed: onShowForest,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Forest'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xff2f7d50)),
        title: Text(title),
        subtitle: Text(body),
      ),
    );
  }
}
