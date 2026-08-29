import 'package:flutter/material.dart';

import 'package:moneymoneymoney/frps/slm/slm_interface.dart';
import 'package:moneymoneymoney/frps/storage/repository.dart';
import 'package:moneymoneymoney/models/finance_profile.dart';

import '../frps_ui/frps_report_controller.dart';
import '../frps_ui/frps_report_view.dart';

/// The on-demand deep financial report screen.
///
/// Runs the FRPS planner over the given user's stored profile and renders the
/// assembled report. This widget is deliberately navigation-free: the
/// orchestrator owns the route and passes [onBack]. See
/// `docs/features/frps-report.md` for how to wire it.
class FrpsReportScreen extends StatefulWidget {
  const FrpsReportScreen({
    super.key,
    required this.repository,
    required this.userId,
    this.seedProfile,
    this.slm,
    this.onBack,
  });

  /// Where FRPS data is read from (and written back to).
  final FrpsRepository repository;

  /// The id of the user to report on.
  final String userId;

  /// When provided, the on-device profile is written into the repository before
  /// the report runs, so the report always reflects the latest answers. When
  /// null, the repository is expected to already hold FRPS data.
  final FinanceProfile? seedProfile;

  /// Narrative engine override; defaults to the slot SLM.
  final SlmInterface? slm;

  final VoidCallback? onBack;

  @override
  State<FrpsReportScreen> createState() => _FrpsReportScreenState();
}

class _FrpsReportScreenState extends State<FrpsReportScreen> {
  late final FrpsReportController _controller;
  FrpsReportOutcome _outcome = const FrpsReportOutcome.loading();

  @override
  void initState() {
    super.initState();
    _controller = FrpsReportController(
      repository: widget.repository,
      slm: widget.slm,
    );
    _generate();
  }

  Future<void> _generate() async {
    final outcome = await _controller.generate(
      userId: widget.userId,
      seedProfile: widget.seedProfile,
    );
    if (!mounted) return;
    setState(() => _outcome = outcome);
  }

  Future<void> _retry() async {
    setState(() => _outcome = const FrpsReportOutcome.loading());
    await _generate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deep Report'),
        leading: widget.onBack == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: _body(),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_outcome.status) {
      case FrpsReportStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case FrpsReportStatus.empty:
        return _MessagePanel(
          icon: Icons.inbox_outlined,
          title: 'Nothing to report yet',
          message: _outcome.message ?? '',
          onRetry: _retry,
        );
      case FrpsReportStatus.error:
        return _MessagePanel(
          icon: Icons.error_outline,
          title: 'Something went wrong',
          message: _outcome.message ?? '',
          onRetry: _retry,
        );
      case FrpsReportStatus.loaded:
        return FrpsReportView(data: _outcome.data!);
    }
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xff173b2f),
            ),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
