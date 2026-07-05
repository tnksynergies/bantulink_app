import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../application/profile_providers.dart';
import '../data/profile_remote_data_source.dart';

class EditParticulierScreen extends ConsumerStatefulWidget {
  const EditParticulierScreen({super.key});
  @override
  ConsumerState<EditParticulierScreen> createState() =>
      _EditParticulierScreenState();
}

class _EditParticulierScreenState extends ConsumerState<EditParticulierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titre = TextEditingController();
  final _resume = TextEditingController();
  final _tel = TextEditingController();
  final _ville = TextEditingController();
  final _pays = TextEditingController();
  final _adresse = TextEditingController();
  final _dateNaissance = TextEditingController();
  bool _visible = true;

  ProfileFile? _image;
  ProfileFile? _cv;
  ProfileFile? _lettre;
  final List<Map<String, String>> _ressources = [];
  final _resNom = TextEditingController();
  final _resLien = TextEditingController();

  bool _isUpdate = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(authControllerProvider).valueOrNull?.particulierRaw;
    _isUpdate = p != null;
    if (p != null) {
      _titre.text = (p['titre_professionnel'] ?? '').toString();
      _resume.text = (p['resume_profil'] ?? '').toString();
      _tel.text = (p['telephone'] ?? '').toString();
      _ville.text = (p['ville'] ?? '').toString();
      _pays.text = (p['pays'] ?? '').toString();
      _adresse.text = (p['adresse'] ?? '').toString();
      _dateNaissance.text = (p['date_naissance'] ?? '').toString();
      _visible = p['is_visible'] == true || p['is_visible'] == 1;
      final r = p['ressources'];
      if (r is String && r.trim().startsWith('[')) {
        try {
          for (final e in (jsonDecode(r) as List)) {
            if (e is Map) {
              _ressources.add({
                'nom': (e['nom'] ?? '').toString(),
                'lien': (e['lien'] ?? '').toString(),
              });
            }
          }
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _titre,
      _resume,
      _tel,
      _ville,
      _pays,
      _adresse,
      _dateNaissance,
      _resNom,
      _resLien
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 90),
      lastDate: now,
    );
    if (picked != null) {
      _dateNaissance.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) {
      final bytes = await x.readAsBytes();
      setState(() => _image = ProfileFile(bytes, x.name));
    }
  }

  Future<ProfileFile?> _pickDoc() async {
    final res = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (res != null && res.files.isNotEmpty && res.files.first.bytes != null) {
      final f = res.files.first;
      return ProfileFile(f.bytes as Uint8List, f.name);
    }
    return null;
  }

  void _put(Map<String, dynamic> m, String k, String v) {
    if (v.trim().isNotEmpty) m[k] = v.trim();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final fields = <String, dynamic>{'is_visible': _visible};
    _put(fields, 'titre_professionnel', _titre.text);
    _put(fields, 'resume_profil', _resume.text);
    _put(fields, 'telephone', _tel.text);
    _put(fields, 'ville', _ville.text);
    _put(fields, 'pays', _pays.text);
    _put(fields, 'adresse', _adresse.text);
    _put(fields, 'date_naissance', _dateNaissance.text);
    fields['ressources'] = jsonEncode(_ressources);

    await ref.read(profileSaveControllerProvider.notifier).save(
          fields: fields,
          isUpdate: _isUpdate,
          image: _image,
          cv: _cv,
          lettre: _lettre,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSaveControllerProvider);
    final isLoading = state.isLoading;

    ref.listen(profileSaveControllerProvider, (prev, next) {
      if (next.isLoading) return;
      if (next.hasError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(next.error.toString()),
              backgroundColor: AppColors.error));
      } else if (next.hasValue && next.value == true) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text('Profil enregistre.'),
              backgroundColor: AppColors.success));
        if (context.canPop()) context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil candidat')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: _PhotoPicker(image: _image, onTap: _pickImage)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titre,
                  decoration: const InputDecoration(
                      labelText: 'Titre professionnel',
                      hintText: 'Ex : Developpeur Fullstack'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _resume,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'Resume du profil', alignLabelWithHint: true),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tel,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telephone'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ville,
                        decoration: const InputDecoration(labelText: 'Ville'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _pays,
                        decoration: const InputDecoration(labelText: 'Pays'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _adresse,
                  decoration: const InputDecoration(labelText: 'Adresse'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateNaissance,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: 'Date de naissance',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                _FileRow(
                  label: 'CV (PDF/DOC)',
                  file: _cv,
                  onPick: () async {
                    final f = await _pickDoc();
                    if (f != null) setState(() => _cv = f);
                  },
                  onClear: () => setState(() => _cv = null),
                ),
                const SizedBox(height: 12),
                _FileRow(
                  label: 'Lettre de motivation (PDF/DOC)',
                  file: _lettre,
                  onPick: () async {
                    final f = await _pickDoc();
                    if (f != null) setState(() => _lettre = f);
                  },
                  onClear: () => setState(() => _lettre = null),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Profil visible des recruteurs'),
                  value: _visible,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _visible = v),
                ),
                const Divider(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Autres ressources (liens)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: AppColors.navy)),
                ),
                const SizedBox(height: 8),
                ..._ressources.asMap().entries.map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.value['nom'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(e.value['lien'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () => setState(() => _ressources.removeAt(e.key)),
                          ),
                        ],
                      ),
                    )),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _resNom,
                        decoration: const InputDecoration(labelText: 'Nom (ex : LinkedIn)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _resLien,
                        decoration: const InputDecoration(labelText: 'Lien'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primary),
                      onPressed: () {
                        if (_resNom.text.trim().isEmpty || _resLien.text.trim().isEmpty) return;
                        setState(() {
                          _ressources.add({
                            'nom': _resNom.text.trim(),
                            'lien': _resLien.text.trim(),
                          });
                          _resNom.clear();
                          _resLien.clear();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({this.image, required this.onTap});
  final ProfileFile? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            backgroundImage: image != null ? MemoryImage(image!.bytes) : null,
            child: image == null
                ? const Icon(Icons.add_a_photo_outlined, color: AppColors.primary)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.edit, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.label,
    required this.file,
    required this.onPick,
    required this.onClear,
  });
  final String label;
  final ProfileFile? file;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                if (file != null)
                  Text(file!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (file != null)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.error),
              onPressed: onClear,
            )
          else
            TextButton(onPressed: onPick, child: const Text('Choisir')),
        ],
      ),
    );
  }
}
