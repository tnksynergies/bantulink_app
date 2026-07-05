import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../jobs/data/models/candidature.dart';
import '../application/recruiter_providers.dart';
import 'widgets/application_status_chip.dart';
import 'widgets/recruiter_drawer.dart';

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key, this.filterOfferId});

  /// Si non null, on filtre les candidatures pour n'afficher que celles
  /// de l'offre indiquee (utilise depuis MyJobPostsScreen).
  final int? filterOfferId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = filterOfferId != null
        ? ref.watch(applicationsByOfferProvider(filterOfferId!))
        : ref.watch(applicationsProvider);
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('recruiter.applications')),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: SizedBox(
              height: 48,
              child: TabBar(
                isScrollable: true,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                tabs: [
                  Tab(text: context.tr('application.tab_all')),
                  Tab(text: context.tr('application.tab_new')),
                  Tab(text: context.tr('application.tab_shortlist')),
                  Tab(text: context.tr('application.tab_interview')),
                  Tab(text: context.tr('application.tab_done')),
                ],
              ),
            ),
          ),
        ),
        drawer: filterOfferId != null
            ? null
            : const RecruiterDrawer(activeRoute: '/recruteur/candidatures'),
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
                    onPressed: () => filterOfferId != null
                        ? ref.invalidate(
                            applicationsByOfferProvider(filterOfferId!))
                        : ref.invalidate(applicationsProvider),
                    child: Text(context.tr('common.retry')),
                  ),
                ],
              ),
            ),
          ),
          data: (apps) {
            return TabBarView(
              children: [
                _ApplicationList(items: apps),
                _ApplicationList(
                    items: apps
                        .where((c) =>
                            c.status == CandidatureStatus.envoyee ||
                            c.status == CandidatureStatus.recue)
                        .toList()),
                _ApplicationList(
                    items: apps
                        .where((c) =>
                            c.status == CandidatureStatus.preselectionne)
                        .toList()),
                _ApplicationList(
                    items: apps
                        .where((c) =>
                            c.status == CandidatureStatus.invitationEntretien)
                        .toList()),
                _ApplicationList(
                    items: apps
                        .where((c) =>
                            c.status == CandidatureStatus.embauche ||
                            c.status == CandidatureStatus.rejete)
                        .toList()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ApplicationList extends StatelessWidget {
  const _ApplicationList({required this.items});
  final List<Candidature> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined,
                  size: 64, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(context.tr('application.no_applications'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ApplicationCard(candidature: items[i]),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.candidature});
  final Candidature candidature;

  @override
  Widget build(BuildContext context) {
    final c = candidature;
    final candidat = c.candidat;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/recruteur/candidature/${c.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row avatar + nom + statut
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.background,
                      image: (candidat?.photoProfil != null &&
                              candidat!.photoProfil!.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(candidat.photoProfil!),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: (candidat?.photoProfil == null ||
                            candidat!.photoProfil!.isEmpty)
                        ? Text(
                            candidat?.initials ?? '?',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          candidat?.displayName ?? 'Candidat',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (c.offreTitre != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            c.offreTitre!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ApplicationStatusChip(status: c.status, small: true),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${context.tr('application.applied_on')} ${c.dateCourt}',
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
