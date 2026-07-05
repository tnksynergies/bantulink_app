/// Configuration du serveur Reverb (protocole Pusher).
class ReverbConfig {
  static const String appKey = 'b43hzxsqfpaoywpaglr4';
  static const String host = 'app.bantulink.tech';
  static const int port = 8002;
  // REVERB_SCHEME=http -> websocket non securise (ws). Passe a true si tu sers en wss.
  static const bool useTLS = false;

  /// Endpoint d'autorisation des canaux prives (le Bearer est ajoute par Dio).
  static const String authPath = '/broadcasting/auth';
}
