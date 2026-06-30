import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/data/bien_model.dart';
import '../../detail/data/detail_provider.dart';
import '../data/publication_form_state.dart';
import '../data/publication_notifier.dart';
import '../../map/widgets/location_picker.dart';

// ══════════════════════════════════════════════════════════════════════════════
// EDIT PUBLICATION SCREEN — Équivalent de ModificationImo.jsx
// Route : /modif/:id
// ══════════════════════════════════════════════════════════════════════════════
class EditPublicationScreen extends ConsumerWidget {
  final String id;
  const EditPublicationScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bienAsync = ref.watch(bienDetailProvider(id));

    return bienAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Modifier l\'annonce')),
        body: Center(child: Text('Erreur : $e')),
      ),
      data: (bien) => _EditForm(bien: bien),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  final BienModel bien;
  const _EditForm({required this.bien});

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  late final _titreCtrl  = TextEditingController(text: widget.bien.titre);
  late final _prixCtrl   = TextEditingController(
      text: widget.bien.prix.toInt().toString());
  late final _piecesCtrl = TextEditingController(
      text: widget.bien.nbPieces.toString());
  late final _superfCtrl = TextEditingController(
      text: widget.bien.superficie?.toInt().toString() ?? '');
  late final _descCtrl   = TextEditingController(
      text: widget.bien.description ?? '');
  late final _villeCtrl  = TextEditingController(text: widget.bien.ville);
  late final _quartierCtrl = TextEditingController(
      text: widget.bien.quartier ?? '');

  late String _typePublication;
  late String _typeBien;
  late String _categorie;
  late String _region;

  final List<File> _newPhotos = [];
  double? _latitude;
  double? _longitude;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _typePublication = PublicationConstants.typesPublication
        .contains(widget.bien.typePublication)
        ? widget.bien.typePublication : 'LOCATION';
    _typeBien = PublicationConstants.typesBien
        .contains(widget.bien.typeBien)
        ? widget.bien.typeBien : 'APPARTEMENT';
    _categorie = PublicationConstants.categories
        .contains(widget.bien.categorie)
        ? widget.bien.categorie : 'MEUBLE';
    // Convertir la région stockée vers la valeur enum si nécessaire
    final rawRegion = widget.bien.region ?? '';
    _region = PublicationConstants.regionKeys.contains(rawRegion)
        ? rawRegion
        : PublicationConstants.normalizeRegion(rawRegion);
    _latitude  = widget.bien.latitude;
    _longitude = widget.bien.longitude;
  }

  @override
  void dispose() {
    _titreCtrl.dispose(); _prixCtrl.dispose(); _piecesCtrl.dispose();
    _superfCtrl.dispose(); _descCtrl.dispose(); _villeCtrl.dispose();
    _quartierCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final imgs = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (imgs.isEmpty) return;
    setState(() => _newPhotos.addAll(imgs.map((x) => File(x.path))));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final payload = {
        'titreBien':             _titreCtrl.text.trim(),
        'prix':                  double.tryParse(_prixCtrl.text) ?? 0,
        'nbrePiece':             int.tryParse(_piecesCtrl.text) ?? 0,
        'superfie':              double.tryParse(_superfCtrl.text) ?? 0,
        'description':           _descCtrl.text.trim(),
        'typePublication':       _typePublication,
        'typeBienImmobilier':    _typeBien,
        'categorie':   _categorie,
        'adresse': {
          'region':    _region,
          'ville':     _villeCtrl.text.trim(),
          'quartier':  _quartierCtrl.text.trim(),
          'lattitude': _latitude ?? 0.0,
          'longitude': _longitude ?? 0.0,
        },
      };

      await ref.read(publicationUpdateProvider).update(widget.bien.id, payload);

      if (!mounted) return;
      ref.invalidate(bienDetailProvider(widget.bien.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annonce mise à jour !'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Modifier l\'annonce'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(_saving ? 'Sauvegarde...' : 'Enregistrer'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Section description ──────────────────────────────────────
          const _SectionHeader(
              icon: Icons.description_outlined, label: 'DESCRIPTION PRINCIPALE'),
          const SizedBox(height: 14),

          _EditField(ctrl: _titreCtrl,  label: 'Titre',
              icon: Icons.title_rounded),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(child: _EditField(ctrl: _piecesCtrl, label: 'Pièces',
                icon: Icons.meeting_room_outlined,
                keyboard: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _EditField(ctrl: _superfCtrl, label: 'Superficie (m²)',
                icon: Icons.straighten_rounded,
                keyboard: TextInputType.number)),
          ]),
          const SizedBox(height: 12),

          _EditField(ctrl: _prixCtrl, label: 'Prix (FCFA)',
              icon: Icons.attach_money_rounded,
              keyboard: TextInputType.number),
          const SizedBox(height: 12),

          const Text('Description', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descCtrl,
            minLines: 3, maxLines: 6,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
            decoration: _inputDeco('Détails...'),
          ),

          const SizedBox(height: 20),

          // ── Section médias ───────────────────────────────────────────
          const _SectionHeader(
              icon: Icons.photo_library_outlined, label: 'MÉDIAS ET DÉTAILS'),
          const SizedBox(height: 14),

          // Photos existantes
          if (widget.bien.photos.isNotEmpty) ...[
            const Text('Photos du bien', style: AppTextStyles.label),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.bien.photos.length,
                itemBuilder: (_, i) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: widget.bien.photos[i],
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.bgTealLight),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.bgTealLight),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Nouvelles photos
          if (_newPhotos.isNotEmpty) ...[
            const Text('Nouvelles photos', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _newPhotos.asMap().entries.map((e) => Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(e.value,
                      width: 70, height: 70, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 3, right: 3,
                  child: GestureDetector(
                    onTap: () => setState(() => _newPhotos.removeAt(e.key)),
                    child: Container(
                      width: 18, height: 18,
                      decoration: const BoxDecoration(
                          color: AppColors.error, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 11),
                    ),
                  ),
                ),
              ])).toList(),
            ),
            const SizedBox(height: 8),
          ],

          TextButton.icon(
            onPressed: _pickPhotos,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: const Text('Ajouter des photos'),
            style: TextButton.styleFrom(foregroundColor: AppColors.teal),
          ),

          const SizedBox(height: 12),

          // Type + Catégorie
          Row(children: [
            Expanded(child: _EditDropdown(
              label: 'TYPE PUBLICATION',
              value: _typePublication,
              items: PublicationConstants.typesPublication,
              onChanged: (v) => setState(() => _typePublication = v!),
            )),
            const SizedBox(width: 12),
            Expanded(child: _EditDropdown(
              label: 'CATÉGORIE',
              value: _categorie,
              items: PublicationConstants.categories,
              onChanged: (v) => setState(() => _categorie = v!),
            )),
          ]),
          const SizedBox(height: 12),
          _EditDropdown(
            label: 'TYPE BIEN IMMOBILIER',
            value: _typeBien,
            items: PublicationConstants.typesBien,
            onChanged: (v) => setState(() => _typeBien = v!),
          ),

          const SizedBox(height: 20),

          // ── Localisation ─────────────────────────────────────────────
          const _SectionHeader(
              icon: Icons.location_on_outlined, label: 'LOCALISATION'),
          const SizedBox(height: 14),

          Row(children: [
            Expanded(child: _EditDropdown(
              label: 'RÉGION',
              value: PublicationConstants.regionKeys.contains(_region)
                  ? _region : PublicationConstants.regionKeys.first,
              items: PublicationConstants.regionKeys,
              itemLabels: PublicationConstants.regionLabels,
              onChanged: (v) => setState(() => _region = v!),
            )),
            const SizedBox(width: 12),
            Expanded(child: _EditField(
                ctrl: _villeCtrl, label: 'Ville',
                icon: Icons.location_city_outlined)),
          ]),
          const SizedBox(height: 12),
          _EditField(ctrl: _quartierCtrl, label: 'Quartier',
              icon: Icons.place_outlined),
          const SizedBox(height: 14),

          // Carte
          LocationPicker(
            initialLat: _latitude,
            initialLng: _longitude,
            onLocationSelected: (lat, lng) {
              setState(() { _latitude = lat; _longitude = lng; });
            },
          ),

          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.teal, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

// ── Widgets réutilisables de la page édition ──────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.teal),
      const SizedBox(width: 8),
      Text(label, style: AppTextStyles.label),
    ]);
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType keyboard;

  const _EditField({
    required this.ctrl, required this.label, required this.icon,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.label),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.teal, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }
}

class _EditDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Map<String, String>? itemLabels; // optionnel : clé=valeur backend, valeur=label
  final void Function(String?) onChanged;

  const _EditDropdown({
    required this.label, required this.value,
    required this.items, required this.onChanged,
    this.itemLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.label),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: value,
        items: items.map((i) => DropdownMenuItem(
          value: i,
          child: Text(
            itemLabels?[i] ?? i,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
          ),
        )).toList(),
        onChanged: onChanged,
        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.dark),
        dropdownColor: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.teal),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.teal, width: 2)),
        ),
      ),
    ]);
  }
}
