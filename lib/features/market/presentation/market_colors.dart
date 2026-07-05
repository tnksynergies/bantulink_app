import 'package:flutter/material.dart';

/// Charte graphique BantuMarket, alignee sur la version web
/// (bantu-market-connect/src/index.css) :
///   --primary:   hsl(142 71% 45%)  -> vert  #22C55E
///   --secondary: hsl(24 100% 50%)  -> orange #FF6600 (accent)
///   --foreground: hsl(142 71% 20%) -> vert fonce (texte)
///   --muted:     hsl(142 20% 96%)  -> fond teinte vert
///   --border:    hsl(142 20% 90%)
///   --radius: 0.75rem (12px)
class MarketColors {
  MarketColors._();

  /// Vert primaire (boutons, prix, liens).
  static const Color primary = Color(0xFF22C55E);

  /// Vert clair (gradient glow hsl(142 71% 55%)).
  static const Color primaryGlow = Color(0xFF3DDC7A);

  /// Vert fonce pour les textes forts (hsl 142 71% 20%).
  static const Color foreground = Color(0xFF0F5729);

  /// Orange accent (etoiles, badges promo, CTA secondaires).
  static const Color accent = Color(0xFFFF6600);

  /// Orange clair (gradient accent hsl(24 100% 60%)).
  static const Color accentGlow = Color(0xFFFF8433);

  /// Fond teinte vert tres clair (hsl 142 20% 96%).
  static const Color muted = Color(0xFFF2F8F4);

  /// Texte secondaire gris-vert (hsl 142 10% 45%).
  static const Color mutedForeground = Color(0xFF67806F);

  /// Bordures teintees (hsl 142 20% 90%).
  static const Color border = Color(0xFFE0EDE4);

  static const double radius = 12;

  /// Gradient hero : vert -> orange, comme le bandeau web
  /// `bg-gradient-to-br from-primary via-secondary to-accent`.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  /// Gradient vert pur (`--gradient-primary`).
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryGlow],
  );
}
