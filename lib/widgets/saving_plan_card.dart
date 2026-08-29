import 'package:flutter/material.dart';

import '../services/daily_saving_plan.dart';
import '../services/money_format.dart';

/// The daily saving plan, with the daily figure as the hero — that is the
/// number someone can act on today; the monthly total is the motivation.
class SavingPlanCard extends StatelessWidget {
  const SavingPlanCard({super.key, required this.plan});

  final DailySavingPlan? plan;

  @override
  Widget build(BuildContext context) {
    final plan = this.plan;
    if (plan == null) {
      return const SizedBox.shrink();
    }

    final percent = (plan.trimFraction * 100).round();

    return Container(
      key: const Key('saving-plan-card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xffedf8ed),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff2f7d50).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.savings, color: Color(0xff2f7d50), size: 20),
              const SizedBox(width: 8),
              Text(
                'Your daily saving plan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff173b2f),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatMoney(plan.dailySaving),
                key: const Key('saving-plan-daily-amount'),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff2f7d50),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'a day',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Spend $percent% less on ${plan.category} — that is '
            '${formatMoney(plan.monthlyCategorySpend)} a month today.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                size: 18,
                color: Color(0xff2f7d50),
              ),
              const SizedBox(width: 6),
              Text(
                formatMoney(plan.monthlySaving),
                key: const Key('saving-plan-monthly-amount'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff2f7d50),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'saved each month',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
