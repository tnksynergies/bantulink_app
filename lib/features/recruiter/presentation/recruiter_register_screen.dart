import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/branding/brand.dart';
import '../application/recruiter_providers.dart';
import '../data/recruiter_remote_data_source.dart';

class RecruiterRegisterScreen extends ConsumerStatefulWidget {
  const RecruiterRegisterScreen({super.key});
  @override
  ConsumerState<RecruiterRegisterScreen> createState() =>
      _RecruiterRegisterScreenState();
}

class _RecruiterRegisterScreenState
    extends ConsumerState<RecruiterRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titre = TextEditingController();
  final _emailPro = TextEditingController();
  final _telPro = TextEditingController();
  final _nomEntreprise = TextEditingController();
  final _siteWeb = TextEditingController();
  final _adresse = TextEditingController();
  final _ville = TextEditingController();
  final _pays = TextEditingController();
  final _numContribuable = TextEditingController();
  final _description = TextEditingController();

  UploadBytes? _logo;
  UploadBytes? _cover;

  @override
  void dispose() {
    for (final c in [
      _titre, _emailPro, _telPro, _nomEntreprise, _siteWeb,
      _adresse, _ville, _pays, _numContribuable, _description
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(void Function(UploadBytes) set) async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) {
      final bytes = await x.readAsBytes();
      setState(() => set(UploadBytes(bytes, x.name)));
    }
  }

  void _put(Map<String, dynamic> m, String k, String v) {
    if (v.trim().isNotEmpty) m[k] = v.trim();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final fields = <String, dynamic>{};
    _put(fields, 'titre_professionnel', _titre.text);
    _put(fields, 'email_pro', _emailPro.text);
    _put(fields, 'telephone_pro', _telPro.text);
    _put(fields, 'nom_entreprise', _nomEntreprise.text);
    _put(fields, 'site_web', _siteWeb.text);
    _put(fields, 'adresse', _adresse.text);
    _put(fields, 'ville', _ville.text);
    _put(fields, 'pays', _pays.text);
    _put(fields, 'num_contribuable', _numContribuable.text);
    _put(fields, 'description_entreprise', _description.text);

    await ref.read(professionnelRegisterControllerProvider.notifier).register(
          fields: fields,
          logo: _logo,
          cover: _cover,
        );
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ requis' : null;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(professionnelRegisterControllerProvider);
    final isLoading = state.isLoading;

    ref.listen(professionnelRegisterControllerProvider, (prev, next) {
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
              content: Text('Profil recruteur cree.'),
              backgroundColor: AppColors.success));
        // Enchaine directement sur la publication d'offre
        context.pushReplacement('/offre/nouvelle');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const BrandLogo(BrandWorld.hire, height: 24), centerTitle: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Renseignez les informations de votre entreprise pour pouvoir publier des offres.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ImageTile(
                        label: 'Logo',
                        file: _logo,
                        onTap: () => _pick((u) => _logo = u),
                        onClear: () => setState(() => _logo = null),
                        circular: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ImageTile(
                        label: 'Couverture',
                        file: _cover,
                        onTap: () => _pick((u) => _cover = u),
                        onClear: () => setState(() => _cover = null),
                        circular: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _tf(_nomEntreprise, "Nom de l'entreprise *", validator: _req),
                const SizedBox(height: 14),
                _tf(_titre, 'Titre professionnel *', validator: _req),
                const SizedBox(height: 14),
                _tf(_emailPro, 'Email professionnel *',
                    keyboard: TextInputType.emailAddress, validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ requis';
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                }),
                const SizedBox(height: 14),
                _tf(_telPro, 'Telephone professionnel *',
                    keyboard: TextInputType.phone, validator: _req),
                const SizedBox(height: 14),
                _tf(_siteWeb, 'Site web (optionnel)',
                    keyboard: TextInputType.url),
                const SizedBox(height: 14),
                _tf(_adresse, 'Adresse *', validator: _req),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _tf(_ville, 'Ville *', validator: _req)),
                    const SizedBox(width: 12),
                    Expanded(child: _tf(_pays, 'Pays *', validator: _req)),
                  ],
                ),
                const SizedBox(height: 14),
                _tf(_numContribuable, 'Numero de contribuable *',
                    validator: _req),
                const SizedBox(height: 14),
                _tf(_description, "Description de l'entreprise *",
                    lines: 4, validator: _req),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text("Creer mon profil recruteur"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String label,
      {String? Function(String?)? validator,
      TextInputType? keyboard,
      int lines = 1}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      maxLines: lines,
      validator: validator,
      decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: lines > 1),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.label,
    required this.file,
    required this.onTap,
    required this.onClear,
    required this.circular,
  });
  final String label;
  final UploadBytes? file;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(circular ? 45 : 12),
              border: Border.all(color: AppColors.border),
              image: file != null
                  ? DecorationImage(
                      image: MemoryImage(file!.bytes), fit: BoxFit.cover)
                  : null,
            ),
            child: file == null
                ? const Icon(Icons.add_photo_alternate_outlined,
                    color: AppColors.primary)
                : null,
          ),
        ),
        const SizedBox(height: 4),
        if (file == null)
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted))
        else
          TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: const Text('Retirer', style: TextStyle(fontSize: 12))),
      ],
    );
  }
}
