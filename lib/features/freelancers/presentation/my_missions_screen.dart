import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../application/missions_providers.dart';
import '../data/models/mission.dart';
import 'sheets/mission_payment_sheet.dart';
import 'sheets/review_mission_sheet.dart';
import 'widgets/mission_card.dart';

class MyMissionsScreen extends ConsumerWidget {
  const MyMissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myMissionsProvider);
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('mission.my_missions')),
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
                  Tab(text: context.tr('mission.tab_all')),
                  Tab(text: context.tr('mission.tab_pending')),
                  Tab(text: context.tr('mission.tab_in_progress')),
                  Tab(text: context.tr('mission.tab_completed')),
                  Tab(text: context.tr('mission.tab_cancelled')),
                ],
              ),
            ),
          ),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('$e', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(myMissionsProvider),
                    child: Text(context.tr('common.retry')),
                  ),
                ],
              ),
            ),
          ),
          data: (all) {
            return TabBarView(children: [
              _MissionList(missions: all),
              _MissionList(missions: all.where((m) => m.status == MissionStatus.enAttente).toList()),
              _MissionList(
                  missions: all
                      .where((m) =>
                          m.status == MissionStatus.enCours ||
                          m.status == MissionStatus.acceptee ||
                          m.status == MissionStatus.enPause)
                      .toList()),
              _MissionList(missions: all.where((m) => m.status == MissionStatus.terminee).toList()),
              _MissionList(missions: all.where((m) => m.status == MissionStatus.annulee).toList()),
            ]);
          },
        ),
      ),
    );
  }
}

class _MissionList extends ConsumerWidget {
  const _MissionList({required this.missions});
  final List<Mission> missions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (missions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assignment_outlined, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(context.tr('mission.no_missions'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myMissionsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: missions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final m = missions[i];
          final actions = <Widget>[
            OutlinedButton.icon(
              onPressed: () => context.push('/mission/${m.id}'),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: Text(context.tr('mission.details')),
            ),
            if (m.canFinish)
              ElevatedButton.icon(
                onPressed: () => _showPaymentSheet(context, m),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: Text(context.tr('mission.finish')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            if (m.canReview)
              OutlinedButton.icon(
                onPressed: () => _showReviewSheet(context, m),
                icon: const Icon(Icons.star_outline, size: 16),
                label: Text(context.tr('mission.review')),
              ),
            if (m.canCancelClient && m.status != MissionStatus.terminee)
              TextButton.icon(
                onPressed: () => _cancel(context, ref, m),
                icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                label: Text(context.tr('mission.cancel'),
                    style: const TextStyle(color: AppColors.error)),
              ),
            if (m.freelancerId != null)
              TextButton.icon(
                onPressed: () => context.push('/prestataire/${m.freelancerId}'),
                icon: const Icon(Icons.person_outline, size: 16),
                label: Text(context.tr('mission.view_provider')),
              ),
          ];
          return MissionCard(
            mission: m,
            perspective: 'client',
            onTap: () => context.push('/mission/${m.id}'),
            actions: actions,
          );
        },
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, Mission m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('mission.cancel')),
        content: Text('${m.titreSafe} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('common.cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(context.tr('mission.cancel')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(updateMissionStatusControllerProvider(m.id).notifier)
          .submit(MissionStatus.annulee);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showPaymentSheet(BuildContext context, Mission m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MissionPaymentSheet(mission: m),
    );
  }

  void _showReviewSheet(BuildContext context, Mission m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewMissionSheet(missionId: m.id),
    );
  }
}
