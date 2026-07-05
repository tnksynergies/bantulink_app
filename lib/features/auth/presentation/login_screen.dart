import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/branding/brand.dart';
import '../../../core/widgets/language_toggle.dart';
import '../../../core/widgets/social_auth_buttons.dart';
import '../application/auth_controller.dart';
import '../data/social_auth_service.dart';
import 'linkedin_webview_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _remember = false;
  bool _googleLoading = false;
  bool _linkedInLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  void _toastError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ));
  }

  Future<void> _loginWithGoogle() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    try {
      final social = ref.read(socialAuthServiceProvider);
      // On force un signOut prealable pour toujours re-demander le compte.
      await social.signOutGoogle();
      final idToken = await social.signInGoogleAndGetIdToken();
      await ref
          .read(authControllerProvider.notifier)
          .loginWithGoogle(idToken);
    } on SocialAuthCancelled {
      // Utilisateur a ferme le popup : silence, pas d'erreur.
    } catch (e) {
      if (mounted) _toastError(e.toString());
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _loginWithLinkedIn() async {
    if (_linkedInLoading) return;
    setState(() => _linkedInLoading = true);
    try {
      // 1) Recupere l'URL d'autorisation LinkedIn aupres du backend
      //    (GET /linkedin-auth-url, fallback ancien contrat gere).
      final authUrl =
          await ref.read(authRepositoryProvider).linkedInAuthUrl();
      if (!mounted) return;
      if (kIsWeb) {
        // Sur web : redirection de l'onglet vers LinkedIn.
        ref.read(socialAuthServiceProvider).redirectToUrl(authUrl);
        return;
      }
      // 2) Sur mobile : WebView, interception du code au retour OAuth.
      final code = await Navigator.of(context).push<String?>(
        MaterialPageRoute(
          builder: (_) => LinkedInWebViewScreen(startUrl: authUrl),
        ),
      );
      if (code == null || code.isEmpty) return; // annulation
      // 3) Echange code -> {user, token} via POST /linkedin-callback.
      await ref
          .read(authControllerProvider.notifier)
          .loginWithLinkedInCode(code);
    } catch (e) {
      if (mounted) _toastError(e.toString());
    } finally {
      if (mounted) setState(() => _linkedInLoading = false);
    }
  }

  void _goForgotPassword() {
    context.push('/mot-de-passe-oublie');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    ref.listen(authControllerProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
          ));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _AuthHeader(
            title: context.tr('auth.welcome_back'),
            subtitle: context.tr('auth.login_subtitle'),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Label(context.tr('auth.email')),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: context.tr('auth.email_hint'),
                          prefixIcon: const Icon(Icons.mail_outline),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return context.tr('auth.email_required');
                          if (!value.contains('@')) return context.tr('common.invalid_email');
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _Label(context.tr('auth.password')),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: context.tr('auth.password_hint'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v ?? '').isEmpty
                            ? context.tr('auth.password_required')
                            : null,
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: _remember,
                            onChanged: (v) => setState(() => _remember = v ?? false),
                          ),
                          Flexible(child: Text(context.tr('auth.remember_me'))),
                          const Spacer(),
                          TextButton(
                            onPressed: _goForgotPassword,
                            child: Text(context.tr('auth.forgot_password')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : Text(context.tr('auth.login')),
                      ),
                      const SizedBox(height: 24),
                      const OrDivider(),
                      const SizedBox(height: 16),
                      GoogleAuthButton(
                        onPressed: _loginWithGoogle,
                        loading: _googleLoading,
                      ),
                      const SizedBox(height: 12),
                      LinkedInAuthButton(
                        onPressed: _loginWithLinkedIn,
                        loading: _linkedInLoading,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(context.tr('auth.no_account'),
                              style: const TextStyle(color: AppColors.textMuted)),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: Text(context.tr('auth.create_account')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.navy)),
        ),
      );
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.title, required this.subtitle, this.showBack = false});
  final String title;
  final String subtitle;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandGreen, AppColors.navy],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  if (showBack)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    )
                  else
                    const SizedBox(width: 4),
                  const Spacer(),
                  const LanguageToggle(),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const BrandLogo(BrandWorld.link, height: 34),
              ),
              const SizedBox(height: 14),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
