/// Convertit un texte saisi (avec sauts de ligne et listes "- ") en HTML simple
/// compatible avec l'affichage HtmlText et le stockage backend.
String textToHtml(String input) {
  final text = input.trim();
  if (text.isEmpty) return '';
  final lines = text.split('\n');
  final buf = StringBuffer();
  var inList = false;
  void closeList() {
    if (inList) {
      buf.write('</ul>');
      inList = false;
    }
  }

  for (final raw in lines) {
    final t = raw.trim();
    if (t.isEmpty) {
      closeList();
      continue;
    }
    if (t.startsWith('- ') || t.startsWith('* ')) {
      if (!inList) {
        buf.write('<ul>');
        inList = true;
      }
      buf.write('<li>${_esc(t.substring(2).trim())}</li>');
    } else {
      closeList();
      buf.write('<p>${_esc(t)}</p>');
    }
  }
  closeList();
  return buf.toString();
}

String _esc(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

/// Conversion inverse (best-effort) : HTML simple → texte avec sauts de ligne
/// et prefixe "- " pour les listes. Utile pour le pre-remplissage
/// des editeurs de texte plein a partir d'un contenu HTML stocke.
String htmlToText(String html) {
  if (html.isEmpty) return '';
  var s = html
      .replaceAll('</p>', '\n')
      .replaceAll('<p>', '')
      .replaceAllMapped(
          RegExp(r'<li>(.*?)</li>', dotAll: true), (m) => '- ${m[1]}\n')
      .replaceAll('<ul>', '')
      .replaceAll('</ul>', '')
      .replaceAll('<br>', '\n')
      .replaceAll('<br/>', '\n')
      .replaceAll('<br />', '\n')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ');
  // Supprime les balises HTML restantes en best-effort
  s = s.replaceAll(RegExp(r'<[^>]+>'), '');
  return s.trim();
}
