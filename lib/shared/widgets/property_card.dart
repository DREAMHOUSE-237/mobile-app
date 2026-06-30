import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../features/home/data/bien_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PROPERTY CARD — Équivalent de la carte annonce dans Accueil.jsx + Recherche.jsx
// ══════════════════════════════════════════════════════════════════════════════
class PropertyCard extends StatelessWidget {
  final BienModel bien;
  final bool compact;

  const PropertyCard({super.key, required this.bien, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.detailPath(bien.id)),
      child: Container(
        decoration: AppDecorations.card,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────────────
            _PropertyImage(photoUrl: bien.photoUrl, compact: compact),

            // ── Infos ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prix + Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          bien.prixFormate,
                          style: AppTextStyles.price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (bien.rating != null) ...[
                        const SizedBox(width: 4),
                        _RatingBadge(rating: bien.rating!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Titre
                  Text(
                    bien.titre,
                    style: AppTextStyles.heading3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Badges
                  Row(children: [
                    _Badge(label: bien.categorieBadge, color: AppColors.teal),
                    const SizedBox(width: 6),
                    _Badge(label: bien.typeBadge, color: AppColors.orange),
                  ]),
                  const SizedBox(height: 8),

                  // Localisation + Pièces
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        bien.localisation,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.meeting_room_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(
                      '${bien.nbPieces} p.',
                      style: AppTextStyles.caption,
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image avec shimmer + fallback ─────────────────────────────────────────────
class _PropertyImage extends StatelessWidget {
  final String? photoUrl;
  final bool compact;
  const _PropertyImage({this.photoUrl, required this.compact});

  @override
  Widget build(BuildContext context) {
    final height = compact ? 130.0 : 170.0;

    if (photoUrl == null || photoUrl!.isEmpty) {
      return _Placeholder(height: height);
    }

    return CachedNetworkImage(
      imageUrl: photoUrl!,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Container(height: height, color: Colors.white),
      ),
      errorWidget: (_, __, ___) => _Placeholder(height: height),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double height;
  const _Placeholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.bgTealLight,
      child: const Center(
        child: Icon(Icons.home_work_outlined,
            size: 40, color: AppColors.textMuted),
      ),
    );
  }
}

// ── Badge catégorie / type ────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Rating badge ──────────────────────────────────────────────────────────────
class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
      const SizedBox(width: 2),
      Text(
        rating.toStringAsFixed(1),
        style: const TextStyle(
          fontFamily: 'Inter', fontSize: 11,
          fontWeight: FontWeight.w700, color: AppColors.dark,
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PROPERTY CARD SHIMMER — Skeleton loader pendant le chargement
// ══════════════════════════════════════════════════════════════════════════════
class PropertyCardShimmer extends StatelessWidget {
  const PropertyCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerLine(width: 120, height: 18),
                  SizedBox(height: 8),
                  _ShimmerLine(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  _ShimmerLine(width: 80, height: 20),
                  SizedBox(height: 8),
                  _ShimmerLine(width: 160, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  final double width;
  final double height;
  const _ShimmerLine({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
