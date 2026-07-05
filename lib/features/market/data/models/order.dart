import 'cart_item.dart';

/// Statuts de commande cote back : en_attente | validee/confirmee | payee |
/// expediee | livree | annulee (tolerant, valeurs exactes non figees).
enum OrderStatus {
  enAttente,
  confirmee,
  payee,
  expediee,
  livree,
  annulee,
  inconnu;

  static OrderStatus fromApi(String? raw) {
    final s = (raw ?? '').toLowerCase().trim();
    if (s.isEmpty) return OrderStatus.inconnu;
    if (s.contains('attente') || s == 'pending') return OrderStatus.enAttente;
    if (s.contains('valid') || s.contains('confirm')) return OrderStatus.confirmee;
    if (s.contains('pay')) return OrderStatus.payee;
    if (s.contains('exped') || s.contains('ship')) return OrderStatus.expediee;
    if (s.contains('livr') || s.contains('deliver')) return OrderStatus.livree;
    if (s.contains('annul') || s.contains('cancel')) return OrderStatus.annulee;
    return OrderStatus.inconnu;
  }

  String get i18nKey {
    switch (this) {
      case OrderStatus.enAttente:
        return 'market.order.status.pending';
      case OrderStatus.confirmee:
        return 'market.order.status.confirmed';
      case OrderStatus.payee:
        return 'market.order.status.paid';
      case OrderStatus.expediee:
        return 'market.order.status.shipped';
      case OrderStatus.livree:
        return 'market.order.status.delivered';
      case OrderStatus.annulee:
        return 'market.order.status.cancelled';
      case OrderStatus.inconnu:
        return 'market.order.status.pending';
    }
  }
}

class Order {
  const Order({
    required this.id,
    this.statutRaw,
    this.sousTotal,
    this.fraisLivraison,
    this.total,
    this.adresseLivraison,
    this.villeLivraison,
    this.paysLivraison,
    this.telLivraison,
    this.dateCommande,
    this.produits = const [],
    this.raw = const {},
  });

  final int id;
  final String? statutRaw;
  final num? sousTotal;
  final num? fraisLivraison;
  final num? total;
  final String? adresseLivraison;
  final String? villeLivraison;
  final String? paysLivraison;
  final String? telLivraison;
  final String? dateCommande;
  final List<CartItem> produits;
  final Map<String, dynamic> raw;

  OrderStatus get status => OrderStatus.fromApi(statutRaw);

  String get dateCourt => (dateCommande != null && dateCommande!.length >= 10)
      ? dateCommande!.substring(0, 10)
      : (dateCommande ?? '');

  int get itemsCount => produits.fold(0, (acc, p) => acc + p.quantite);

  factory Order.fromJson(Map<String, dynamic> j) {
    final produits = <CartItem>[];
    if (j['produits'] is List) {
      for (final p in j['produits'] as List) {
        if (p is Map) produits.add(CartItem.fromJson(Map<String, dynamic>.from(p)));
      }
    }
    return Order(
      id: _i(j['id']),
      statutRaw: _s(j['statut']),
      sousTotal: _num(j['sous_total']),
      fraisLivraison: _num(j['frais_livraison']),
      total: _num(j['total']),
      adresseLivraison: _s(j['adresse_livraison']),
      villeLivraison: _s(j['ville_livraison']),
      paysLivraison: _s(j['pays_livraison']),
      telLivraison: _s(j['tel_livraison']),
      dateCommande: _s(j['date_commande']) ?? _s(j['created_at']),
      produits: produits,
      raw: j,
    );
  }
}

/// Option de livraison de base (catalogue global GET /option-livraisons).
class DeliveryOption {
  const DeliveryOption({required this.id, required this.nom, this.description, this.prix});

  final int id;
  final String nom;
  final String? description;
  final num? prix;

  factory DeliveryOption.fromJson(Map<String, dynamic> j) {
    return DeliveryOption(
      id: _i(j['id']),
      nom: _s(j['nom']) ?? _s(j['name']) ?? _s(j['libelle']) ?? 'Option #${j['id']}',
      description: _s(j['description']),
      prix: _num(j['prix']) ?? _num(j['pivot']?['prix']),
    );
  }
}

/// Mode de paiement (catalogue global GET /mode-paiements).
class PaymentModeOption {
  const PaymentModeOption({required this.id, required this.nom, this.description});

  final int id;
  final String nom;
  final String? description;

  factory PaymentModeOption.fromJson(Map<String, dynamic> j) {
    return PaymentModeOption(
      id: _i(j['id']),
      nom: _s(j['nom']) ?? _s(j['name']) ?? _s(j['libelle']) ?? 'Mode #${j['id']}',
      description: _s(j['description']),
    );
  }
}

int _i(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

num? _num(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

String? _s(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}
