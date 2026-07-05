/// Stub non-web : jette explicitement pour signaler au caller que la
/// redirection navigateur n'est pas supportee sur cette plateforme.
void launchLinkedInLogin(String url) {
  throw UnsupportedError(
      'LinkedIn sign-in via redirection navigateur : disponible sur web '
      'uniquement. Ajoute flutter_web_auth_2 pour le support mobile.');
}
