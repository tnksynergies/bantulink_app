class AppConfig {
  AppConfig._();
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://app.bantulink.tech/api',
  );
  // Base des fichiers (logos, CV...). Si vide, on utilise l'URL telle quelle.
  static const String storageBaseUrl = String.fromEnvironment(
    'STORAGE_BASE_URL',
    defaultValue: '',
  );
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Client ID Google (type Web) pour l'authentification OAuth.
  /// - Web    : passe en `clientId` a GoogleSignIn.
  /// - Mobile : passe en `serverClientId` (OBLIGATOIRE pour obtenir un
  ///   idToken sur Android/iOS -- sans lui, authentication.idToken == null).
  /// Surchargable via --dart-define=GOOGLE_CLIENT_ID_WEB=...
  /// (un client ID OAuth n'est pas un secret : il est deja visible dans
  /// web/index.html).
  static const String googleClientIdWeb = String.fromEnvironment(
    'GOOGLE_CLIENT_ID_WEB',
    defaultValue:
        '284173138547-u6mu6e82rig962d74icdas8qp3uj8m64.apps.googleusercontent.com',
  );
}
