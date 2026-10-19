import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/branding/brand.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../market/application/market_providers.dart';
import '../../market/application/vendor_providers.dart';
import '../../market/data/models/product.dart';
import '../../market/presentation/market_colors.dart';

/// Ecran principal BantuMarket (onglet Boutique) : recherche, categories,
/// grille de produits, acces panier / mes commandes / ma boutique vendeur.
class BoutiqueScreen extends ConsumerStatefulWidget {
  const BoutiqueScreen({super.key});

  @override
  ConsumerState<BoutiqueScreen> createState() => _BoutiqueScreenState();
}

class _BoutiqueScreenState extends ConsumerState<BoutiqueScreen> {
  final _searchCtrl = TextEditingController();
  int? _selectedCategoryId; // null = tout

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> _filter(List<Product> all) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return all.where((p) {
      if (_selectedCategoryId != null &&
          p.categorie?.id != _selectedCategoryId) {
        return false;
      }
      if (q.isNotEmpty) {
        final inName = (p.nom ?? '').toLowerCase().contains(q);
        final inDesc = (p.description ?? '').toLowerCase().contains(q);
        if (!inName && !inDesc) return false;
      }
      return true;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final asyncProducts = ref.watch(productsProvider);
    final asyncCategories = ref.watch(productCategoriesProvider);
    final cartCount = ref.watch(cartCountProvider);
    final isVendor = ref.watch(isCurrentUserVendorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(BrandWorld.market, height: 24),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: context.tr('market.favorites'),
            icon: const Icon(Icons.favorite_border),
            onPressed: () => context.push('/mes-favoris'),
          ),
          IconButton(
            tooltip: context.tr('market.my_orders'),
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.push('/mes-commandes'),
          ),
          if (isVendor)
            IconButton(
              tooltip: context.tr('market.seller_dashboard'),
              icon: const Icon(Icons.storefront_outlined),
              onPressed: () => context.push('/vendeur/dashboard'),
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: context.tr('market.cart'),
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.push('/panier'),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(
                        color: AppColors.brandRed, shape: BoxShape.circle),
                    child: Text(
                      cartCount > 9 ? '9+' : '$cartCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productsProvider);
          ref.invalidate(productCategoriesProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Hero banner gradient vert -> orange (charte web)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: MarketColors.heroGradient,
                  borderRadius: BorderRadius.circular(MarketColors.radius + 4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('market.hero_title'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(context.tr('market.hero_subtitle'),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: context.tr('market.search_hint'),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: asyncCategories.maybeWhen(
                  data: (cats) => ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _categoryChip(
                          label: context.tr('market.all_categories'),
                          selected: _selectedCategoryId == null,
                          onTap: () =>
                              setState(() => _selectedCategoryId = null)),
                      for (final c in cats)
                        _categoryChip(
                            label: c.nom,
                            selected: _selectedCategoryId == c.id,
                            onTap: () =>
                                setState(() => _selectedCategoryId = c.id)),
                    ],
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ),
            ),
            asyncProducts.when(
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text('$e', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(productsProvider),
                          child: Text(context.tr('common.retry')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (all) {
                final filtered = _filter(all);
                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shopping_bag_outlined,
                                size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(context.tr('market.no_products'),
                                style: const TextStyle(
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 250,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ProductCard(product: filtered[i]),
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? MarketColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: selected ? MarketColors.primary : MarketColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Comme la version web : rating par defaut 4.5, avis par defaut 0.
    final rating = _asDouble(product.raw['rating']) ?? 4.5;
    final reviews = _asInt(product.raw['reviews']) ?? 0;
    final sellerName = product.vendeur?.nom;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(MarketColors.radius),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(MarketColors.radius),
        onTap: () => context.push('/produit/${product.id}'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image en decoration (pattern web-safe : jamais Image.network)
            Container(
              height: 118,
              decoration: BoxDecoration(
                color: MarketColors.muted,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(MarketColors.radius)),
                image: product.coverImage != null
                    ? DecorationImage(
                        image: NetworkImage(product.coverImage!),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: product.coverImage == null
                  ? const Icon(Icons.image_outlined,
                      size: 40, color: MarketColors.mutedForeground)
                  : (!product.inStock
                      ? Container(
                          color: Colors.white70,
                          alignment: Alignment.center,
                          child: Text(context.tr('market.out_of_stock'),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error)),
                        )
                      : null),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nomSafe,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MarketColors.foreground),
                  ),
                  if (sellerName != null)
                    Text(
                      '${context.tr('market.by_seller')} $sellerName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: MarketColors.mutedForeground),
                    ),
                  const SizedBox(height: 4),
                  // Etoiles orange (charte web : fill-secondary)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 5; i++)
                        Icon(
                          i < rating.floor() ? Icons.star : Icons.star_border,
                          size: 13,
                          color: MarketColors.accent,
                        ),
                      const SizedBox(width: 3),
                      Text('($reviews)',
                          style: const TextStyle(
                              fontSize: 10,
                              color: MarketColors.mutedForeground)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${(product.prix ?? 0).toStringAsFixed(0)} XAF',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: MarketColors.primary),
                        ),
                      ),
                      // Ajout rapide au panier (comme la card web)
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: Material(
                          color: product.inStock
                              ? MarketColors.primary
                              : MarketColors.border,
                          borderRadius: BorderRadius.circular(9),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: product.inStock
                                ? () => _quickAdd(context, ref)
                                : null,
                            child: const Icon(Icons.add_shopping_cart,
                                size: 17, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickAdd(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(addToCartControllerProvider.notifier)
          .submit(produitId: product.id, quantite: 1);
      final err = ref.read(addToCartControllerProvider).error;
      if (err != null) throw err;
      messenger.showSnackBar(SnackBar(
        content:
            Text(context.mounted ? context.tr('market.added_to_cart') : ''),
        backgroundColor: MarketColors.primary,
      ));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error));
    }
  }
}

double? _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}
