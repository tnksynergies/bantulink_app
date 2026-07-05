import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../freelancers/data/upload_file.dart';
import '../application/market_providers.dart';
import '../application/vendor_providers.dart';
import '../data/models/product.dart';
import 'market_colors.dart';

/// Formulaire produit vendeur : creation (initialProduct == null) ou edition.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.initialProduct});
  final Product? initialProduct;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  int? _categorieId;
  final List<UploadFile> _newImages = [];
  bool _submitting = false;

  bool get _isEdit => widget.initialProduct != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;
    if (p != null) {
      _nomCtrl.text = p.nom ?? '';
      _descCtrl.text = p.description ?? '';
      _prixCtrl.text = p.prix?.toString() ?? '';
      _stockCtrl.text = p.stockQtte?.toString() ?? '';
      _categorieId = p.categorie?.id;
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descCtrl.dispose();
    _prixCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(limit: 6);
    if (picked.isEmpty) return;
    final files = <UploadFile>[];
    for (final x in picked) {
      files.add(await UploadFile.fromXFile(x));
    }
    setState(() => _newImages.addAll(files));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categorieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${context.tr('market.category')} : ${context.tr('common.required')}'),
          backgroundColor: AppColors.error));
      return;
    }
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_isEdit) {
        await ref
            .read(updateProductControllerProvider(widget.initialProduct!.id)
                .notifier)
            .submit(
              nom: _nomCtrl.text.trim(),
              description: _descCtrl.text.trim(),
              prix: num.tryParse(_prixCtrl.text.trim()),
              stockQtte: int.tryParse(_stockCtrl.text.trim()),
              categorieId: _categorieId,
              newImages: _newImages,
            );
        final err = ref
            .read(updateProductControllerProvider(widget.initialProduct!.id))
            .error;
        if (err != null) throw err;
        messenger.showSnackBar(SnackBar(
            content: Text(context.mounted
                ? context.tr('market.product_updated')
                : ''),
            backgroundColor: MarketColors.primary));
      } else {
        await ref.read(createProductControllerProvider.notifier).submit(
              nom: _nomCtrl.text.trim(),
              prix: num.tryParse(_prixCtrl.text.trim()) ?? 0,
              stockQtte: int.tryParse(_stockCtrl.text.trim()) ?? 0,
              categorieId: _categorieId!,
              description: _descCtrl.text.trim().isEmpty
                  ? null
                  : _descCtrl.text.trim(),
              images: _newImages,
            );
        messenger.showSnackBar(SnackBar(
            content: Text(context.mounted
                ? context.tr('market.product_created')
                : ''),
            backgroundColor: MarketColors.primary));
      }
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/vendeur/dashboard');
      }
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncCategories = ref.watch(productCategoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit
            ? context.tr('market.edit_product')
            : context.tr('market.new_product')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomCtrl,
              decoration: InputDecoration(
                  labelText: '${context.tr('market.product_name')} *'),
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? context.tr('common.required')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.tr('market.description'),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prixCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: '${context.tr('market.price')} *'),
                    validator: (v) {
                      final n = num.tryParse(v?.trim() ?? '');
                      if (n == null || n < 0) {
                        return context.tr('common.required');
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: '${context.tr('market.stock')} *'),
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n < 0) {
                        return context.tr('common.required');
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            asyncCategories.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) =>
                  Text('$e', style: const TextStyle(color: AppColors.error)),
              data: (cats) => DropdownButtonFormField<int>(
                initialValue: _categorieId,
                isExpanded: true,
                decoration: InputDecoration(
                    labelText: '${context.tr('market.category')} *'),
                items: cats
                    .map((c) => DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.nom),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _categorieId = v),
              ),
            ),
            const SizedBox(height: 20),

            // Images existantes (edition) — apercu seul
            if (_isEdit && widget.initialProduct!.imageUrls.isNotEmpty) ...[
              Text(context.tr('market.images'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.initialProduct!.imageUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(
                            widget.initialProduct!.imageUrls[i]),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Nouvelles images
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(
                  '${context.tr('market.add_images')} (${_newImages.length})'),
            ),
            if (_newImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _newImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.memory(_newImages[i].bytes,
                            fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _newImages.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                  : Text(_isEdit
                      ? context.tr('market.save_product')
                      : context.tr('market.publish')),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
