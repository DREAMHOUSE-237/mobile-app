import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PHOTO GALLERY — Carousel + lightbox plein écran
// Équivalent de la galerie dans detail.jsx
// ══════════════════════════════════════════════════════════════════════════════
class PropertyGallery extends StatefulWidget {
  final List<String> photos;
  final double height;

  const PropertyGallery({
    super.key,
    required this.photos,
    this.height = 260,
  });

  @override
  State<PropertyGallery> createState() => _PropertyGalleryState();
}

class _PropertyGalleryState extends State<PropertyGallery> {
  int _current = 0;
  final PageController _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _openLightbox(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _Lightbox(photos: widget.photos, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) return _EmptyGallery(height: widget.height);

    return Column(
      children: [
        // ── Carousel principal ──────────────────────────────────────────
        SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageCtrl,
                itemCount: widget.photos.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _openLightbox(i),
                  child: _GalleryImage(url: widget.photos[i]),
                ),
              ),

              // Bouton plein écran
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => _openLightbox(_current),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Compteur photos
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_current + 1} / ${widget.photos.length}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Miniatures ──────────────────────────────────────────────────
        if (widget.photos.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.photos.length,
              itemBuilder: (_, i) {
                final isActive = i == _current;
                return GestureDetector(
                  onTap: () {
                    _pageCtrl.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive ? AppColors.teal : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: widget.photos[i],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.bgTealLight),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.bgTealLight,
                          child: const Icon(Icons.image_outlined,
                              size: 20, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ── Image individuelle du carousel ────────────────────────────────────────────
class _GalleryImage extends StatelessWidget {
  final String url;
  const _GalleryImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Container(color: Colors.white),
      ),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.bgTealLight,
        child: const Center(
          child: Icon(Icons.broken_image_outlined,
              size: 48, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

// ── Galerie vide ──────────────────────────────────────────────────────────────
class _EmptyGallery extends StatelessWidget {
  final double height;
  const _EmptyGallery({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.bgTealLight,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 56, color: AppColors.textMuted),
            SizedBox(height: 8),
            Text('Aucune photo disponible',
                style: TextStyle(
                  fontFamily: 'Inter', fontSize: 13,
                  color: AppColors.textMuted,
                )),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LIGHTBOX — Plein écran avec zoom (photo_view)
// ══════════════════════════════════════════════════════════════════════════════
class _Lightbox extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  const _Lightbox({required this.photos, required this.initialIndex});

  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_current + 1} / ${widget.photos.length}',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        itemCount: widget.photos.length,
        pageController: PageController(initialPage: widget.initialIndex),
        onPageChanged: (i) => setState(() => _current = i),
        builder: (context, i) => PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(widget.photos[i]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (_, __) => const Center(
          child: CircularProgressIndicator(color: AppColors.teal),
        ),
      ),
    );
  }
}
