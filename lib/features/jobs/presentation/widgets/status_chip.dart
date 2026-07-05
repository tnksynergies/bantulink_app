import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StatusInfo {
  const StatusInfo(this.label, this.color);
  final String label;
  final Color color;
}

StatusInfo candidatureStatus(String? statut) {
  switch ((statut ?? '').toLowerCase()) {
    case 'embauche':
    case 'embauché':
      return const StatusInfo('Embauche', AppColors.success);
    case 'rejete':
    case 'rejeté':
    case 'refuse':
      return const StatusInfo('Non retenu', AppColors.error);
    case 'preselectionne':
    case 'présélectionné':
      return const StatusInfo('Preselectionne', AppColors.primary);
    case 'invitation_entretien':
    case 'entretien':
      return const StatusInfo('Entretien', AppColors.royalBlue);
    case 'en_revision':
    case 'en_attente':
    case 'envoyee':
    case 'envoyée':
    case 'recue':
    case 'reçue':
      return const StatusInfo("En cours d'examen", AppColors.textMuted);
    default:
      return StatusInfo(
          (statut == null || statut.isEmpty) ? 'En cours' : statut,
          AppColors.textMuted);
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.statut});
  final String? statut;

  @override
  Widget build(BuildContext context) {
    final info = candidatureStatus(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(info.label,
          style: TextStyle(
              color: info.color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
