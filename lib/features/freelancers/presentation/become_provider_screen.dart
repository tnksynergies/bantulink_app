import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../application/become_provider_controller.dart';
import '../application/freelancers_providers.dart';
import '../data/upload_file.dart';

class BecomeProviderScreen extends ConsumerStatefulWidget {
  const BecomeProviderScreen({super.key});

  @override
  ConsumerState<BecomeProviderScreen> createState() => _BecomeProviderScreenState();
}

class _BecomeProviderScreenState extends ConsumerState<BecomeProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _paysCtrl = TextEditingController(text: 'Cameroun');
  final _titreCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _competencesCtrl = TextEditingController();

  UploadFile? _photoProfil;
  UploadFile? _photoCouverture;
  bool _submitting = false;
  bool _prefillDone = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _adresseCtrl.dispose();
    _villeCtrl.dispose();
    _paysCtrl.dispose();
    _titreCtrl.dispose();
    _minCtrl.dispose();
    _descCtrl.dispose();
    _competencesCtrl.dispose();
    super.dispose();
  }

  /// Prefill : priorite au profil freelancer existant (mode edition),
  /// fallback sur les donnees utilisateur (mode inscription).
  void _prefillFromSources() {
    if (_prefillDone) return;
    final freelancer = ref.read(myFreelancerProfileProvider).valueOrNull;
    if (freelancer != null) {
      _nomCtrl.text = freelancer.nomComplet ?? '';
      _emailCtrl.text = freelancer.emailPro ?? '';
      _telCtrl.text = freelancer.telephone ?? '';
      _adresseCtrl.text = freelancer.adresse ?? '';
      _villeCtrl.text = freelancer.ville ?? '';
      if ((freelancer.pays ?? '').isNotEmpty) _paysCtrl.text = freelancer.pays!;
      _titreCtrl.text = freelancer.titrePro ?? '';
      _minCtrl.text = freelancer.montantMinimum?.toString() ?? '';
      _descCtrl.text = freelancer.description ?? '';
      _competencesCtrl.text =
          freelancer.competences.map((c) => c.nom).join(', ');
      _prefillDone = true;
      return;
    }

    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;
    _nomCtrl.text = user.fullName;
    _emailCtrl.text = user.email;
    if (user.telephone != null) _telCtrl.text = user.telephone!;
    final particulier = user.particulierRaw;
    if (particulier != null) {
      _villeCtrl.text = (particulier['ville'] ?? '').toString();
      _adresseCtrl.text = (particulier['adresse'] ?? '').toString();
    }
    _prefillDone = true;
  }

  Future<void> _pickImage(bool profil) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final file = await UploadFile.fromXFile(picked);
      setState(() {
        if (profil) {
          _photoProfil = file;
        } else {
          _photoCouverture = file;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final competences = _competencesCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await ref.read(becomeProviderControllerProvider.notifier).submit(
            nomComplet: _nomCtrl.text.trim(),
            titrePro: _titreCtrl.text.trim(),
            emailPro: _emailCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            telephone: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
            adresse: _adresseCtrl.text.trim().isEmpty ? null : _adresseCtrl.text.trim(),
            ville: _villeCtrl.text.trim().isEmpty ? null : _villeCtrl.text.trim(),
            pays: _paysCtrl.text.trim().isEmpty ? null : _paysCtrl.text.trim(),
            montantMinimum: num.tryParse(_minCtrl.text.trim()),
            competences: competences.isEmpty ? null : competences,
            photoProfil: _photoProfil,
            photoCouverture: _photoCouverture,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('become.success')), backgroundColor: AppColors.success),
      );
      context.go('/prestataire/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // On watch pour re-declencher le prefill quand le profil freelancer arrive.
    final asyncFreelancer = ref.watch(myFreelancerProfileProvider);
    if (asyncFreelancer.hasValue) _prefillFromSources();

    final isEditing = asyncFreelancer.valueOrNull != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing
            ? context.tr('provider.edit_profile')
            : context.tr('become.title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isEditing) ...[
                _Hero(),
                const SizedBox(height: 24),
                _BenefitsGrid(),
                const SizedBox(height: 24),
              ],
              Text(
                  isEditing
                      ? context.tr('provider.edit_profile')
                      : context.tr('become.form_title'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _tf(_nomCtrl, '${context.tr('become.full_name')} *', required: true),
              _tf(_emailCtrl, '${context.tr('become.email_pro')} *',
                  required: true,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return context.tr('common.required');
                    if (!v.contains('@')) return context.tr('common.invalid_email');
                    return null;
                  }),
              _tf(_telCtrl, '${context.tr('become.phone')} *', required: true, keyboardType: TextInputType.phone),
              _tf(_adresseCtrl, context.tr('become.address')),
              Row(
                children: [
                  Expanded(child: _tf(_villeCtrl, '${context.tr('become.city')} *', required: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _tf(_paysCtrl, context.tr('become.country'))),
                ],
              ),
              _tf(_titreCtrl, '${context.tr('become.title_pro')} *',
                  required: true, hint: context.tr('become.title_pro_hint')),
              _tf(_minCtrl, '${context.tr('become.min_amount')} *',
                  required: true, keyboardType: TextInputType.number),
              _tf(_descCtrl, context.tr('become.description'),
                  maxLines: 4, hint: context.tr('become.description_hint')),
              _tf(_competencesCtrl, context.tr('become.competences'),
                  hint: context.tr('become.competences_hint')),
              const SizedBox(height: 8),
              _photoRow(context.tr('become.photo_profil'), _photoProfil, () => _pickImage(true)),
              _photoRow(context.tr('become.photo_couverture'), _photoCouverture, () => _pickImage(false)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(context.tr('become.submit')),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String label,
      {bool required = false,
      TextInputType? keyboardType,
      int? maxLines = 1,
      String? hint,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: (maxLines ?? 1) > 1,
        ),
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty) ? context.tr('common.required') : null
                : null),
      ),
    );
  }

  Widget _photoRow(String label, UploadFile? file, VoidCallback onTap) {
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
                borderRadius: BorderRadius.circular(8)),
            child: file == null
                ? const Icon(Icons.image_outlined, color: AppColors.textMuted)
                : Image.memory(file.bytes, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          OutlinedButton(onPressed: onTap, child: Text(context.tr('become.pick_photo'))),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.royalBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('become.hero'),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(context.tr('become.subtitle'),
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

class _BenefitsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      (Icons.visibility, 'become.benefit1_title', 'become.benefit1_desc'),
      (Icons.dashboard_customize, 'become.benefit2_title', 'become.benefit2_desc'),
      (Icons.security, 'become.benefit3_title', 'become.benefit3_desc'),
      (Icons.support_agent, 'become.benefit4_title', 'become.benefit4_desc'),
    ];
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(context.tr('become.benefits_title'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.3,
          children: items.map((it) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(it.$1, color: AppColors.primary, size: 22),
                  const SizedBox(height: 6),
                  Text(context.tr(it.$2),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(context.tr(it.$3),
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
