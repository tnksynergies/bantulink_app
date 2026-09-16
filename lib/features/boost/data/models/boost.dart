import 'boost_pack.dart';

class Boost {
  final int id;
  final String boostableType;
  final int boostableId;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;
  final bool isExpired;
  final String? paymentReference;
  final BoostPack? pack;

  Boost({
    required this.id,
    required this.boostableType,
    required this.boostableId,
    required this.startsAt,
    required this.endsAt,
    required this.isActive,
    required this.isExpired,
    this.paymentReference,
    this.pack,
  });

  factory Boost.fromJson(Map<String, dynamic> json) {
    return Boost(
      id: json['id'] ?? 0,
      boostableType: json['boostable_type'] ?? '',
      boostableId: json['boostable_id'] ?? 0,
      startsAt: DateTime.parse(json['starts_at']),
      endsAt: DateTime.parse(json['ends_at']),
      isActive: json['is_active'] ?? false,
      isExpired: json['is_expired'] ?? false,
      paymentReference: json['payment_reference'],
      pack: json['pack'] != null ? BoostPack.fromJson(json['pack']) : null,
    );
  }
}
