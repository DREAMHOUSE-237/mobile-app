import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/publication_form_state.dart';
import '../../data/publication_notifier.dart';

// ══════════════════════════════════════════════════════════════════════════════
// STEP 2 — Médias & Détails
// Le numéro de paiement a été retiré de cette étape.
// Il est désormais saisi dans le modal de paiement au moment de la soumission
// (étape 3 → "Passer au paiement"), exactement comme dans Publication.jsx.
// ══════════════════════════════════════════════════════════════════════════════
class PublishStep2 extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onPrev;
  const PublishStep2({super.key, required this.onNext, required this.onPrev});

  @override
  ConsumerState<PublishStep2> createState() => _PublishStep2State();
}

class _PublishStep2State extends ConsumerState<PublishStep2> {
  List<File> _photos    = [];
  List<File> _documents = [];
  late String _typePublication;
  late String _typeBien;
  late String _categorie;

  @override
  void initState() {
    super.initState();
    final s = ref.read(publicationNotifierProvider);
    _photos          = List.from(s.photos);
    _documents       = List.from(s.documents);
    _typePublication = s.typePublication;
    _typeBien        = s.typeBien;
    _categorie       = s.categorie;
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) return;
    setState(() => _photos.addAll(images.map((x) => File(x.path))));
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (img == null) return;
    setState(() => _documents.add(File(img.path)));
  }

  void _next() {
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ajoutez au moins une photo du logement')),
      );
      return;
    }
    ref.read(publicationNotifierProvider.notifier).updateStep2(
      photos:          _photos,
      documents:       _documents,
      typePublication: _typePublication,
      typeBien:        _typeBien,
      categorie:       _categorie,
    );
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Photos du logement ─────────────────────────────────────────
        const Text('PHOTOS DU LOGEMENT', style: AppTextStyles.label),
        const SizedBox(height: 10),
        _PhotoGrid(
          photos: _photos,
          onAdd: _pickPhotos,
          onRemove: (i) => setState(() => _photos.removeAt(i)),
        ),

        const SizedBox(height: 20),

        // ── Documents du logement ──────────────────────────────────────
        const Text('PHOTOS DES DOCUMENTS DU LOGEMENT',
            style: AppTextStyles.label),
        const SizedBox(height: 10),
        _DocumentGrid(
          documents: _documents,
          onAdd: _pickDocument,
          onRemove: (i) => setState(() => _documents.removeAt(i)),
        ),

        const SizedBox(height: 20),

        // ── Type publication + Type bien ───────────────────────────────
        Row(children: [
          Expanded(child: _DropdownField(
            label: 'Type de Publication',
            value: _typePublication,
            items: PublicationConstants.typesPublication,
            onChanged: (v) => setState(() => _typePublication = v!),
          )),
          const SizedBox(width: 12),
          Expanded(child: _DropdownField(
            label: 'Type Bien Immobilier',
            value: _typeBien,
            items: PublicationConstants.typesBien,
            onChanged: (v) => setState(() => _typeBien = v!),
          )),
        ]),
        const SizedBox(height: 14),

        // ── Catégorie ──────────────────────────────────────────────────
        _DropdownField(
          label: 'Catégorie du Bien',
          value: _categorie,
          items: PublicationConstants.categories,
          onChanged: (v) => setState(() => _categorie = v!),
        ),

        const SizedBox(height: 32),

        // ── Boutons nav ────────────────────────────────────────────────
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onPrev,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Précédent'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Suivant'),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Grille photos ──────────────────────────────────────────────────────────────
class _PhotoGrid extends StatelessWidget {
  final List<File> photos;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _PhotoGrid({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...photos.asMap().entries.map((e) => _PhotoTile(
              file: e.value,
              onRemove: () => onRemove(e.key),
            )),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.bgTealLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.teal.withOpacity(0.3),
                  style: BorderStyle.solid),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: AppColors.teal, size: 24),
                SizedBox(height: 2),
                Text('Ajouter',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _PhotoTile({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
      ),
      Positioned(
        top: 4,
        right: 4,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
                color: AppColors.error, shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded,
                color: Colors.white, size: 12),
          ),
        ),
      ),
    ]);
  }
}

// ── Grille documents ───────────────────────────────────────────────────────────
class _DocumentGrid extends StatelessWidget {
  final List<File> documents;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _DocumentGrid({
    required this.documents,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...documents.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              const Icon(Icons.insert_drive_file_outlined,
                  size: 16, color: AppColors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.value.path.split('/').last,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.dark),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => onRemove(e.key),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.error),
              ),
            ]),
          )),
      TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('+ Ajouter'),
        style: TextButton.styleFrom(foregroundColor: AppColors.teal),
      ),
    ]);
  }
}

// ── Dropdown réutilisable ──────────────────────────────────────────────────────
class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.label),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: value,
        items: items
            .map((i) => DropdownMenuItem(
                  value: i,
                  child: Text(i,
                      style: const TextStyle(
                          fontFamily: 'Inter', fontSize: 12)),
                ))
            .toList(),
        onChanged: onChanged,
        style: const TextStyle(
            fontFamily: 'Inter', fontSize: 13, color: AppColors.dark),
        dropdownColor: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.teal, size: 20),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.borderLight)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.borderLight)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.teal, width: 2)),
        ),
      ),
    ]);
  }
}
