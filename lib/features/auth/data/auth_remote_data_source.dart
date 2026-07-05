import 'package:dio/dio.dart';
import '../../../core/errors/api_exception.dart';
import 'models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<({User user, String token})> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post('/login', data: {
        'email': email,
        'password': password,
      });
      final data = res.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      return (user: user, token: token);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /register -> { message: "...verifie ton email..." } (pas de token).
  Future<String> register(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/register', data: data);
      final body = res.data;
      if (body is Map && body['message'] is String) {
        return body['message'] as String;
      }
      return 'Inscription reussie. Verifie ton email pour activer ton compte.';
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<User> fetchCurrentUser() async {
    try {
      final res = await _dio.get('/user');
      final body = res.data;
      final map = (body is Map && body['data'] is Map)
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;
      return User.fromJson(map);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } on DioException catch (_) {}
  }

  /// POST /google-login avec JWT_ID_Token -> { user, token }
  Future<({User user, String token})> googleLogin(String idToken) async {
    try {
      final res = await _dio.post('/google-login', data: {
        'JWT_ID_Token': idToken,
      });
      final data = res.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final userMap = data['user'] is Map
          ? Map<String, dynamic>.from(data['user'] as Map)
          : (data['user']?['data'] as Map<String, dynamic>? ?? {});
      return (user: User.fromJson(userMap), token: token);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Recupere l'URL d'autorisation LinkedIn a ouvrir (WebView / onglet).
  ///
  /// Contrat deploye : GET /linkedin-auth-url -> { url } (ou string).
  /// Fallback ancien contrat : GET /linkedin-login redirige lui-meme, donc
  /// on retourne directement cette URL comme point d'entree.
  Future<String> linkedInAuthUrl() async {
    try {
      final res = await _dio.get('/linkedin-auth-url');
      final data = res.data;
      String? url;
      if (data is String) url = data;
      if (data is Map) {
        url = (data['url'] ??
                data['auth_url'] ??
                data['authUrl'] ??
                (data['data'] is Map ? data['data']['url'] : data['data']))
            ?.toString();
      }
      if (url != null && url.startsWith('http')) return url;
      throw ApiException('URL LinkedIn introuvable dans la reponse.');
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404 || code == 405) {
        return '${_dio.options.baseUrl}/linkedin-login';
      }
      throw ApiException.fromDio(e);
    }
  }

  /// Echange le `code` OAuth LinkedIn contre { user, token }.
  ///
  /// Contrat deploye : POST /linkedin-callback (code en query + body).
  /// Fallback ancien contrat : GET /linkedin-login-callback?code=...
  Future<({User user, String token})> linkedinExchangeCode(String code) async {
    Response<dynamic> res;
    try {
      res = await _dio.post(
        '/linkedin-callback',
        queryParameters: {'code': code},
        data: {'code': code},
      );
    } on DioException catch (e) {
      final sc = e.response?.statusCode;
      if (sc == 404 || sc == 405) {
        try {
          res = await _dio.get(
            '/linkedin-login-callback',
            queryParameters: {'code': code},
          );
        } on DioException catch (e2) {
          throw ApiException.fromDio(e2);
        }
      } else {
        throw ApiException.fromDio(e);
      }
    }
    final data = res.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final userMap = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : (data['user']?['data'] as Map<String, dynamic>? ?? {});
    return (user: User.fromJson(userMap), token: token);
  }

  /// POST /forgot-password {email} -> { message }
  /// Le backend envoie un email avec un lien de reset (token embarque dans l'URL).
  Future<String> forgotPassword(String email) async {
    try {
      final res = await _dio.post('/forgot-password', data: {'email': email});
      final body = res.data;
      if (body is Map && body['message'] is String) {
        return body['message'] as String;
      }
      return 'Email envoye. Verifie ta boite de reception.';
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /reset-password {email, token, password} -> { message }
  Future<String> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    try {
      final res = await _dio.post('/reset-password', data: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': password,
      });
      final body = res.data;
      if (body is Map && body['message'] is String) {
        return body['message'] as String;
      }
      return 'Mot de passe reinitialise avec succes.';
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /email/verification-notification {email} -> { message }
  /// Renvoie un email de verification a l'utilisateur (throttled a 6/min).
  Future<String> resendVerificationEmail(String email) async {
    try {
      final res = await _dio.post(
        '/email/verification-notification',
        data: {'email': email},
      );
      final body = res.data;
      if (body is Map && body['message'] is String) {
        return body['message'] as String;
      }
      return 'Email de verification renvoye.';
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
