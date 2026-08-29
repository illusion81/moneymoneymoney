class UserProfile {
  const UserProfile({required this.monthlyIncome, required this.age});

  final double monthlyIncome;
  final int age;

  Map<String, dynamic> toJson() => {
        'monthlyIncome': monthlyIncome,
        'age': age,
      };

  static UserProfile fromJson(Map<String, dynamic> json) => UserProfile(
        monthlyIncome: (json['monthlyIncome'] as num).toDouble(),
        age: json['age'] as int,
      );
}
