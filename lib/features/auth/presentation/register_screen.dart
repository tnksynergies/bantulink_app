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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _email = TextEditingController();
  final _tel = TextEditingController();
  final _pwd = TextEditingController();
  final _pwdConfirm = TextEditingController();
  bool _obscure = true;
  bool _googleLoading = false;
  bool _linkedInLoading = false;

  @override
  void dispose() {
    _nom.dispose();
    _prenom.dispose();
    _email.dispose();
    _tel.dispose();
    _pwd.dispose();
    _pwdConfirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final data = <String, dynamic>{
      'nom': _nom.text.trim(),
      'prenom': _prenom.text.trim(),
      'email': _email.text.trim(),
      'password': _pwd.text,
      'password_confirmation': _pwdConfirm.text,
    };
    if (_tel.text.trim().isNotEmpty) data['telephone'] = _tel.text.trim();
    await ref.read(registerControllerProvider.notifier).submit(data);
  }

  void _toastError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ));
  }

  Future<void> _signupWithGoogle() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    try {
      final social = ref.read(socialAuthServiceProvider);
      await social.signOutGoogle();
      final idToken = await social.signInGoogleAndGetIdToken();
      await ref
          .read(authControllerProvider.notifier)
          .loginWithGoogle(idToken);
    } on SocialAuthCancelled {
      // silence
    } catch (e) {
      if (mounted) _toastError(e.toString());
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _signupWithLinkedIn() async {
    if (_linkedInLoading) return;
    setState(() => _linkedInLoading = true);
    try {
      final authUrl =
          await ref.read(authRepositoryProvider).linkedInAuthUrl();
      if (!mounted) return;
      if (kIsWeb) {
        ref.read(socialAuthServiceProvider).redirectToUrl(authUrl);
        return;
      }
      final code = await Navigator.of(context).push<String?>(
        MaterialPageRoute(
          builder: (_) => LinkedInWebViewScreen(startUrl: authUrl),
        ),
      );
      if (code == null || code.isEmpty) return;
      await ref
          .read(authControllerProvider.notifier)
          .loginWithLinkedInCode(code);
    } catch (e) {
      if (mounted) _toastError(e.toString());
    } finally {
      if (mounted) setState(() => _linkedInLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerControllerProvider);
    final isLoading = state.isLoading;

    ref.listen(registerControllerProvider, (prev, next) {
      if (next.isLoading) return;
      if (next.hasError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(next.error.toString()),
              backgroundColor: AppColors.error));
      } else if (next.hasValue && next.value != null) {
        // Bascule directement sur l'ecran de verification email avec l'email
        // deja rempli, plutot qu'un simple dialog.
        context.go('/verifier-email?email=${Uri.encodeQueryComponent(_email.text.trim())}');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _AuthHeaderR(
            title: context.tr('auth.register_title'),
            subtitle: context.tr('auth.register_subtitle'),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _prenom,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                  labelText: context.tr('auth.first_name')),
                              validator: (v) => (v ?? '').trim().isEmpty
                                  ? context.tr('auth.required')
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nom,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                  labelText: context.tr('auth.last_name')),
                              validator: (v) => (v ?? '').trim().isEmpty
                                  ? context.tr('auth.required')
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                            labelText: context.tr('auth.email'),
                            prefixIcon: const Icon(Icons.mail_outline)),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return context.tr('auth.email_required');
                          if (!value.contains('@')) return context.tr('common.invalid_email');
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tel,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                            labelText: context.tr('auth.phone'),
                            prefixIcon: const Icon(Icons.phone_outlined)),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pwd,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.tr('auth.password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v ?? '').length < 8
                            ? context.tr('auth.password_min')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pwdConfirm,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                            labelText: context.tr('auth.confirm_password'),
                            prefixIcon: const Icon(Icons.lock_outline)),
                        validator: (v) => v != _pwd.text
                            ? context.tr('auth.passwords_mismatch')
                            : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : Text(context.tr('auth.register')),
                      ),
                      const SizedBox(height: 24),
                      const OrDivider(),
                      const SizedBox(height: 16),
                      GoogleAuthButton(
                        onPressed: _signupWithGoogle,
                        loading: _googleLoading,
                      ),
                      const SizedBox(height: 12),
                      LinkedInAuthButton(
                        onPressed: _signupWithLinkedIn,
                        loading: _linkedInLoading,
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(context.tr('auth.already_account')),
                        ),
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

class _AuthHeaderR extends StatelessWidget {
  const _AuthHeaderR({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

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
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 22),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/login'),
                  ),
                  const Spacer(),
                  const LanguageToggle(),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const BrandLogo(BrandWorld.link, height: 32),
              ),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
