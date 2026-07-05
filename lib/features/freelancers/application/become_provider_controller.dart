import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_controller.dart';
import '../data/models/freelancer.dart';
import '../data/upload_file.dart';
import 'freelancers_providers.dart';

/// Controller pour l'inscription en tant que prestataire.
/// Cree/maj le profil freelancer puis attribue le role id=11.
class BecomeProviderController extends AutoDisposeAsyncNotifier<Freelancer?> {
  @override
  Future<Freelancer?> build() async => null;

  Future<Freelancer> submit({
    required String nomComplet,
    required String titrePro,
    required String emailPro,
    String? description,
    String? telephone,
    String? adresse,
    String? ville,
    String? pays,
    num? montantMinimum,
    List<String>? competences,
    UploadFile? photoProfil,
    UploadFile? photoCouverture,
  }) async {
    state = const AsyncValue.loading();
    final ds = ref.read(freelancersDataSourceProvider);
    final freelancer = await ds.storeOrUpdateProfile(
      nomComplet: nomComplet,
      titrePro: titrePro,
      emailPro: emailPro,
      description: description,
      telephone: telephone,
      adresse: adresse,
      ville: ville,
      pays: pays,
      montantMinimum: montantMinimum,
      competences: competences,
      photoProfil: photoProfil,
      photoCouverture: photoCouverture,
    );

    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    if (userId != null) {
      // Best-effort : si le role existe deja, le back peut retourner un message
      // d'info ; on ignore l'erreur pour ne pas bloquer le flux.
      try {
        await ds.assignFreelancerRole(userId);
      } catch (_) {}
    }

    // Rafraichir l'auth pour recharger les roles cote client.
    try {
      await ref.read(authControllerProvider.notifier).refreshUser();
    } catch (_) {}

    state = AsyncValue.data(freelancer);
    ref.invalidate(myFreelancerProfileProvider);
    ref.invalidate(freelancersListProvider);
    return freelancer;
  }
}

final becomeProviderControllerProvider =
    AutoDisposeAsyncNotifierProvider<BecomeProviderController, Freelancer?>(
        BecomeProviderController.new);

/// Retourne true si l'utilisateur connecte est deja Freelancer (via /user/:id/roles).
final isCurrentUserFreelancerProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return false;
  // Verification rapide via le champ raw d'abord.
  if (user.raw['freelancer'] != null) return true;
  for (final r in user.roles) {
    final n = r.toLowerCase();
    if (n == 'freelancer' || n == 'prestataire' || n == 'provider') return true;
  }
  // Sinon appel API roles.
  return ref.watch(freelancersDataSourceProvider).hasFreelancerRole(user.id);
});
