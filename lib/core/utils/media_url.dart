import '../env/app_config.dart';

/// Normalise une URL de media (photo, document...) retournee par l'API.
/// - Si absolue (http/https) : retournee telle quelle.
/// - Si vide/null : null.
/// - Sinon : prefixee par storageBaseUrl si defini, ou derivee depuis
///   apiBaseUrl en substituant `/api` → `/storage` (convention Laravel).
String? mediaUrl(String? path) {
  if (path == null) return null;
  final p = path.trim();
  if (p.isEmpty) return null;
  if (p.startsWith('http://') || p.startsWith('https://')) return p;

  final explicit = AppConfig.storageBaseUrl;
  final base = explicit.isNotEmpty
      ? explicit
      : _deriveStorageBaseFromApi(AppConfig.apiBaseUrl);
  if (base.isEmpty) return p;

  final cleanPath = p.startsWith('/') ? p.substring(1) : p;
  final sep = base.endsWith('/') ? '' : '/';
  return '$base$sep$cleanPath';
}

String _deriveStorageBaseFromApi(String apiBase) {
  if (apiBase.isEmpty) return '';
  // Cas typique : https://host/api  → https://host/storage
  if (apiBase.endsWith('/api')) {
    return '${apiBase.substring(0, apiBase.length - 4)}/storage';
  }
  if (apiBase.endsWith('/api/')) {
    return '${apiBase.substring(0, apiBase.length - 5)}/storage';
  }
  // Fallback : ajouter /storage a la racine du host.
  final uri = Uri.tryParse(apiBase);
  if (uri == null) return '';
  return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/storage';
}
