import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/subscriptions/subscriptions_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../jobs/data/models/offer.dart';
import '../application/recruiter_providers.dart';
import 'widgets/recruiter_drawer.dart';

class MyJobPostsScreen extends ConsumerWidget {
  const MyJobPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myOffersProvider);
    // Plan Gratuit = 1 offre publiee. "Publier plusieurs offres" est un
    // module du plan Pro Recruteur (ou de l'essai 2 mois).
    final access = ref.watch(recruiterAccessProvider);
    final offersCount = async.valueOrNull?.length ?? 0;
    final needsPro = !access.canUseProFeatures && offersCount >= 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('recruiter.my_offers')),
      ),
      drawer: const RecruiterDrawer(activeRoute: '/recruteur/offres'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (needsPro) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(SnackBar(
              content: Text(
                  '${context.tr('gate.recruiter_locked')} ${context.tr('rsub.pro_b1')}.'),
            ));
            context.push('/recruteur/abonnement');
            return;
          }
          context.push('/offre/nouvelle');
        },
        icon: Icon(needsPro ? Icons.lock_outline : Icons.add),
        label: Text(context.tr('recruiter.new_offer')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myOffersProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _errorView(context, ref, e),
          data: (offers) {
            if (offers.isEmpty) return _emptyView(context);
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: offers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _OfferCard(offer: offers[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _emptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.work_outline,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(context.tr('recruiter.offers_empty'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/offre/nouvelle'),
              icon: const Icon(Icons.add),
              label: Text(context.tr('recruiter.new_offer')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView(BuildContext context, WidgetRef ref, Object e) {
    return Center(
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
              onPressed: () => ref.invalidate(myOffersProvider),
              child: Text(context.tr('common.retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends ConsumerWidget {
  const _OfferCard({required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              offer.titreSafe,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (offer.typeContrat != null)
                  _pill(offer.typeContrat!, AppColors.royalBlue),
                if (offer.ville != null)
                  _pill(offer.ville!, AppColors.textMuted),
                if (offer.remuneration != null)
                  _pill('${offer.remuneration!} FCFA', AppColors.primary),
              ],
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(Icons.people_outline,
                        size: 14, color: AppColors.textMuted),
                  ),
                  TextSpan(
                    text:
                        '  ${context.tr('recruiter.view_applications').replaceAll('{count}', '${offer.candidaturesCount}')}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/recruteur/candidatures?offre=${offer.id}'),
                  icon: const Icon(Icons.people_outline, size: 16),
                  label: Text(
                    context.tr('recruiter.view_applications')
                        .replaceAll('{count}', '${offer.candidaturesCount}'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/offre/${offer.id}/editer'),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(context.tr('recruiter.edit_offer')),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push(
                      '/recruteur/offres/${offer.id}/matching?titre=${Uri.encodeComponent(offer.titreSafe)}'),
                  icon: const Icon(Icons.auto_awesome,
                      size: 16, color: AppColors.royalBlue),
                  label: Text(context.tr('matching.view_matching'),
                      style: const TextStyle(color: AppColors.royalBlue)),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, ref, offer),
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.error),
                  label: Text(context.tr('recruiter.delete_offer'),
                      style: const TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Offer offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('recruiter.confirm_delete_offer')),
        content: Text('${offer.titreSafe}\n${context.tr('recruiter.delete_desc')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(context.tr('recruiter.delete_offer')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(deleteOfferControllerProvider.notifier).submit(offer.id);
      messenger.showSnackBar(
        SnackBar(content: Text(context.mounted ? context.tr('recruiter.deleted') : '')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }
}
