// The Plus membership screen.
//
// The checkout here is a DEMO ONLY. It deliberately collects no payment
// details of any kind — no card number, no expiry, no CVV — because a
// realistic-looking payment form invites people to type real card details
// into something that cannot protect them. Wiring this to a real payment
// provider means server-held keys, HTTPS, and webhook handling; none of that
// exists yet, and the UI should not pretend otherwise.

import 'package:flutter/material.dart';

const Color _plusGold = Color(0xffc79a33);
const Color _plusInk = Color(0xff173b2f);

class PlusScreen extends StatelessWidget {
  const PlusScreen({
    super.key,
    required this.isPlusMember,
    required this.onSubscribe,
    required this.onCancelMembership,
    required this.onBack,
  });

  final bool isPlusMember;
  final VoidCallback onSubscribe;
  final VoidCallback onCancelMembership;
  final VoidCallback onBack;

  static const List<String> _benefits = [
    'Unlock every Plus-exclusive item in the shop',
    'Earn double coins on each healthy day',
    'Level up 1.5x faster',
    'Buy Freeze Streak Tickets for missed days',
    'A Plus badge on your profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wealth Forest Plus'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _DemoBanner(),
                const SizedBox(height: 20),
                _header(context),
                const SizedBox(height: 24),
                for (final benefit in _benefits) _benefitRow(context, benefit),
                const SizedBox(height: 24),
                if (isPlusMember) ...[
                  const _ActiveBadge(),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('plus-cancel-button'),
                    onPressed: onCancelMembership,
                    child: const Text('Cancel membership'),
                  ),
                ] else
                  _planCards(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _plusGold.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium,
            size: 44,
            color: _plusGold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Grow faster with Plus',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: _plusInk,
          ),
        ),
      ],
    );
  }

  Widget _benefitRow(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: _plusGold, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _planCards(BuildContext context) {
    return Column(
      children: [
        _PlanCard(
          title: 'Monthly',
          price: '\$4.99',
          period: 'per month',
          onTap: () => _openCheckout(context, 'Monthly', '\$4.99'),
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: 'Yearly',
          price: '\$39.99',
          period: 'per year · save 33%',
          highlighted: true,
          onTap: () => _openCheckout(context, 'Yearly', '\$39.99'),
        ),
        const SizedBox(height: 12),
        _PlanCard(
          key: const Key('freeze-streak-ticket-card'),
          title: 'Freeze Streak Ticket',
          price: '\$0.99',
          period: 'each',
          onTap: () => _openTicketCheckout(context),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('plus-subscribe-button'),
          onPressed: () => _openCheckout(context, 'Yearly', '\$39.99'),
          icon: const Icon(Icons.workspace_premium),
          label: const Text('Get Plus'),
        ),
      ],
    );
  }

  void _openCheckout(BuildContext context, String plan, String price) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _CheckoutSheet(
        plan: plan,
        price: price,
        onConfirm: () {
          Navigator.of(sheetContext).pop();
          onSubscribe();
        },
      ),
    );
  }

  void _openTicketCheckout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _CheckoutSheet(
        plan: 'Freeze Streak Ticket',
        price: '\$0.99',
        lineItem: 'Freeze Streak Ticket',
        onConfirm: () {
          Navigator.of(sheetContext).pop();
          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Freeze Streak Ticket demo purchase'),
              ),
            );
        },
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('plus-demo-banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade700),
      ),
      child: Row(
        children: [
          Icon(Icons.science_outlined, color: Colors.amber.shade900, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demo only — no payment is taken and no card details are '
              'collected. Membership is simulated locally.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('plus-active-badge'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _plusGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: _plusGold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Plus is active (demo)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.period,
    required this.onTap,
    this.highlighted = false,
  });

  final String title;
  final String price;
  final String period;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: highlighted ? _plusGold : const Color(0xffe5decf),
            width: highlighted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(period, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text(
              price,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: _plusGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The simulated checkout. No input fields by design — see the file header.
class _CheckoutSheet extends StatelessWidget {
  const _CheckoutSheet({
    required this.plan,
    required this.price,
    String? lineItem,
    required this.onConfirm,
  }) : lineItem = lineItem ?? '$plan plan';

  final String plan;
  final String price;
  final String lineItem;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('plus-checkout-sheet'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DemoBanner(),
          const SizedBox(height: 20),
          Text(
            'Confirm your plan',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text(lineItem)),
              Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A real checkout would hand off to a payment provider here. '
            'This build simply switches membership on.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('plus-confirm-button'),
            onPressed: onConfirm,
            icon: const Icon(Icons.check),
            label: const Text('Simulate payment'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }
}
