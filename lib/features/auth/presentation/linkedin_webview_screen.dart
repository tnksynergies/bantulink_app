import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_colors.dart';

/// WebView qui pilote le flow OAuth LinkedIn.
///
/// Ouvre `startUrl` (l'URL d'autorisation LinkedIn fournie par le backend),
/// attend que l'utilisateur s'authentifie, puis intercepte la redirection
/// vers la redirect_uri pour extraire le parametre `code`.
///
/// L'interception est generique : toute navigation HORS linkedin.com dont
/// l'URL contient `?code=...` est consideree comme le retour OAuth. Cela
/// fonctionne quelle que soit la valeur de LINKEDIN_REDIRECT cote serveur.
///
/// Retourne le code via `Navigator.pop(code)` ou `null` si l'utilisateur
/// annule (retour arriere).
class LinkedInWebViewScreen extends StatefulWidget {
  const LinkedInWebViewScreen({super.key, required this.startUrl});

  final String startUrl;

  @override
  State<LinkedInWebViewScreen> createState() => _LinkedInWebViewScreenState();
}

class _LinkedInWebViewScreenState extends State<LinkedInWebViewScreen> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _codeReturned = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p / 100),
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final code = uri?.queryParameters['code'];
            final host = uri?.host ?? '';
            // Retour OAuth : code present ET on quitte le domaine LinkedIn.
            if (code != null &&
                code.isNotEmpty &&
                !host.contains('linkedin.com') &&
                !_codeReturned) {
              _codeReturned = true;
              // On empeche la webview de charger la callback : c'est le
              // Dio de l'app qui va faire l'echange code -> token.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.of(context).pop(code);
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.startUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LinkedIn'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          if (_progress < 1)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: AppColors.background,
              color: AppColors.royalBlue,
              minHeight: 3,
            ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
