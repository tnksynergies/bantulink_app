import 'package:dio/dio.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_unwrap.dart';
import 'models/cart_item.dart';
import 'models/order.dart';
import 'models/product.dart';

/// Endpoints marketplace cote acheteur + catalogue public.
///
/// Public :
///   GET /produits, /produits/search, /produits/categorie/{id}, /produits/{id}
///   GET /categorie-produits
/// Auth (acheteur) :
///   POST /profile/acheteur                (cree le profil acheteur + role)
///   GET/POST/DELETE /panier               (panier persistant)
///   GET/POST/DELETE /favoris
///   GET /commandes, GET /commandes/{id}, POST /commandes
///   GET /option-livraisons, GET /mode-paiements
class MarketRemoteDataSource {
  MarketRemoteDataSource(this._dio);
  final Dio _dio;

  // ---------- Catalogue public ----------

  Future<List<Product>> listProducts() async {
    try {
      final res = await _dio.get('/produits');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Product>> searchProducts({
    String? nom,
    num? prixMin,
    num? prixMax,
  }) async {
    try {
      final res = await _dio.get('/produits/search', queryParameters: {
        if (nom != null && nom.isNotEmpty) 'nom': nom,
        if (prixMin != null) 'prix_min': prixMin,
        if (prixMax != null) 'prix_max': prixMax,
      });
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Product>> productsByCategory(int categoryId) async {
    try {
      final res = await _dio.get('/produits/categorie/$categoryId');
      final data = res.data;
      // Reponse : { message, produits: [...] }
      final list = (data is Map && data['produits'] is List)
          ? data['produits'] as List
          : unwrapList(data);
      return list
          .whereType<Map>()
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Product> getProduct(int id) async {
    try {
      final res = await _dio.get('/produits/$id');
      return Product.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ProductCategory>> categories() async {
    try {
      final res = await _dio.get('/categorie-produits');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => ProductCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---------- Profil acheteur ----------

  /// Cree le profil acheteur (role + table). A appeler UNE SEULE FOIS
  /// (aucune garde anti-doublon cote back) : verifier user.raw['acheteur']
  /// avant.
  Future<void> registerAcheteur() async {
    try {
      await _dio.post('/profile/acheteur');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---------- Panier ----------

  Future<List<CartItem>> cart() async {
    try {
      final res = await _dio.get('/panier');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> addToCart({
    required int produitId,
    required int quantite,
    List<int> attributValeurIds = const [],
  }) async {
    try {
      await _dio.post('/panier', data: {
        'produit_id': produitId,
        'quantite': quantite,
        if (attributValeurIds.isNotEmpty)
          'produit_attribut_valeurs': attributValeurIds,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// DELETE /panier/{produit_id} : retire un produit du panier.
  Future<void> removeFromCart(int produitId) async {
    try {
      await _dio.delete('/panier/$produitId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> clearCart() async {
    try {
      await _dio.delete('/panier');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---------- Favoris ----------

  Future<List<Product>> favorites() async {
    try {
      final res = await _dio.get('/favoris');
      // FavoriResource contient probablement { produit: {...} } ou le produit
      // directement : on tente les deux formes.
      return unwrapList(res.data).whereType<Map>().map((e) {
        final m = Map<String, dynamic>.from(e);
        final p = m['produit'];
        if (p is Map) return Product.fromJson(Map<String, dynamic>.from(p));
        return Product.fromJson(m);
      }).toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> addFavorite(int produitId) async {
    try {
      await _dio.post('/favoris', data: {'produit_id': produitId});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> removeFavorite(int produitId) async {
    try {
      await _dio.delete('/favoris/$produitId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---------- Commandes ----------

  Future<List<Order>> myOrders() async {
    try {
      final res = await _dio.get('/commandes');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Order.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Order> getOrder(int id) async {
    try {
      final res = await _dio.get('/commandes/$id');
      return Order.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Transforme le panier (commande en_attente) en commande confirmee.
  Future<Order> checkout({
    required int optionLivraisonId,
    required int modePaiementId,
    String? adresse,
    String? ville,
    String? pays,
    String? telephone,
    String? couponCode,
  }) async {
    try {
      final res = await _dio.post('/commandes', data: {
        'option_livraison_id': optionLivraisonId,
        'mode_paiement_id': modePaiementId,
        if (adresse != null && adresse.isNotEmpty) 'adresse_livraison': adresse,
        if (ville != null && ville.isNotEmpty) 'ville_livraison': ville,
        if (pays != null && pays.isNotEmpty) 'pays_livraison': pays,
        if (telephone != null && telephone.isNotEmpty) 'tel_livraison': telephone,
        if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
      });
      return Order.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---------- Referentiels checkout ----------

  Future<List<DeliveryOption>> deliveryOptions() async {
    try {
      final res = await _dio.get('/option-livraisons');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => DeliveryOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<PaymentModeOption>> paymentModes() async {
    try {
      final res = await _dio.get('/mode-paiements');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => PaymentModeOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---------- Paiement Mobile Money (Moala) ----------

  /// Initie un paiement Mobile Money pour une commande.
  /// Aligne sur la version web : POST /paiements/initiate-payment
  ///   {amount, phone (237XXXXXXXXX), provider (OM|MOMO),
  ///    type: 'marketplace', commande_id}
  /// Retourne la reference pour le polling.
  Future<String?> initiateOrderPayment({
    required num amount,
    required String phone,
    required String provider,
    required int commandeId,
  }) async {
    try {
      final res = await _dio.post('/paiements/initiate-payment', data: {
        'amount': amount,
        'phone': phone,
        'provider': provider,
        'type': 'marketplace',
        'commande_id': commandeId,
      });
      final data = res.data;
      if (data is! Map) return null;
      return (data['data']?['partnerId'] ??
              data['partnerId'] ??
              data['reference'] ??
              data['data']?['reference'])
          ?.toString();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Poll unique /paiements/status/:ref -> 'success'|'failed'|'pending'|null.
  Future<String?> paymentStatus(String reference) async {
    try {
      final res = await _dio.get('/paiements/status/$reference');
      final data = res.data;
      if (data is Map) {
        return (data['status'] ?? data['data']?['status'])
            ?.toString()
            .toLowerCase();
      }
    } on DioException catch (_) {
      return null;
    }
    return null;
  }

  /// Historique des paiements marketplace de l'utilisateur.
  Future<List<Map<String, dynamic>>> paymentsHistory() async {
    try {
      final res = await _dio.get('/paiements/history',
          queryParameters: {'type': 'marketplace'});
      // Reponse potentiellement paginee : data.data ou data.
      final body = res.data;
      dynamic list = body;
      if (body is Map) {
        list = body['data'];
        if (list is Map && list['data'] is List) list = list['data'];
      }
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
