class BoostPack {
  final int id;
  final String name;
  final String labelFr;
  final String labelEn;
  final int price;
  final int durationDays;
  final List<String> features;
  final bool isActive;

  BoostPack({
    required this.id,
    required this.name,
    required this.labelFr,
    required this.labelEn,
    required this.price,
    required this.durationDays,
    required this.features,
    required this.isActive,
  });

  factory BoostPack.fromJson(Map<String, dynamic> json) {
    return BoostPack(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      labelFr: json['label_fr'] ?? '',
      labelEn: json['label_en'] ?? '',
      price: json['price'] ?? 0,
      durationDays: json['duration_days'] ?? 0,
      features: (json['features'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isActive: json['is_active'] ?? true,
    );
  }
}
