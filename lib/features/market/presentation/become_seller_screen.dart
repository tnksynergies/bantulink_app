import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../freelancers/data/upload_file.dart';
import '../application/vendor_providers.dart';
import 'market_colors.dart';

class BecomeSellerScreen extends ConsumerStatefulWidget {
  const BecomeSellerScreen({super.key});

  @override
  ConsumerState<BecomeSellerScreen> createState() => _BecomeSellerScreenState();
}

class _BecomeSellerScreenState extends ConsumerState<BecomeSellerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sloganCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _paysCtrl = TextEditingController(text: 'Cameroun');
  final _contribuableCtrl = TextEditingController();
  UploadFile? _logo;
  UploadFile? _couverture;
  bool _submitting = false;
  bool _prefillDone = false;

  @override
  void dispose() {
    for (final c in [
      _nomCtrl, _emailCtrl, _telCtrl, _descCtrl, _sloganCtrl,
      _adresseCtrl, _villeCtrl, _paysCtrl, _contribuableCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill() {
    if (_prefillDone) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;
    _emailCtrl.text = user.email;
    if (user.telephone != null) _telCtrl.text = user.telephone!;
    _prefillDone = true;
  }

  Future<void> _pickImage(bool isLogo) async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final file = await UploadFile.fromXFile(picked);
    setState(() {
      if (isLogo) {
        _logo = file;
      } else {
        _couverture = file;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(registerVendorControllerProvider.notifier).submit(
            nom: _nomCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            telephone: _telCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            adresse: _adresseCtrl.text.trim(),
            ville: _villeCtrl.text.trim(),
            pays: _paysCtrl.text.trim(),
            slogan: _sloganCtrl.text.trim().isEmpty
                ? null
                : _sloganCtrl.text.trim(),
            numContribuable: _contribuableCtrl.text.trim().isEmpty
                ? null
                : _contribuableCtrl.text.trim(),
            logo: _logo,
            couverture: _couverture,
          );
      final err = ref.read(registerVendorControllerProvider).error;
      if (err != null) throw err;
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(context.tr('market.seller_created')),
        backgroundColor: MarketColors.primary,
      ));
      context.go('/vendeur/dashboard');
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _prefill();
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('market.become_seller'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: MarketColors.heroGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('market.seller_hero'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(context.tr('market.seller_subtitle'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _tf(_nomCtrl, '${context.tr('market.shop_name')} *',
                required: true),
            _tf(_emailCtrl, '${context.tr('market.shop_email')} *',
                required: true,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return context.tr('common.required');
                  if (!value.contains('@')) {
                    return context.tr('common.invalid_email');
                  }
                  return null;
                }),
            _tf(_telCtrl, '${context.tr('market.phone')} *',
                required: true, keyboardType: TextInputType.phone),
            _tf(_descCtrl, '${context.tr('market.shop_description')} *',
                required: true, maxLines: 3),
            _tf(_sloganCtrl, context.tr('market.shop_slogan')),
            _tf(_adresseCtrl, '${context.tr('market.address')} *',
                required: true),
            Row(
              children: [
                Expanded(
                    child: _tf(_villeCtrl, '${context.tr('market.city')} *',
                        required: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _tf(_paysCtrl, context.tr('market.country'))),
              ],
            ),
            _tf(_contribuableCtrl, context.tr('market.tax_number')),
            const SizedBox(height: 8),

            _photoRow(context.tr('market.logo'), _logo,
                () => _pickImage(true)),
            _photoRow(context.tr('market.cover'), _couverture,
                () => _pickImage(false)),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: MarketColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(context.tr('market.register_seller')),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String label,
      {bool required = false,
      TextInputType? keyboardType,
      int? maxLines = 1,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: (maxLines ?? 1) > 1,
        ),
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? context.tr('common.required')
                    : null
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
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14))),
          OutlinedButton(
              onPressed: onTap,
              child: Text(context.tr('become.pick_photo'))),
        ],
      ),
    );
  }
}
