import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../application/market_providers.dart';
import '../data/models/product.dart';
import 'market_colors.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('market.favorites'))),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(favoritesProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 100),
              Center(
                  child: Text('$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted))),
            ],
          ),
          data: (products) {
            if (products.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  const Icon(Icons.favorite_border,
                      size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(context.tr('market.no_favorites'),
                        style: const TextStyle(color: AppColors.textMuted)),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _FavoriteTile(product: products[i]),
            );
          },
        ),
      ),
    );
  }
}

class _FavoriteTile extends ConsumerWidget {
  const _FavoriteTile({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = product.coverImage;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(MarketColors.radius),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.04),
      child: InkWell(
        borderRadius: BorderRadius.circular(MarketColors.radius),
        onTap: () => context.push('/produit/${product.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: MarketColors.muted,
                  borderRadius: BorderRadius.circular(10),
                  image: image != null
                      ? DecorationImage(
                          image: NetworkImage(image),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: image == null
                    ? const Icon(Icons.image_outlined,
                        color: MarketColors.mutedForeground)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.nomSafe,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '${(product.prix ?? 0).toStringAsFixed(0)} XAF',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: MarketColors.primary),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.tr('market.remove'),
                icon: const Icon(Icons.favorite, color: AppColors.brandRed),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(toggleFavoriteControllerProvider(product.id)
                            .notifier)
                        .toggle(isCurrentlyFavorite: true);
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(
                        content: Text('$e'),
                        backgroundColor: AppColors.error));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
