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
    required this.onBuyFreezeTicket,
    required this.onBack,
  });

  final bool isPlusMember;
  final VoidCallback onSubscribe;
  final VoidCallback onCancelMembership;

  /// A single streak freeze, sold outside the subscription. Offered to
  /// members too — three freezes still run out on a bad month.
  final VoidCallback onBuyFreezeTicket;

  final VoidCallback onBack;

  static const List<String> _benefits = [
    // The freeze goes first on purpose. It is the only perk that changes what
    // happens on a bad day, which is the day that decides whether someone
    // keeps using this.
    'Hold 3 streak freezes instead of 1, and earn them twice as fast',
    'Unlock every Plus-exclusive item in the shop',
    'Earn double coins on each healthy day',
    'Level up 1.5x faster',
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
                const SizedBox(height: 24),
                _PartnerOfferCard(onTap: () => _showPartnerOffer(context)),
                const SizedBox(height: 16),
                _FreezeTicketCard(
                  onTap: () => _openCheckout(
                    context,
                    'Freeze Streak Ticket',
                    '\$0.99',
                    onConfirm: onBuyFreezeTicket,
                  ),
                ),
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

  /// Harbour Invest does not exist. The dialog says so because an in-app
  /// investment promotion that looks real is indistinguishable from an
  /// investment scam — and this lives beside the card rather than in the
  /// caller so the offer can never be shown without its disclosure.
  void _showPartnerOffer(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('partner-offer-dialog'),
        title: const Text('Harbour Invest'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Open an investment account with Harbour Invest and get 3 '
              'months of Plus at no cost.',
            ),
            SizedBox(height: 12),
            Text(
              'Demo only. Harbour Invest is a fictional company invented for '
              'this prototype — there is no account to open, no investment '
              'product and no offer. The link below goes nowhere.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'example.invalid/harbour-invest',
              style: TextStyle(
                color: Color(0xff1f4f7a),
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('partner-offer-close'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openCheckout(
    BuildContext context,
    String plan,
    String price, {
    VoidCallback? onConfirm,
  }) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _CheckoutSheet(
        plan: plan,
        price: price,
        onConfirm: () {
          Navigator.of(sheetContext).pop();
          (onConfirm ?? onSubscribe)();
        },
      ),
    );
  }
}

/// A one-off streak freeze. Separate from the subscription on purpose: the
/// person who needs it most is the one who just broke a streak and is not
/// ready to commit to a monthly plan.
/// A sponsored investment offer from a partner.
///
/// "Harbour Invest" is deliberately fictional. An in-app investment promotion
/// carrying a real bank's name would be an unauthorised financial promotion,
/// and "open an account, get a reward" is the standard shape of an investment
/// scam — so the brand is invented and the dialog says so outright.
class _PartnerOfferCard extends StatelessWidget {
  const _PartnerOfferCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('partner-offer-card'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff1f4f7a), Color(0xff2f7d9a)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SPONSORED · DEMO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Harbour Invest',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Open an investment account and get 3 months of Plus, free.',
              style: TextStyle(color: Colors.white, height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Learn more',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FreezeTicketCard extends StatelessWidget {
  const _FreezeTicketCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('freeze-ticket-card'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xffe8f5f3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xff3f8f8a)),
        ),
        child: Row(
          children: [
            const Icon(Icons.ac_unit, color: Color(0xff3f8f8a), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Freeze Streak Ticket',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'One freeze, used once. Keeps a streak alive on a day you '
                    'go over budget.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '\$0.99',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xff3f8f8a),
              ),
            ),
          ],
        ),
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
    required this.onConfirm,
  });

  final String plan;
  final String price;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    // A bottom sheet gets the height it asks for, and on a 390x844 phone this
    // content asked for 62pt more than there was. Scroll rather than clip, and
    // keep clear of the home indicator.
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
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
              Expanded(child: Text('$plan plan')),
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
        ),
      ),
    );
  }
}
