// Large planned expenses — concert tickets, a flight, a laptop.
//
// The point of this screen: saving for something on purpose is not the same as
// overspending. The backend reserves goal money before it judges any bucket, so
// putting $60 a week aside for a concert never cracks the tower.

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Goal> _goals = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _goals = await widget.api.goals();
      _error = null;
    } on ApiException catch (e) {
      _error = e.needsSurvey
          ? 'Finish the questionnaire first — we need your income to work out what fits.'
          : e.message;
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _money(double v) => '\$${v.toStringAsFixed(v.abs() >= 100 ? 0 : 2)}';

  Future<void> _addGoal() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _AddGoalSheet(api: widget.api),
      ),
    );
    if (created == true) _load();
  }

  Future<void> _contribute(Goal g) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Put money toward ${g.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: '\$ ',
            labelText: 'Amount',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(controller.text)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    try {
      await widget.api.contributeToGoal(g.id, amount);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Saving for something')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGoal,
        icon: const Icon(Icons.add),
        label: const Text('New goal'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _goals.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.savings_outlined, size: 44),
                            const SizedBox(height: 12),
                            Text('Nothing saved for yet', style: t.titleMedium),
                            const SizedBox(height: 6),
                            Text(
                              'Concert tickets, a flight home, a new laptop. '
                              'Add one and we will work out what it costs a week '
                              'and set that money aside before judging your spending.',
                              textAlign: TextAlign.center,
                              style: t.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: _goals.length,
                        itemBuilder: (_, i) => _goalCard(_goals[i]),
                      ),
                    ),
    );
  }

  Widget _goalCard(Goal g) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(g.name, style: t.titleMedium)),
            Text('${_money(g.savedSoFar)} / ${_money(g.targetAmount)}',
                style: t.titleSmall),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: g.progress,
              minHeight: 9,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                  g.funded ? const Color(0xff2f7d50) : scheme.primary),
            ),
          ),
          const SizedBox(height: 10),
          Text(g.headline, style: t.bodyMedium),
          if (g.warning != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(g.warning!, style: t.bodySmall),
            ),
          ],
          const SizedBox(height: 10),
          Row(children: [
            _chip('${g.daysLeft} days left'),
            const SizedBox(width: 8),
            if (!g.funded) _chip('${_money(g.perWeekNeeded)}/week'),
            const Spacer(),
            if (!g.funded)
              TextButton(
                  onPressed: () => _contribute(g),
                  child: const Text('Add money')),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () async {
                await widget.api.deleteGoal(g.id);
                _load();
              },
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      );
}

class _AddGoalSheet extends StatefulWidget {
  const _AddGoalSheet({required this.api});
  final ApiClient api;

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _saved = TextEditingController(text: '0');
  DateTime _date = DateTime.now().add(const Duration(days: 42));
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final amount = double.tryParse(_amount.text);
    if (_name.text.trim().isEmpty || amount == null || amount <= 0) {
      setState(() => _error = 'Give it a name and an amount.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.addGoal(
        name: _name.text.trim(),
        targetAmount: amount,
        targetDate: _date.toIso8601String().substring(0, 10),
        savedSoFar: double.tryParse(_saved.text) ?? 0,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('What are you saving for?',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(
                labelText: 'Concert tickets, flight home, laptop…',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'How much do you need?',
                prefixText: '\$ ',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _saved,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Already put aside',
                prefixText: '\$ ',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: const Text('When do you need it?'),
            subtitle: Text(_date.toIso8601String().substring(0, 10)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Saving…' : 'Add goal'),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      );
}
