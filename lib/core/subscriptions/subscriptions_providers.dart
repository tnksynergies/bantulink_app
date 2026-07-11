import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/application/auth_controller.dart';
import '../network/network_providers.dart';

/// Abonnement actif tel que renvoye par GET /subscriptions/active
/// ({id, user_id, plan, period, status, start_date, end_date}).
class ActiveSubscription {
  const ActiveSubscription({
    required this.plan,
    required this.period,
    this.endDate,
    this.raw = const {},
  });

  final String plan; // 'standard' | 'pro' | 'monthly'... (libre cote back)
  final String period; // monthly | quarterly | yearly
  final String? endDate;
  final Map<String, dynamic> raw;

  String get endDateCourt =>
      (endDate != null && endDate!.length >= 10) ? endDate!.substring(0, 10) : (endDate ?? '');

  factory ActiveSubscription.fromJson(Map<String, dynamic> j) {
    return ActiveSubscription(
      plan: (j['plan'] ?? '').toString().toLowerCase(),
      period: (j['period'] ?? '').toString().toLowerCase(),
      endDate: j['end_date']?.toString(),
      raw: j,
    );
  }
}

/// Charge les abonnements actifs de l'utilisateur connecte.
/// Retourne une liste vide si non connecte ou en cas d'erreur reseau :
/// le gating doit degrader proprement (considerer "pas d'abonnement"),
/// jamais bloquer l'app.
final activeSubscriptionsProvider =
    FutureProvider.autoDispose<List<ActiveSubscription>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.get('/subscriptions/active');
    final data = res.data;
    final list = (data is Map && data['data'] is List)
        ? data['data'] as List
        : (data is List ? data : const []);
    return list
        .whereType<Map>()
        .map((m) => ActiveSubscription.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  } on DioException {
    return const [];
  }
});

/// Le backend ne stocke pas le type de profil sur la Subscription : on
/// retrouve le type via le prefixe/plan envoye a la souscription.
/// Convention mobile : plan 'standard' => candidat, 'pro' => recruteur,
/// 'freelancer'/'monthly'/'annual' herites => freelance.
bool _matchesCandidat(ActiveSubscription s) =>
    s.plan.contains('standard') || s.plan.contains('candidat');

bool _matchesRecruteur(ActiveSubscription s) =>
    s.plan.contains('pro') || s.plan.contains('recrut') || s.plan.contains('entreprise');

bool _matchesFreelance(ActiveSubscription s) =>
    s.plan.contains('freelance') ||
    s.plan.contains('prestataire') ||
    // anciens abonnements crees avant la refonte (plan = period)
    s.plan == 'monthly' ||
    s.plan == 'annual' ||
    s.plan == 'yearly';

/// Abonnement candidat Standard actif (null sinon).
final candidateSubscriptionProvider =
    Provider.autoDispose<ActiveSubscription?>((ref) {
  final subs = ref.watch(activeSubscriptionsProvider).valueOrNull ?? const [];
  for (final s in subs) {
    if (_matchesCandidat(s)) return s;
  }
  return null;
});

/// Abonnement recruteur Pro actif (null sinon).
final recruiterSubscriptionProvider =
    Provider.autoDispose<ActiveSubscription?>((ref) {
  final subs = ref.watch(activeSubscriptionsProvider).valueOrNull ?? const [];
  for (final s in subs) {
    if (_matchesRecruteur(s)) return s;
  }
  return null;
});

/// Abonnement freelance (modele 2) actif (null sinon).
final freelanceSubscriptionProvider =
    Provider.autoDispose<ActiveSubscription?>((ref) {
  final subs = ref.watch(activeSubscriptionsProvider).valueOrNull ?? const [];
  for (final s in subs) {
    if (_matchesFreelance(s)) return s;
  }
  return null;
});

/// Acces recruteur d'apres le PLAN TARIFAIRE : plan Gratuit = 2 mois d'essai
/// a partir de la creation du profil professionnel, ensuite plan Pro requis.
class RecruiterAccess {
  const RecruiterAccess({
    required this.hasPro,
    required this.inTrial,
    this.trialDaysLeft,
    this.subscription,
  });

  final bool hasPro;
  final bool inTrial;
  final int? trialDaysLeft;
  final ActiveSubscription? subscription;

  /// Peut utiliser les modules Pro (matching, offres multiples...).
  bool get canUseProFeatures => hasPro || inTrial;
}

final recruiterAccessProvider = Provider.autoDispose<RecruiterAccess>((ref) {
  final sub = ref.watch(recruiterSubscriptionProvider);
  if (sub != null) {
    return RecruiterAccess(hasPro: true, inTrial: false, subscription: sub);
  }
  // Essai gratuit : 2 mois depuis la creation du profil professionnel.
  final user = ref.watch(authControllerProvider).valueOrNull;
  final createdRaw = user?.professionnelRaw?['created_at']?.toString();
  final created = createdRaw != null ? DateTime.tryParse(createdRaw) : null;
  if (created != null) {
    final trialEnd = DateTime(created.year, created.month + 2, created.day);
    final now = DateTime.now();
    if (now.isBefore(trialEnd)) {
      return RecruiterAccess(
        hasPro: false,
        inTrial: true,
        trialDaysLeft: trialEnd.difference(now).inDays,
      );
    }
    return const RecruiterAccess(hasPro: false, inTrial: false);
  }
  // Date de creation inconnue : on n'enferme pas l'utilisateur dehors,
  // on le considere en essai (le backend reste l'autorite de paiement).
  return const RecruiterAccess(hasPro: false, inTrial: true);
});
