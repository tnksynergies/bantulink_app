class Promotion {
  final int id;
  final String type;
  final String titleFr;
  final String titleEn;
  final String? descriptionFr;
  final String? descriptionEn;
  final String discountType;
  final int discountValue;
  final String? code;
  final String? image;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? usageLimit;
  final int usageCount;

  Promotion({
    required this.id,
    required this.type,
    required this.titleFr,
    required this.titleEn,
    this.descriptionFr,
    this.descriptionEn,
    required this.discountType,
    required this.discountValue,
    this.code,
    this.image,
    this.startsAt,
    this.endsAt,
    this.usageLimit,
    required this.usageCount,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      titleFr: json['title_fr'] ?? '',
      titleEn: json['title_en'] ?? '',
      descriptionFr: json['description_fr'],
      descriptionEn: json['description_en'],
      discountType: json['discount_type'] ?? 'percent',
      discountValue: json['discount_value'] ?? 0,
      code: json['code'],
      image: json['image'],
      startsAt: json['starts_at'] != null ? DateTime.tryParse(json['starts_at']) : null,
      endsAt: json['ends_at'] != null ? DateTime.tryParse(json['ends_at']) : null,
      usageLimit: json['usage_limit'],
      usageCount: json['usage_count'] ?? 0,
    );
  }

  String get discountLabel {
    if (discountType == 'percent') return '-$discountValue%';
    return '-${discountValue} FCFA';
  }
}
