import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/data/bien_model.dart';
import '../data/detail_provider.dart';
import '../widgets/property_gallery.dart';
import '../widgets/comment_section.dart';
import '../../map/widgets/property_map_viewer.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DETAIL SCREEN — Équivalent de detail.jsx
// FIX : ajout bouton "Itinéraire" qui ouvre Google Maps avec tracer,
//       identique à la version web
// ══════════════════════════════════════════════════════════════════════════════
class DetailScreen extends ConsumerWidget {
  final String id;
  const DetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bienAsync = ref.watch(bienDetailProvider(id));

    return bienAsync.when(
      loading: () => const _LoadingDetail(),
      error:   (e, _) => _ErrorDetail(message: e.toString()),
      data:    (bien) => _DetailContent(bien: bien),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CONTENU PRINCIPAL DU DÉTAIL
// ══════════════════════════════════════════════════════════════════════════════
class _DetailContent extends StatelessWidget {
  final BienModel bien;
  const _DetailContent({required this.bien});

  Future<void> _openWhatsApp(BuildContext context) async {
    final tel = bien.proprietaireTelephone ?? '';
    if (tel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro WhatsApp non disponible')),
      );
      return;
    }

    String number = tel.replaceAll(RegExp(r'\D'), '');
    if (!number.startsWith('237')) {
      number = '237$number';
    }

    final message = Uri.encodeComponent(
      'Bonjour, je suis intéressé par votre bien "${bien.titre}" publié sur DreamHouse.',
    );

    final uriNatif = Uri.parse('whatsapp://send?phone=$number&text=$message');
    final uriWeb   = Uri.parse('https://wa.me/$number?text=$message');

    try {
      if (await canLaunchUrl(uriNatif)) {
        await launchUrl(uriNatif, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(uriWeb)) {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uriWeb, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WhatsApp non disponible. Numéro : $number'),
            action: SnackBarAction(
              label: 'Copier',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: number));
              },
            ),
          ),
        );
      }
    }
  }

  // FIX : ouvre Google Maps avec l'itinéraire depuis la position actuelle
  // Identique au comportement de la version web (lien Google Maps directions)
  Future<void> _openDirections(BuildContext context) async {
    final lat = bien.latitude!;
    final lng = bien.longitude!;
    final label = Uri.encodeComponent(bien.titre);

    // Essai 1 : Application Google Maps native
    final googleMapsApp = Uri.parse(
      'google.navigation:q=$lat,$lng&mode=d',
    );
    // Essai 2 : URL Google Maps universelle (web fallback)
    final googleMapsWeb = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$label&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(googleMapsApp)) {
        await launchUrl(googleMapsApp, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(googleMapsWeb, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar avec galerie ───────────────────────────────
          SliverAppBar(
            expandedHeight: bien.photos.isNotEmpty ? 300 : 80,
            pinned: true,
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.dark,
            flexibleSpace: bien.photos.isNotEmpty
                ? FlexibleSpaceBar(
                    background: PropertyGallery(
                      photos: bien.photos,
                      height: 300,
                    ),
                  )
                : null,
            title: Text(
              bien.titre,
              style: const TextStyle(
                fontFamily: 'Inter', fontSize: 16,
                fontWeight: FontWeight.w800, color: AppColors.dark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Infos principales ───────────────────────────────────
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: AppDecorations.card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bien.titre, style: AppTextStyles.heading1),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.location_on_rounded,
                            size: 14, color: AppColors.teal),
                        const SizedBox(width: 4),
                        Text(
                          bien.localisation,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.teal, fontWeight: FontWeight.w600),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _InfoGrid(bien: bien),
                      const SizedBox(height: 16),
                      if (bien.description != null &&
                          bien.description!.isNotEmpty) ...[
                        const Text('DESCRIPTION DU BIEN', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        Text(
                          bien.description!,
                          style: AppTextStyles.body,
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Contact WhatsApp ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ContactCard(
                    bien: bien,
                    onWhatsApp: () => _openWhatsApp(context),
                  ),
                ),

                // ── Carte + bouton itinéraire ───────────────────────────
                if (bien.hasLocation) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LOCALISATION', style: AppTextStyles.label),
                        const SizedBox(height: 10),
                        PropertyMapViewer(
                          latitude:  bien.latitude!,
                          longitude: bien.longitude!,
                          label:     bien.localisation,
                        ),
                        const SizedBox(height: 10),
                        // FIX : bouton itinéraire — ouvre Google Maps
                        // comme la version web
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _openDirections(context),
                            icon: const Icon(Icons.directions_rounded, size: 18),
                            label: const Text(
                              'OBTENIR L\'ITINÉRAIRE',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Commentaires ────────────────────────────────────────
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CommentSection(publicationId: bien.id),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grille d'informations ──────────────────────────────────────────────────────
class _InfoGrid extends StatelessWidget {
  final BienModel bien;
  const _InfoGrid({required this.bien});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.attach_money_rounded, 'Prix',        bien.prixFormate,    AppColors.orange),
      (Icons.swap_horiz_rounded,   'Type',        bien.typePublication, AppColors.teal),
      (Icons.home_work_outlined,   'Type Bien',   bien.typeBien,        AppColors.dark),
      (Icons.category_outlined,    'Catégorie',   bien.categorie,       AppColors.dark),
      (Icons.meeting_room_outlined,'Pièces',      '${bien.nbPieces}',   AppColors.dark),
      if (bien.superficie != null)
        (Icons.straighten_rounded, 'Superficie',  '${bien.superficie!.toInt()} m²', AppColors.dark),
    ];

    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Icon(item.$1, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.$3.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: item.$4,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ]),
      )).toList(),
    );
  }
}

// ── Card contact propriétaire ──────────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final BienModel bien;
  final VoidCallback onWhatsApp;
  const _ContactCard({required this.bien, required this.onWhatsApp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card,
      child: Column(
        children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  size: 26, color: AppColors.teal),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RESPONSABLE DU BIEN',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 10,
                      fontWeight: FontWeight.w800, color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    )),
                Text('Réponse rapide',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 12,
                      fontWeight: FontWeight.w600, color: AppColors.teal,
                    )),
              ],
            ),
          ]),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onWhatsApp,
              icon: const Icon(Icons.chat_rounded, size: 20),
              label: Text(
                'WHATSAPP : ${bien.proprietaireTelephone ?? "N/A"}',
                style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ÉTATS CHARGEMENT / ERREUR
// ══════════════════════════════════════════════════════════════════════════════
class _LoadingDetail extends StatelessWidget {
  const _LoadingDetail();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: SingleChildScrollView(
          child: Column(children: [
            Container(height: 280, color: Colors.white),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: List.generate(5, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ))),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ErrorDetail extends StatelessWidget {
  final String message;
  const _ErrorDetail({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail du bien')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text('Bien introuvable', style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              Text(message, style: AppTextStyles.caption, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}