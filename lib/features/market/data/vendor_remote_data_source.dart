import 'package:dio/dio.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_unwrap.dart';
import '../../freelancers/data/upload_file.dart';
import 'models/order.dart';
import 'models/product.dart';

/// Donnees du wallet vendeur.
class VendorWallet {
  const VendorWallet({required this.balance, this.transactions = const []});
  final num balance;
  final List<Map<String, dynamic>> transactions;
}

/// Endpoints marketplace cote vendeur (gates can:isVendeur).
///
///   POST /profile/vendeur                  (inscription vendeur, multipart)
///   GET  /vendeur/produits                 (mes produits)
///   POST /vendeur/produits                 (creer, multipart images[])
///   PUT  /vendeur/produits/{id}
///   DELETE /vendeur/produits/{id}
///   POST /vendeur/produits/{id}/media
///   GET  /vendeur/wallet, POST /vendeur/wallet/withdraw
///   GET/POST/DELETE /vendeur/option-livraisons
class VendorRemoteDataSource {
  VendorRemoteDataSource(this._dio);
  final Dio _dio;

  /// Inscription vendeur : nom boutique, email pro, telephone, description,
  /// adresse, ville, pays requis + logo/couverture optionnels.
  Future<void> registerVendeur({
    required String nom,
    required String email,
    required String telephone,
    required String description,
    required String adresse,
    required String ville,
    required String pays,
    String? slogan,
    String? numContribuable,
    UploadFile? logo,
    UploadFile? couverture,
  }) async {
    try {
      final form = FormData();
      form.fields.addAll([
        MapEntry('nom', nom),
        MapEntry('email', email),
        MapEntry('telephone', telephone),
        MapEntry('description', description),
        MapEntry('adresse', adresse),
        MapEntry('ville', ville),
        MapEntry('pays', pays),
      ]);
      if (slogan != null && slogan.isNotEmpty) {
        form.fields.add(MapEntry('slogan', slogan));
      }
      if (numContribuable != null && numContribuable.isNotEmpty) {
        form.fields.add(MapEntry('num_contribuable', numContribuable));
      }
      if (logo != null) form.files.add(MapEntry('logo', logo.toMultipart()));
      if (couverture != null) {
        form.files.add(MapEntry('couverture', couverture.toMultipart()));
      }
      await _dio.post('/profile/vendeur', data: form);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Product>> myProducts() async {
    try {
      final res = await _dio.get('/vendeur/produits');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Product> createProduct({
    required String nom,
    required num prix,
    required int stockQtte,
    required int categorieId,
    String? description,
    List<UploadFile> images = const [],
  }) async {
    try {
      final form = FormData();
      form.fields.addAll([
        MapEntry('nom', nom),
        MapEntry('prix', prix.toString()),
        MapEntry('stock_qtte', stockQtte.toString()),
        MapEntry('categorie_id', categorieId.toString()),
      ]);
      if (description != null && description.isNotEmpty) {
        form.fields.add(MapEntry('description', description));
      }
      for (final f in images) {
        form.files.add(MapEntry('images[]', f.toMultipart()));
      }
      final res = await _dio.post('/vendeur/produits', data: form);
      return Product.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> updateProduct(
    int id, {
    String? nom,
    String? description,
    num? prix,
    int? stockQtte,
    int? categorieId,
  }) async {
    try {
      await _dio.put('/vendeur/produits/$id', data: {
        if (nom != null) 'nom': nom,
        if (description != null) 'description': description,
        if (prix != null) 'prix': prix,
        if (stockQtte != null) 'stock_qtte': stockQtte,
        if (categorieId != null) 'categorie_id': categorieId,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete('/vendeur/produits/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Ajoute des images a un produit existant.
  Future<void> addProductMedia(int id, {List<UploadFile> images = const []}) async {
    try {
      final form = FormData();
      for (final f in images) {
        form.files.add(MapEntry('images[]', f.toMultipart()));
      }
      await _dio.post('/vendeur/produits/$id/media', data: form);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteProductMedia(int produitId, int mediaId) async {
    try {
      await _dio.delete('/vendeur/produits/$produitId/media/$mediaId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---------- Commandes recues ----------

  /// Toutes les commandes (GET /commandes/all). Le filtrage par vendeur
  /// se fait cote app (comme la version web) car le back n'expose pas
  /// d'endpoint dedie vendeur.
  Future<List<Order>> allOrders() async {
    try {
      final res = await _dio.get('/commandes/all');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Order.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Met a jour le profil boutique (POST /profile/vendeur/update).
  Future<void> updateProfile({
    String? nom,
    String? description,
    String? slogan,
    String? adresse,
    String? ville,
    String? pays,
    String? telephone,
    String? email,
    String? numContribuable,
    UploadFile? logo,
    UploadFile? couverture,
  }) async {
    try {
      final form = FormData();
      void add(String key, String? v) {
        if (v != null && v.isNotEmpty) form.fields.add(MapEntry(key, v));
      }

      add('nom', nom);
      add('description', description);
      add('slogan', slogan);
      add('adresse', adresse);
      add('ville', ville);
      add('pays', pays);
      add('telephone', telephone);
      add('email', email);
      add('num_contribuable', numContribuable);
      if (logo != null) {
        form.files.add(MapEntry('logo_img', logo.toMultipart()));
      }
      if (couverture != null) {
        form.files.add(MapEntry('couverture_img', couverture.toMultipart()));
      }
      await _dio.post('/profile/vendeur/update', data: form);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---------- Wallet ----------

  Future<VendorWallet> wallet() async {
    try {
      final res = await _dio.get('/vendeur/wallet');
      final data = unwrapMap(res.data);
      final txs = <Map<String, dynamic>>[];
      if (data['transactions'] is List) {
        for (final t in data['transactions'] as List) {
          if (t is Map) txs.add(Map<String, dynamic>.from(t));
        }
      }
      return VendorWallet(
        balance: _num(data['solde'] ?? data['balance'] ?? data['wallet_balance']) ?? 0,
        transactions: txs,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> withdraw({
    required num amount,
    required String phone,
    required String method,
  }) async {
    try {
      await _dio.post('/vendeur/wallet/withdraw', data: {
        'amount': amount,
        'phone': phone,
        'method': method,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---------- Options de livraison du vendeur ----------

  Future<List<DeliveryOption>> myDeliveryOptions() async {
    try {
      final res = await _dio.get('/vendeur/option-livraisons');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => DeliveryOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> addDeliveryOption({required int optionId, required num prix}) async {
    try {
      await _dio.post('/vendeur/option-livraisons', data: {
        'option_id': optionId,
        'prix': prix,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

num? _num(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}
