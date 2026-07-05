import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/missions_providers.dart';
import '../../data/models/freelancer.dart';
import '../../data/upload_file.dart';

class RequestMissionSheet extends ConsumerStatefulWidget {
  const RequestMissionSheet({super.key, required this.freelancer});
  final Freelancer freelancer;

  @override
  ConsumerState<RequestMissionSheet> createState() => _RequestMissionSheetState();
}

class _RequestMissionSheetState extends ConsumerState<RequestMissionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateFin;
  final List<UploadFile> _images = [];
  final List<UploadFile> _documents = [];
  bool _submitting = false;

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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

  Future<void> _pickDocument() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      withData: true,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'],
    );
    if (res != null) {
      setState(() {
        _documents.addAll(
            res.files.map(UploadFile.fromPlatformFile).whereType<UploadFile>());
      });
    }
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? now : (_dateDebut ?? now),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateDebut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('mission.start_required'))));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(createMissionControllerProvider.notifier).submit(
            freelancerId: widget.freelancer.id,
            titre: _titreCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            dateDebut: _dateDebut!.toIso8601String().substring(0, 10),
            dateFin: _dateFin?.toIso8601String().substring(0, 10),
            cout: num.tryParse(_budgetCtrl.text.trim()),
            images: _images,
            documents: _documents,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('mission.success'))),
      );
      // Envoie directement l'utilisateur vers son suivi des demandes.
      context.push('/mes-missions');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _fmt(DateTime? d) =>
      d == null ? '' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('mission.create_title'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${context.tr('mission.provider')}: ${widget.freelancer.nomSafe}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titreCtrl,
                        decoration: InputDecoration(
                          labelText: '${context.tr('mission.title_label')} *',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? context.tr('mission.title_required')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: '${context.tr('mission.description_label')} *',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? context.tr('mission.description_required')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: '${context.tr('mission.start_date')} *',
                                  suffixIcon: const Icon(Icons.calendar_today, size: 16),
                                ),
                                child: Text(_fmt(_dateDebut)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(false),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: context.tr('mission.end_date'),
                                  suffixIcon: const Icon(Icons.calendar_today, size: 16),
                                ),
                                child: Text(_fmt(_dateFin)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _budgetCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: context.tr('mission.budget')),
                      ),
                      const SizedBox(height: 16),
                      Text(context.tr('mission.attachments'),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_outlined, size: 18),
                            label: Text('${context.tr('mission.add_image')} (${_images.length})'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickDocument,
                            icon: const Icon(Icons.description_outlined, size: 18),
                            label: Text('${context.tr('mission.add_document')} (${_documents.length})'),
                          ),
                        ],
                      ),
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
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(context.tr('mission.submit')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
