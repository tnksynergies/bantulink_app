import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/subscriptions/subscription_gate.dart';
import '../../../core/subscriptions/subscriptions_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

/// Offre recommandee par le matching IA (GET matching/candidate/{userId}).
class CandidateMatch {
  const CandidateMatch({
    required this.offreId,
    required this.titre,
    required this.score,
    this.ville,
    this.typeContrat,
  });
  final int offreId;
  final String titre;
  final double score;
  final String? ville;
  final String? typeContrat;

  factory CandidateMatch.fromJson(Map<String, dynamic> j) {
    return CandidateMatch(
      offreId: j['offre_id'] is int
          ? j['offre_id'] as int
          : int.tryParse('${j['offre_id']}') ?? 0,
      titre: (j['titre'] ?? 'Offre').toString(),
      score: j['score'] is num
          ? (j['score'] as num).toDouble()
          : double.tryParse('${j['score']}') ?? 0,
      ville: j['ville']?.toString(),
      typeContrat: j['type_contrat']?.toString(),
    );
  }
}

final candidateMatchesProvider =
    FutureProvider.autoDispose<List<CandidateMatch>>((ref) async {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return const [];
  final res = await ref.watch(dioProvider).get('/matching/candidate/${user.id}');
  final data = res.data;
  final list = data is List ? data : (data is Map && data['data'] is List ? data['data'] as List : const []);
  return list
      .whereType<Map>()
      .map((m) => CandidateMatch.fromJson(Map<String, dynamic>.from(m)))
      .toList();
});

/// "Matching Offres d'emploi" — module du plan Standard candidat.
/// Sans abonnement Standard actif, l'acces est verrouille (gate).
class CandidateMatchingScreen extends ConsumerWidget {
  const CandidateMatchingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasStandard = ref.watch(candidateSubscriptionProvider) != null;
    final subsLoading = ref.watch(activeSubscriptionsProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('cmatch.title'))),
      body: subsLoading
          ? const Center(child: CircularProgressIndicator())
          : !hasStandard
              ? SubscriptionGate(
                  message: context.tr('gate.candidate_locked'),
                  subscribeRoute: '/candidat/abonnement',
                  icon: Icons.auto_awesome,
                )
              : const _MatchesList(),
    );
  }
}

class _MatchesList extends ConsumerWidget {
  const _MatchesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(candidateMatchesProvider);
    return async.when(
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
                onPressed: () => ref.invalidate(candidateMatchesProvider),
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
                  const Icon(Icons.work_outline,
                      size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(context.tr('cmatch.empty'),
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
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(context.tr('cmatch.subtitle'),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
              );
            }
            final m = matches[i - 1];
            return _MatchTile(match: m);
          },
        );
      },
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match});
  final CandidateMatch match;

  Color get _scoreColor {
    if (match.score >= 70) return AppColors.success;
    if (match.score >= 40) return AppColors.primary;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/offre/${match.offreId}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (match.ville != null && match.ville!.isNotEmpty)
                        match.ville!,
                      if (match.typeContrat != null &&
                          match.typeContrat!.isNotEmpty)
                        match.typeContrat!,
                    ].join(' · '),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (match.score / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.background,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_scoreColor),
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
      ),
    );
  }
}
