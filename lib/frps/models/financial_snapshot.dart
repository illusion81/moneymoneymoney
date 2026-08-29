class FinancialSnapshot {
  const FinancialSnapshot({
    required this.userId,
    required this.date,
    required this.income,
    required this.expenses,
    required this.assets,
    required this.liabilities,
    required this.monthlySavingsGoal,
  });

  final String userId;
  final DateTime date;
  final double income;
  final Map<String, double> expenses;
  final Map<String, double> assets;
  final Map<String, double> liabilities;
  final double monthlySavingsGoal;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'date': date.toIso8601String(),
        'income': income,
        'expenses': expenses,
        'assets': assets,
        'liabilities': liabilities,
        'monthlySavingsGoal': monthlySavingsGoal,
      };

  static FinancialSnapshot fromJson(Map<String, dynamic> json) => FinancialSnapshot(
        userId: json['userId'] as String,
        date: DateTime.parse(json['date'] as String),
        income: (json['income'] as num).toDouble(),
        expenses: _stringDoubleMap(json['expenses'] as Map<String, dynamic>),
        assets: _stringDoubleMap(json['assets'] as Map<String, dynamic>),
        liabilities: _stringDoubleMap(json['liabilities'] as Map<String, dynamic>),
        monthlySavingsGoal: (json['monthlySavingsGoal'] as num).toDouble(),
      );

  static Map<String, double> _stringDoubleMap(Map<String, dynamic> json) =>
      json.map((key, value) => MapEntry(key, (value as num).toDouble()));
}
