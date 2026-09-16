import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../application/promotions_providers.dart';

class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(activePromosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('promo.title')),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/ventes-flash'),
            icon: const Icon(Icons.flash_on, color: Colors.red, size: 18),
            label: Text(context.tr('promo.flashSales'),
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ],
      ),
      body: promosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (promos) {
          if (promos.isEmpty) {
            return Center(
              child: Text(context.tr('promo.noPromos'),
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: promos.length,
            itemBuilder: (_, i) {
              final promo = promos[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      promo.discountLabel,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ),
                  title: Text(promo.titleFr,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    promo.descriptionFr ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  trailing: promo.code != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(promo.code!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1)),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
