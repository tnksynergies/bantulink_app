import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../application/market_providers.dart';
import '../data/models/cart_item.dart';
import 'market_colors.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('market.cart')),
        actions: [
          if ((async.valueOrNull ?? const []).isNotEmpty)
            IconButton(
              tooltip: context.tr('market.clear_cart'),
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, ref),
            ),
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
                  onPressed: () => ref.invalidate(cartProvider),
                  child: Text(context.tr('common.retry')),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(context.tr('market.cart_empty'),
                        style: const TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => context.go('/boutique'),
                      child: Text(context.tr('market.title')),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final item in items) _CartTile(item: item),
              const SizedBox(height: 16),
              // Total + CTA
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(context.tr('market.subtotal'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const Expanded(child: SizedBox()),
                        Text(
                          '${total.toStringAsFixed(0)} XAF',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MarketColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/commander'),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: Text(context.tr('market.checkout')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MarketColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('market.clear_cart')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('common.cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: Text(context.tr('market.clear_cart')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(clearCartControllerProvider.notifier).run();
      messenger.showSnackBar(SnackBar(
          content:
              Text(context.mounted ? context.tr('market.cart_cleared') : '')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error));
    }
  }
}

class _CartTile extends ConsumerWidget {
  const _CartTile({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = item.produit.coverImage;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.background,
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
                    color: AppColors.textMuted)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.produit.nomSafe,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '${context.tr('market.quantity')} : ${item.quantite}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                if (item.attributs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.attributs.map((a) => a.label).join(' · '),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${item.lineTotal.toStringAsFixed(0)} XAF',
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
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(removeFromCartControllerProvider(item.produitId)
                        .notifier)
                    .run();
              } catch (e) {
                messenger.showSnackBar(SnackBar(
                    content: Text('$e'), backgroundColor: AppColors.error));
              }
            },
          ),
        ],
      ),
    );
  }
}
