import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/subscriptions/subscription_gate.dart';
import '../../../core/subscriptions/subscriptions_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../application/recruiter_providers.dart';
import '../data/recruiter_remote_data_source.dart';

/// Apercu du matching IA cote recruteur (point 3 de la seance de travail) :
/// pour une offre donnee, liste des candidats classes par score de
/// compatibilite (GET matching/job/{offreId}).
class MatchingPreviewScreen extends ConsumerWidget {
  const MatchingPreviewScreen({super.key, required this.offreId, this.offreTitre});
  final int offreId;
  final String? offreTitre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Module "Matching des meilleurs profils" : reserve au plan Pro
    // Recruteur (ou pendant les 2 mois d'essai gratuit).
    final access = ref.watch(recruiterAccessProvider);
    final subsLoading = ref.watch(activeSubscriptionsProvider).isLoading;
    if (subsLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('matching.title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!access.canUseProFeatures) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('matching.title'))),
        body: SubscriptionGate(
          message:
              '${context.tr('gate.recruiter_locked')} ${context.tr('rsub.trial_over')}',
          subscribeRoute: '/recruteur/abonnement',
          icon: Icons.auto_awesome,
        ),
      );
    }

    final matchesAsync = ref.watch(jobMatchesProvider(offreId));

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('matching.title'))),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 40, color: AppColors.error),
                const SizedBox(height: 12),
                Text('$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(jobMatchesProvider(offreId)),
                  child: Text(context.tr('common.retry')),
                ),
              ],
            ),
          ),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_search_outlined,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(context.tr('matching.empty'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == 0) {
                // En-tete : rappel de l'offre + sous-titre
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (offreTitre != null && offreTitre!.isNotEmpty)
                      Text(offreTitre!,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(context.tr('matching.subtitle'),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                  ],
                );
              }
              return _MatchCard(match: matches[i - 1], rank: i);
            },
          );
        },
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.rank});
  final JobMatch match;
  final int rank;

  Color get _scoreColor {
    if (match.score >= 70) return AppColors.success;
    if (match.score >= 40) return AppColors.primary;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        match.name.isNotEmpty ? match.name.characters.first.toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: rank == 1 ? AppColors.success : AppColors.border,
            width: rank == 1 ? 1.5 : 1),
      ),
      child: Row(
        children: [
          // Rang + avatar initiale
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _scoreColor.withOpacity(0.12),
            ),
            alignment: Alignment.center,
            child: Text(initial,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _scoreColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                // Barre de progression du score
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (match.score / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${match.score.toStringAsFixed(0)} %',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _scoreColor)),
              Text(context.tr('matching.score'),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
