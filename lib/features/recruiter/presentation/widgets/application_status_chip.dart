import 'package:flutter/material.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../jobs/data/models/candidature.dart';

class ApplicationStatusChip extends StatelessWidget {
  const ApplicationStatusChip({super.key, required this.status, this.small = false});

  final CandidatureStatus status;
  final bool small;

  ({Color bg, Color fg, String i18nKey, IconData icon}) _style() {
    switch (status) {
      case CandidatureStatus.envoyee:
        return (
          bg: const Color(0xFFDBEAFE),
          fg: const Color(0xFF1E40AF),
          i18nKey: 'application.status.sent',
          icon: Icons.send_outlined
        );
      case CandidatureStatus.recue:
        return (
          bg: const Color(0xFFE0F2FE),
          fg: const Color(0xFF0369A1),
          i18nKey: 'application.status.received',
          icon: Icons.mark_email_read_outlined
        );
      case CandidatureStatus.preselectionne:
        return (
          bg: const Color(0xFFFFEDD5),
          fg: const Color(0xFFC2410C),
          i18nKey: 'application.status.preselected',
          icon: Icons.star_outline
        );
      case CandidatureStatus.invitationEntretien:
        return (
          bg: const Color(0xFFEDE9FE),
          fg: const Color(0xFF6D28D9),
          i18nKey: 'application.status.interview',
          icon: Icons.event_available_outlined
        );
      case CandidatureStatus.embauche:
        return (
          bg: const Color(0xFFDCFCE7),
          fg: const Color(0xFF15803D),
          i18nKey: 'application.status.hired',
          icon: Icons.check_circle_outline
        );
      case CandidatureStatus.rejete:
        return (
          bg: const Color(0xFFFEE2E2),
          fg: const Color(0xFFB91C1C),
          i18nKey: 'application.status.rejected',
          icon: Icons.close
        );
      case CandidatureStatus.inconnu:
        return (
          bg: const Color(0xFFF3F4F6),
          fg: const Color(0xFF4B5563),
          i18nKey: 'application.status.sent',
          icon: Icons.help_outline
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style();
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 10, vertical: small ? 4 : 6),
      decoration:
          BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: small ? 12 : 14, color: s.fg),
          const SizedBox(width: 4),
          Text(
            context.tr(s.i18nKey),
            style: TextStyle(
                color: s.fg,
                fontSize: small ? 11 : 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
