import '../../../../core/utils/media_url.dart';

/// Media d'un produit : le back renvoie image_link / video_link /
/// document_link en URLs absolues (asset('storage/...')).
class ProductMedia {
  const ProductMedia({required this.id, this.imageUrl, this.videoUrl, this.documentUrl});

  final int id;
  final String? imageUrl;
  final String? videoUrl;
  final String? documentUrl;

  factory ProductMedia.fromJson(Map<String, dynamic> j) {
    return ProductMedia(
      id: _i(j['id']),
      imageUrl: mediaUrl(_s(j['image_link'])),
      videoUrl: mediaUrl(_s(j['video_link'])),
      documentUrl: mediaUrl(_s(j['document_link'])),
    );
  }
}

/// Valeur d'attribut attachee au produit (ex: Taille=XL, +500 XAF).
class ProductAttribute {
  const ProductAttribute({
    required this.id,
    required this.attribut,
    required this.valeur,
    this.supplementCout = 0,
    this.stockQtte = 0,
  });

  final int id;
  final String attribut; // ex: "Taille"
  final String valeur;   // ex: "XL"
  final num supplementCout;
  final int stockQtte;

  String get label => '$attribut : $valeur';

  factory ProductAttribute.fromJson(Map<String, dynamic> j) {
    return ProductAttribute(
      id: _i(j['id']),
      attribut: _s(j['attribut']) ?? '',
      valeur: _s(j['valeur']) ?? '',
      supplementCout: _num(j['supplement_cout']) ?? 0,
      stockQtte: _i(j['stock_qtte']),
    );
  }
}

class VendorSummary {
  const VendorSummary({required this.id, this.nom, this.ville, this.logoUrl, this.telephone});

  final int id;
  final String? nom;
  final String? ville;
  final String? logoUrl;
  final String? telephone;

  factory VendorSummary.fromJson(Map<String, dynamic> j) {
    return VendorSummary(
      id: _i(j['id']),
      nom: _s(j['nom']) ?? _s(j['nom_entreprise']) ?? _s(j['name']),
      ville: _s(j['ville']),
      logoUrl: mediaUrl(_s(j['logo_img']) ?? _s(j['logo'])),
      telephone: _s(j['telephone']),
    );
  }
}

class ProductCategory {
  const ProductCategory({required this.id, required this.nom, this.description});

  final int id;
  final String nom;
  final String? description;

  factory ProductCategory.fromJson(Map<String, dynamic> j) {
    return ProductCategory(
      id: _i(j['id']),
      nom: _s(j['nom']) ?? _s(j['name']) ?? '',
      description: _s(j['description']),
    );
  }
}

class Product {
  const Product({
    required this.id,
    this.nom,
    this.description,
    this.prix,
    this.stockQtte,
    this.vendeur,
    this.categorie,
    this.medias = const [],
    this.attributs = const [],
    this.raw = const {},
  });

  final int id;
  final String? nom;
  final String? description;
  final num? prix;
  final int? stockQtte;
  final VendorSummary? vendeur;
  final ProductCategory? categorie;
  final List<ProductMedia> medias;
  final List<ProductAttribute> attributs;
  final Map<String, dynamic> raw;

  String get nomSafe => nom ?? 'Produit #$id';
  bool get inStock => (stockQtte ?? 0) > 0;

  String? get coverImage {
    for (final m in medias) {
      if (m.imageUrl != null && m.imageUrl!.isNotEmpty) return m.imageUrl;
    }
    return null;
  }

  List<String> get imageUrls => medias
      .map((m) => m.imageUrl)
      .whereType<String>()
      .where((u) => u.isNotEmpty)
      .toList(growable: false);

  factory Product.fromJson(Map<String, dynamic> j) {
    final medias = <ProductMedia>[];
    if (j['medias'] is List) {
      for (final m in j['medias'] as List) {
        if (m is Map) medias.add(ProductMedia.fromJson(Map<String, dynamic>.from(m)));
      }
    }
    final attributs = <ProductAttribute>[];
    if (j['attributs'] is List) {
      for (final a in j['attributs'] as List) {
        if (a is Map) attributs.add(ProductAttribute.fromJson(Map<String, dynamic>.from(a)));
      }
    }
    return Product(
      id: _i(j['id']),
      nom: _s(j['nom']),
      description: _s(j['description']),
      prix: _num(j['prix']),
      stockQtte: _iOrNull(j['stock_qtte']),
      vendeur: j['vendeur'] is Map
          ? VendorSummary.fromJson(Map<String, dynamic>.from(j['vendeur'] as Map))
          : null,
      categorie: j['categorie'] is Map
          ? ProductCategory.fromJson(Map<String, dynamic>.from(j['categorie'] as Map))
          : null,
      medias: medias,
      attributs: attributs,
      raw: j,
    );
  }
}

int _i(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

int? _iOrNull(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
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
