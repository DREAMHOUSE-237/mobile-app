import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// LOCATION PICKER — Carte interactive avec recherche Nominatim
// FIX : tuiles Google Maps (roadmap) pour un rendu identique à la version web
// ui.Path utilisé pour éviter le conflit avec go_router Path
// ══════════════════════════════════════════════════════════════════════════════
class LocationPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final void Function(double lat, double lng) onLocationSelected;

  const LocationPicker({
    super.key,
    this.initialLat,
    this.initialLng,
    required this.onLocationSelected,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LatLng _selected = const LatLng(3.848, 11.502); // Yaoundé par défaut
  final MapController _mapCtrl   = MapController();
  final _searchCtrl = TextEditingController();
  List<_NominatimResult> _suggestions = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selected = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=5&countrycodes=cm',
      );
      final resp = await http.get(url, headers: {
        'User-Agent': 'DreamHouse237/1.0',
      });
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        setState(() {
          _suggestions = data.map((e) => _NominatimResult(
            displayName: e['display_name'] ?? '',
            lat: double.tryParse(e['lat'] ?? '0') ?? 0,
            lng: double.tryParse(e['lon'] ?? '0') ?? 0,
          )).toList();
        });
      }
    } catch (_) {
      setState(() => _suggestions = []);
    } finally {
      setState(() => _searching = false);
    }
  }

  void _selectSuggestion(_NominatimResult result) {
    final pos = LatLng(result.lat, result.lng);
    setState(() {
      _selected    = pos;
      _suggestions = [];
      _searchCtrl.text = result.shortName;
    });
    _mapCtrl.move(pos, 15);
    widget.onLocationSelected(result.lat, result.lng);
  }

  void _onMapTap(TapPosition _, LatLng pos) {
    setState(() => _selected = pos);
    widget.onLocationSelected(pos.latitude, pos.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Barre de recherche ────────────────────────────────────────
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _searchCtrl,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Rechercher un lieu (ex: Bastos, Yaoundé)...',
                hintStyle: const TextStyle(
                    fontFamily: 'Inter', fontSize: 12,
                    color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textMuted, size: 20),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.teal),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.teal, width: 2)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _search(_searchCtrl.text),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Trouver',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ]),

        // Suggestions
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06),
                    blurRadius: 8),
              ],
            ),
            child: Column(
              children: _suggestions.map((s) => InkWell(
                onTap: () => _selectSuggestion(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(children: [
                    const Icon(Icons.location_on_rounded,
                        size: 16, color: AppColors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s.displayName,
                          style: const TextStyle(
                            fontFamily: 'Inter', fontSize: 12,
                            color: AppColors.dark,
                          ),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ),
              )).toList(),
            ),
          ),

        const SizedBox(height: 12),

        // ── Carte interactive ─────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 260,
            child: Stack(children: [
              FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: _selected,
                  initialZoom: 13,
                  onTap: _onMapTap,
                ),
                children: [
                  // ✅ Tuiles Google Maps — même rendu que la version web
                  TileLayer(
                    urlTemplate:
                        'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                    subdomains: const ['0', '1', '2', '3'],
                    userAgentPackageName:
                        'com.example.dreamhouse237_mobile',
                    maxZoom: 20,
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: _selected,
                      width: 48, height: 56,
                      child: Column(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal.withOpacity(0.4),
                                blurRadius: 12, spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.home_rounded,
                              color: AppColors.white, size: 18),
                        ),
                        CustomPaint(
                          size: const Size(12, 8),
                          painter: _TrianglePainter(AppColors.teal),
                        ),
                      ]),
                    ),
                  ]),
                ],
              ),

              Positioned(
                bottom: 10, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Appuyez sur la carte pour placer votre bien',
                      style: TextStyle(fontFamily: 'Inter',
                          fontSize: 11, color: Colors.white),
                    ),
                  ),
                ),
              ),

              // © Google Maps (attribution obligatoire)
              Positioned(
                bottom: 4, right: 8,
                child: Text('© Google Maps',
                    style: TextStyle(fontSize: 9,
                        color: Colors.black.withOpacity(0.4))),
              ),
            ]),
          ),
        ),

        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.gps_fixed_rounded,
              size: 14, color: AppColors.teal),
          const SizedBox(width: 6),
          Text(
            'Lat: ${_selected.latitude.toStringAsFixed(5)}  '
            'Lng: ${_selected.longitude.toStringAsFixed(5)}',
            style: const TextStyle(
              fontFamily: 'Inter', fontSize: 11,
              color: AppColors.textSecondary, fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      ],
    );
  }
}

class _NominatimResult {
  final String displayName;
  final double lat;
  final double lng;
  _NominatimResult(
      {required this.displayName, required this.lat, required this.lng});
  String get shortName =>
      displayName.split(',').take(2).join(',').trim();
}

// ── Triangle — ui.Path pour éviter conflit go_router ─────────────────────────
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_) => false;
}