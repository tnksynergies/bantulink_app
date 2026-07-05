/// Deballe une reponse API quelle que soit l'enveloppe (trait ApiResponseHandler,
/// JsonResource { data: ... }, ou liste brute).
List<dynamic> unwrapList(dynamic body) {
  dynamic cur = body;
  var guard = 0;
  while (cur is Map && guard < 5) {
    cur = cur['data'] ??
        cur['datas'] ??
        cur['items'] ??
        cur['result'] ??
        cur['offres'] ??
        cur['candidatures'];
    guard++;
  }
  return cur is List ? cur : const <dynamic>[];
}

/// Deballe jusqu'a trouver l'objet ressource (celui qui possede un 'id').
Map<String, dynamic> unwrapMap(dynamic body) {
  dynamic cur = body;
  var guard = 0;
  while (cur is Map && cur['id'] == null && cur['data'] != null && guard < 5) {
    cur = cur['data'];
    guard++;
  }
  if (cur is Map) return Map<String, dynamic>.from(cur);
  if (body is Map) return Map<String, dynamic>.from(body);
  return <String, dynamic>{};
}
