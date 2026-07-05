import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../jobs/data/models/candidature.dart';
import '../application/recruiter_providers.dart';
import 'widgets/recruiter_drawer.dart';

class RecruiterDashboardScreen extends ConsumerWidget {
  const RecruiterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOffers = ref.watch(myOffersProvider);
    final asyncApps = ref.watch(applicationsProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('recruiter.dashboard')),
        actions: [
          IconButton(
            tooltip: context.tr('nav.home'),
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/accueil'),
          ),
        ],
      ),
      drawer: const RecruiterDrawer(activeRoute: '/recruteur/dashboard'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/offre/nouvelle'),
        icon: const Icon(Icons.add),
        label: Text(context.tr('recruiter.new_offer')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myOffersProvider);
          ref.invalidate(applicationsProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header salutation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navy, AppColors.royalBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.tr('recruiter.welcome')}${(user?.displayFirstName ?? '').isNotEmpty ? ', ${user!.displayFirstName}' : ''}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('recruiter.dashboard'),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Grille de 4 KPI en 2 lignes de 2 colonnes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _kpiCard(
                          context,
                          label: context.tr('recruiter.total_offers'),
                          value: '${asyncOffers.valueOrNull?.length ?? '-'}',
                          icon: Icons.work_outline,
                          color: AppColors.royalBlue,
                          onTap: () => context.go('/recruteur/offres'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _kpiCard(
                          context,
                          label: context.tr('recruiter.active_offers'),
                          value:
                              '${_countActiveOffers(asyncOffers.valueOrNull ?? const [])}',
                          icon: Icons.trending_up,
                          color: AppColors.success,
                          onTap: () => context.go('/recruteur/offres'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _kpiCard(
                          context,
                          label: context.tr('recruiter.total_applications'),
                          value: '${asyncApps.valueOrNull?.length ?? '-'}',
                          icon: Icons.description_outlined,
                          color: AppColors.primary,
                          onTap: () => context.go('/recruteur/candidatures'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _kpiCard(
                          context,
                          label: context.tr('recruiter.pending_applications'),
                          value: '${_countPending(asyncApps.valueOrNull ?? const [])}',
                          icon: Icons.pending_actions_outlined,
                          color: AppColors.warning,
                          onTap: () => context.go('/recruteur/candidatures'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Activite recente : 5 dernieres candidatures
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                context.tr('recruiter.recent_activity'),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            asyncApps.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('$e',
                    style: const TextStyle(color: AppColors.error)),
              ),
              data: (apps) {
                if (apps.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        context.tr('recruiter.no_activity'),
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }
                final sorted = [...apps]..sort((a, b) =>
                    (b.dateCreation ?? '').compareTo(a.dateCreation ?? ''));
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final c in sorted.take(5))
                      _activityTile(context, c),
                  ],
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  static int _countActiveOffers(List offers) {
    return offers.where((o) {
      final s = (o.statut ?? '').toString().toLowerCase();
      return s.isEmpty || s.contains('actif') || s.contains('publ') || s == 'active';
    }).length;
  }

  static int _countPending(List<Candidature> apps) {
    return apps.where((c) {
      final s = c.status;
      return s == CandidatureStatus.envoyee || s == CandidatureStatus.recue;
    }).length;
  }

  Widget _kpiCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityTile(BuildContext context, Candidature c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => context.push('/recruteur/candidature/${c.id}'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.candidat?.displayName ?? 'Candidat',
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              c.offreTitre ?? '',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              '${context.tr('application.applied_on')} ${c.dateCourt}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
