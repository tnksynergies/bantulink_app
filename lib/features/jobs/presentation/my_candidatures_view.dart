import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../application/jobs_providers.dart';
import 'widgets/status_chip.dart';

class MyCandidaturesView extends ConsumerWidget {
  const MyCandidaturesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myCandidaturesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              OutlinedButton(
                  onPressed: () => ref.invalidate(myCandidaturesProvider),
                  child: const Text('Reessayer')),
            ],
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myCandidaturesProvider);
              await ref.read(myCandidaturesProvider.future);
            },
            child: ListView(
              children: const [
                SizedBox(height: 100),
                Icon(Icons.inbox_outlined, size: 56, color: AppColors.textMuted),
                SizedBox(height: 12),
                Center(
                  child: Text('Aucune candidature pour le moment.',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myCandidaturesProvider);
            await ref.read(myCandidaturesProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(c.offreTitre ?? 'Candidature #${c.id}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: AppColors.navy)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        StatusChip(statut: c.statutRaw),
                        const Spacer(),
                        if (c.dateCourt.isNotEmpty)
                          Text(c.dateCourt,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/candidature/${c.id}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
