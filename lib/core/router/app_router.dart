import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/startup_providers.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/jobs/presentation/jobs_screen.dart';
import '../../features/jobs/presentation/offer_detail_screen.dart';
import '../../features/jobs/presentation/candidature_detail_screen.dart';
import '../../features/jobs/presentation/candidate_matching_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_particulier_screen.dart';
import '../../features/boutique/presentation/boutique_screen.dart';
import '../../features/messaging/presentation/conversations_screen.dart';
import '../../features/messaging/presentation/chat_screen.dart';
import '../../features/shell/presentation/main_shell.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../shared/presentation/coming_soon_screen.dart';
import '../../features/recruiter/presentation/create_offer_screen.dart';
import '../../features/recruiter/presentation/recruiter_register_screen.dart';
import '../../features/recruiter/presentation/recruiter_dashboard_screen.dart';
import '../../features/recruiter/presentation/my_job_posts_screen.dart';
import '../../features/recruiter/presentation/applications_screen.dart';
import '../../features/recruiter/presentation/application_detail_screen.dart';
import '../../features/recruiter/presentation/matching_preview_screen.dart';
import '../../features/recruiter/presentation/recruiter_subscription_screen.dart';
import '../../features/recruiter/presentation/widgets/recruiter_guard.dart';
import '../../features/recruiter/application/recruiter_providers.dart';
import '../../features/jobs/data/models/offer.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/freelancers/presentation/freelancers_search_screen.dart';
import '../../features/freelancers/presentation/freelancer_profile_screen.dart';
import '../../features/freelancers/presentation/my_missions_screen.dart';
import '../../features/freelancers/presentation/mission_detail_screen.dart';
import '../../features/freelancers/presentation/become_provider_screen.dart';
import '../../features/freelancers/presentation/provider_dashboard_screen.dart';
import '../../features/freelancers/presentation/new_realisation_screen.dart';
import '../../features/freelancers/presentation/wallet_screen.dart';
import '../../features/freelancers/presentation/subscription_screen.dart';
import '../../features/freelancers/presentation/kyc_screen.dart';
import '../../features/market/presentation/product_detail_screen.dart';
import '../../features/market/presentation/cart_screen.dart';
import '../../features/market/presentation/checkout_screen.dart';
import '../../features/market/presentation/my_orders_screen.dart';
import '../../features/market/presentation/favorites_screen.dart';
import '../../features/market/presentation/become_seller_screen.dart';
import '../../features/market/presentation/seller_dashboard_screen.dart';
import '../../features/market/presentation/product_form_screen.dart';
import '../../features/market/presentation/widgets/vendor_guard.dart';
import '../../features/market/presentation/vendor_pricing_screen.dart';
import '../../features/market/application/vendor_providers.dart';
import '../../features/market/data/models/product.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.listen(onboardingControllerProvider, (_, __) => refresh.value++);
  ref.listen(splashCompletedProvider, (_, __) => refresh.value++);
  ref.listen(splashAnimationDoneProvider, (_, __) => refresh.value++);
  ref.listen(onboardingDoneProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  // Verrou : une fois le splash passe, on n'y revient plus jamais
  // (evite le flash de l'ecran de demarrage apres connexion).
  bool splashLatched = false;

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final splashDone = splashLatched ||
          ref.read(splashCompletedProvider) ||
          ref.read(splashAnimationDoneProvider);
      if (splashDone) splashLatched = true;
      final auth = ref.read(authControllerProvider);
      final onboardingSeen = ref.read(onboardingControllerProvider) ||
          ref.read(onboardingDoneProvider) ||
          (ref.read(sharedPrefsProvider).getBool(kOnboardingSeenKey) ?? false);
      final loc = state.matchedLocation;

      // Splash uniquement au demarrage a froid (tant qu'il n'est pas termine).
      if (!splashDone) {
        return loc == '/splash' ? null : '/splash';
      }
      // Connexion / deconnexion en cours : ne pas rebondir vers le splash,
      // on reste sur l'ecran courant (login affiche son propre spinner).
      if (auth.isLoading) {
        return null;
      }
      if (!onboardingSeen) {
        return loc == '/onboarding' ? null : '/onboarding';
      }
      final loggedIn = auth.valueOrNull != null;
      // Routes accessibles hors session pour couvrir tout le flow auth.
      const authRoutes = {
        '/login',
        '/register',
        '/mot-de-passe-oublie',
        '/reset-password',
        '/verifier-email',
      };
      if (!loggedIn) {
        return authRoutes.contains(loc) ? null : '/login';
      }
      if (loc == '/splash' || loc == '/onboarding' || loc == '/login') {
        return '/accueil';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/mot-de-passe-oublie',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordScreen(
          initialToken: state.uri.queryParameters['token'],
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/verifier-email',
        builder: (_, state) => VerifyEmailScreen(
          email: state.uri.queryParameters['email'],
        ),
      ),

      // Ecrans plein ecran (par-dessus la barre du bas)
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/conversation/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ChatScreen(
          conversationId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          title: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: '/recruteur/inscription',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const RecruiterRegisterScreen(),
      ),

      // Recruteur : dashboard + sidebar
      // Toutes ces routes sont protegees par RecruiterGuard qui redirige
      // vers /recruteur/inscription si l'utilisateur n'a pas le role.
      GoRoute(
        path: '/recruteur/dashboard',
        parentNavigatorKey: _rootKey,
        builder: (_, __) =>
            const RecruiterGuard(child: RecruiterDashboardScreen()),
      ),
      GoRoute(
        path: '/recruteur/offres',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const RecruiterGuard(child: MyJobPostsScreen()),
      ),
      GoRoute(
        path: '/recruteur/candidatures',
        parentNavigatorKey: _rootKey,
        builder: (_, state) {
          final offre = state.uri.queryParameters['offre'];
          final id = offre != null ? int.tryParse(offre) : null;
          return RecruiterGuard(
              child: ApplicationsScreen(filterOfferId: id));
        },
      ),
      GoRoute(
        path: '/recruteur/candidature/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => RecruiterGuard(
          child: ApplicationDetailScreen(
            applicationId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/recruteur/abonnement',
        parentNavigatorKey: _rootKey,
        builder: (_, __) =>
            const RecruiterGuard(child: RecruiterSubscriptionScreen()),
      ),
      GoRoute(
        path: '/recruteur/analytics',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const RecruiterGuard(
            child: ComingSoonScreen(label: 'Statistiques')),
      ),
      GoRoute(
        path: '/recruteur/parametres',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const RecruiterGuard(
            child: ComingSoonScreen(label: 'Parametres')),
      ),
      GoRoute(
        path: '/recruteur/offres/:id/matching',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => RecruiterGuard(
          child: MatchingPreviewScreen(
            offreId: int.parse(state.pathParameters['id']!),
            offreTitre: state.uri.queryParameters['titre'],
          ),
        ),
      ),
      GoRoute(
        path: '/offre/nouvelle',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const RecruiterGuard(child: CreateOfferScreen()),
      ),
      GoRoute(
        path: '/offre/:id/editer',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => RecruiterGuard(
          child: Consumer(
            builder: (ctx, ref, _) {
              final id = int.parse(state.pathParameters['id']!);
              final async = ref.watch(myOffersProvider);
              return async.when(
                loading: () => const Scaffold(
                    body: Center(child: CircularProgressIndicator())),
                error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
                data: (offers) {
                  final Offer? found = offers
                      .cast<Offer?>()
                      .firstWhere((o) => o?.id == id, orElse: () => null);
                  if (found == null) {
                    return const Scaffold(
                        body: Center(child: Text('Offre introuvable')));
                  }
                  return CreateOfferScreen(initialOffer: found);
                },
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: '/offre/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            OfferDetailScreen(offreId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/candidature/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            CandidatureDetailScreen(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/profil/editer',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const EditParticulierScreen(),
      ),
      GoRoute(
        path: '/coming-soon',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ComingSoonScreen(
            label: (state.extra as String?) ?? 'Cette fonctionnalite'),
      ),

      // Freelancers / Prestations
      GoRoute(
        path: '/prestataires',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const FreelancersSearchScreen(),
      ),
      GoRoute(
        path: '/prestataire/dashboard',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const ProviderDashboardScreen(),
      ),
      GoRoute(
        path: '/prestataire/wallet',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const WalletScreen(),
      ),
      GoRoute(
        path: '/prestataire/abonnement',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/candidat/abonnement',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CandidateSubscriptionScreen(),
      ),
      GoRoute(
        path: '/candidat/matching',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CandidateMatchingScreen(),
      ),
      GoRoute(
        path: '/prestataire/verification',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const KycScreen(),
      ),
      GoRoute(
        path: '/prestataire/realisation/nouvelle',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const NewRealisationScreen(),
      ),
      GoRoute(
        path: '/prestataire/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            FreelancerProfileScreen(freelancerId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/devenir-prestataire',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const BecomeProviderScreen(),
      ),
      GoRoute(
        path: '/mes-missions',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const MyMissionsScreen(),
      ),
      GoRoute(
        path: '/mission/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            MissionDetailScreen(missionId: int.parse(state.pathParameters['id']!)),
      ),

      // BantuMarket — acheteur
      GoRoute(
        path: '/produit/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ProductDetailScreen(
            productId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/panier',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CartScreen(),
      ),
      GoRoute(
        path: '/commander',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/mes-commandes',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: '/mes-favoris',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const FavoritesScreen(),
      ),

      // BantuMarket — vendeur
      GoRoute(
        path: '/devenir-vendeur',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const BecomeSellerScreen(),
      ),
      GoRoute(
        path: '/vendeur/dashboard',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const VendorGuard(child: SellerDashboardScreen()),
      ),
      GoRoute(
        path: '/vendeur/tarifs',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const VendorPricingScreen(),
      ),
      GoRoute(
        path: '/vendeur/produit/nouveau',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const VendorGuard(child: ProductFormScreen()),
      ),
      GoRoute(
        path: '/vendeur/produit/:id/editer',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => VendorGuard(
          child: Consumer(
            builder: (ctx, ref, _) {
              final id = int.parse(state.pathParameters['id']!);
              final async = ref.watch(myVendorProductsProvider);
              return async.when(
                loading: () => const Scaffold(
                    body: Center(child: CircularProgressIndicator())),
                error: (e, _) =>
                    Scaffold(body: Center(child: Text('$e'))),
                data: (products) {
                  final Product? found = products
                      .cast<Product?>()
                      .firstWhere((p) => p?.id == id, orElse: () => null);
                  if (found == null) {
                    return const Scaffold(
                        body: Center(child: Text('Produit introuvable')));
                  }
                  return ProductFormScreen(initialProduct: found);
                },
              );
            },
          ),
        ),
      ),

      // Navigation principale a 5 onglets
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/accueil', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/emploi', builder: (_, __) => const JobsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/boutique', builder: (_, __) => const BoutiqueScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/messages', builder: (_, __) => const MessagesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profil', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
