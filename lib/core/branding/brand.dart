import 'package:flutter/material.dart';

/// Les trois univers de marque BantuLink.
enum BrandWorld { link, hire, market }

class Brand {
  static const String _link = 'assets/logos/logobantulink.png';
  static const String _hire = 'assets/logos/logobantuhire.png';
  static const String _market = 'assets/logos/logobantumarket.png';

  static String asset(BrandWorld w) {
    switch (w) {
      case BrandWorld.hire:
        return _hire;
      case BrandWorld.market:
        return _market;
      case BrandWorld.link:
        return _link;
    }
  }

  /// Couleur d'accent (le rouge propre a chaque sous-marque).
  static Color accent(BrandWorld w) {
    switch (w) {
      case BrandWorld.hire:
        return const Color(0xFFE6324B);
      case BrandWorld.market:
        return const Color(0xFFED1C24);
      case BrandWorld.link:
        return const Color(0xFFE63946);
    }
  }
}

/// Affiche le logo PNG de l'univers demande.
class BrandLogo extends StatelessWidget {
  const BrandLogo(this.world, {super.key, this.height = 28});
  final BrandWorld world;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      Brand.asset(world),
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
