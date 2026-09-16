import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../application/boost_providers.dart';

class MyBoostsScreen extends ConsumerWidget {
  const MyBoostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boostsAsync = ref.watch(myBoostsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('boost.myBoosts'))),
      body: boostsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (boosts) {
          if (boosts.isEmpty) {
            return Center(
              child: Text(context.tr('boost.noBoosts'),
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: boosts.length,
            itemBuilder: (_, i) {
              final b = boosts[i];
              final isExpired = b.isExpired || b.endsAt.isBefore(DateTime.now());
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: isExpired
                        ? Colors.grey.shade200
                        : AppColors.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.rocket_launch,
                      color: isExpired ? Colors.grey : AppColors.primary,
                    ),
                  ),
                  title: Text(
                    b.pack?.labelFr ?? b.pack?.name ?? 'Boost #${b.id}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.tr('boost.until')} ${b.endsAt.day}/${b.endsAt.month}/${b.endsAt.year}',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? Colors.grey.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isExpired
                              ? context.tr('boost.expired')
                              : context.tr('boost.active'),
                          style: TextStyle(
                            fontSize: 11,
                            color: isExpired ? Colors.grey : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
