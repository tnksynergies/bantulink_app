import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/vendor_providers.dart';

/// Autorise [child] uniquement si l'utilisateur possede le role Vendeur.
/// Sinon redirige vers /devenir-vendeur (inscription boutique).
class VendorGuard extends ConsumerWidget {
  const VendorGuard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVendor = ref.watch(isCurrentUserVendorProvider);
    if (!isVendor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/devenir-vendeur');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return child;
  }
}
