import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../application/jobs_providers.dart';
import 'widgets/status_chip.dart';

class CandidatureDetailScreen extends ConsumerWidget {
  const CandidatureDetailScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(candidatureDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Ma candidature')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
          ),
        ),
        data: (c) {
          final steps = <_Step>[
            const _Step('Candidature envoyee', ['en_revision', 'en_attente', 'envoyee', 'recue']),
            const _Step('Preselection', ['preselectionne']),
            const _Step('Entretien', ['invitation_entretien', 'entretien']),
            const _Step('Decision', ['embauche', 'rejete', 'refuse']),
          ];
          final statut = (c.statutRaw ?? '').toLowerCase();
          var current = 0;
          for (var i = 0; i < steps.length; i++) {
            if (steps[i].match.contains(statut)) current = i;
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(c.offreTitre ?? 'Candidature #${c.id}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy)),
              const SizedBox(height: 12),
              Row(
                children: [
                  StatusChip(statut: c.statutRaw),
                  const Spacer(),
                  if (c.dateCourt.isNotEmpty)
                    Text('Postule le ${c.dateCourt}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Suivi',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 12),
              ...List.generate(steps.length, (i) {
                final done = i <= current;
                final rejected = statut == 'rejete' ||
                    statut == 'refuse' ||
                    statut == 'rejeté';
                final color = (rejected && i == current)
                    ? AppColors.error
                    : (done ? AppColors.success : AppColors.border);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                          child: done
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                        if (i != steps.length - 1)
                          Container(
                              width: 2, height: 36, color: AppColors.border),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(steps[i].label,
                          style: TextStyle(
                              fontWeight:
                                  i == current ? FontWeight.bold : FontWeight.normal,
                              color: done
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted)),
                    ),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _Step {
  const _Step(this.label, this.match);
  final String label;
  final List<String> match;
}
