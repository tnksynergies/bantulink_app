import 'loyalty_level.dart';

class LoyaltyAccount {
  final int totalPoints;
  final int availablePoints;
  final LoyaltyLevel? level;
  final LoyaltyLevel? nextLevel;
  final int conversionRate;

  LoyaltyAccount({
    required this.totalPoints,
    required this.availablePoints,
    this.level,
    this.nextLevel,
    required this.conversionRate,
  });

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) {
    final account = json['account'] ?? {};
    return LoyaltyAccount(
      totalPoints: account['total_points'] ?? 0,
      availablePoints: account['available_points'] ?? 0,
      level: account['level'] != null
          ? LoyaltyLevel.fromJson(account['level'])
          : null,
      nextLevel: json['next_level'] != null
          ? LoyaltyLevel.fromJson(json['next_level'])
          : null,
      conversionRate: json['conversion_rate'] ?? 100,
    );
  }

  double get progressToNext {
    if (nextLevel == null) return 1.0;
    final currentMin = level?.minPoints ?? 0;
    final range = nextLevel!.minPoints - currentMin;
    if (range <= 0) return 1.0;
    return ((totalPoints - currentMin) / range).clamp(0.0, 1.0);
  }
}
