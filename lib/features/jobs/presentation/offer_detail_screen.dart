import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../application/jobs_providers.dart';
import '../data/models/offer.dart';
import '../../../core/widgets/html_text.dart';
import 'apply_sheet.dart';

class OfferDetailScreen extends ConsumerWidget {
  const OfferDetailScreen({super.key, required this.offreId});
  final int offreId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(offerDetailProvider(offreId));
    return Scaffold(
      appBar: AppBar(title: const Text("Detail de l'offre")),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 16),
                OutlinedButton(
                    onPressed: () => ref.invalidate(offerDetailProvider(offreId)),
                    child: const Text('Reessayer')),
              ],
            ),
          ),
        ),
        data: (offer) => _OfferBody(offer: offer),
      ),
    );
  }
}

class _OfferBody extends ConsumerWidget {
  const _OfferBody({required this.offer});
  final Offer offer;

  void _onApply(BuildContext context, WidgetRef ref) {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;
    if (!user.hasCandidatProfile) {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Profil candidat requis'),
          content: const Text(
              'Completez votre profil candidat pour pouvoir postuler.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Plus tard')),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/profil/editer');
              },
              child: const Text('Completer'),
            ),
          ],
        ),
      );
      return;
    }
    showApplySheet(context, offer.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emp = offer.employeur;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: (emp?.logo == null)
                          ? Container(
                              color: AppColors.primary.withOpacity(0.10),
                              child: const Icon(Icons.business,
                                  color: AppColors.primary))
                          : CachedNetworkImage(
                              imageUrl: emp!.logo!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.primary.withOpacity(0.10),
                                child: const Icon(Icons.business,
                                    color: AppColors.primary),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(offer.titreSafe,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy)),
                        if ((emp?.nom ?? '').isNotEmpty)
                          Text(emp!.nom!,
                              style: const TextStyle(
                                  color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoGrid(offer: offer),
              if ((offer.description ?? '').isNotEmpty)
                _Section(title: 'Description du poste', body: offer.description!),
              if ((offer.responsabilites ?? '').isNotEmpty)
                _Section(title: 'Responsabilites', body: offer.responsabilites!),
              if ((offer.exigences ?? '').isNotEmpty)
                _Section(title: 'Exigences', body: offer.exigences!),
              if (offer.skills.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Competences',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.navy)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: offer.skills
                      .map((s) => Chip(
                            label: Text(s),
                            backgroundColor: AppColors.background,
                            side: const BorderSide(color: AppColors.border),
                          ))
                      .toList(),
                ),
              ],
              if (emp != null) _EmployerCard(emp: emp),
              const SizedBox(height: 80),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: offer.dejaCandidature
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check),
                      label: const Text('Deja candidate'),
                    )
                  : ElevatedButton(
                      onPressed: () => _onApply(context, ref),
                      child: const Text('Postuler'),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final items = <List<String>>[];
    void add(String label, String? value) {
      if (value != null && value.trim().isNotEmpty) items.add([label, value]);
    }

    add('Type de contrat', offer.typeContrat);
    add('Lieu', offer.ville);
    add('Experience', offer.niveauExperience);
    add('Remuneration', offer.remuneration);
    add('Fonction', offer.fonction);
    add('Date limite', offer.dateLimiteCourt.isEmpty ? null : offer.dateLimiteCourt);

    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(e[0],
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                      ),
                      Expanded(
                        child: Text(e[1],
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 16)),
        const SizedBox(height: 8),
        HtmlText(body),
      ],
    );
  }
}

class _EmployerCard extends StatelessWidget {
  const _EmployerCard({required this.emp});
  final dynamic emp;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("A propos de l'entreprise",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          if ((emp.description ?? '').toString().isNotEmpty)
            Text(emp.description.toString(),
                style: const TextStyle(color: AppColors.textPrimary, height: 1.4)),
          if ((emp.adresse ?? emp.ville ?? '').toString().isNotEmpty)
            _line(Icons.place_outlined,
                (emp.adresse ?? emp.ville).toString()),
          if ((emp.email ?? '').toString().isNotEmpty)
            _line(Icons.mail_outline, emp.email.toString()),
          if ((emp.telephone ?? '').toString().isNotEmpty)
            _line(Icons.phone_outlined, emp.telephone.toString()),
          if ((emp.siteWeb ?? '').toString().isNotEmpty)
            _line(Icons.language, emp.siteWeb.toString()),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}
