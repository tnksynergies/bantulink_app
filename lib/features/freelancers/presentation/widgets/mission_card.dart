import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/mission.dart';
import 'status_chip.dart';

class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.mission,
    required this.perspective,
    this.onTap,
    this.actions = const [],
  });

  final Mission mission;

  /// 'client' = affiche le prestataire ; 'freelancer' = affiche le client.
  final String perspective;
  final VoidCallback? onTap;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isClient = perspective == 'client';
    final counterparty = isClient ? mission.freelancer?.nomComplet : mission.client?.nomComplet;
    final avatar = isClient ? mission.freelancer?.photoProfil : mission.client?.photoProfil;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.04),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
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
                            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  MissionStatusChip(status: mission.status, small: true),
                ],
              ),
              if (mission.description != null) ...[
                const SizedBox(height: 8),
                Text(mission.description!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.background,
                    backgroundImage: (avatar != null && avatar.isNotEmpty)
                        ? CachedNetworkImageProvider(avatar)
                        : null,
                    child: (avatar == null || avatar.isEmpty)
                        ? const Icon(Icons.person_outline, size: 16, color: AppColors.textMuted)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${context.tr(isClient ? 'mission.provider' : 'mission.client')}: ${counterparty ?? '-'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _MetaChip(icon: Icons.calendar_today_outlined, text: mission.dateCreationCourt),
                  if (mission.cout != null)
                    _MetaChip(
                        icon: Icons.payments_outlined,
                        text: '${mission.cout!.toStringAsFixed(0)} XAF',
                        highlight: true),
                ],
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text, this.highlight = false});
  final IconData icon;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.primary : AppColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: highlight ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }
}
