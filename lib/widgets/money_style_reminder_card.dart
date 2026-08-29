import 'package:flutter/material.dart';

/// A quiet "you can still do this later" reminder, shown after the user skips
/// the Money Style questionnaire.
///
/// Deliberately non-intrusive: an inline dismissible card, not a dialog and
/// not a notification. The app has no scheduler, and a persisted
/// "not-yet-completed, offer to resume" flag surfaced where the user actually
/// lands is enough to keep the offer alive without nagging.
class MoneyStyleReminderCard extends StatelessWidget {
  const MoneyStyleReminderCard({
    super.key,
    required this.onResume,
    this.onDismiss,
    this.message =
        'You skipped the Money Style questions. They take 2–3 minutes and '
        'you can do them whenever you like.',
  });

  final VoidCallback onResume;
  final VoidCallback? onDismiss;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('money-style-reminder'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff3f0e2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffd9d2ba)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 10, top: 2),
                child: Icon(
                  Icons.psychology_outlined,
                  size: 20,
                  color: Color(0xff2f7d50),
                ),
              ),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onDismiss != null)
                TextButton(
                  key: const Key('money-style-reminder-dismiss'),
                  onPressed: onDismiss,
                  child: const Text('Not now'),
                ),
              TextButton(
                key: const Key('money-style-reminder-resume'),
                onPressed: onResume,
                child: const Text('Take it now'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
