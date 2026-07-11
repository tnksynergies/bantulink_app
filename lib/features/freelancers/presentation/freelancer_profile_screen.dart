import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../application/freelancers_providers.dart';
import '../data/models/freelancer.dart';
import 'sheets/request_mission_sheet.dart';

class FreelancerProfileScreen extends ConsumerWidget {
  const FreelancerProfileScreen({super.key, required this.freelancerId});

  final int freelancerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(freelancerDetailProvider(freelancerId));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          async.valueOrNull?.nomSafe ?? context.tr('common.loading'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          error: e,
          onRetry: () => ref.invalidate(freelancerDetailProvider(freelancerId)),
        ),
        data: (freelancer) => _ProfileBody(freelancer: freelancer),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.tr('common.retry')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Version ENRICHIE mais restant sur des patterns eprouves cote Flutter web.
/// Regles de survie :
/// - ListView top-level (bornee par le viewport)
/// - Container avec DecorationImage pour toutes les images (jamais Image.network)
/// - Column parents ont mainAxisSize.min
/// - Row parents ont soit Expanded, soit mainAxisSize.min pour eviter les
///   cascades de contraintes infinies
/// - Pas de SingleChildScrollView ni SliverAppBar ni bottomNavigationBar
class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.freelancer});
  final Freelancer freelancer;

  void _openRequestSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RequestMissionSheet(freelancer: freelancer),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _cover(),
        _headerCard(context),
        const SizedBox(height: 8),
        _ctaCard(context),
        const SizedBox(height: 8),
        _statsCard(context),
        const SizedBox(height: 8),
        _aboutCard(context),
        if (freelancer.competences.isNotEmpty) ...[
          const SizedBox(height: 8),
          _skillsCard(context),
        ],
        if (freelancer.realisations.isNotEmpty) ...[
          const SizedBox(height: 8),
          _portfolioCard(context),
        ],
        const SizedBox(height: 8),
        _reviewsCard(context),
        const SizedBox(height: 40),
      ],
    );
  }

  // 1. Cover simple (Container avec DecorationImage)
  Widget _cover() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.navy,
        image: _bgImage(freelancer.photoCouverture),
      ),
    );
  }

  // 2. Header : avatar (Container + DecorationImage circulaire) + nom + titre + localisation
  Widget _headerCard(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar rond via Container + DecorationImage (jamais Image.network)
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
              image: _bgImage(freelancer.photoProfil),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            alignment: Alignment.center,
            child: (freelancer.photoProfil == null ||
                    freelancer.photoProfil!.isEmpty)
                ? Text(
                    _initial(freelancer.nomSafe),
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          // Nom + badge Verifie via Text.rich (evite le Row)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: freelancer.nomSafe,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (freelancer.isVerified)
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.verified,
                          color: AppColors.royalBlue, size: 18),
                    ),
                  ),
              ],
            ),
          ),
          if (freelancer.titrePro != null) ...[
            const SizedBox(height: 4),
            Text(freelancer.titrePro!,
                style:
                    const TextStyle(fontSize: 14, color: AppColors.textMuted)),
          ],
          if (freelancer.localisation.isNotEmpty) ...[
            const SizedBox(height: 6),
            // Icone + localisation via Text.rich
            Text.rich(
              TextSpan(
                children: [
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.textMuted),
                  ),
                  TextSpan(
                    text: '  ${freelancer.localisation}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
          if (freelancer.profileViews > 0) ...[
            const SizedBox(height: 6),
            // Compteur de vues du profil (point 6)
            Text.rich(
              TextSpan(
                children: [
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(Icons.visibility_outlined,
                        size: 14, color: AppColors.textMuted),
                  ),
                  TextSpan(
                    text:
                        '  ${freelancer.profileViews} ${context.tr('views.profile_views').toLowerCase()}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 3. CTA + prix
  Widget _ctaCard(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (freelancer.montantMinimum != null &&
              freelancer.montantMinimum! > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${context.tr('provider.from_price')} '
                '${freelancer.montantMinimum!.toStringAsFixed(0)} XAF',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ),
          ElevatedButton.icon(
            onPressed: () => _openRequestSheet(context),
            icon: const Icon(Icons.assignment_outlined, size: 18),
            label: Text(context.tr('mission.request')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Stats en 3 colonnes via Row(3 Expanded + 2 separateurs de largeur fixe)
  Widget _statsCard(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              icon: Icons.star,
              value: freelancer.computedRating.toStringAsFixed(1),
              label:
                  '${freelancer.reviewCount} ${context.tr('provider.reviews')}',
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          Expanded(
            child: _Stat(
              icon: Icons.task_alt,
              value: '${freelancer.missionsCount ?? 0}',
              label: context.tr('provider.completed_jobs'),
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          Expanded(
            child: _Stat(
              icon: Icons.calendar_today_outlined,
              value: '${freelancer.memberSinceYear}',
              label: context.tr('provider.member_since'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutCard(BuildContext context) {
    return _Section(
      title: context.tr('provider.about'),
      child: Text(
        (freelancer.description?.isNotEmpty == true)
            ? freelancer.description!
            : context.tr('provider.no_description'),
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }

  // 5. Competences en chips via Wrap
  Widget _skillsCard(BuildContext context) {
    return _Section(
      title: context.tr('provider.skills'),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: freelancer.competences.map((c) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(c.nom, style: const TextStyle(fontSize: 12)),
          );
        }).toList(),
      ),
    );
  }

  // 6. Portfolio via ListView horizontal borne en hauteur
  Widget _portfolioCard(BuildContext context) {
    return _Section(
      title: context.tr('provider.portfolio'),
      child: SizedBox(
        height: 180,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: freelancer.realisations.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final r = freelancer.realisations[i];
            return SizedBox(
              width: 200,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 200,
                    height: 130,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      image: _bgImage(r.cover?.path),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.titre ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (r.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        r.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 7. Avis avec avatar client + etoiles
  Widget _reviewsCard(BuildContext context) {
    return _Section(
      title:
          '${context.tr('provider.reviews_section')} (${freelancer.notes.length})',
      child: freelancer.notes.isEmpty
          ? Text(context.tr('provider.no_reviews'),
              style: const TextStyle(color: AppColors.textMuted))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final n in freelancer.notes.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Avatar client — Container circulaire, pas de widget image
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.background,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                n.authorName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.authorName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(n.dateCourt,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            _StarsRow(score: n.score),
                          ],
                        ),
                        if (n.description != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              n.description!,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  static String _initial(String name) =>
      name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();
}

/// Retourne une DecorationImage a partir d'une URL. Silencieux en cas d'erreur.
DecorationImage? _bgImage(String? url) {
  if (url == null || url.isEmpty) return null;
  return DecorationImage(
    image: NetworkImage(url),
    fit: BoxFit.cover,
    onError: (_, __) {},
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < score ? Icons.star : Icons.star_border,
          size: 14,
          color: Colors.amber,
        );
      }),
    );
  }
}
