import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_outlined,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text('$label arrive bientot',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy)),
              const SizedBox(height: 8),
              const Text('Ce module est en cours de construction.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 24),
              OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Retour')),
            ],
          ),
        ),
      ),
    );
  }
}
