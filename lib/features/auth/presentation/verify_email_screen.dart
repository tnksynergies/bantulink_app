import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../application/auth_controller.dart';

/// Ecran affiche apres l'inscription, ou depuis le login si l'email
/// n'est pas encore verifie. L'activation elle-meme se fait via le lien
/// dans l'email (endpoint back /email/verify/{id}/{hash} qui exige un lien
/// signe -- non manipulable a la main). L'ecran offre un moyen simple de
/// re-envoyer l'email.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.email != null) _emailCtrl.text = widget.email!;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(context.tr('common.invalid_email')),
            backgroundColor: AppColors.error));
      return;
    }
    await ref
        .read(resendVerificationControllerProvider.notifier)
        .submit(email);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resendVerificationControllerProvider);

    ref.listen(resendVerificationControllerProvider, (prev, next) {
      if (next.isLoading) return;
      if (next.hasError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(next.error.toString()),
              backgroundColor: AppColors.error));
      } else if (next.hasValue && next.value != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(context.tr('verify.resent')),
              backgroundColor: AppColors.success));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.12),
                  ),
                  child: const Icon(Icons.mark_email_unread_outlined,
                      size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('verify.title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('verify.subtitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 24),
                _InstructionsCard(),
                const SizedBox(height: 24),
                Text(
                  context.tr('verify.no_email_received'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(context.tr('verify.email_label'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                        fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.mail_outline)),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: state.isLoading ? null : _resend,
                  icon: state.isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_outlined, size: 18),
                  label: Text(context.tr('verify.resend')),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(context.tr('auth.go_to_login')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget line(int n, String key) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.15),
                ),
                alignment: Alignment.center,
                child: Text('$n',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(context.tr(key),
                    style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('verify.instructions_title'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          line(1, 'verify.instruction_1'),
          line(2, 'verify.instruction_2'),
          line(3, 'verify.instruction_3'),
        ],
      ),
    );
  }
}
