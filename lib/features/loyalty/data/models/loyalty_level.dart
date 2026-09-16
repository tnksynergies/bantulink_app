class LoyaltyLevel {
  final int id;
  final String name;
  final String labelFr;
  final String labelEn;
  final String? icon;
  final String? color;
  final int minPoints;
  final double multiplier;
  final List<String> perks;

  LoyaltyLevel({
    required this.id,
    required this.name,
    required this.labelFr,
    required this.labelEn,
    this.icon,
    this.color,
    required this.minPoints,
    required this.multiplier,
    required this.perks,
  });

  factory LoyaltyLevel.fromJson(Map<String, dynamic> json) {
    return LoyaltyLevel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      labelFr: json['label_fr'] ?? '',
      labelEn: json['label_en'] ?? '',
      icon: json['icon'],
      color: json['color'],
      minPoints: json['min_points'] ?? 0,
      multiplier: (json['multiplier'] ?? 1.0).toDouble(),
      perks: (json['perks'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
