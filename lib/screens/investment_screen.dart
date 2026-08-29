import 'package:flutter/material.dart';

import '../widgets/app_nav_bar.dart';

class InvestmentScreen extends StatelessWidget {
  const InvestmentScreen({
    super.key,
    required this.onShowForest,
    required this.onShowSpending,
    required this.onShowCalendar,
    required this.onShowHomestead,
  });

  final VoidCallback onShowForest;
  final VoidCallback onShowSpending;
  final VoidCallback onShowCalendar;
  final VoidCallback onShowHomestead;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Investment')),
      bottomNavigationBar: AppNavBar(
        selectedIndex: 4,
        onShowForest: onShowForest,
        onShowSpending: onShowSpending,
        onShowCalendar: onShowCalendar,
        onShowHomestead: onShowHomestead,
        onShowInvestment: () {},
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xfff3f8ef),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.account_balance,
                              color: Color(0xff2f7d50),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'CommBank investing demo',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Put your spare money to work with CommBank investment products, from starter portfolios to long-term wealth building tools.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This is a fake promotional link for the demo. It does not open an account, place trades, or give personal financial advice.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        key: const Key('commbank-investment-link'),
                        onPressed: () => _showFakeLink(context),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('View CommBank investing'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFakeLink(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('CommBank investment demo link')),
      );
  }
}
