import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Logo texte BantuLink (Bantu = vert, Link = rouge).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.fontSize = 30, this.tagline});
  final double fontSize;
  final String? tagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800),
            children: const [
              TextSpan(text: 'Bantu', style: TextStyle(color: AppColors.brandGreen)),
              TextSpan(text: 'Link', style: TextStyle(color: AppColors.brandRed)),
            ],
          ),
        ),
        if (tagline != null) ...[
          const SizedBox(height: 4),
          Text(tagline!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ],
    );
  }
}

/// Pastille ronde avec le monogramme "BL" (pour en-tete compact).
class BrandBadge extends StatelessWidget {
  const BrandBadge({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandGreen, AppColors.navy],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text('BL',
            style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}
