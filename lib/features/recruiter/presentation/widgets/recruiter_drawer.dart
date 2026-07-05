import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Drawer lateral du recruteur — replique la sidebar de la version web.
class RecruiterDrawer extends StatelessWidget {
  const RecruiterDrawer({super.key, required this.activeRoute});

  /// Chemin exact de la route courante (ex: '/recruteur/dashboard').
  final String activeRoute;

  static const _items = <_Item>[
    _Item('recruiter.dashboard', Icons.dashboard_outlined, '/recruteur/dashboard'),
    _Item('recruiter.my_offers', Icons.work_outline, '/recruteur/offres'),
    _Item('recruiter.applications', Icons.description_outlined, '/recruteur/candidatures'),
    _Item('recruiter.messages', Icons.forum_outlined, '/messages'),
    _Item('recruiter.subscriptions', Icons.credit_card, '/recruteur/abonnement'),
    _Item('recruiter.analytics', Icons.bar_chart, '/recruteur/analytics'),
    _Item('recruiter.settings', Icons.settings_outlined, '/recruteur/parametres'),
  ];

  /// Item special : retour a l'accueil (sort du contexte recruteur).
  static const _homeItem =
      _Item('nav.home', Icons.home_outlined, '/accueil');

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: AppColors.navy,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.badge, color: Colors.white, size: 28),
                  const SizedBox(height: 8),
                  Text(context.tr('recruiter.dashboard'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Retour rapide a l'accueil (hors sidebar recruteur)
            _navItem(context, _homeItem),
            const Divider(height: 20, color: AppColors.border),
            for (final it in _items) _navItem(context, it),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, _Item it) {
    final selected = activeRoute == it.route;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(it.icon,
            color: selected ? AppColors.primary : AppColors.textMuted),
        title: Text(
          context.tr(it.i18nKey),
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop(); // ferme le drawer
          if (!selected) {
            context.go(it.route);
          }
        },
      ),
    );
  }
}

class _Item {
  const _Item(this.i18nKey, this.icon, this.route);
  final String i18nKey;
  final IconData icon;
  final String route;
}
