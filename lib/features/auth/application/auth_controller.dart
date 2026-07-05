import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../data/auth_remote_data_source.dart';
import '../data/auth_repository.dart';
import '../data/models/user_model.dart';
import '../data/social_auth_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepository(AuthRemoteDataSource(dio), tokenStorage);
});

final socialAuthServiceProvider =
    Provider<SocialAuthService>((ref) => SocialAuthService());

class AuthController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    return repo.tryRestoreSession();
  }

  Future<void> login({required String email, required String password}) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repo.login(email: email, password: password),
    );
  }

  Future<void> loginWithGoogle(String idToken) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.loginWithGoogle(idToken));
  }

  Future<void> loginWithLinkedInCode(String code) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.loginWithLinkedInCode(code));
  }

  /// Recharge /user (apres completion de profil par ex.).
  Future<void> refreshUser() async {
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.tryRestoreSession();
    state = AsyncValue.data(user);
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController.new);

class RegisterController extends AutoDisposeAsyncNotifier<String?> {
  @override
  FutureOr<String?> build() => null;

  Future<void> submit(Map<String, dynamic> data) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.register(data));
  }
}

final registerControllerProvider =
    AutoDisposeAsyncNotifierProvider<RegisterController, String?>(
        RegisterController.new);

/// Envoie l'email "mot de passe oublie" via /forgot-password.
/// L'etat contient le message serveur en cas de succes.
class ForgotPasswordController extends AutoDisposeAsyncNotifier<String?> {
  @override
  FutureOr<String?> build() => null;

  Future<void> submit(String email) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.forgotPassword(email));
  }
}

final forgotPasswordControllerProvider =
    AutoDisposeAsyncNotifierProvider<ForgotPasswordController, String?>(
        ForgotPasswordController.new);

/// Reinitialise le mot de passe via /reset-password (token depuis l'email).
class ResetPasswordController extends AutoDisposeAsyncNotifier<String?> {
  @override
  FutureOr<String?> build() => null;

  Future<void> submit({
    required String email,
    required String token,
    required String password,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => repo.resetPassword(email: email, token: token, password: password));
  }
}

final resetPasswordControllerProvider =
    AutoDisposeAsyncNotifierProvider<ResetPasswordController, String?>(
        ResetPasswordController.new);

/// Renvoie l'email de verification via /email/verification-notification.
class ResendVerificationController extends AutoDisposeAsyncNotifier<String?> {
  @override
  FutureOr<String?> build() => null;

  Future<void> submit(String email) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.resendVerificationEmail(email));
  }
}

final resendVerificationControllerProvider = AutoDisposeAsyncNotifierProvider<
    ResendVerificationController, String?>(ResendVerificationController.new);
