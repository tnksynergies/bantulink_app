import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../application/market_providers.dart';
import '../data/models/product.dart';
import 'market_colors.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  int _imageIndex = 0;
  final Set<int> _selectedAttributeIds = {};
  bool _adding = false;

  Future<void> _addToCart(Product product) async {
    if (_adding) return;
    setState(() => _adding = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(addToCartControllerProvider.notifier).submit(
            produitId: product.id,
            quantite: _quantity,
            attributValeurIds: _selectedAttributeIds.toList(),
          );
      final err = ref.read(addToCartControllerProvider).error;
      if (err != null) throw err;
      messenger.showSnackBar(SnackBar(
        content: Text(
            context.mounted ? context.tr('market.added_to_cart') : ''),
        backgroundColor: MarketColors.primary,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text('$e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productDetailProvider(widget.productId));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          async.valueOrNull?.nomSafe ?? context.tr('common.loading'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          _FavoriteButton(productId: widget.productId),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
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
                  onPressed: () =>
                      ref.invalidate(productDetailProvider(widget.productId)),
                  child: Text(context.tr('common.retry')),
                ),
              ],
            ),
          ),
        ),
        data: (product) => _body(context, product),
      ),
    );
  }

  Widget _body(BuildContext context, Product product) {
    final images = product.imageUrls;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Galerie images (Container + DecorationImage, pattern web-safe)
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: AppColors.background,
            image: images.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(
                        images[_imageIndex.clamp(0, images.length - 1)]),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: images.isEmpty
              ? const Icon(Icons.image_outlined,
                  size: 64, color: AppColors.textMuted)
              : null,
        ),
        // Miniatures
        if (images.length > 1)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => InkWell(
                  onTap: () => setState(() => _imageIndex = i),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: i == _imageIndex
                              ? AppColors.primary
                              : AppColors.border,
                          width: i == _imageIndex ? 2 : 1),
                      image: DecorationImage(
                        image: NetworkImage(images[i]),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Infos principales
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.nomSafe,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: MarketColors.foreground)),
              const SizedBox(height: 4),
              // Etoiles orange (charte web)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 5; i++)
                    Icon(
                      i < ((_asDouble(product.raw['rating']) ?? 4.5).floor())
                          ? Icons.star
                          : Icons.star_border,
                      size: 16,
                      color: MarketColors.accent,
                    ),
                  const SizedBox(width: 4),
                  Text('(${_asInt(product.raw['reviews']) ?? 0})',
                      style: const TextStyle(
                          fontSize: 12,
                          color: MarketColors.mutedForeground)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${(product.prix ?? 0).toStringAsFixed(0)} XAF',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: MarketColors.primary),
              ),
              const SizedBox(height: 6),
              Text(
                product.inStock
                    ? '${context.tr('market.in_stock')} (${product.stockQtte})'
                    : context.tr('market.out_of_stock'),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: product.inStock
                        ? MarketColors.primary
                        : AppColors.error),
              ),
              if (product.vendeur?.nom != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${context.tr('market.sold_by')} ${product.vendeur!.nom}'
                  '${product.vendeur!.ville != null ? ' · ${product.vendeur!.ville}' : ''}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted),
                ),
              ],
              if (product.categorie != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(product.categorie!.nom,
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
        ),

        // Options / attributs
        if (product.attributs.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('market.options'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: product.attributs.map((a) {
                    final selected = _selectedAttributeIds.contains(a.id);
                    return InkWell(
                      onTap: () => setState(() {
                        if (selected) {
                          _selectedAttributeIds.remove(a.id);
                        } else {
                          _selectedAttributeIds.add(a.id);
                        }
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? MarketColors.primary.withOpacity(0.1)
                              : MarketColors.muted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: selected
                                  ? MarketColors.primary
                                  : MarketColors.border,
                              width: selected ? 1.6 : 1),
                        ),
                        child: Text(
                          a.supplementCout > 0
                              ? '${a.label} (+${a.supplementCout.toStringAsFixed(0)} XAF)'
                              : a.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? MarketColors.foreground
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],

        // Description
        const SizedBox(height: 8),
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('market.description'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                product.description ?? '-',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),

        // Quantite + ajouter au panier
        const SizedBox(height: 8),
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(context.tr('market.quantity'),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Expanded(child: SizedBox()),
                  IconButton(
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_quantity',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed:
                    (!product.inStock || _adding) ? null : () => _addToCart(product),
                icon: _adding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_shopping_cart, size: 18),
                label: Text(context.tr('market.add_to_cart')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MarketColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/panier'),
                icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                label: Text(context.tr('market.cart')),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
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

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds = ref.watch(favoriteIdsProvider);
    final isFav = favIds.contains(productId);
    return IconButton(
      tooltip: context.tr('market.favorites'),
      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
          color: isFav ? AppColors.brandRed : null),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await ref
              .read(toggleFavoriteControllerProvider(productId).notifier)
              .toggle(isCurrentlyFavorite: isFav);
        } catch (e) {
          messenger.showSnackBar(SnackBar(
              content: Text('$e'), backgroundColor: AppColors.error));
        }
      },
    );
  }
}
