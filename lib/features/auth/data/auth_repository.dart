import '../../../core/storage/token_storage.dart';
import 'auth_remote_data_source.dart';
import 'models/user_model.dart';

class AuthRepository {
  AuthRepository(this._remote, this._tokenStorage);
  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  Future<User> login({required String email, required String password}) async {
    final result = await _remote.login(email: email, password: password);
    await _tokenStorage.saveToken(result.token);
    return result.user;
  }

  Future<User> loginWithGoogle(String idToken) async {
    final result = await _remote.googleLogin(idToken);
    await _tokenStorage.saveToken(result.token);
    return result.user;
  }

  Future<User> loginWithLinkedInCode(String code) async {
    final result = await _remote.linkedinExchangeCode(code);
    await _tokenStorage.saveToken(result.token);
    return result.user;
  }

  /// URL d'autorisation LinkedIn a ouvrir (WebView mobile / onglet web).
  Future<String> linkedInAuthUrl() => _remote.linkedInAuthUrl();

  Future<String> register(Map<String, dynamic> data) => _remote.register(data);

  Future<String> forgotPassword(String email) => _remote.forgotPassword(email);

  Future<String> resetPassword({
    required String email,
    required String token,
    required String password,
  }) =>
      _remote.resetPassword(email: email, token: token, password: password);

  Future<String> resendVerificationEmail(String email) =>
      _remote.resendVerificationEmail(email);

  Future<User?> tryRestoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      return await _remote.fetchCurrentUser();
    } catch (_) {
      await _tokenStorage.clear();
      return null;
    }
  }

  Future<void> logout() async {
    await _remote.logout();
    await _tokenStorage.clear();
  }
}
