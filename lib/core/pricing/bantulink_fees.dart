/// Grille tarifaire BantuLink — Strategie de lancement v1.0 (08/07/2026).
///
/// Source de verite : document "Strategie de Tarification des Transactions"
/// + endpoint backend GET /tarifs (les valeurs ci-dessous servent de
/// fallback hors-ligne et DOIVENT rester synchronisees avec le backend).
class BantulinkFees {
  BantulinkFees._();

  /// Commission forfaitaire BantuMarket, tout compris
  /// (plateforme + traitement des paiements).
  static const double marketCommissionPercent = 5.5;

  /// Paliers de commission Freelance selon la valeur du projet (FCFA).
  static const List<FreelanceTier> freelanceTiers = [
    FreelanceTier(min: 0, max: 20000, percent: 10.00),
    FreelanceTier(min: 20001, max: 80000, percent: 8.50),
    FreelanceTier(min: 80001, max: 200000, percent: 6.75),
    FreelanceTier(min: 200001, max: null, percent: 5.50),
  ];

  /// Taux de commission freelance applicable a un montant de projet donne.
  static double freelanceRateFor(num amount) {
    for (final t in freelanceTiers) {
      if (amount >= t.min && (t.max == null || amount <= t.max!)) {
        return t.percent;
      }
    }
    return freelanceTiers.last.percent;
  }

  /// Montant de commission freelance pour un projet donne.
  static double freelanceFeeFor(num amount) =>
      amount * freelanceRateFor(amount) / 100;

  /// Montant net percu par le freelance apres commission.
  static double freelanceNetFor(num amount) => amount - freelanceFeeFor(amount);

  /// Commission BantuMarket pour un montant de vente donne.
  static double marketFeeFor(num amount) =>
      amount * marketCommissionPercent / 100;

  /// Net vendeur apres commission BantuMarket.
  static double marketNetFor(num amount) => amount - marketFeeFor(amount);
}

class FreelanceTier {
  const FreelanceTier({required this.min, required this.max, required this.percent});
  final int min;
  final int? max; // null = illimite
  final double percent;

  String rangeLabel() {
    if (max == null) return '> ${_fmt(min - 1)}';
    return '${_fmt(min)} – ${_fmt(max!)}';
  }

  static String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
