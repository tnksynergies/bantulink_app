import 'package:flutter/material.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../data/models/mission.dart';

class MissionStatusChip extends StatelessWidget {
  const MissionStatusChip({super.key, required this.status, this.small = false});
  final MissionStatus status;
  final bool small;

  ({Color bg, Color fg, String i18nKey, IconData icon}) _style() {
    switch (status) {
      case MissionStatus.enAttente:
        return (bg: const Color(0xFFFFF5D6), fg: const Color(0xFFB88700), i18nKey: 'status.pending', icon: Icons.schedule);
      case MissionStatus.acceptee:
        return (bg: const Color(0xFFDFF7E7), fg: const Color(0xFF166534), i18nKey: 'status.accepted', icon: Icons.check_circle_outline);
      case MissionStatus.enCours:
        return (bg: const Color(0xFFDBEAFE), fg: const Color(0xFF1E40AF), i18nKey: 'status.in_progress', icon: Icons.play_arrow);
      case MissionStatus.enPause:
        return (bg: const Color(0xFFFEE2C7), fg: const Color(0xFFB25502), i18nKey: 'status.paused', icon: Icons.pause);
      case MissionStatus.terminee:
        return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF15803D), i18nKey: 'status.completed', icon: Icons.done_all);
      case MissionStatus.annulee:
        return (bg: const Color(0xFFFEE2E2), fg: const Color(0xFFB91C1C), i18nKey: 'status.cancelled', icon: Icons.cancel_outlined);
      case MissionStatus.inconnu:
        return (bg: const Color(0xFFF3F4F6), fg: const Color(0xFF4B5563), i18nKey: 'status.pending', icon: Icons.help_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style();
    final label = context.tr(s.i18nKey);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 4 : 6),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: small ? 12 : 14, color: s.fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(color: s.fg, fontSize: small ? 11 : 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
