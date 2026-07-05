import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../application/auth_controller.dart';

/// Ecran de reinitialisation du mot de passe.
/// Peut etre atteint via un deep link genre :
///   /reset-password?token=xxxxxxx&email=user@example.com
/// Sinon, l'utilisateur peut saisir manuellement le token depuis son email.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.initialToken,
    this.initialEmail,
  });

  final String? initialToken;
  final String? initialEmail;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null) _tokenCtrl.text = widget.initialToken!;
    if (widget.initialEmail != null) _emailCtrl.text = widget.initialEmail!;
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(resetPasswordControllerProvider.notifier).submit(
          email: _emailCtrl.text.trim(),
          token: _tokenCtrl.text.trim(),
          password: _pwdCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordControllerProvider);

    ref.listen(resetPasswordControllerProvider, (prev, next) {
      if (next.isLoading) return;
      if (next.hasError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(next.error.toString()),
              backgroundColor: AppColors.error));
      } else if (next.hasValue && next.value != null) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: Text(context.tr('reset.title')),
            content: Text(context.tr('reset.success')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/login');
                },
                child: Text(context.tr('auth.go_to_login')),
              ),
            ],
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.12),
                    ),
                    child: const Icon(Icons.password,
                        size: 42, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.tr('reset.title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('reset.subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  _label(context, 'reset.email_label'),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.mail_outline)),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return context.tr('auth.email_required');
                      if (!value.contains('@')) {
                        return context.tr('common.invalid_email');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _label(context, 'reset.token_label'),
                  TextFormField(
                    controller: _tokenCtrl,
                    decoration: InputDecoration(
                      hintText: context.tr('reset.token_hint'),
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? context.tr('reset.token_required')
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _label(context, 'reset.password_label'),
                  TextFormField(
                    controller: _pwdCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if ((v ?? '').isEmpty) return context.tr('auth.required');
                      if ((v ?? '').length < 8) {
                        return context.tr('auth.password_min');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _label(context, 'reset.confirm_label'),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if ((v ?? '').isEmpty) return context.tr('auth.required');
                      if (v != _pwdCtrl.text) {
                        return context.tr('auth.passwords_mismatch');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: state.isLoading ? null : _submit,
                    child: state.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : Text(context.tr('reset.submit')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(context.tr(key),
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.navy)),
      ),
    );
  }
}
