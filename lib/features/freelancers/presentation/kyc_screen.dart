import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../application/freelancers_providers.dart';
import '../data/upload_file.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  UploadFile? _niu;
  UploadFile? _cni;
  UploadFile? _selfie;
  bool _busy = false;

  Future<void> _pickImage(void Function(UploadFile) onPicked) async {
    final picker = ImagePicker();
    final res = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (res != null) onPicked(await UploadFile.fromXFile(res));
  }

  Future<void> _pickFile(void Function(UploadFile) onPicked) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (res == null || res.files.isEmpty) return;
    final file = UploadFile.fromPlatformFile(res.files.single);
    if (file != null) onPicked(file);
  }

  Future<void> _submit() async {
    if (_niu == null || _cni == null || _selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('kyc.missing_docs'))));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(freelancersDataSourceProvider).submitCertification(
            niu: _niu!,
            documentIdentite: _cni!,
            photoSelfie: _selfie!,
          );
      ref.invalidate(myFreelancerProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('kyc.success'))),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(myFreelancerProfileProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('kyc.title'))),
      body: asyncProfile.maybeWhen(
        data: (freelancer) {
          final status = freelancer?.certificationStatus;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (status != null) _statusBanner(context, status, freelancer!.isVerified),
              Text(context.tr('kyc.subtitle'),
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 20),
              _docTile(
                context.tr('kyc.doc_identite'),
                _cni,
                () => _pickFile((f) => setState(() => _cni = f)),
              ),
              _docTile(
                context.tr('kyc.selfie'),
                _selfie,
                () => _pickImage((f) => setState(() => _selfie = f)),
                imagePreview: true,
              ),
              _docTile(
                context.tr('kyc.niu'),
                _niu,
                () => _pickFile((f) => setState(() => _niu = f)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(context.tr('kyc.submit')),
              ),
            ],
          );
        },
        orElse: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _statusBanner(BuildContext context, String status, bool verified) {
    Color bg;
    IconData icon;
    String textKey;
    if (verified || status == 'approved') {
      bg = AppColors.success.withOpacity(0.15);
      icon = Icons.verified;
      textKey = 'kyc.status_approved';
    } else if (status == 'rejected') {
      bg = AppColors.error.withOpacity(0.15);
      icon = Icons.error_outline;
      textKey = 'kyc.status_rejected';
    } else {
      bg = AppColors.warning.withOpacity(0.15);
      icon = Icons.hourglass_top;
      textKey = 'kyc.status_pending';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPrimary),
          const SizedBox(width: 12),
          Expanded(child: Text(context.tr(textKey), style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _docTile(String label, UploadFile? file, VoidCallback onTap,
      {bool imagePreview = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: file == null
                ? const Icon(Icons.upload_file_outlined, color: AppColors.textMuted)
                : (imagePreview
                    ? Image.memory(file.bytes, fit: BoxFit.cover)
                    : const Icon(Icons.description, color: AppColors.royalBlue)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          OutlinedButton(onPressed: onTap, child: Text(context.tr('become.pick_photo'))),
        ],
      ),
    );
  }
}
