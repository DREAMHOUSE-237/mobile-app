import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MAP VIEWER — Carte read-only pour afficher la position d'un bien
// FIX : tuiles Google Maps (roadmap) pour un rendu identique à la version web
// ══════════════════════════════════════════════════════════════════════════════
class PropertyMapViewer extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? label;
  final double height;

  const PropertyMapViewer({
    super.key,
    required this.latitude,
    required this.longitude,
    this.label,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    final position = LatLng(latitude, longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: position,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                // ✅ Tuiles Google Maps — même rendu que la version web
                TileLayer(
                  urlTemplate:
                      'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                  subdomains: const ['0', '1', '2', '3'],
                  userAgentPackageName: 'com.example.dreamhouse237_mobile',
                  maxZoom: 20,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: position,
                      width: 48,
                      height: 56,
                      child: Column(
                        children: [
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
                            child: const Icon(
                              Icons.home_rounded,
                              color: AppColors.white, size: 18,
                            ),
                          ),
                          CustomPaint(
                            size: const Size(12, 8),
                            painter: _TrianglePainter(AppColors.teal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (label != null)
              Positioned(
                bottom: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_on_rounded,
                        size: 14, color: AppColors.teal),
                    const SizedBox(width: 4),
                    Text(label!, style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 11,
                      fontWeight: FontWeight.w700, color: AppColors.dark,
                    )),
                  ]),
                ),
              ),

            // © Google Maps (attribution obligatoire)
            Positioned(
              bottom: 4, right: 8,
              child: Text('© Google Maps',
                  style: TextStyle(fontSize: 9,
                      color: Colors.black.withOpacity(0.5))),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Triangle sous le marqueur — utilise ui.Path pour éviter le conflit ────────
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path  = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}