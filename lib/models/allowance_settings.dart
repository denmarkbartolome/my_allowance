enum AllowancePeriod {
  weekly,
  monthly;

  String get label => this == weekly ? 'Weekly' : 'Monthly';
  String get noun => this == weekly ? 'week' : 'month';
}

class AllowanceSettings {
  const AllowanceSettings({required this.amount, required this.period});

  static const empty =
      AllowanceSettings(amount: 0, period: AllowancePeriod.weekly);

  final double amount;
  final AllowancePeriod period;

  factory AllowanceSettings.fromMap(Map<String, dynamic> m) => AllowanceSettings(
        amount: (m['amount'] as num).toDouble(),
        period: AllowancePeriod.values.firstWhere(
          (p) => p.name == m['period'],
          orElse: () => AllowancePeriod.weekly,
        ),
      );
}
