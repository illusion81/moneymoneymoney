// The missing entry point: how a user links a bank.
//
// Wire it from the home screen's app bar or from onboarding:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => ConnectBankScreen(api: ApiClient()),
//   ));
//
// Flow: tap Connect -> backend returns a Basiq consent URL -> we open it in a
// browser -> the user logs in at their bank -> we poll until the connection
// goes active -> data starts flowing. The app never sees bank credentials.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api_client.dart';

class ConnectBankScreen extends StatefulWidget {
  const ConnectBankScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<ConnectBankScreen> createState() => _ConnectBankScreenState();
}

class _ConnectBankScreenState extends State<ConnectBankScreen> {
  String _provider = 'mock';
  bool _busy = false;
  bool _waiting = false;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await widget.api.providerName();
      if (mounted) setState(() => _provider = p);
    } catch (_) {}
  }

  /// Most people will never finish a bank consent flow. Let them hand us a
  /// statement instead — same data, no credentials, no accreditation.
  Future<void> _upload() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'pdf'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final f = picked.files.first;
      if (f.bytes == null) {
        setState(() => _error = 'Could not read that file.');
        return;
      }
      final status = await widget.api.uploadStatement(
        filename: f.name,
        bytes: f.bytes!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(status.message)));
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final s = await widget.api.connectBank();
      if (s.connected) {
        _finish();
        return;
      }
      if (s.consentUrl == null) {
        setState(
          () => _error =
              'No bank connection configured on the server. Running on demo data.',
        );
        return;
      }

      final uri = Uri.parse(s.consentUrl!);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        setState(() => _error = 'Could not open the consent page.');
        return;
      }

      // The user is now at their bank. Poll until the connection goes active.
      setState(() => _waiting = true);
      _poll = Timer.periodic(const Duration(seconds: 4), (t) async {
        try {
          if (await widget.api.dataTrusted()) {
            t.cancel();
            _finish();
          }
        } catch (_) {}
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _finish() {
    _poll?.cancel();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bank connected — your spending syncs automatically.'),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Connect your bank')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stop typing your spending', style: t.headlineSmall),
            const SizedBox(height: 12),
            Text(
              'Connect once and your transactions arrive on their own. '
              'No logging, no receipts — the forest grows from what you actually spend.',
              style: t.bodyLarge,
            ),
            const SizedBox(height: 28),

            _Point(
              icon: Icons.lock_outline,
              title: 'We never see your login',
              body:
                  'You sign in at your own bank. We only receive transactions.',
            ),
            _Point(
              icon: Icons.visibility_off_outlined,
              title: 'Read-only',
              body: 'Nothing here can move, spend or transfer your money.',
            ),
            _Point(
              icon: Icons.event_available_outlined,
              title: 'You control the window',
              body:
                  'Consent lasts up to 12 months and you can disconnect any time '
                  'from your bank or from here.',
            ),

            const SizedBox(height: 28),
            if (_provider != 'basiq')
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Currently on $_provider data. Connecting a real bank replaces it.',
                  style: t.bodySmall,
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_waiting)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Waiting for you to finish at your bank…'),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy || _waiting ? null : _connect,
                icon: const Icon(Icons.account_balance),
                label: Text(_busy ? 'Opening…' : 'Connect my bank'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy || _waiting ? null : _upload,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload a statement (CSV or PDF)'),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Export from your banking app. The file is read on your own '
              'machine and never sent to a third party.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Skip for now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title, body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(body, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}
