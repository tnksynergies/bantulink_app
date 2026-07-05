import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as htmlparser;
import '../theme/app_colors.dart';

/// Rend du HTML simple (sortie ReactQuill : p, br, strong, em, u, a, ul, ol, li, h1-h6).
class HtmlText extends StatelessWidget {
  const HtmlText(this.html, {super.key, this.baseStyle});
  final String html;
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context) {
    final base = baseStyle ??
        const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary);
    final frag = htmlparser.parseFragment(html);
    final blocks = _renderNodes(frag.nodes, base);
    if (blocks.isEmpty) {
      final txt = _strip(html);
      return txt.isEmpty ? const SizedBox.shrink() : Text(txt, style: base);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks);
  }

  String _strip(String h) => h
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  List<Widget> _renderNodes(List<dom.Node> nodes, TextStyle base) {
    final widgets = <Widget>[];
    final pending = <dom.Node>[];

    void flush() {
      if (pending.isEmpty) return;
      final spans = _inline(pending, base);
      pending.clear();
      if (spans.isEmpty) return;
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RichText(text: TextSpan(style: base, children: spans)),
      ));
    }

    for (final node in nodes) {
      if (node is dom.Element) {
        final tag = node.localName?.toLowerCase() ?? '';
        if (tag == 'ul' || tag == 'ol') {
          flush();
          widgets.add(_list(node, base, ordered: tag == 'ol'));
        } else if (tag == 'p' || tag == 'div') {
          flush();
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RichText(
                text: TextSpan(style: base, children: _inline(node.nodes, base))),
          ));
        } else if (tag.length == 2 &&
            tag.startsWith('h') &&
            int.tryParse(tag.substring(1)) != null) {
          flush();
          final level = int.parse(tag.substring(1));
          final size = (22 - (level * 2)).clamp(14, 22).toDouble();
          final hs = base.copyWith(
              fontSize: size,
              fontWeight: FontWeight.bold,
              color: AppColors.navy);
          widgets.add(Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: RichText(
                text: TextSpan(style: hs, children: _inline(node.nodes, hs))),
          ));
        } else {
          pending.add(node);
        }
      } else if (node is dom.Text) {
        if (node.text.trim().isNotEmpty) pending.add(node);
      }
    }
    flush();
    return widgets;
  }

  Widget _list(dom.Element listEl, TextStyle base, {required bool ordered}) {
    final items = <Widget>[];
    var index = 1;
    for (final li in listEl.nodes
        .whereType<dom.Element>()
        .where((e) => e.localName?.toLowerCase() == 'li')) {
      final marker = ordered ? '${index++}.' : '\u2022';
      items.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: ordered ? 24 : 18, child: Text(marker, style: base)),
            Expanded(
                child: RichText(
                    text: TextSpan(style: base, children: _inline(li.nodes, base)))),
          ],
        ),
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: items),
    );
  }

  List<InlineSpan> _inline(List<dom.Node> nodes, TextStyle style) {
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      if (node is dom.Text) {
        spans.add(TextSpan(text: node.text, style: style));
      } else if (node is dom.Element) {
        final tag = node.localName?.toLowerCase() ?? '';
        switch (tag) {
          case 'br':
            spans.add(const TextSpan(text: '\n'));
            break;
          case 'b':
          case 'strong':
            spans.addAll(_inline(node.nodes, style.copyWith(fontWeight: FontWeight.bold)));
            break;
          case 'i':
          case 'em':
            spans.addAll(_inline(node.nodes, style.copyWith(fontStyle: FontStyle.italic)));
            break;
          case 'u':
            spans.addAll(_inline(node.nodes, style.copyWith(decoration: TextDecoration.underline)));
            break;
          case 'a':
            spans.addAll(_inline(node.nodes, style.copyWith(color: AppColors.royalBlue, decoration: TextDecoration.underline)));
            break;
          case 'p':
          case 'div':
          case 'ul':
          case 'ol':
          case 'li':
            spans.add(const TextSpan(text: '\n'));
            spans.addAll(_inline(node.nodes, style));
            break;
          default:
            spans.addAll(_inline(node.nodes, style));
        }
      }
    }
    return spans;
  }
}
