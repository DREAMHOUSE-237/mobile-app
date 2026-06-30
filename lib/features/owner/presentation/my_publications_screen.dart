import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../home/data/bien_model.dart';
import '../../home/data/bien_repository.dart';
import '../data/publication_notifier.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MES PUBLICATIONS PROVIDER
// ══════════════════════════════════════════════════════════════════════════════
final mesPublicationsProvider =
    FutureProvider.autoDispose<List<BienModel>>((ref) {
  return ref.watch(bienRepositoryProvider).getMesPublications();
});

// ══════════════════════════════════════════════════════════════════════════════
// MY PUBLICATIONS SCREEN — Équivalent de MesPublications.jsx
// Route : /mes-publications
// ══════════════════════════════════════════════════════════════════════════════
class MyPublicationsScreen extends ConsumerWidget {
  const MyPublicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pubsAsync = ref.watch(mesPublicationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Mes publications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(mesPublicationsProvider.future),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            color: AppColors.teal,
            onPressed: () => context.go(AppRoutes.publish),
          ),
        ],
      ),
      body: pubsAsync.when(
        loading: () => const _PublicationsShimmer(),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(mesPublicationsProvider.future),
        ),
        data: (pubs) => pubs.isEmpty
            ? _EmptyView(onPublish: () => context.go(AppRoutes.publish))
            : _PublicationsList(
                publications: pubs,
                onDelete: (id) => _confirmDelete(context, ref, id),
                onEdit: (id) => context.go(AppRoutes.editPath(id)),
              ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer l\'annonce',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        content: const Text(
          'Cette action est irréversible. Voulez-vous vraiment supprimer cette annonce ?',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler',
                style: TextStyle(fontFamily: 'Inter', color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(80, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Supprimer',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;
    try {
      await ref.read(publicationUpdateProvider).delete(id);
      ref.refresh(mesPublicationsProvider.future);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce supprimée'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }
}

// ── Liste publications ─────────────────────────────────────────────────────────
class _PublicationsList extends StatelessWidget {
  final List<BienModel> publications;
  final void Function(String) onDelete;
  final void Function(String) onEdit;

  const _PublicationsList({
    required this.publications,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          const Text('Mes publications', style: AppTextStyles.heading2),
          const SizedBox(width: 8),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${publications.length} Annonces',
              style: const TextStyle(
                fontFamily: 'Inter', fontSize: 11,
                fontWeight: FontWeight.w700, color: AppColors.teal,
              ),
            ),
          ),
        ]),
      ),

      // Sous-titre
      const Padding(
        padding: EdgeInsets.only(left: 16, bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Gérez vos annonces immobilières',
              style: AppTextStyles.caption),
        ),
      ),

      // Liste
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: publications.length,
          itemBuilder: (_, i) => _PublicationTile(
            bien: publications[i],
            onDelete: () => onDelete(publications[i].id),
            onEdit:   () => onEdit(publications[i].id),
          ),
        ),
      ),
    ]);
  }
}

// ── Tuile publication ──────────────────────────────────────────────────────────
class _PublicationTile extends StatelessWidget {
  final BienModel bien;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _PublicationTile({
    required this.bien, required this.onDelete, required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.card,
      child: Row(children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20)),
          child: bien.photoUrl != null
              ? CachedNetworkImage(
                  imageUrl: bien.photoUrl!,
                  width: 90, height: 100,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      width: 90, height: 100, color: AppColors.bgTealLight),
                  errorWidget: (_, __, ___) => Container(
                    width: 90, height: 100,
                    color: AppColors.bgTealLight,
                    child: const Icon(Icons.home_work_outlined,
                        color: AppColors.textMuted),
                  ),
                )
              : Container(
                  width: 90, height: 100,
                  color: AppColors.bgTealLight,
                  child: const Icon(Icons.home_work_outlined,
                      color: AppColors.textMuted),
                ),
        ),

        // Infos
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Text(bien.titre, style: AppTextStyles.heading3,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),

                // Localisation + Catégorie
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(bien.localisation,
                        style: AppTextStyles.caption,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(bien.categorie,
                        style: const TextStyle(
                          fontFamily: 'Inter', fontSize: 8,
                          fontWeight: FontWeight.w800, color: AppColors.teal,
                        )),
                  ),
                ]),
                const SizedBox(height: 6),

                // Prix + Date
                Row(children: [
                  Text('PRIX MENSUEL', style: AppTextStyles.label
                      .copyWith(fontSize: 8)),
                  const Spacer(),
                  if (bien.createdAt != null)
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 10, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        'Posté le ${bien.createdAt!.day}/${bien.createdAt!.month}/${bien.createdAt!.year}',
                        style: const TextStyle(
                            fontFamily: 'Inter', fontSize: 9,
                            color: AppColors.textMuted),
                      ),
                    ]),
                ]),
                Text(bien.prixFormate,
                    style: AppTextStyles.price.copyWith(fontSize: 15)),
                const SizedBox(height: 8),

                // Actions
                Row(children: [
                  _ActionBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.teal,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.error,
                    onTap: onDelete,
                  ),
                ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

// ── Vue vide ───────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final VoidCallback onPublish;
  const _EmptyView({required this.onPublish});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
              color: AppColors.bgTealLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.home_work_outlined,
                size: 40, color: AppColors.teal),
          ),
          const SizedBox(height: 20),
          const Text('Aucune publication', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          const Text(
            'Vous n\'avez pas encore publié de bien immobilier.',
            style: AppTextStyles.caption, textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onPublish,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Publier mon premier bien'),
          ),
        ]),
      ),
    );
  }
}

// ── Shimmer ────────────────────────────────────────────────────────────────────
class _PublicationsShimmer extends StatelessWidget {
  const _PublicationsShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded,
            size: 56, color: AppColors.textMuted),
        const SizedBox(height: 12),
        const Text('Erreur de chargement', style: AppTextStyles.heading3),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Réessayer'),
        ),
      ]),
    );
  }
}
