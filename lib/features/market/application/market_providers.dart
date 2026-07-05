import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/market_remote_data_source.dart';
import '../data/models/cart_item.dart';
import '../data/models/order.dart';
import '../data/models/product.dart';

final marketDataSourceProvider = Provider<MarketRemoteDataSource>(
    (ref) => MarketRemoteDataSource(ref.watch(dioProvider)));

// ---------- Catalogue ----------

final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  return ref.watch(marketDataSourceProvider).listProducts();
});

final productCategoriesProvider =
    FutureProvider.autoDispose<List<ProductCategory>>((ref) async {
  return ref.watch(marketDataSourceProvider).categories();
});

final productsByCategoryProvider =
    FutureProvider.autoDispose.family<List<Product>, int>((ref, catId) async {
  return ref.watch(marketDataSourceProvider).productsByCategory(catId);
});

final productDetailProvider =
    FutureProvider.autoDispose.family<Product, int>((ref, id) async {
  return ref.watch(marketDataSourceProvider).getProduct(id);
});

// ---------- Profil acheteur ----------

/// S'assure que l'utilisateur a un profil acheteur avant les operations
/// panier/commande. Cree le profil silencieusement au premier appel.
Future<void> ensureAcheteur(Ref ref) async {
  final user = ref.read(authControllerProvider).valueOrNull;
  if (user == null) return;
  if (user.raw['acheteur'] != null) return; // deja acheteur
  await ref.read(marketDataSourceProvider).registerAcheteur();
  await ref.read(authControllerProvider.notifier).refreshUser();
}

// ---------- Panier ----------

final cartProvider = FutureProvider.autoDispose<List<CartItem>>((ref) async {
  final user = ref.watch(authControllerProvider).valueOrNull;
  // Sans profil acheteur, /panier renverrait une 500 (acheteur null cote back).
  if (user == null || user.raw['acheteur'] == null) return const [];
  return ref.watch(marketDataSourceProvider).cart();
});

final cartCountProvider = Provider.autoDispose<int>((ref) {
  final items = ref.watch(cartProvider).valueOrNull ?? const [];
  return items.fold(0, (acc, i) => acc + i.quantite);
});

final cartTotalProvider = Provider.autoDispose<num>((ref) {
  final items = ref.watch(cartProvider).valueOrNull ?? const [];
  return items.fold<num>(0, (acc, i) => acc + i.lineTotal);
});

/// Ajoute un produit au panier (cree le profil acheteur si necessaire).
class AddToCartController extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> submit({
    required int produitId,
    required int quantite,
    List<int> attributValeurIds = const [],
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ensureAcheteur(ref);
      await ref.read(marketDataSourceProvider).addToCart(
            produitId: produitId,
            quantite: quantite,
            attributValeurIds: attributValeurIds,
          );
      ref.invalidate(cartProvider);
      return true;
    });
  }
}

final addToCartControllerProvider =
    AutoDisposeAsyncNotifierProvider<AddToCartController, bool>(
        AddToCartController.new);

class RemoveFromCartController
    extends AutoDisposeFamilyAsyncNotifier<bool, int> {
  @override
  Future<bool> build(int arg) async => false;

  Future<void> run() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(marketDataSourceProvider).removeFromCart(arg);
      ref.invalidate(cartProvider);
      return true;
    });
  }
}

final removeFromCartControllerProvider =
    AutoDisposeAsyncNotifierProvider.family<RemoveFromCartController, bool, int>(
        RemoveFromCartController.new);

class ClearCartController extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> run() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(marketDataSourceProvider).clearCart();
      ref.invalidate(cartProvider);
      return true;
    });
  }
}

final clearCartControllerProvider =
    AutoDisposeAsyncNotifierProvider<ClearCartController, bool>(
        ClearCartController.new);

// ---------- Favoris ----------

final favoritesProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null || user.raw['acheteur'] == null) return const [];
  return ref.watch(marketDataSourceProvider).favorites();
});

final favoriteIdsProvider = Provider.autoDispose<Set<int>>((ref) {
  final favs = ref.watch(favoritesProvider).valueOrNull ?? const [];
  return favs.map((p) => p.id).toSet();
});

class ToggleFavoriteController
    extends AutoDisposeFamilyAsyncNotifier<bool, int> {
  @override
  Future<bool> build(int arg) async => false;

  Future<void> toggle({required bool isCurrentlyFavorite}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ensureAcheteur(ref);
      final ds = ref.read(marketDataSourceProvider);
      if (isCurrentlyFavorite) {
        await ds.removeFavorite(arg);
      } else {
        await ds.addFavorite(arg);
      }
      ref.invalidate(favoritesProvider);
      return true;
    });
  }
}

final toggleFavoriteControllerProvider =
    AutoDisposeAsyncNotifierProvider.family<ToggleFavoriteController, bool, int>(
        ToggleFavoriteController.new);

// ---------- Commandes ----------

final myOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null || user.raw['acheteur'] == null) return const [];
  return ref.watch(marketDataSourceProvider).myOrders();
});

final orderDetailProvider =
    FutureProvider.autoDispose.family<Order, int>((ref, id) async {
  return ref.watch(marketDataSourceProvider).getOrder(id);
});

/// Finalise le panier en commande (checkout).
class CheckoutController extends AutoDisposeAsyncNotifier<Order?> {
  @override
  Future<Order?> build() async => null;

  Future<Order> submit({
    required int optionLivraisonId,
    required int modePaiementId,
    String? adresse,
    String? ville,
    String? pays,
    String? telephone,
    String? couponCode,
  }) async {
    state = const AsyncValue.loading();
    final order = await ref.read(marketDataSourceProvider).checkout(
          optionLivraisonId: optionLivraisonId,
          modePaiementId: modePaiementId,
          adresse: adresse,
          ville: ville,
          pays: pays,
          telephone: telephone,
          couponCode: couponCode,
        );
    state = AsyncValue.data(order);
    ref.invalidate(cartProvider);
    ref.invalidate(myOrdersProvider);
    return order;
  }
}

final checkoutControllerProvider =
    AutoDisposeAsyncNotifierProvider<CheckoutController, Order?>(
        CheckoutController.new);

// ---------- Referentiels checkout ----------

final deliveryOptionsProvider =
    FutureProvider.autoDispose<List<DeliveryOption>>((ref) async {
  return ref.watch(marketDataSourceProvider).deliveryOptions();
});

final paymentModesProvider =
    FutureProvider.autoDispose<List<PaymentModeOption>>((ref) async {
  return ref.watch(marketDataSourceProvider).paymentModes();
});

// ---------- Paiement Mobile Money commande ----------

enum OrderPayStage { idle, initiating, polling, success, failed }

class OrderPayState {
  const OrderPayState(this.stage, [this.reference]);
  final OrderPayStage stage;
  final String? reference;
}

/// Initie le paiement Mobile Money d'une commande + polling 5s
/// jusqu'a success/failed (comme la version web).
class PayOrderController
    extends AutoDisposeFamilyAsyncNotifier<OrderPayState, int> {
  Timer? _timer;

  @override
  Future<OrderPayState> build(int arg) async {
    ref.onDispose(() => _timer?.cancel());
    return const OrderPayState(OrderPayStage.idle);
  }

  Future<void> initiate({
    required num amount,
    required String phone,
    required String provider,
  }) async {
    state = const AsyncValue.data(OrderPayState(OrderPayStage.initiating));
    try {
      final reference =
          await ref.read(marketDataSourceProvider).initiateOrderPayment(
                amount: amount,
                phone: phone,
                provider: provider,
                commandeId: arg,
              );
      if (reference == null) {
        state = AsyncValue.error(
            'Reference paiement introuvable', StackTrace.current);
        return;
      }
      state =
          AsyncValue.data(OrderPayState(OrderPayStage.polling, reference));
      _startPolling(reference);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _startPolling(String reference) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final status =
          await ref.read(marketDataSourceProvider).paymentStatus(reference);
      if (status == null) return;
      if (status == 'success' ||
          status == 'succeeded' ||
          status == 'active' ||
          status == 'completed') {
        _timer?.cancel();
        state = const AsyncValue.data(OrderPayState(OrderPayStage.success));
        ref.invalidate(myOrdersProvider);
      } else if (status == 'failed' || status == 'error') {
        _timer?.cancel();
        state = const AsyncValue.data(OrderPayState(OrderPayStage.failed));
      }
    });
  }
}

final payOrderControllerProvider = AutoDisposeAsyncNotifierProvider.family<
    PayOrderController, OrderPayState, int>(PayOrderController.new);

/// Historique des paiements marketplace.
final marketPaymentsHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(marketDataSourceProvider).paymentsHistory();
});
