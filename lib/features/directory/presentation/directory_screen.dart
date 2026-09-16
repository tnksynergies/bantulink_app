import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../application/directory_providers.dart';

class DirectoryScreen extends ConsumerWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(directoryListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('directory.title'))),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/annuaire/nouveau'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (businesses) {
          if (businesses.isEmpty) {
            return Center(
              child: Text(context.tr('directory.empty'),
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: businesses.length,
            itemBuilder: (_, i) {
              final b = businesses[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        b.logo != null ? NetworkImage(b.logo!) : null,
                    child: b.logo == null
                        ? Text(b.name.isNotEmpty ? b.name[0].toUpperCase() : '?')
                        : null,
                  ),
                  title: Text(b.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    [b.category, b.city].whereType<String>().join(' - '),
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  trailing: b.reviewsAvg != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(b.reviewsAvg!.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 13)),
                          ],
                        )
                      : null,
                  onTap: () => context.push('/annuaire/${b.slug}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
