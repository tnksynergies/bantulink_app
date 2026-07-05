import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/jobs_remote_data_source.dart';
import '../data/models/offer.dart';
import '../data/models/candidature.dart';
import '../../messaging/application/messaging_providers.dart';

int? _recruiterUserId(Map<String, dynamic> raw) {
  final emp = raw['employeur'] ?? raw['professionnel'] ?? raw['entreprise'];
  if (emp is Map) {
    final uid = emp['user_id'];
    final v = uid is int ? uid : int.tryParse('${uid}');
    if (v != null) return v;
    final u = emp['user'];
    if (u is Map) {
      final id = u['id'];
      return id is int ? id : int.tryParse('${id}');
    }
  }
  final top = raw['user_id'];
  return top is int ? top : int.tryParse('${top}');
}

final jobsDataSourceProvider = Provider<JobsRemoteDataSource>(
    (ref) => JobsRemoteDataSource(ref.watch(dioProvider)));

final offersProvider = FutureProvider.autoDispose<List<Offer>>((ref) async {
  return ref.watch(jobsDataSourceProvider).getOffers();
});

final matchingScoresProvider =
    FutureProvider.autoDispose<Map<int, double>>((ref) async {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return {};
  return ref.watch(jobsDataSourceProvider).getMatchingScores(user.id);
});

final offerDetailProvider =
    FutureProvider.autoDispose.family<Offer, int>((ref, id) async {
  return ref.watch(jobsDataSourceProvider).getOffer(id);
});

final myCandidaturesProvider =
    FutureProvider.autoDispose<List<Candidature>>((ref) async {
  return ref.watch(jobsDataSourceProvider).myCandidatures();
});

final candidatureDetailProvider =
    FutureProvider.autoDispose.family<Candidature, int>((ref, id) async {
  return ref.watch(jobsDataSourceProvider).getCandidature(id);
});

class ApplyController extends AutoDisposeFamilyAsyncNotifier<bool, int> {
  @override
  Future<bool> build(int arg) async => false;

  Future<void> submit({String? lettre}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(jobsDataSourceProvider)
          .apply(offreId: arg, lettreMotivation: lettre);
      // Demarre automatiquement une conversation avec le recruteur (best-effort).
      try {
        final offer = ref.read(offerDetailProvider(arg)).valueOrNull;
        final rid = offer == null ? null : _recruiterUserId(offer.raw);
        final myId = ref.read(authControllerProvider).valueOrNull?.id;
        if (rid != null && rid != myId) {
          await ref.read(messagesDataSourceProvider).createConversation(rid);
          ref.invalidate(conversationsProvider);
        }
      } catch (_) {}
      ref.invalidate(offersProvider);
      ref.invalidate(myCandidaturesProvider);
      ref.invalidate(offerDetailProvider(arg));
      return true;
    });
  }
}

final applyControllerProvider =
    AsyncNotifierProvider.autoDispose.family<ApplyController, bool, int>(
        ApplyController.new);
