import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../jobs/application/jobs_providers.dart';
import '../../jobs/data/models/candidature.dart';
import '../../jobs/data/models/offer.dart';
import '../data/ref_data_source.dart';
import '../data/recruiter_remote_data_source.dart';

final refDataSourceProvider =
    Provider<RefDataSource>((ref) => RefDataSource(ref.watch(dioProvider)));

final recruiterDataSourceProvider = Provider<RecruiterRemoteDataSource>(
    (ref) => RecruiterRemoteDataSource(ref.watch(dioProvider)));

final categoriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => ref.watch(refDataSourceProvider).categories());

final experienceLevelsProvider = FutureProvider.autoDispose<List<String>>(
    (ref) => ref.watch(refDataSourceProvider).experienceLevels());

final contractTypesProvider = FutureProvider.autoDispose<List<String>>(
    (ref) => ref.watch(refDataSourceProvider).contractTypes());

final skillsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
    (ref) => ref.watch(refDataSourceProvider).skills());

class CreateOfferController extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> submit(Map<String, dynamic> payload) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(recruiterDataSourceProvider).postOffer(payload);
      ref.invalidate(offersProvider);
      return true;
    });
  }
}

final createOfferControllerProvider =
    AutoDisposeAsyncNotifierProvider<CreateOfferController, bool>(
        CreateOfferController.new);

class ProfessionnelRegisterController extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> register({
    required Map<String, dynamic> fields,
    UploadBytes? logo,
    UploadBytes? cover,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(recruiterDataSourceProvider)
          .createProfessionnel(fields: fields, logo: logo, cover: cover);
      await ref.read(authControllerProvider.notifier).refreshUser();
      return true;
    });
  }
}

final professionnelRegisterControllerProvider =
    AutoDisposeAsyncNotifierProvider<ProfessionnelRegisterController, bool>(
        ProfessionnelRegisterController.new);

/// Liste des offres du recruteur connecte.
final myOffersProvider = FutureProvider.autoDispose<List<Offer>>((ref) async {
  return ref.watch(recruiterDataSourceProvider).myOffers();
});

/// Toutes les candidatures pour toutes les offres du recruteur.
final applicationsProvider =
    FutureProvider.autoDispose<List<Candidature>>((ref) async {
  return ref.watch(recruiterDataSourceProvider).listApplications();
});

/// Candidatures d'une offre precise.
final applicationsByOfferProvider =
    FutureProvider.autoDispose.family<List<Candidature>, int>((ref, offerId) async {
  return ref.watch(recruiterDataSourceProvider).applicationsByOffer(offerId);
});

/// Detail d'une candidature.
final applicationDetailProvider =
    FutureProvider.autoDispose.family<Candidature, int>((ref, id) async {
  return ref.watch(recruiterDataSourceProvider).getApplication(id);
});

/// Supprime une offre.
class DeleteOfferController extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> submit(int offerId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(recruiterDataSourceProvider).deleteOffer(offerId);
      ref.invalidate(myOffersProvider);
      ref.invalidate(offersProvider);
      return true;
    });
  }
}

final deleteOfferControllerProvider =
    AutoDisposeAsyncNotifierProvider<DeleteOfferController, bool>(
        DeleteOfferController.new);

/// Met a jour une offre existante.
class UpdateOfferController extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> submit(int offerId, Map<String, dynamic> payload) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(recruiterDataSourceProvider).updateOffer(offerId, payload);
      ref.invalidate(myOffersProvider);
      ref.invalidate(offersProvider);
      return true;
    });
  }
}

final updateOfferControllerProvider =
    AutoDisposeAsyncNotifierProvider<UpdateOfferController, bool>(
        UpdateOfferController.new);

/// Change le statut d'une candidature (avec extras si invitation entretien).
class UpdateApplicationStatusController
    extends AutoDisposeFamilyAsyncNotifier<Candidature?, int> {
  @override
  Future<Candidature?> build(int arg) async => null;

  Future<Candidature> submit({
    required String statut,
    String? dateEntretien,
    String? modeEntretien,
    String? lieuEntretien,
    String? lienVisio,
  }) async {
    state = const AsyncValue.loading();
    final c = await ref
        .read(recruiterDataSourceProvider)
        .updateApplicationStatus(
          arg,
          statut: statut,
          dateEntretien: dateEntretien,
          modeEntretien: modeEntretien,
          lieuEntretien: lieuEntretien,
          lienVisio: lienVisio,
        );
    state = AsyncValue.data(c);
    ref.invalidate(applicationsProvider);
    ref.invalidate(applicationDetailProvider(arg));
    return c;
  }
}

final updateApplicationStatusControllerProvider =
    AutoDisposeAsyncNotifierProvider.family<UpdateApplicationStatusController,
        Candidature?, int>(UpdateApplicationStatusController.new);

/// Envoie une invitation d'entretien.
class SendInvitationController
    extends AutoDisposeFamilyAsyncNotifier<bool, int> {
  @override
  Future<bool> build(int arg) async => false;

  Future<void> submit({
    required String dateHeureEntretien,
    required String typeEntretien,
    String? lieu,
    String? lienVisio,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(recruiterDataSourceProvider).sendInvitation(
            arg,
            dateHeureEntretien: dateHeureEntretien,
            typeEntretien: typeEntretien,
            lieu: lieu,
            lienVisio: lienVisio,
          );
      ref.invalidate(applicationDetailProvider(arg));
      return true;
    });
  }
}

final sendInvitationControllerProvider =
    AutoDisposeAsyncNotifierProvider.family<SendInvitationController, bool, int>(
        SendInvitationController.new);

/// Retourne true si l'utilisateur connecte est recruteur (role
/// "recruteur"/"professionnel"/etc.). Source d'autorite : /user/:id/roles.
/// Verifie d'abord le cache local, puis appelle l'API en repli.
final isCurrentUserRecruiterProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return false;

  // 1) Verification rapide sur les roles deja charges via /user
  final localRoles = user.roles.map((r) => r.toLowerCase().trim()).toList();
  if (RecruiterRemoteDataSource.isRecruiterRole(localRoles)) return true;

  // 2) Appel API /user/:id/roles pour la source d'autorite
  try {
    final roles = await ref
        .watch(recruiterDataSourceProvider)
        .getUserRoles(user.id);
    return RecruiterRemoteDataSource.isRecruiterRole(roles);
  } catch (_) {
    // 3) Repli tres prudent : uniquement si l'API echoue, on regarde le cache
    return user.hasRecruteurProfile == true;
  }
});
