import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/widgets/language_toggle.dart';
import '../../auth/application/auth_controller.dart';
import '../../market/application/vendor_providers.dart';
import '../../recruiter/data/recruiter_remote_data_source.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final photo = mediaUrl(user?.photoProfil);

    // ---- Detection des roles (synchrone, base sur /user deja charge) ----
    // NB : acheter, trouver un prestataire et candidater sont ouverts a tous
    // par defaut. Seuls les espaces vendeur / prestataire / recruteur sont
    // conditionnes au role.
    // Vendeur : profil vendeur OU role Vendeur (provider market).
    final isVendor = ref.watch(isCurrentUserVendorProvider);
    // Prestataire : profil freelancer OU role dedie.
    final lowerRoles =
        (user?.roles ?? const <String>[]).map((r) => r.toLowerCase().trim());
    final isFreelancer = user?.raw['freelancer'] != null ||
        lowerRoles.any((n) =>
            n == 'freelancer' || n == 'prestataire' || n == 'provider');
    // Recruteur : match strict sur les noms de roles.
    final isRecruiter =
        RecruiterRemoteDataSource.isRecruiterRole(lowerRoles);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile.title')),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: LanguageToggle(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                backgroundImage: photo != null
                    ? CachedNetworkImageProvider(photo)
                    : null,
                child: photo == null
                    ? const Icon(Icons.person, size: 34, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? '',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy)),
                    Text(user?.email ?? '',
                        style: const TextStyle(color: AppColors.textMuted)),
                    if ((user?.roleActif ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.brandGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(user!.roleActif!,
                              style: const TextStyle(
                                  color: AppColors.brandGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (user != null && !user.hasCandidatProfile)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        context.tr('profile.complete_candidate_hint'),
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          _Tile(
            icon: Icons.badge_outlined,
            title: context.tr('profile.my_candidate_profile'),
            subtitle: user?.hasCandidatProfile == true
                ? context.tr('profile.edit_info')
                : context.tr('profile.complete_profile'),
            onTap: () => context.push('/profil/editer'),
          ),
          // Candidater : visible uniquement si le profil candidat existe.
          if (user?.hasCandidatProfile == true)
            _Tile(
              icon: Icons.assignment_outlined,
              title: context.tr('profile.my_applications'),
              subtitle: context.tr('profile.track_evolution'),
              onTap: () => context.go('/emploi'),
            ),
          if (user?.hasCandidatProfile == true)
            _Tile(
              icon: Icons.auto_awesome_outlined,
              title: context.tr('cmatch.title'),
              subtitle: context.tr('cmatch.tile_sub'),
              onTap: () => context.push('/candidat/matching'),
            ),
          if (user?.hasCandidatProfile == true)
            _Tile(
              icon: Icons.workspace_premium_outlined,
              title: context.tr('csub.profile_tile'),
              subtitle: context.tr('csub.profile_tile_sub'),
              onTap: () => context.push('/candidat/abonnement'),
            ),
          // Trouver un prestataire : ouvert a tous.
          _Tile(
            icon: Icons.handshake_outlined,
            title: context.tr('profile.my_service_requests'),
            subtitle: context.tr('profile.track_pay_review'),
            onTap: () => context.push('/mes-missions'),
          ),
          // Acheter : ouvert a tous (le profil acheteur se cree
          // automatiquement au premier ajout au panier).
          _Tile(
            icon: Icons.shopping_bag_outlined,
            title: context.tr('profile.my_orders_market'),
            subtitle: context.tr('profile.orders_subtitle'),
            onTap: () => context.push('/mes-commandes'),
          ),
          _Tile(
            icon: Icons.favorite_border,
            title: context.tr('profile.my_favorites'),
            subtitle: context.tr('profile.favorites_subtitle'),
            onTap: () => context.push('/mes-favoris'),
          ),

          // ---- Tuiles conditionnelles par role ----

          // Vendeur : espace boutique
          if (isVendor)
            _Tile(
              icon: Icons.storefront_outlined,
              title: context.tr('profile.my_shop'),
              subtitle: context.tr('profile.shop_subtitle'),
              onTap: () => context.push('/vendeur/dashboard'),
            ),

          // Prestataire : espace freelance
          if (isFreelancer)
            _Tile(
              icon: Icons.design_services_outlined,
              title: context.tr('profile.provider_space'),
              subtitle: context.tr('profile.missions_wallet_reviews'),
              onTap: () => context.push('/prestataire/dashboard'),
            ),

          // Recruteur : espace recrutement
          if (isRecruiter)
            _Tile(
              icon: Icons.badge_outlined,
              title: context.tr('profile.recruiter_space'),
              subtitle: context.tr('profile.recruiter_subtitle'),
              onTap: () => context.push('/recruteur/dashboard'),
            ),

          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: Text(context.tr('profile.logout'),
                style: const TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.navy)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
