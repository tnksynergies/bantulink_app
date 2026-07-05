import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/branding/brand.dart';
import '../../../core/utils/html_convert.dart';
import '../../../core/widgets/html_text.dart';
import '../../auth/application/auth_controller.dart';
import '../../jobs/data/models/offer.dart';
import '../application/recruiter_providers.dart';

class CreateOfferScreen extends ConsumerStatefulWidget {
  const CreateOfferScreen({super.key, this.initialOffer});

  /// Si fourni, l'ecran fonctionne en mode edition (PUT au lieu de POST).
  final Offer? initialOffer;

  @override
  ConsumerState<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends ConsumerState<CreateOfferScreen> {
  int _step = 0;

  final _titre = TextEditingController();
  final _fonction = TextEditingController();
  final _lieu = TextEditingController();
  final _ville = TextEditingController();
  final _pays = TextEditingController();
  final _desc = TextEditingController();
  final _resp = TextEditingController();
  final _exig = TextEditingController();
  final _remMin = TextEditingController();
  final _remMax = TextEditingController();
  final _email = TextEditingController();
  final _url = TextEditingController();
  final _instr = TextEditingController();
  final _docInput = TextEditingController();

  int? _categorieId;
  String? _experience;
  String? _typeContrat;
  String _dateLimite = '';
  bool _afficherSalaire = false;
  // Initialisee au premier build avec les libelles traduits (CV, lettre...).
  final List<String> _documents = [];
  bool _documentsInitialized = false;
  final Set<int> _skills = {};

  @override
  void initState() {
    super.initState();
    final pro = ref.read(authControllerProvider).valueOrNull?.professionnelRaw;
    if (pro != null) {
      _ville.text = (pro['ville'] ?? '').toString();
      _pays.text = (pro['pays'] ?? '').toString();
    }
    _prefillFromInitialOffer();
  }

  void _prefillFromInitialOffer() {
    final o = widget.initialOffer;
    if (o == null) return;
    _titre.text = o.titre ?? '';
    _fonction.text = o.fonction ?? '';
    _ville.text = o.ville ?? _ville.text;
    _desc.text = htmlToText(o.description ?? '');
    _resp.text = htmlToText(o.responsabilites ?? '');
    _exig.text = htmlToText(o.exigences ?? '');
    _typeContrat = o.typeContrat;
    _experience = o.niveauExperience;
    _email.text = o.emailCandidature ?? '';
    _url.text = o.urlCandidature ?? '';
    _dateLimite = o.dateLimite ?? '';
    final catId = o.raw['categorie_id'];
    if (catId is int) _categorieId = catId;
    if (catId is String) _categorieId = int.tryParse(catId);
    final remMin = o.raw['remuneration_min'];
    final remMax = o.raw['remuneration_max'];
    if (remMin != null || remMax != null) {
      _afficherSalaire = true;
      if (remMin != null) _remMin.text = remMin.toString();
      if (remMax != null) _remMax.text = remMax.toString();
    }
  }

  @override
  void dispose() {
    for (final c in [
      _titre, _fonction, _lieu, _ville, _pays, _desc, _resp, _exig,
      _remMin, _remMax, _email, _url, _instr, _docInput
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _today {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  bool _validateOffre() {
    final missing = <String>[];
    if (_titre.text.trim().isEmpty) missing.add(context.tr('offer.f_title'));
    if (_categorieId == null) missing.add(context.tr('offer.f_category'));
    if (_fonction.text.trim().isEmpty) {
      missing.add(context.tr('offer.f_function'));
    }
    if (_experience == null) missing.add(context.tr('offer.f_experience'));
    if (_typeContrat == null) missing.add(context.tr('offer.f_contract'));
    if (_ville.text.trim().isEmpty) missing.add(context.tr('offer.f_city'));
    if (_pays.text.trim().isEmpty) missing.add(context.tr('offer.f_country'));
    if (_desc.text.trim().isEmpty) {
      missing.add(context.tr('offer.f_description'));
    }
    if (_resp.text.trim().isEmpty) {
      missing.add(context.tr('offer.f_responsibilities'));
    }
    if (_exig.text.trim().isEmpty) {
      missing.add(context.tr('offer.f_requirements'));
    }
    if (missing.isNotEmpty) {
      _toast('${context.tr('offer.missing_fields')} ${missing.join(', ')}');
      return false;
    }
    return true;
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.error));
  }

  Map<String, dynamic> _buildPayload() {
    final p = <String, dynamic>{
      'titre_poste': _titre.text.trim(),
      'fonction': _fonction.text.trim(),
      'description_poste': textToHtml(_desc.text),
      'responsabilites': textToHtml(_resp.text),
      'exigences': textToHtml(_exig.text),
      'experience_requise': _experience,
      'ville': _ville.text.trim(),
      'pays': _pays.text.trim(),
      'type_contrat': _typeContrat,
      'date_publication': _today,
      'documents_requis': _documents,
      'skills': _skills.toList(),
      'categorie_id': _categorieId,
      'statut': 'active',
    };
    if (_lieu.text.trim().isNotEmpty) p['lieu_travail'] = _lieu.text.trim();
    if (_dateLimite.isNotEmpty) p['date_limite_soumission'] = _dateLimite;
    if (_afficherSalaire) {
      final mn = double.tryParse(_remMin.text.trim());
      final mx = double.tryParse(_remMax.text.trim());
      if (mn != null) p['remuneration_min'] = mn;
      if (mx != null) p['remuneration_max'] = mx;
    }
    if (_email.text.trim().isNotEmpty) p['email_candidature'] = _email.text.trim();
    if (_url.text.trim().isNotEmpty) p['url_candidature'] = _url.text.trim();
    if (_instr.text.trim().isNotEmpty) {
      p['instructions_candidature'] = _instr.text.trim();
    }
    return p;
  }

  Future<void> _publish() async {
    final payload = _buildPayload();
    if (widget.initialOffer != null) {
      await ref
          .read(updateOfferControllerProvider.notifier)
          .submit(widget.initialOffer!.id, payload);
    } else {
      await ref.read(createOfferControllerProvider.notifier).submit(payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialOffer != null;
    final state = isEdit
        ? ref.watch(updateOfferControllerProvider)
        : ref.watch(createOfferControllerProvider);

    // Documents requis par defaut, traduits selon la langue active.
    if (!_documentsInitialized) {
      _documentsInitialized = true;
      _documents.addAll([
        context.tr('offer.doc_cv'),
        context.tr('offer.doc_cover_letter'),
      ]);
    }

    void onDone(AsyncValue<bool> next) {
      if (next.isLoading) return;
      if (next.hasError) {
        _toast(next.error.toString());
      } else if (next.hasValue && next.value == true) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(isEdit
                  ? context.tr('offer.updated')
                  : context.tr('offer.published')),
              backgroundColor: AppColors.success));
        if (context.canPop()) context.pop();
      }
    }

    if (isEdit) {
      ref.listen(updateOfferControllerProvider, (_, next) => onDone(next));
    } else {
      ref.listen(createOfferControllerProvider, (_, next) => onDone(next));
    }

    return Scaffold(
      appBar: AppBar(title: const BrandLogo(BrandWorld.hire, height: 24), centerTitle: false),
      body: Column(
        children: [
          _StepHeader(step: _step),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                _buildOffreStep(),
                _buildCandidatureStep(),
                _buildPreviewStep(),
              ],
            ),
          ),
          _NavBar(
            step: _step,
            isLoading: state.isLoading,
            onBack: _step > 0 ? () => setState(() => _step--) : null,
            onNext: () {
              if (_step == 0 && !_validateOffre()) return;
              if (_step < 2) setState(() => _step++);
            },
            onPublish: _publish,
          ),
        ],
      ),
    );
  }

  // ---------- Step 0 : Offre ----------
  Widget _buildOffreStep() {
    final cats = ref.watch(categoriesProvider);
    final exps = ref.watch(experienceLevelsProvider);
    final contrats = ref.watch(contractTypesProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _field(_titre, context.tr('offer.title_label')),
        const SizedBox(height: 14),
        cats.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) =>
              Text(context.tr('offer.categories_unavailable'), style: _err),
          data: (list) => DropdownButtonFormField<int>(
            value: _categorieId,
            isExpanded: true,
            decoration:
                InputDecoration(labelText: context.tr('offer.category')),
            items: list
                .map((c) => DropdownMenuItem<int>(
                      value: c['id'] is int ? c['id'] as int : int.tryParse('${c['id']}'),
                      child: Text('${c['nom'] ?? c['name'] ?? ''}'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _categorieId = v),
          ),
        ),
        const SizedBox(height: 14),
        _field(_fonction, context.tr('offer.function')),
        const SizedBox(height: 14),
        exps.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) =>
              Text(context.tr('offer.levels_unavailable'), style: _err),
          data: (list) => DropdownButtonFormField<String>(
            value: _experience,
            isExpanded: true,
            decoration:
                InputDecoration(labelText: context.tr('offer.experience')),
            items: list
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _experience = v),
          ),
        ),
        const SizedBox(height: 14),
        contrats.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) =>
              Text(context.tr('offer.contracts_unavailable'), style: _err),
          data: (list) => DropdownButtonFormField<String>(
            value: _typeContrat,
            isExpanded: true,
            decoration:
                InputDecoration(labelText: context.tr('offer.contract_type')),
            items: list
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _typeContrat = v),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _field(_ville, context.tr('offer.city'))),
          const SizedBox(width: 12),
          Expanded(child: _field(_pays, context.tr('offer.country'))),
        ]),
        const SizedBox(height: 14),
        _field(_lieu, context.tr('offer.workplace')),
        const SizedBox(height: 14),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final d = await showDatePicker(
              context: context,
              initialDate: now,
              firstDate: now,
              lastDate: DateTime(now.year + 2),
            );
            if (d != null) {
              setState(() => _dateLimite =
                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: context.tr('offer.deadline'),
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(_dateLimite.isEmpty
                ? context.tr('offer.pick_date')
                : _dateLimite),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('offer.show_salary')),
          value: _afficherSalaire,
          activeColor: AppColors.primary,
          onChanged: (v) => setState(() => _afficherSalaire = v),
        ),
        if (_afficherSalaire)
          Row(children: [
            Expanded(
                child: _field(_remMin, context.tr('offer.salary_min'),
                    number: true)),
            const SizedBox(width: 12),
            Expanded(
                child: _field(_remMax, context.tr('offer.salary_max'),
                    number: true)),
          ]),
        const SizedBox(height: 14),
        _richField(_desc, context.tr('offer.description')),
        const SizedBox(height: 14),
        _richField(_resp, context.tr('offer.responsibilities')),
        const SizedBox(height: 14),
        _richField(_exig, context.tr('offer.requirements')),
      ],
    );
  }

  // ---------- Step 1 : Candidature ----------
  Widget _buildCandidatureStep() {
    final skills = ref.watch(skillsProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _field(_email, context.tr('offer.application_email')),
        const SizedBox(height: 14),
        _field(_url, context.tr('offer.application_url')),
        const SizedBox(height: 14),
        _field(_instr, context.tr('offer.application_instructions'), lines: 3),
        const SizedBox(height: 20),
        Text(context.tr('offer.required_documents'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _documents
              .map((d) => Chip(
                    label: Text(d),
                    onDeleted: () => setState(() => _documents.remove(d)),
                  ))
              .toList(),
        ),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _docInput,
              decoration: InputDecoration(
                  labelText: context.tr('offer.add_document')),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: () {
              final v = _docInput.text.trim();
              if (v.isNotEmpty && !_documents.contains(v)) {
                setState(() {
                  _documents.add(v);
                  _docInput.clear();
                });
              }
            },
          ),
        ]),
        const SizedBox(height: 20),
        Text(context.tr('offer.skills_wanted'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 8),
        skills.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) =>
              Text(context.tr('offer.skills_unavailable'), style: _err),
          data: (list) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: list.map((s) {
              final id = s['id'] is int ? s['id'] as int : int.tryParse('${s['id']}');
              if (id == null) return const SizedBox.shrink();
              final selected = _skills.contains(id);
              return FilterChip(
                label: Text('${s['nom'] ?? s['name'] ?? ''}'),
                selected: selected,
                selectedColor: AppColors.primary.withOpacity(0.15),
                checkmarkColor: AppColors.primary,
                onSelected: (v) => setState(() {
                  if (v) {
                    _skills.add(id);
                  } else {
                    _skills.remove(id);
                  }
                }),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ---------- Step 2 : Apercu ----------
  Widget _buildPreviewStep() {
    final pro = ref.watch(authControllerProvider).valueOrNull?.professionnelRaw;
    final entreprise = (pro?['nom_entreprise'] ?? '').toString();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  _titre.text.trim().isEmpty
                      ? context.tr('offer.title_placeholder')
                      : _titre.text.trim(),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
              if (entreprise.isNotEmpty)
                Text(entreprise, style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              _recap(context.tr('offer.recap_contract'), _typeContrat),
              _recap(
                  context.tr('offer.recap_location'),
                  [_ville.text, _pays.text]
                      .where((e) => e.trim().isNotEmpty)
                      .join(', ')),
              _recap(context.tr('offer.recap_experience'), _experience),
              if (_afficherSalaire)
                _recap(context.tr('offer.recap_salary'),
                    '${_remMin.text} - ${_remMax.text}'.trim()),
              if (_dateLimite.isNotEmpty)
                _recap(context.tr('offer.recap_deadline'), _dateLimite),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _previewSection(context.tr('offer.description'), _desc.text),
        _previewSection(context.tr('offer.responsibilities'), _resp.text),
        _previewSection(context.tr('offer.requirements'), _exig.text),
        const SizedBox(height: 8),
        Text(context.tr('offer.preview_check'),
            style: const TextStyle(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _recap(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _previewSection(String title, String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
        const SizedBox(height: 6),
        HtmlText(textToHtml(text)),
      ],
    );
  }

  // ---------- helpers ----------
  TextStyle get _err => const TextStyle(color: AppColors.error, fontSize: 13);

  Widget _field(TextEditingController c, String label,
      {bool number = false, int lines = 1}) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      maxLines: lines,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _richField(TextEditingController c, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: c,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: label,
            alignLabelWithHint: true,
            helperText: context.tr('offer.rich_hint'),
          ),
        ),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.tr('offer.step_offer'),
      context.tr('offer.step_application'),
      context.tr('offer.step_preview'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == step;
          final done = i < step;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: (active || done)
                      ? AppColors.primary
                      : AppColors.border,
                  child: done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text('${i + 1}',
                          style: TextStyle(
                              fontSize: 12,
                              color: active ? Colors.white : AppColors.textMuted)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(labels[i],
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                          color: active ? AppColors.navy : AppColors.textMuted)),
                ),
                if (i < labels.length - 1)
                  Container(width: 12, height: 1, color: AppColors.border),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.step,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
    required this.onPublish,
  });
  final int step;
  final bool isLoading;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final Future<void> Function() onPublish;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(
          children: [
            if (onBack != null)
              Expanded(
                child: OutlinedButton(
                    onPressed: isLoading ? null : onBack,
                    child: Text(context.tr('common.back'))),
              ),
            if (onBack != null) const SizedBox(width: 12),
            Expanded(
              child: step < 2
                  ? ElevatedButton(
                      onPressed: onNext,
                      child: Text(context.tr('common.next')))
                  : ElevatedButton(
                      onPressed: isLoading ? null : () => onPublish(),
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : Text(context.tr('offer.publish')),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
