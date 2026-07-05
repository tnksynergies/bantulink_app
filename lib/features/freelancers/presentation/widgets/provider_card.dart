import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/freelancer.dart';

class ProviderCard extends StatelessWidget {
  const ProviderCard({super.key, required this.freelancer});

  final Freelancer freelancer;

  void _openProfile(BuildContext context) {
    context.push('/prestataire/${freelancer.id}');
  }

  @override
  Widget build(BuildContext context) {
    final cover = freelancer.photoCouverture;
    final avatar = freelancer.photoProfil;
    final rating = freelancer.computedRating;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: () => _openProfile(context),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: cover != null && cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: cover,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.background),
                            errorWidget: (_, __, ___) => _fallbackCover(),
                          )
                        : _fallbackCover(),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: -20,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.background,
                      backgroundImage: (avatar != null && avatar.isNotEmpty)
                          ? CachedNetworkImageProvider(avatar)
                          : null,
                      child: (avatar == null || avatar.isEmpty)
                          ? Text(
                              freelancer.nomSafe.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          freelancer.nomSafe,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (freelancer.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified, size: 16, color: AppColors.royalBlue),
                        ),
                    ],
                  ),
                  if (freelancer.titrePro != null) ...[
                    const SizedBox(height: 2),
                    Text(freelancer.titrePro!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(' (${freelancer.reviewCount})',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  if (freelancer.localisation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(freelancer.localisation,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (freelancer.competences.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: freelancer.competences.take(2).map((c) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(c.nom,
                              style: const TextStyle(fontSize: 10, color: AppColors.textPrimary)),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 8),
                  if (freelancer.montantMinimum != null)
                    Text(
                      '${context.tr('provider.from_price')} ${freelancer.montantMinimum!.toStringAsFixed(0)} XAF',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackCover() {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Icon(Icons.person_outline, size: 48, color: AppColors.textMuted),
      ),
    );
  }
}
