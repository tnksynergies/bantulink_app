import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/offer.dart';
import 'matching_score_circle.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer, required this.onTap, this.score});
  final Offer offer;
  final VoidCallback onTap;
  final double? score;

  @override
  Widget build(BuildContext context) {
    final logo = offer.employeur?.logo;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Logo(url: logo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(offer.titreSafe,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy)),
                        if ((offer.employeur?.nom ?? '').isNotEmpty)
                          Text(offer.employeur!.nom!,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (score != null) ...[
                    const SizedBox(width: 8),
                    MatchingScoreCircle(score: score!, size: 44),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if ((offer.ville ?? '').isNotEmpty)
                    _MetaChip(icon: Icons.place_outlined, label: offer.ville!),
                  if ((offer.typeContrat ?? '').isNotEmpty)
                    _MetaChip(icon: Icons.description_outlined, label: offer.typeContrat!),
                  if ((offer.niveauExperience ?? '').isNotEmpty)
                    _MetaChip(icon: Icons.workspace_premium_outlined, label: offer.niveauExperience!),
                  if (offer.dejaCandidature)
                    _MetaChip(icon: Icons.check_circle, label: 'Deja candidate', color: AppColors.success),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (offer.datePubCourt.isNotEmpty)
                    Text('Publie le ${offer.datePubCourt}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const Spacer(),
                  if (offer.isFavoris)
                    const Icon(Icons.bookmark, color: AppColors.primary, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 48,
        height: 48,
        child: (url == null)
            ? _fallback()
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _fallback(),
                errorWidget: (_, __, ___) => _fallback(),
              ),
      ),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.primary.withOpacity(0.10),
        child: const Icon(Icons.business, color: AppColors.primary),
      );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color == null ? AppColors.background : color!.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color == null ? AppColors.border : color!.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color == null ? AppColors.textPrimary : c,
                  fontWeight: color == null ? FontWeight.normal : FontWeight.w600)),
        ],
      ),
    );
  }
}
