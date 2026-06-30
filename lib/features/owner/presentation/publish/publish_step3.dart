import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/theme/app_theme.dart';
import '../../data/publication_form_state.dart';
import '../../data/publication_notifier.dart';
import '../../../../features/map/widgets/location_picker.dart';

// ══════════════════════════════════════════════════════════════════════════════
// STEP 3 — Position géographique
// FIX : LocationPicker reçoit une ValueKey basée sur les coordonnées du state.
//       Quand l'utilisateur commence UNE NOUVELLE publication (lat/lng = null),
//       la key change → Flutter reconstruit le widget → initState se réexécute
//       → la carte se réinitialise sur Yaoundé et n'affiche plus l'ancienne position.
// ══════════════════════════════════════════════════════════════════════════════
class PublishStep3 extends ConsumerStatefulWidget {
  final VoidCallback onRequestPayment;
  final VoidCallback onPrev;
  const PublishStep3({
    super.key,
    required this.onRequestPayment,
    required this.onPrev,
  });

  @override
  ConsumerState<PublishStep3> createState() => _PublishStep3State();
}

class _PublishStep3State extends ConsumerState<PublishStep3> {
  late String _region;
  late final _villeCtrl    = TextEditingController();
  late final _quartierCtrl = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _geoLoading = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(publicationNotifierProvider);
    _region   = s.region.isEmpty ? PublicationConstants.regionKeys.first : s.region;
    _villeCtrl.text    = s.ville;
    _quartierCtrl.text = s.quartier;
    _latitude  = s.latitude;
    _longitude = s.longitude;
  }

  @override
  void dispose() {
    _villeCtrl.dispose();
    _quartierCtrl.dispose();
    super.dispose();
  }

  // ── Reverse geocoding Nominatim ──────────────────────────────────────────
  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() => _geoLoading = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json&lat=$lat&lon=$lng&addressdetails=1',
      );
      final resp = await http.get(url, headers: {
        'User-Agent': 'DreamHouse237/1.0',
      }).timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final ville = addr['city'] ?? addr['town'] ??
              addr['village'] ?? addr['county'] ?? '';
          final quartier = addr['suburb'] ?? addr['neighbourhood'] ??
              addr['quarter'] ?? '';
          final stateRaw = addr['state'] ?? addr['region'] ?? '';
          final regionEnum = PublicationConstants.normalizeRegion(stateRaw);

          setState(() {
            if (ville.isNotEmpty && _villeCtrl.text.isEmpty) {
              _villeCtrl.text = ville;
            }
            if (quartier.isNotEmpty && _quartierCtrl.text.isEmpty) {
              _quartierCtrl.text = quartier;
            }
            if (regionEnum.isNotEmpty) {
              _region = regionEnum;
            }
          });
        }
      }
    } catch (_) {
      // Silencieux — remplissage manuel possible
    } finally {
      if (mounted) setState(() => _geoLoading = false);
    }
  }

  void _goToPayment() {
    if (_villeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La ville est requise')),
      );
      return;
    }
    ref.read(publicationNotifierProvider.notifier).updateStep3(
      region:    _region,
      ville:     _villeCtrl.text.trim(),
      quartier:  _quartierCtrl.text.trim(),
      latitude:  _latitude,
      longitude: _longitude,
    );
    widget.onRequestPayment();
  }

  @override
  Widget build(BuildContext context) {
    // FIX : la key encode les coordonnées actuelles du state.
    // Si l'utilisateur arrive sur une nouvelle publication (lat/lng null),
    // la key est différente de celle de la publication précédente, ce qui
    // force Flutter à recréer LocationPicker et réinitialiser la carte.
    final s = ref.watch(publicationNotifierProvider);
    final mapKey = ValueKey('map_${s.latitude}_${s.longitude}');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Région ──────────────────────────────────────────────────────────
        Row(children: [
          const Icon(Icons.flag_outlined, size: 14, color: AppColors.teal),
          const SizedBox(width: 6),
          const Text('RÉGION', style: AppTextStyles.label),
          if (_geoLoading) ...const [
            SizedBox(width: 8),
            SizedBox(
              width: 12, height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
            ),
          ],
        ]),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: PublicationConstants.regionKeys.contains(_region)
              ? _region : PublicationConstants.regionKeys.first,
          items: PublicationConstants.regionKeys.map((key) => DropdownMenuItem(
            value: key,
            child: Text(
              '${PublicationConstants.regionLabels[key]}',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
            ),
          )).toList(),
          onChanged: (v) => setState(() => _region = v!),
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.dark),
          dropdownColor: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.teal),
          decoration: _inputDeco(),
        ),
        const SizedBox(height: 14),

        // ── Ville ──────────────────────────────────────────────────────────
        const Row(children: [
          Icon(Icons.location_city_outlined, size: 14, color: AppColors.teal),
          SizedBox(width: 6),
          Text('VILLE', style: AppTextStyles.label),
        ]),
        const SizedBox(height: 8),
        TextFormField(
          controller: _villeCtrl,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
          decoration: _inputDeco(hint: 'Ex: Yaoundé, Douala...'),
        ),
        const SizedBox(height: 14),

        // ── Quartier ───────────────────────────────────────────────────────
        const Row(children: [
          Icon(Icons.place_outlined, size: 14, color: AppColors.teal),
          SizedBox(width: 6),
          Text('QUARTIER', style: AppTextStyles.label),
        ]),
        const SizedBox(height: 8),
        TextFormField(
          controller: _quartierCtrl,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
          decoration: _inputDeco(hint: 'Ex: Bastos, Bonapriso...'),
        ),
        const SizedBox(height: 20),

        // ── Carte interactive ──────────────────────────────────────────────
        const Text('LOCALISATION PRÉCISE (CLIQUEZ SUR LA CARTE)',
            style: AppTextStyles.label),
        const SizedBox(height: 10),
        // FIX : ValueKey force la reconstruction du widget quand les coords changent
        LocationPicker(
          key: mapKey,
          initialLat: _latitude,
          initialLng: _longitude,
          onLocationSelected: (lat, lng) {
            setState(() { _latitude = lat; _longitude = lng; });
            _reverseGeocode(lat, lng);
          },
        ),

        const SizedBox(height: 32),

        // ── Boutons ────────────────────────────────────────────────────────
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
              onPressed: _goToPayment,
              icon: const Icon(Icons.credit_card_rounded, size: 18),
              label: const Text('Passer au paiement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 20),
      ]),
    );
  }

  InputDecoration _inputDeco({String? hint}) => InputDecoration(
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