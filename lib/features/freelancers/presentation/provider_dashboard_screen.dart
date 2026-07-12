import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/pricing/bantulink_fees.dart';
import '../../../core/services/invoice_pdf.dart';
import '../../../core/theme/app_colors.dart';
import '../application/freelancers_providers.dart';
import '../application/missions_providers.dart';
import '../data/models/freelancer.dart';
import '../data/models/mission.dart';
import 'widgets/mission_card.dart';

class ProviderDashboardScreen extends ConsumerWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myFreelancerProfileProvider);
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(context.tr('provider.dashboard'))),
        body: Center(child: Text('$e')),
      ),
      data: (freelancer) {
        if (freelancer == null) {
          // Cas rare : rediriger vers l'inscription.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/devenir-prestataire');
          });
          return const SizedBox.shrink();
        }
        return _Dashboard(freelancer: freelancer);
      },
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.freelancer});
  final Freelancer freelancer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('provider.dashboard')),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              tooltip: context.tr('wallet.title'),
              onPressed: () => context.push('/prestataire/wallet'),
            ),
            IconButton(
              icon: const Icon(Icons.workspace_premium_outlined),
              tooltip: context.tr('subscription.title'),
              onPressed: () => context.push('/prestataire/abonnement'),
            ),
            IconButton(
              icon: const Icon(Icons.shield_outlined),
              tooltip: context.tr('kyc.title'),
              onPressed: () => context.push('/prestataire/verification'),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: TabBar(
              isScrollable: true,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              tabs: [
                Tab(text: context.tr('provider.tab_profile')),
                Tab(text: context.tr('provider.tab_missions')),
                Tab(text: context.tr('provider.tab_portfolio')),
                Tab(text: context.tr('provider.tab_reviews')),
              ],
            ),
          ),
        ),
        body: TabBarView(children: [
          _ProfileTab(freelancer: freelancer),
          const _MissionsTab(),
          _PortfolioTab(freelancerId: freelancer.id),
          _ReviewsTab(freelancer: freelancer),
        ]),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.freelancer});
  final Freelancer freelancer;

  @override
  Widget build(BuildContext context) {
    final avatar = freelancer.photoProfil;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.background,
                  backgroundImage: (avatar != null && avatar.isNotEmpty)
                      ? CachedNetworkImageProvider(avatar)
                      : null,
                  child: (avatar == null || avatar.isEmpty)
                      ? Text(freelancer.nomSafe.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(freelancer.nomSafe,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold))),
                          if (freelancer.isVerified)
                            const Icon(Icons.verified, color: AppColors.royalBlue, size: 18),
                        ],
                      ),
                      if (freelancer.titrePro != null)
                        Text(freelancer.titrePro!,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      if (freelancer.localisation.isNotEmpty)
                        Text(freelancer.localisation,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: context.tr('provider.stats_completed'),
                    value: '${freelancer.missionsCount ?? 0}',
                    color: AppColors.success)),
            const SizedBox(width: 8),
            Expanded(
                child: _StatCard(
                    label: context.tr('provider.stats_rating'),
                    value: freelancer.computedRating.toStringAsFixed(1),
                    color: Colors.amber)),
            const SizedBox(width: 8),
            Expanded(
                child: _StatCard(
                    label: context.tr('views.profile_views'),
                    value: '${freelancer.profileViews}',
                    color: AppColors.royalBlue)),
          ],
        ),
        const SizedBox(height: 16),
        if (freelancer.description != null && freelancer.description!.isNotEmpty) ...[
          Text(context.tr('provider.about'),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(freelancer.description!),
          const SizedBox(height: 16),
        ],
        if (freelancer.competences.isNotEmpty) ...[
          Text(context.tr('provider.skills'),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: freelancer.competences.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(c.nom, style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/devenir-prestataire'),
            icon: const Icon(Icons.edit),
            label: Text(context.tr('provider.edit_profile')),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _MissionsTab extends ConsumerWidget {
  const _MissionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(freelancerMissionsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (missions) {
        if (missions.isEmpty) {
          return Center(
            child: Text(context.tr('provider.no_missions_provider'),
                style: const TextStyle(color: AppColors.textMuted)),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(freelancerMissionsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: missions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final m = missions[i];
              return MissionCard(
                mission: m,
                perspective: 'freelancer',
                onTap: () => context.push('/mission/${m.id}'),
                actions: _actions(context, ref, m),
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _actions(BuildContext context, WidgetRef ref, Mission m) {
    Future<void> setStatus(MissionStatus s) async {
      try {
        await ref
            .read(updateMissionStatusControllerProvider(m.id).notifier)
            .submit(s);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
          );
        }
      }
    }

    final list = <Widget>[
      OutlinedButton.icon(
        onPressed: () => context.push('/mission/${m.id}'),
        icon: const Icon(Icons.visibility_outlined, size: 16),
        label: Text(context.tr('mission.details')),
      ),
    ];
    if (m.canAcceptFreelancer) {
      list.add(ElevatedButton.icon(
        onPressed: () => setStatus(MissionStatus.acceptee),
        icon: const Icon(Icons.check, size: 16),
        label: Text(context.tr('provider.accept')),
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success, foregroundColor: Colors.white),
      ));
    }
    if (m.canStartFreelancer) {
      list.add(ElevatedButton.icon(
        onPressed: () => setStatus(MissionStatus.enCours),
        icon: const Icon(Icons.play_arrow, size: 16),
        label: Text(context.tr('provider.start')),
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.royalBlue, foregroundColor: Colors.white),
      ));
    }
    if (m.canFinishFreelancer) {
      list.add(OutlinedButton.icon(
        onPressed: () => setStatus(MissionStatus.terminee),
        icon: const Icon(Icons.done_all, size: 16),
        label: Text(context.tr('provider.finish_provider')),
      ));
      if (m.status == MissionStatus.enCours) {
        list.add(TextButton.icon(
          onPressed: () => setStatus(MissionStatus.enPause),
          icon: const Icon(Icons.pause, size: 16),
          label: Text(context.tr('provider.pause')),
        ));
      }
    }
    // Facture de prestation (logo BantuLink) sur les missions terminees.
    if (m.status == MissionStatus.terminee && (m.cout ?? 0) > 0) {
      list.add(OutlinedButton.icon(
        onPressed: () => _printMissionInvoice(context, m),
        icon: const Icon(Icons.print_outlined,
            size: 16, color: AppColors.royalBlue),
        label: Text(context.tr('invoice.download'),
            style: const TextStyle(color: AppColors.royalBlue)),
      ));
    }
    return list;
  }

  Future<void> _printMissionInvoice(BuildContext context, Mission m) async {
    final labels = invoiceLabels(context);
    final missionLabel = context.tr('invoice.mission');
    final messenger = ScaffoldMessenger.of(context);
    final amount = m.cout ?? 0;
    try {
      await InvoicePdf.printMission(
        missionId: m.id,
        missionTitle: m.titre ?? '$missionLabel #${m.id}',
        amount: amount,
        commissionPercent: BantulinkFees.freelanceRateFor(amount),
        commissionAmount: BantulinkFees.freelanceFeeFor(amount),
        netAmount: BantulinkFees.freelanceNetFor(amount),
        date: ((m.dateFin ?? m.updatedAt) ?? '').split('T').first,
        clientName: m.client?.nomComplet,
        tr: (k) => labels[k] ?? k,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }
}

class _PortfolioTab extends ConsumerWidget {
  const _PortfolioTab({required this.freelancerId});
  final int freelancerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myRealisationsProvider);
    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (realisations) {
          if (realisations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo_library_outlined,
                        size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(context.tr('provider.no_realisations'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myRealisationsProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: realisations.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, i) {
                final r = realisations[i];
                final cover = r.cover?.path;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: cover != null && cover.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: cover,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    Container(color: AppColors.background),
                              )
                            : Container(
                                color: AppColors.background,
                                child: const Center(
                                    child: Icon(Icons.image_outlined, size: 32)),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(r.titre ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/prestataire/realisation/nouvelle'),
        icon: const Icon(Icons.add),
        label: Text(context.tr('provider.add_realisation')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({required this.freelancer});
  final Freelancer freelancer;

  @override
  Widget build(BuildContext context) {
    if (freelancer.notes.isEmpty) {
      return Center(
        child: Text(context.tr('provider.no_reviews'),
            style: const TextStyle(color: AppColors.textMuted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: freelancer.notes.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, i) {
        final n = freelancer.notes[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.background,
                  child: Text(n.authorName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Text(n.authorName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Row(
                  children: List.generate(
                      5,
                      (i) => Icon(i < n.score ? Icons.star : Icons.star_border,
                          color: Colors.amber, size: 14)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(n.dateCourt,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            if (n.description != null) ...[
              const SizedBox(height: 4),
              Text(n.description!),
            ],
          ],
        );
      },
    );
  }
}
