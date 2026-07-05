import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../freelancers/data/upload_file.dart';
import '../data/models/order.dart';
import '../data/models/product.dart';
import '../data/vendor_remote_data_source.dart';
import 'market_providers.dart';

final vendorDataSourceProvider = Provider<VendorRemoteDataSource>(
    (ref) => VendorRemoteDataSource(ref.watch(dioProvider)));

/// True si l'utilisateur connecte possede le role Vendeur (ou un profil
/// vendeur charge dans /user).
final isCurrentUserVendorProvider = Provider.autoDispose<bool>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return false;
  if (user.raw['vendeur'] != null) return true;
  const vendorNames = {'vendeur', 'seller'};
  for (final r in user.roles) {
    if (vendorNames.contains(r.toLowerCase().trim())) return true;
  }
  return false;
});

// ---------- Produits du vendeur ----------

final myVendorProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  return ref.watch(vendorDataSourceProvider).myProducts();
});

class RegisterVendorController extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> submit({
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
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(vendorDataSourceProvider).registerVendeur(
            nom: nom,
            email: email,
            telephone: telephone,
            description: description,
            adresse: adresse,
            ville: ville,
            pays: pays,
            slogan: slogan,
            numContribuable: numContribuable,
            logo: logo,
            couverture: couverture,
          );
      await ref.read(authControllerProvider.notifier).refreshUser();
      return true;
    });
  }
}

final registerVendorControllerProvider =
    AutoDisposeAsyncNotifierProvider<RegisterVendorController, bool>(
        RegisterVendorController.new);

class CreateProductController extends AutoDisposeAsyncNotifier<Product?> {
  @override
  Future<Product?> build() async => null;

  Future<Product> submit({
    required String nom,
    required num prix,
    required int stockQtte,
    required int categorieId,
    String? description,
    List<UploadFile> images = const [],
  }) async {
    state = const AsyncValue.loading();
    final product = await ref.read(vendorDataSourceProvider).createProduct(
          nom: nom,
          prix: prix,
          stockQtte: stockQtte,
          categorieId: categorieId,
          description: description,
          images: images,
        );
    state = AsyncValue.data(product);
    ref.invalidate(myVendorProductsProvider);
    ref.invalidate(productsProvider);
    return product;
  }
}

final createProductControllerProvider =
    AutoDisposeAsyncNotifierProvider<CreateProductController, Product?>(
        CreateProductController.new);

class UpdateProductController
    extends AutoDisposeFamilyAsyncNotifier<bool, int> {
  @override
  Future<bool> build(int arg) async => false;

  Future<void> submit({
    String? nom,
    String? description,
    num? prix,
    int? stockQtte,
    int? categorieId,
    List<UploadFile> newImages = const [],
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final ds = ref.read(vendorDataSourceProvider);
      await ds.updateProduct(
        arg,
        nom: nom,
        description: description,
        prix: prix,
        stockQtte: stockQtte,
        categorieId: categorieId,
      );
      if (newImages.isNotEmpty) {
        await ds.addProductMedia(arg, images: newImages);
      }
      ref.invalidate(myVendorProductsProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(productDetailProvider(arg));
      return true;
    });
  }
}

final updateProductControllerProvider =
    AutoDisposeAsyncNotifierProvider.family<UpdateProductController, bool, int>(
        UpdateProductController.new);

class DeleteProductController extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> submit(int productId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(vendorDataSourceProvider).deleteProduct(productId);
      ref.invalidate(myVendorProductsProvider);
      ref.invalidate(productsProvider);
      return true;
    });
  }
}

final deleteProductControllerProvider =
    AutoDisposeAsyncNotifierProvider<DeleteProductController, bool>(
        DeleteProductController.new);

// ---------- Wallet vendeur ----------

final vendorWalletProvider =
    FutureProvider.autoDispose<VendorWallet>((ref) async {
  return ref.watch(vendorDataSourceProvider).wallet();
});

// ---------- Commandes recues ----------

/// Id du profil vendeur de l'utilisateur connecte (depuis /user).
final myVendorIdProvider = Provider.autoDispose<int?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  final v = user?.raw['vendeur'];
  if (v is Map && v['id'] != null) {
    final id = v['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
  }
  return null;
});

/// Commandes contenant au moins un produit du vendeur connecte.
/// Filtrage cote app comme la version web : on ne garde que les lignes du
/// vendeur et on recalcule le total sur ces lignes.
final vendorOrdersProvider =
    FutureProvider.autoDispose<List<Order>>((ref) async {
  final vendorId = ref.watch(myVendorIdProvider);
  if (vendorId == null) return const [];
  final all = await ref.watch(vendorDataSourceProvider).allOrders();
  final result = <Order>[];
  for (final order in all) {
    final mine = order.produits
        .where((item) => item.produit.vendeur?.id == vendorId)
        .toList(growable: false);
    if (mine.isEmpty) continue;
    final sellerTotal = mine.fold<num>(0, (acc, i) => acc + i.lineTotal);
    result.add(Order(
      id: order.id,
      statutRaw: order.statutRaw,
      sousTotal: sellerTotal,
      fraisLivraison: order.fraisLivraison,
      total: sellerTotal,
      adresseLivraison: order.adresseLivraison,
      villeLivraison: order.villeLivraison,
      paysLivraison: order.paysLivraison,
      telLivraison: order.telLivraison,
      dateCommande: order.dateCommande,
      produits: mine,
      raw: order.raw,
    ));
  }
  return result;
});

/// Met a jour le profil boutique.
class UpdateVendorProfileController extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> submit({
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
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(vendorDataSourceProvider).updateProfile(
            nom: nom,
            description: description,
            slogan: slogan,
            adresse: adresse,
            ville: ville,
            pays: pays,
            telephone: telephone,
            email: email,
            numContribuable: numContribuable,
            logo: logo,
            couverture: couverture,
          );
      await ref.read(authControllerProvider.notifier).refreshUser();
      return true;
    });
  }
}

final updateVendorProfileControllerProvider =
    AutoDisposeAsyncNotifierProvider<UpdateVendorProfileController, bool>(
        UpdateVendorProfileController.new);
