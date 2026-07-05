import 'product.dart';

/// Item du panier tel que renvoye par GET /panier
/// (PanierResource -> CommandeProduitResource) :
/// { produit: SimpleProduit, attributs: [...], quantite, prix_unitaire, prix_total }
class CartItem {
  const CartItem({
    required this.produit,
    required this.quantite,
    this.prixUnitaire,
    this.prixTotal,
    this.attributs = const [],
  });

  final Product produit;
  final int quantite;
  final num? prixUnitaire;
  final num? prixTotal;
  final List<ProductAttribute> attributs;

  /// L'id utilise pour DELETE /panier/{produit_id}.
  int get produitId => produit.id;

  num get lineTotal => prixTotal ?? ((prixUnitaire ?? produit.prix ?? 0) * quantite);

  factory CartItem.fromJson(Map<String, dynamic> j) {
    final prodRaw = j['produit'];
    final produit = prodRaw is Map
        ? Product.fromJson(Map<String, dynamic>.from(prodRaw))
        : Product(id: _i(j['produit_id'] ?? j['id']));

    final attributs = <ProductAttribute>[];
    if (j['attributs'] is List) {
      for (final a in j['attributs'] as List) {
        if (a is Map) {
          attributs.add(ProductAttribute.fromJson(Map<String, dynamic>.from(a)));
        }
      }
    }

    return CartItem(
      produit: produit,
      quantite: _i(j['quantite']),
      prixUnitaire: _num(j['prix_unitaire']),
      prixTotal: _num(j['prix_total']),
      attributs: attributs,
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
