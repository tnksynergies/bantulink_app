import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage(this._storage);
  final FlutterSecureStorage _storage;
  static const _kToken = 'auth_token';

  Future<void> saveToken(String token) =>
      _storage.write(key: _kToken, value: token);
  Future<String?> readToken() => _storage.read(key: _kToken);
  Future<void> clear() => _storage.delete(key: _kToken);
}
