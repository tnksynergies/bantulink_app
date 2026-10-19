import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../application/missions_providers.dart';
import '../data/models/mission.dart';
import 'sheets/mission_payment_sheet.dart';
import 'sheets/review_mission_sheet.dart';
import 'widgets/status_chip.dart';

class MissionDetailScreen extends ConsumerWidget {
  const MissionDetailScreen({super.key, required this.missionId});
  final int missionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(missionDetailProvider(missionId));
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('mission.details')),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('$e', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        data: (m) => _MissionDetailBody(
          mission: m,
          isFreelancer: m.freelancerId != null &&
              ref.watch(authControllerProvider).valueOrNull?.id ==
                  m.freelancerId,
        ),
      ),
    );
  }
}

class _MissionDetailBody extends ConsumerWidget {
  const _MissionDetailBody({required this.mission, required this.isFreelancer});
  final Mission mission;
  final bool isFreelancer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(mission.titreSafe,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              MissionStatusChip(status: mission.status),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _kv(context.tr('mission.start_date'), mission.dateDebutCourt),
              _kv(context.tr('mission.end_date'), mission.dateFinCourt),
              _kv(
                  context.tr('mission.budget'),
                  mission.cout != null
                      ? '${mission.cout!.toStringAsFixed(0)} XAF'
                      : '-'),
              _kv(context.tr('mission.provider'),
                  mission.freelancer?.nomComplet ?? '-'),
            ],
          ),
          const Divider(height: 32),
          Text(context.tr('mission.description_label'),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(mission.description ?? '-'),
          if (mission.images.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(context.tr('mission.attachments'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mission.images.map((img) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: img.path,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.background,
                      width: 90,
                      height: 90,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (mission.documents.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...mission.documents.map((d) => ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text('Document #${d.id}'),
                  subtitle: Text(d.path,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!isFreelancer && mission.canFinish)
                ElevatedButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => MissionPaymentSheet(mission: mission),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(context.tr('mission.finish')),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white),
                ),
              if (!isFreelancer && mission.canReview)
                OutlinedButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ReviewMissionSheet(missionId: mission.id),
                  ),
                  icon: const Icon(Icons.star_outline),
                  label: Text(context.tr('mission.review')),
                ),
              if (mission.freelancerId != null)
                TextButton.icon(
                  onPressed: () =>
                      context.push('/prestataire/${mission.freelancerId}'),
                  icon: const Icon(Icons.person_outline),
                  label: Text(context.tr('mission.view_provider')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
