// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Redirige l'onglet courant vers l'endpoint backend qui declenche le flux
/// OAuth LinkedIn. Apres authentification, le backend traite le callback
/// et renvoie {user, token} en JSON dans le meme onglet.
void launchLinkedInLogin(String url) {
  html.window.location.href = url;
}
