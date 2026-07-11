import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../i18n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Carte de verrouillage d'un module reserve a un plan payant
/// (PLAN TARIFAIRE BANTUHIRE : les modules s'activent selon l'abonnement).
/// Affiche le motif + un CTA vers l'ecran d'abonnement concerne.
class SubscriptionGate extends StatelessWidget {
  const SubscriptionGate({
    super.key,
    required this.message,
    required this.subscribeRoute,
    this.icon = Icons.lock_outline,
  });

  /// Message deja traduit (ex: context.tr('gate.recruiter_locked')).
  final String message;

  /// Route de l'ecran d'abonnement (ex: '/recruteur/abonnement').
  final String subscribeRoute;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: Icon(icon, size: 30, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              Text(context.tr('gate.locked_title'),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textMuted,
                      height: 1.4)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push(subscribeRoute),
                  icon: const Icon(Icons.workspace_premium_outlined,
                      size: 18),
                  label: Text(context.tr('gate.subscribe_now')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
