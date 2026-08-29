// A 4-digit gate in front of the demo simulation controls.
//
// This is a demo convenience, NOT security. It stops a judge or a passer-by
// tapping "Simulate a week" and fast-forwarding the farm mid-pitch. Anyone with
// the source can read the PIN, and that is fine — it is guarding a debug
// button, not an account. Never put anything real behind this.

import 'package:flutter/material.dart';

class DevGate {
  DevGate._();

  /// Demo PIN. Change it in one place.
  static const String pin = '2026';

  static bool _unlocked = false;
  static bool get isUnlocked => _unlocked;
  static void lock() => _unlocked = false;

  /// Returns true when dev mode is (or becomes) unlocked.
  static Future<bool> ensureUnlocked(BuildContext context) async {
    if (_unlocked) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _PinDialog(),
    );
    return ok ?? false;
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog();

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim() == DevGate.pin) {
      DevGate._unlocked = true;
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Wrong code');
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Developer mode'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter the 4-digit code to unlock demo controls.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          TextField(
            key: const Key('dev-pin-field'),
            controller: _controller,
            autofocus: true,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, letterSpacing: 10),
            decoration: InputDecoration(
              counterText: '',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Unlock')),
      ],
    );
  }
}
