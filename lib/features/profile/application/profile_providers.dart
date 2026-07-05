import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/profile_remote_data_source.dart';

final profileDataSourceProvider = Provider<ProfileRemoteDataSource>(
    (ref) => ProfileRemoteDataSource(ref.watch(dioProvider)));

class ProfileSaveController extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> save({
    required Map<String, dynamic> fields,
    required bool isUpdate,
    ProfileFile? image,
    ProfileFile? cv,
    ProfileFile? lettre,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileDataSourceProvider).saveParticulier(
            fields: fields,
            isUpdate: isUpdate,
            image: image,
            cv: cv,
            lettre: lettre,
          );
      await ref.read(authControllerProvider.notifier).refreshUser();
      return true;
    });
  }
}

final profileSaveControllerProvider =
    AutoDisposeAsyncNotifierProvider<ProfileSaveController, bool>(
        ProfileSaveController.new);
