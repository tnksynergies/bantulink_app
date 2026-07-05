import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../i18n/app_localizations.dart';

/// Bouton "Continuer avec Google" (style officiel : fond blanc, bordure).
class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({super.key, required this.onPressed, this.loading = false});
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return _SocialButton(
      onPressed: loading ? null : onPressed,
      background: Colors.white,
      foreground: const Color(0xFF1F1F1F),
      border: const Color(0xFFDADCE0),
      loading: loading,
      leading: const _GoogleG(),
      label: context.tr('auth.continue_google'),
    );
  }
}

/// Bouton "Continuer avec LinkedIn" (bleu LinkedIn).
class LinkedInAuthButton extends StatelessWidget {
  const LinkedInAuthButton({super.key, required this.onPressed, this.loading = false});
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return _SocialButton(
      onPressed: loading ? null : onPressed,
      background: const Color(0xFF0A66C2),
      foreground: Colors.white,
      border: const Color(0xFF0A66C2),
      loading: loading,
      leading: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(4)),
        alignment: Alignment.center,
        child: const Text('in',
            style: TextStyle(
                color: Color(0xFF0A66C2),
                fontWeight: FontWeight.w900,
                fontSize: 13)),
      ),
      label: context.tr('auth.continue_linkedin'),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.border,
    required this.leading,
    required this.label,
    required this.loading,
  });
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final Color border;
  final Widget leading;
  final String label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: foreground),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Text(label,
                      style: TextStyle(
                          color: foreground,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

/// "G" multicolore simplifie de Google.
class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: Text('G',
          style: TextStyle(
              color: Color(0xFF4285F4),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.05)),
    );
  }
}

/// Separateur "ou continuer avec".
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(context.tr('auth.or_continue_with'),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
