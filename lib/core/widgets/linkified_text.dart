import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Texte selectionnable (copie via appui long) dont les URLs sont
/// soulignees et cliquables : le tap ouvre le lien dans le navigateur.
/// Utilise dans les bulles de chat.
class LinkifiedText extends StatefulWidget {
  const LinkifiedText(this.text, {super.key, this.style, this.linkColor});

  final String text;
  final TextStyle? style;

  /// Couleur des liens (defaut : couleur du texte, soulignee).
  final Color? linkColor;

  /// http(s)://... ou www....
  static final urlRegex = RegExp(
    r'(https?://[^\s<>()\[\]{}"]+|www\.[^\s<>()\[\]{}"]+)',
    caseSensitive: false,
  );

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  // Les TapGestureRecognizer doivent etre liberes explicitement.
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _open(String raw) async {
    var url = raw;
    if (url.toLowerCase().startsWith('www.')) url = 'https://$url';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // Lien invalide : on n'interrompt pas l'utilisateur.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reconstruit : on repart de zero pour les recognizers.
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final base = widget.style ?? DefaultTextStyle.of(context).style;
    final linkStyle = base.copyWith(
      color: widget.linkColor ?? base.color,
      decoration: TextDecoration.underline,
      decorationColor: widget.linkColor ?? base.color,
      fontWeight: FontWeight.w600,
    );

    final spans = <TextSpan>[];
    var idx = 0;
    for (final m in LinkifiedText.urlRegex.allMatches(widget.text)) {
      var url = m.group(0)!;
      // La ponctuation finale ("lien.", "(lien)") ne fait pas partie du lien.
      var end = m.end;
      while (url.isNotEmpty && '.,;:!?)'.contains(url[url.length - 1])) {
        url = url.substring(0, url.length - 1);
        end--;
      }
      if (url.isEmpty) continue;
      if (m.start > idx) {
        spans.add(TextSpan(text: widget.text.substring(idx, m.start)));
      }
      final recognizer = TapGestureRecognizer()..onTap = () => _open(url);
      _recognizers.add(recognizer);
      spans.add(TextSpan(text: url, style: linkStyle, recognizer: recognizer));
      idx = end;
    }
    if (idx < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(idx)));
    }

    return SelectableText.rich(TextSpan(style: base, children: spans));
  }
}
