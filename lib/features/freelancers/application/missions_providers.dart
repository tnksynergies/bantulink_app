import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../data/missions_remote_data_source.dart';
import '../data/models/mission.dart';
import '../data/upload_file.dart';
import 'freelancers_providers.dart';

final missionsDataSourceProvider = Provider<MissionsRemoteDataSource>(
    (ref) => MissionsRemoteDataSource(ref.watch(dioProvider)));

/// Missions du client connecte.
final myMissionsProvider = FutureProvider.autoDispose<List<Mission>>((ref) async {
  return ref.watch(missionsDataSourceProvider).myMissions();
});

/// Missions recues par le freelancer connecte.
final freelancerMissionsProvider =
    FutureProvider.autoDispose<List<Mission>>((ref) async {
  return ref.watch(missionsDataSourceProvider).freelancerMissions();
});

final missionDetailProvider =
    FutureProvider.autoDispose.family<Mission, int>((ref, id) async {
  return ref.watch(missionsDataSourceProvider).get(id);
});

/// Cree une mission puis invalide les providers derives.
class CreateMissionController extends AutoDisposeAsyncNotifier<Mission?> {
  @override
  Future<Mission?> build() async => null;

  Future<Mission> submit({
    required int freelancerId,
    required String titre,
    required String description,
    required String dateDebut,
    String? dateFin,
    num? cout,
    List<UploadFile> images = const [],
    List<UploadFile> documents = const [],
    List<UploadFile> videos = const [],
  }) async {
    state = const AsyncValue.loading();
    final mission = await ref.read(missionsDataSourceProvider).create(
          freelancerId: freelancerId,
          titre: titre,
          description: description,
          dateDebut: dateDebut,
          dateFin: dateFin,
          cout: cout,
          images: images,
          documents: documents,
          videos: videos,
        );
    state = AsyncValue.data(mission);
    ref.invalidate(myMissionsProvider);
    ref.invalidate(freelancerMissionsProvider);
    return mission;
  }
}

final createMissionControllerProvider =
    AutoDisposeAsyncNotifierProvider<CreateMissionController, Mission?>(
        CreateMissionController.new);

/// Change le statut d'une mission (client ou freelancer selon transitions).
class UpdateMissionStatusController
    extends AutoDisposeFamilyAsyncNotifier<Mission?, int> {
  @override
  Future<Mission?> build(int arg) async => null;

  Future<Mission> submit(MissionStatus target, {String? paymentMode}) async {
    state = const AsyncValue.loading();
    final mission = await ref
        .read(missionsDataSourceProvider)
        .updateStatus(arg, status: target, paymentMode: paymentMode);
    state = AsyncValue.data(mission);
    ref.invalidate(myMissionsProvider);
    ref.invalidate(freelancerMissionsProvider);
    ref.invalidate(missionDetailProvider(arg));
    return mission;
  }
}

final updateMissionStatusControllerProvider = AutoDisposeAsyncNotifierProvider
    .family<UpdateMissionStatusController, Mission?, int>(
        UpdateMissionStatusController.new);

/// Initie le paiement mobile money + poll toutes les 5s jusqu'a success/failed.
class PayMissionController
    extends AutoDisposeFamilyAsyncNotifier<PayMissionState, int> {
  Timer? _timer;

  @override
  Future<PayMissionState> build(int arg) async {
    ref.onDispose(() => _timer?.cancel());
    return const PayMissionState.idle();
  }

  Future<void> initiate({required String phone, required String provider}) async {
    state = const AsyncValue.data(PayMissionState.initiating());
    try {
      final ref0 = await ref
          .read(missionsDataSourceProvider)
          .initiatePayment(arg, phone: phone, provider: provider);
      if (ref0 == null) {
        state = AsyncValue.error('Reference paiement introuvable', StackTrace.current);
        return;
      }
      state = AsyncValue.data(PayMissionState.polling(ref0));
      _startPolling(ref0);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _startPolling(String reference) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final status = await ref.read(missionsDataSourceProvider).paymentStatus(reference);
      if (status == null) return;
      if (status == 'success' || status == 'succeeded' || status == 'active' || status == 'completed') {
        _timer?.cancel();
        state = const AsyncValue.data(PayMissionState.success());
        ref.invalidate(myMissionsProvider);
        ref.invalidate(missionDetailProvider(arg));
      } else if (status == 'failed' || status == 'error') {
        _timer?.cancel();
        state = const AsyncValue.data(PayMissionState.failed());
      }
    });
  }
}

class PayMissionState {
  const PayMissionState._(this.stage, [this.reference]);
  const PayMissionState.idle() : this._(PayStage.idle);
  const PayMissionState.initiating() : this._(PayStage.initiating);
  const PayMissionState.polling(String ref) : this._(PayStage.polling, ref);
  const PayMissionState.success() : this._(PayStage.success);
  const PayMissionState.failed() : this._(PayStage.failed);

  final PayStage stage;
  final String? reference;
}

enum PayStage { idle, initiating, polling, success, failed }

final payMissionControllerProvider = AutoDisposeAsyncNotifierProvider.family<
    PayMissionController, PayMissionState, int>(PayMissionController.new);

/// Note (avis) apres mission terminee.
class LeaveNoteController extends AutoDisposeFamilyAsyncNotifier<bool, int> {
  @override
  Future<bool> build(int arg) async => false;

  Future<void> submit({required int score, required String description}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(missionsDataSourceProvider)
          .leaveNote(arg, score: score, description: description);
      ref.invalidate(myMissionsProvider);
      ref.invalidate(missionDetailProvider(arg));
      // Rafraichir aussi la fiche du freelancer si visible (best-effort).
      final freelancerId = ref.read(missionDetailProvider(arg)).valueOrNull?.freelancerId;
      if (freelancerId != null) {
        ref.invalidate(freelancerNotesProvider(freelancerId));
        ref.invalidate(freelancerDetailProvider(freelancerId));
      }
      return true;
    });
  }
}

final leaveNoteControllerProvider =
    AutoDisposeAsyncNotifierProvider.family<LeaveNoteController, bool, int>(
        LeaveNoteController.new);
