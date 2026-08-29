import 'dart:math';

enum DebtStrategy { avalanche, snowball }

class Debt {
  const Debt({
    required this.name,
    required this.balance,
    required this.annualRate,
    required this.minPayment,
  });
  final String name;
  final double balance;
  final double annualRate;   // e.g. 0.18 for 18%
  final double minPayment;
}

class DebtPayoffMonth {
  const DebtPayoffMonth({required this.date, required this.remainingBalances});
  final DateTime date;
  final Map<String, double> remainingBalances;
}

class DebtPayoffPlan {
  const DebtPayoffPlan({
    required this.schedule,
    required this.totalInterest,
    required this.totalPaid,
    required this.payoffDate,
    required this.monthsToPayoff,
  });
  final List<DebtPayoffMonth> schedule;
  final double totalInterest;
  final double totalPaid;
  final DateTime payoffDate;
  final int monthsToPayoff;
}

DebtPayoffPlan debtPayoffPlanner(
  List<Debt> debts, {
  DebtStrategy strategy = DebtStrategy.avalanche,
  double extraPayment = 0,
  DateTime? startDate,
}) {
  final start = startDate ?? DateTime(2000, 1, 1);

  for (final d in debts) {
    if (d.balance < 0 || d.minPayment <= 0) {
      throw ArgumentError('Each debt must have balance >= 0 and minPayment > 0');
    }
  }

  if (debts.isEmpty) {
    return DebtPayoffPlan(
      schedule: const [],
      totalInterest: 0,
      totalPaid: 0,
      payoffDate: startDate ?? DateTime(2000, 1, 1),
      monthsToPayoff: 0,
    );
  }

  final order = List<int>.generate(debts.length, (i) => i);
  if (strategy == DebtStrategy.avalanche) {
    order.sort((a, b) {
      final cmp = debts[b].annualRate.compareTo(debts[a].annualRate);
      return cmp != 0 ? cmp : a.compareTo(b);
    });
  } else {
    order.sort((a, b) {
      final cmp = debts[a].balance.compareTo(debts[b].balance);
      return cmp != 0 ? cmp : a.compareTo(b);
    });
  }

  final balances = List<double>.generate(debts.length, (i) => debts[i].balance);

  final schedule = <DebtPayoffMonth>[];
  var totalInterest = 0.0;
  var totalPaid = 0.0;

  var months = 0;
  for (var i = 0; i < 600; i++) {
    for (final idx in order) {
      if (balances[idx] > 0) {
        final interest = balances[idx] * debts[idx].annualRate / 12;
        balances[idx] += interest;
        totalInterest += interest;
      }
    }

    int? target;
    for (final idx in order) {
      if (balances[idx] > 0) {
        target = idx;
        break;
      }
    }

    for (final idx in order) {
      if (balances[idx] <= 0) continue;
      final pay = (idx == target)
          ? min(balances[idx], debts[idx].minPayment + extraPayment)
          : min(balances[idx], debts[idx].minPayment);
      balances[idx] -= pay;
      totalPaid += pay;
    }

    months++;
    final remaining = <String, double>{};
    for (final idx in order) {
      remaining[debts[idx].name] = double.parse(balances[idx].toStringAsFixed(2));
    }
    schedule.add(DebtPayoffMonth(
      date: DateTime(start.year, start.month + months, start.day),
      remainingBalances: remaining,
    ));

    if (order.every((idx) => balances[idx] <= 0.005)) break;
  }

  return DebtPayoffPlan(
    schedule: schedule,
    totalInterest: totalInterest,
    totalPaid: totalPaid,
    payoffDate: DateTime(start.year, start.month + months, start.day),
    monthsToPayoff: months,
  );
}
