import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/recruiter_providers.dart';

/// Wrapper qui autorise l'affichage de [child] uniquement si l'utilisateur
/// connecte possede le role Recruteur. Sinon, redirige vers
/// /recruteur/inscription.
///
/// A poser sur chaque route /recruteur/* qui expose des donnees ou actions
/// reservees au recruteur, pour bloquer l'acces direct via URL bar / back.
class RecruiterGuard extends ConsumerStatefulWidget {
  const RecruiterGuard({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<RecruiterGuard> createState() => _RecruiterGuardState();
}

class _RecruiterGuardState extends ConsumerState<RecruiterGuard> {
  bool _refreshed = false;

  @override
  void initState() {
    super.initState();
    // Recharge /user au montage : garantit une decision basee sur la donnee
    // fraiche (l'utilisateur a pu creer/supprimer son profil pro sur un
    // autre ecran ou depuis le web entre-temps).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(authControllerProvider.notifier).refreshUser();
      } catch (_) {
        // On garde la valeur du cache existant.
      } finally {
        if (mounted) {
          ref.invalidate(isCurrentUserRecruiterProvider);
          setState(() => _refreshed = true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_refreshed) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final async = ref.watch(isCurrentUserRecruiterProvider);
    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/accueil'),
                  child: const Text('Retour a l\'accueil'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (isRecruiter) {
        if (!isRecruiter) {
          // Redirection differee au prochain frame pour eviter le
          // "setState during build".
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/recruteur/inscription');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.child;
      },
    );
  }
}
