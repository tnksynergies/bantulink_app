import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../jobs/data/models/candidature.dart';
import '../application/recruiter_providers.dart';
import 'sheets/interview_invite_sheet.dart';
import 'widgets/application_status_chip.dart';

class ApplicationDetailScreen extends ConsumerWidget {
  const ApplicationDetailScreen({super.key, required this.applicationId});
  final int applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(applicationDetailProvider(applicationId));
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('recruiter.applications')),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('$e', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        data: (c) => _Body(candidature: c),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.candidature});
  final Candidature candidature;

  Future<void> _openUrl(BuildContext context, String url) async {
    // Copie l'URL dans le presse-papier + SnackBar pour l'ouvrir manuellement.
    // (evite la dependance url_launcher, cross-platform sans setup natif)
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: url));
    messenger.showSnackBar(SnackBar(
      content: Text('URL copiee. Colle-la dans ton navigateur : $url',
          maxLines: 2, overflow: TextOverflow.ellipsis),
      duration: const Duration(seconds: 4),
    ));
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref, {
    required String statut,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(updateApplicationStatusControllerProvider(candidature.id)
              .notifier)
          .submit(statut: statut);
      messenger.showSnackBar(
        SnackBar(content: Text(context.mounted ? context.tr('application.status_updated') : '')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _openInterviewSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          InterviewInviteSheet(applicationId: candidature.id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = candidature;
    final candidat = c.candidat;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                  image: (candidat?.photoProfil != null &&
                          candidat!.photoProfil!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(candidat.photoProfil!),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                alignment: Alignment.center,
                child: (candidat?.photoProfil == null ||
                        candidat!.photoProfil!.isEmpty)
                    ? Text(candidat?.initials ?? '?',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(height: 12),
              Text(candidat?.displayName ?? 'Candidat',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ApplicationStatusChip(status: c.status),
              const SizedBox(height: 12),
              if (candidat?.email != null)
                _kv(context, Icons.mail_outline, candidat!.email!),
              if (candidat?.telephone != null)
                _kv(context, Icons.phone_outlined, candidat!.telephone!),
              if (candidat?.ville != null)
                _kv(context, Icons.location_on_outlined,
                    '${candidat!.ville}${candidat.pays != null ? ', ${candidat.pays}' : ''}'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Offer info
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('application.for_offer'),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Text(c.offreTitre ?? '-',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('${context.tr('application.applied_on')} ${c.dateCourt}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Documents (CV + lettre + autres)
        if (c.cvUrl != null || c.motivationUrl != null || c.documents.isNotEmpty)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('application.other_docs'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (c.cvUrl != null)
                  _docTile(context, Icons.description_outlined,
                      context.tr('application.view_cv'), () => _openUrl(context, c.cvUrl!)),
                if (c.motivationUrl != null)
                  _docTile(context, Icons.article_outlined,
                      context.tr('application.view_motivation'),
                      () => _openUrl(context, c.motivationUrl!)),
                for (final d in c.documents)
                  _docTile(context, Icons.attach_file_outlined, d.title,
                      () => _openUrl(context, d.url)),
              ],
            ),
          ),

        if (c.lettreMotivation != null) ...[
          const SizedBox(height: 8),
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('application.view_motivation'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(c.lettreMotivation!,
                    style: const TextStyle(fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],

        const SizedBox(height: 8),

        // Actions
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('application.action.change_status'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _actionBtn(
                    context,
                    icon: Icons.star_outline,
                    label: context.tr('application.action.preselect'),
                    color: const Color(0xFFC2410C),
                    onTap: () =>
                        _changeStatus(context, ref, statut: 'preselectionne'),
                  ),
                  _actionBtn(
                    context,
                    icon: Icons.event_available_outlined,
                    label: context.tr('application.action.invite'),
                    color: const Color(0xFF6D28D9),
                    onTap: () => _openInterviewSheet(context),
                  ),
                  _actionBtn(
                    context,
                    icon: Icons.check_circle_outline,
                    label: context.tr('application.action.hire'),
                    color: AppColors.success,
                    onTap: () =>
                        _changeStatus(context, ref, statut: 'embauche'),
                  ),
                  _actionBtn(
                    context,
                    icon: Icons.close,
                    label: context.tr('application.action.reject'),
                    color: AppColors.error,
                    onTap: () =>
                        _changeStatus(context, ref, statut: 'rejete'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _kv(BuildContext context, IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(icon, size: 14, color: AppColors.textMuted),
            ),
            TextSpan(
              text: '  $value',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _docTile(BuildContext context, IconData icon, String label,
      VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
      ),
    );
  }

  Widget _actionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
