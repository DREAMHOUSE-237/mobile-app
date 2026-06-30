import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/publication_notifier.dart';

// ══════════════════════════════════════════════════════════════════════════════
// STEP 1 — Description principale
// Équivalent de l'étape 1 dans Publication.jsx
// ══════════════════════════════════════════════════════════════════════════════
class PublishStep1 extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const PublishStep1({super.key, required this.onNext});

  @override
  ConsumerState<PublishStep1> createState() => _PublishStep1State();
}

class _PublishStep1State extends ConsumerState<PublishStep1> {
  final _formKey   = GlobalKey<FormState>();
  late final _titreCtrl    = TextEditingController();
  late final _prixCtrl     = TextEditingController();
  late final _superfCtrl   = TextEditingController();
  late final _piecesCtrl   = TextEditingController();
  late final _descCtrl     = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pré-remplir depuis le state si retour arrière
    final s = ref.read(publicationNotifierProvider);
    _titreCtrl.text  = s.titre;
    _prixCtrl.text   = s.prix;
    _superfCtrl.text = s.superficie;
    _piecesCtrl.text = s.nbPieces;
    _descCtrl.text   = s.description;
  }

  @override
  void dispose() {
    _titreCtrl.dispose(); _prixCtrl.dispose();
    _superfCtrl.dispose(); _piecesCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(publicationNotifierProvider.notifier).updateStep1(
      titre:       _titreCtrl.text.trim(),
      prix:        _prixCtrl.text.trim(),
      superficie:  _superfCtrl.text.trim(),
      nbPieces:    _piecesCtrl.text.trim(),
      description: _descCtrl.text.trim(),
    );
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('DESCRIPTION PRINCIPALE', style: AppTextStyles.label),
          const SizedBox(height: 16),

          // Titre
          _FormField(
            ctrl: _titreCtrl,
            label: 'Titre du bien',
            hint: 'Studio moderne...',
            icon: Icons.title_rounded,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
          ),
          const SizedBox(height: 14),

          // Prix + Superficie
          Row(children: [
            Expanded(child: _FormField(
              ctrl: _prixCtrl,
              label: 'Prix du loyer (FCFA)',
              hint: '150 000',
              icon: Icons.attach_money_rounded,
              keyboard: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Prix requis';
                final val = double.tryParse(v.trim());
                if (val == null || val <= 0) return 'Prix invalide';
                return null;
              },
            )),
            const SizedBox(width: 12),
            // FIX #1 : superficie était sans validator → le backend @Positive rejetait 0
            Expanded(child: _FormField(
              ctrl: _superfCtrl,
              label: 'Superficie (m²)',
              hint: '100',
              icon: Icons.straighten_rounded,
              keyboard: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Superficie requise';
                final val = double.tryParse(v.trim());
                if (val == null || val <= 0) return 'Doit être > 0';
                return null;
              },
            )),
          ]),
          const SizedBox(height: 14),

          // FIX #2 : nbrePiece validait uniquement "non vide" → le backend @Min(1) rejetait 0
          _FormField(
            ctrl: _piecesCtrl,
            label: 'Nombre de pièces',
            hint: '5',
            icon: Icons.meeting_room_outlined,
            keyboard: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Requis';
              final val = int.tryParse(v.trim());
              if (val == null || val < 1) return 'Minimum 1 pièce';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // FIX #3 : description n'avait pas de validator → le backend @NotBlank/@Size rejetait la valeur vide
          const Text('Description', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descCtrl,
            minLines: 4,
            maxLines: 8,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Description requise';
              if (v.trim().length < 10) return 'Description trop courte (min. 10 caractères)';
              return null;
            },
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Détails importants...',
              hintStyle: const TextStyle(
                  fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.teal, width: 2)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),

          const SizedBox(height: 32),

          // Bouton suivant
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Suivant'),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Champ de formulaire réutilisable ──────────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboard;
  final String? Function(String?)? validator;

  const _FormField({
    required this.ctrl, required this.label,
    required this.hint, required this.icon,
    this.keyboard = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.label),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        validator: validator,
        style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted),
          prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.teal, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }
}