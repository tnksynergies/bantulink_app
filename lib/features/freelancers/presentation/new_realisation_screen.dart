import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../application/freelancers_providers.dart';
import '../data/upload_file.dart';

class NewRealisationScreen extends ConsumerStatefulWidget {
  const NewRealisationScreen({super.key});

  @override
  ConsumerState<NewRealisationScreen> createState() => _NewRealisationScreenState();
}

class _NewRealisationScreenState extends ConsumerState<NewRealisationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _localCtrl = TextEditingController();
  final _lienCtrl = TextEditingController();
  DateTime? _date;
  final List<UploadFile> _images = [];
  bool _submitting = false;

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _localCtrl.dispose();
    _lienCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(limit: 5);
    if (picked.isNotEmpty) {
      final files = <UploadFile>[];
      for (final x in picked) {
        files.add(await UploadFile.fromXFile(x));
      }
      setState(() => _images.addAll(files));
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('common.required'))));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(freelancersDataSourceProvider).createRealisation(
            titre: _titreCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            dateRealisation: _date!.toIso8601String().substring(0, 10),
            localisation: _localCtrl.text.trim().isEmpty ? null : _localCtrl.text.trim(),
            lien: _lienCtrl.text.trim().isEmpty ? null : _lienCtrl.text.trim(),
            images: _images,
          );
      ref.invalidate(myRealisationsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('realisation.success'))),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _fmt(DateTime? d) => d == null
      ? ''
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('realisation.new_title'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titreCtrl,
              decoration: InputDecoration(labelText: '${context.tr('realisation.title_label')} *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? context.tr('common.required') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(labelText: '${context.tr('realisation.description')} *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? context.tr('common.required') : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: '${context.tr('realisation.date')} *',
                  suffixIcon: const Icon(Icons.calendar_today, size: 16),
                ),
                child: Text(_fmt(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _localCtrl,
              decoration: InputDecoration(labelText: context.tr('realisation.location')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lienCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: context.tr('realisation.link')),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.image_outlined),
              label: Text('${context.tr('mission.add_image')} (${_images.length})'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
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
                  : Text(context.tr('realisation.submit')),
            ),
          ],
        ),
      ),
    );
  }
}
