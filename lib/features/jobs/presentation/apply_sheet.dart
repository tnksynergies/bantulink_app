import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../application/jobs_providers.dart';

Future<void> showApplySheet(BuildContext context, int offreId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ApplySheet(offreId: offreId),
  );
}

class _ApplySheet extends ConsumerStatefulWidget {
  const _ApplySheet({required this.offreId});
  final int offreId;
  @override
  ConsumerState<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends ConsumerState<_ApplySheet> {
  final _msg = TextEditingController();

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(applyControllerProvider(widget.offreId));
    final isLoading = state.isLoading;

    ref.listen(applyControllerProvider(widget.offreId), (prev, next) {
      if (next.isLoading) return;
      if (next.hasError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(next.error.toString()),
              backgroundColor: AppColors.error));
      } else if (next.hasValue && next.value == true) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text('Candidature envoyee avec succes.'),
              backgroundColor: AppColors.success));
      }
    });

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Postuler a cette offre',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy)),
          const SizedBox(height: 4),
          const Text(
              'Votre profil candidat sera joint automatiquement a la candidature.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: _msg,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Message / lettre de motivation (optionnel)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () => ref
                    .read(applyControllerProvider(widget.offreId).notifier)
                    .submit(lettre: _msg.text),
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Envoyer ma candidature'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
