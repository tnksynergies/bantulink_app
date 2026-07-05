import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/env/app_config.dart';
import 'linkedin_launcher_stub.dart'
    if (dart.library.html) 'linkedin_launcher_web.dart';

/// Erreur specifique remontee quand l'utilisateur ferme le popup Google
/// (ce n'est PAS une vraie erreur, on doit l'ignorer silencieusement).
class SocialAuthCancelled implements Exception {
  const SocialAuthCancelled();
  @override
  String toString() => 'Sign-in cancelled by user';
}

/// Encapsule les flux OAuth mobiles/web pour Google et LinkedIn.
class SocialAuthService {
  SocialAuthService();

  static const _scopes = ['email', 'profile', 'openid'];

  GoogleSignIn _buildGoogle() {
    // - Web    : `clientId` requis (client OAuth type Web).
    // - Mobile : `serverClientId` requis pour obtenir un idToken JWT
    //   verifiable cote backend. C'est le MEME client ID type Web.
    //   Sans lui, authentication.idToken est null sur Android/iOS.
    final webClientId = AppConfig.googleClientIdWeb;
    return GoogleSignIn(
      scopes: _scopes,
      clientId: kIsWeb ? webClientId : null,
      serverClientId: kIsWeb ? null : webClientId,
    );
  }

  /// Ouvre le popup Google puis retourne l'idToken JWT a envoyer au back.
  /// Lance [SocialAuthCancelled] si l'utilisateur ferme le popup.
  Future<String> signInGoogleAndGetIdToken() async {
    final googleSignIn = _buildGoogle();
    // Sur web, si l'utilisateur ferme le popup, signIn() retourne null.
    // Sur mobile aussi.
    final account = await googleSignIn.signIn();
    if (account == null) {
      throw const SocialAuthCancelled();
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google idToken absent. Verifie le clientId web.');
    }
    return idToken;
  }

  /// Deconnecte proprement le compte Google local (sinon signIn() peut
  /// re-utiliser le compte precedent sans re-demander).
  Future<void> signOutGoogle() async {
    try {
      await _buildGoogle().signOut();
    } catch (_) {}
  }

  /// Web uniquement : redirige l'onglet courant vers [url]
  /// (URL d'autorisation LinkedIn recuperee aupres du backend).
  /// Sur mobile, utiliser LinkedInWebViewScreen a la place.
  void redirectToUrl(String url) {
    if (!kIsWeb) {
      throw Exception(
          'redirectToUrl est reserve au web. Utilise la WebView sur mobile.');
    }
    launchLinkedInLogin(url);
  }
}
