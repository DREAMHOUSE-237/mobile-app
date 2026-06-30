import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/property_card.dart';
import '../../home/data/bien_model.dart';
import '../../home/data/bien_repository.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ══════════════════════════════════════════════════════════════════════════════
final _filterProvider = StateProvider<BienFilter>((ref) => const BienFilter());

final catalogueBiensProvider = FutureProvider.autoDispose<List<BienModel>>((ref) {
  final filter = ref.watch(_filterProvider);
  final repo   = ref.watch(bienRepositoryProvider);
  return repo.search(filter);
});

// ══════════════════════════════════════════════════════════════════════════════
// CATALOGUE SCREEN — Équivalent de Recherche.jsx
// Route : /catalogue
// ══════════════════════════════════════════════════════════════════════════════
class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key});
  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  final _villeCtrl    = TextEditingController();
  final _quartierCtrl = TextEditingController();

  String _type       = 'Tous les types';
  String _categorie  = 'Toutes catégories';
  double _prixMax    = 500000;
  int    _piecesMin  = 2;
  bool   _showAdv    = false;
  int    _page       = 1;
  static const int _perPage = 8;

  final _types      = ['Tous les types', 'LOCATION', 'VENTE'];
  final _categories = ['Toutes catégories', 'MEUBLE', 'NON_MEUBLE'];

  @override
  void dispose() {
    _villeCtrl.dispose();
    _quartierCtrl.dispose();
    super.dispose();
  }

  void _search() {
    _page = 1;
    ref.read(_filterProvider.notifier).state = BienFilter(
      ville:     _villeCtrl.text.trim().isEmpty ? null : _villeCtrl.text.trim(),
      categorie: _categorie == 'Toutes catégories' ? null : _categorie,
      type:      _type == 'Tous les types' ? null : _type,
      quartier:  _quartierCtrl.text.trim().isEmpty ? null : _quartierCtrl.text.trim(),
      prixMax:   _prixMax,
      piecesMin: _piecesMin,
    );
  }

  void _reset() {
    setState(() {
      _villeCtrl.clear(); _quartierCtrl.clear();
      _type = 'Tous les types'; _categorie = 'Toutes catégories';
      _prixMax = 500000; _piecesMin = 2;
      _page = 1;
    });
    ref.read(_filterProvider.notifier).state = const BienFilter();
  }

  @override
  Widget build(BuildContext context) {
    final biensAsync = ref.watch(catalogueBiensProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Catalogue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(catalogueBiensProvider.future),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Panneau filtres ────────────────────────────────────────────
          _FiltersPanel(
            villeCtrl:    _villeCtrl,
            quartierCtrl: _quartierCtrl,
            type:         _type,
            types:        _types,
            categorie:    _categorie,
            categories:   _categories,
            prixMax:      _prixMax,
            piecesMin:    _piecesMin,
            showAdv:      _showAdv,
            onTypeChanged:      (v) => setState(() => _type = v!),
            onCategorieChanged: (v) => setState(() => _categorie = v!),
            onPrixMaxChanged:   (v) => setState(() => _prixMax = v),
            onPiecesMinChanged: (v) => setState(() => _piecesMin = v),
            onToggleAdv:        () => setState(() => _showAdv = !_showAdv),
            onSearch: _search,
            onReset:  _reset,
          ),

          // ── Liste résultats ────────────────────────────────────────────
          Expanded(
            child: biensAsync.when(
              loading: () => _buildShimmerList(),
              error:   (e, _) => _ErrorView(onRetry: () => ref.refresh(catalogueBiensProvider.future)),
              data:    (biens) => _buildResults(biens),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<BienModel> biens) {
    if (biens.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('Aucun bien trouvé', style: AppTextStyles.heading2),
            SizedBox(height: 8),
            Text('Essayez d\'autres critères', style: AppTextStyles.caption),
          ],
        ),
      );
    }

    final totalPages = (biens.length / _perPage).ceil();
    final paginated  = biens.skip((_page - 1) * _perPage).take(_perPage).toList();

    return Column(
      children: [
        // Header résultats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Text(
                'Annonces Actuelles',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${biens.length} disponibles',
                  style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 11,
                    fontWeight: FontWeight.w700, color: AppColors.teal,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grille
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.65,
            ),
            itemCount: paginated.length,
            itemBuilder: (_, i) => PropertyCard(bien: paginated[i], compact: true),
          ),
        ),

        // Pagination
        if (totalPages > 1)
          _Pagination(
            currentPage: _page,
            totalPages:  totalPages,
            onPageChanged: (p) => setState(() => _page = p),
          ),
      ],
    );
  }

  Widget _buildShimmerList() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 14,
        crossAxisSpacing: 14, childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const PropertyCardShimmer(),
    );
  }
}

// ── Panneau de filtres ────────────────────────────────────────────────────────
class _FiltersPanel extends StatelessWidget {
  final TextEditingController villeCtrl;
  final TextEditingController quartierCtrl;
  final String type;
  final List<String> types;
  final String categorie;
  final List<String> categories;
  final double prixMax;
  final int piecesMin;
  final bool showAdv;
  final void Function(String?) onTypeChanged;
  final void Function(String?) onCategorieChanged;
  final void Function(double) onPrixMaxChanged;
  final void Function(int) onPiecesMinChanged;
  final VoidCallback onToggleAdv;
  final VoidCallback onSearch;
  final VoidCallback onReset;

  const _FiltersPanel({
    required this.villeCtrl, required this.quartierCtrl,
    required this.type, required this.types,
    required this.categorie, required this.categories,
    required this.prixMax, required this.piecesMin,
    required this.showAdv,
    required this.onTypeChanged, required this.onCategorieChanged,
    required this.onPrixMaxChanged, required this.onPiecesMinChanged,
    required this.onToggleAdv, required this.onSearch, required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.filter_list_rounded, size: 16, color: AppColors.teal),
            const SizedBox(width: 6),
            const Text('FILTRES DE RECHERCHE', style: AppTextStyles.label),
            const Spacer(),
            GestureDetector(
              onTap: onReset,
              child: const Text('Réinitialiser', style: TextStyle(
                fontFamily: 'Inter', fontSize: 11, color: AppColors.error,
                fontWeight: FontWeight.w600,
              )),
            ),
          ]),
          const SizedBox(height: 12),

          // Ligne 1 : Type + Catégorie + Ville
          Row(children: [
            Expanded(child: _miniDrop('TYPE', type, types, onTypeChanged)),
            const SizedBox(width: 8),
            Expanded(child: _miniDrop('CATÉGORIE', categorie, categories, onCategorieChanged)),
          ]),
          const SizedBox(height: 10),
          _miniField(villeCtrl, 'Ville (ex: Yaoundé)', Icons.location_city_outlined),
          const SizedBox(height: 12),

          // Bouton rechercher
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Rechercher'),
            ),
          ),
          const SizedBox(height: 8),

          // Toggle filtres avancés
          GestureDetector(
            onTap: onToggleAdv,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                showAdv ? 'MASQUER OPTIONS ∧' : 'PLUS DE CRITÈRES ∨',
                style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 11,
                  fontWeight: FontWeight.w700, color: AppColors.teal,
                ),
              ),
            ]),
          ),

          // Filtres avancés
          if (showAdv) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 10),
            _miniField(quartierCtrl, 'Quartier (ex: Bastos)', Icons.place_outlined),
            const SizedBox(height: 10),
            const Text('PRIX MAX (XAF)', style: AppTextStyles.label),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(
                child: Slider(
                  value: prixMax,
                  min: 50000, max: 5000000,
                  divisions: 99,
                  activeColor: AppColors.teal,
                  onChanged: onPrixMaxChanged,
                ),
              ),
              Text(
                '${(prixMax / 1000).toInt()}K',
                style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 12,
                  fontWeight: FontWeight.w700, color: AppColors.teal,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            const Text('PIÈCES MIN', style: AppTextStyles.label),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(
                child: Slider(
                  value: piecesMin.toDouble(),
                  min: 1, max: 10,
                  divisions: 9,
                  activeColor: AppColors.teal,
                  onChanged: (v) => onPiecesMinChanged(v.toInt()),
                ),
              ),
              Text(
                '$piecesMin p.',
                style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 12,
                  fontWeight: FontWeight.w700, color: AppColors.teal,
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _miniDrop(String label, String val, List<String> opts, void Function(String?) cb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: val,
          isDense: true,
          items: opts.map((o) => DropdownMenuItem(
            value: o,
            child: Text(o, style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
          )).toList(),
          onChanged: cb,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
          ),
          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.dark),
          dropdownColor: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.teal),
        ),
      ],
    );
  }

  Widget _miniField(TextEditingController ctrl, String hint, IconData icon) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.teal, width: 2)),
      ),
    );
  }
}

// ── Pagination ────────────────────────────────────────────────────────────────
class _Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final void Function(int) onPageChanged;
  const _Pagination({required this.currentPage, required this.totalPages, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            color: AppColors.teal,
          ),
          ...List.generate(totalPages, (i) {
            final p = i + 1;
            final isActive = p == currentPage;
            return GestureDetector(
              onTap: () => onPageChanged(p),
              child: Container(
                width: 32, height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? AppColors.teal : AppColors.borderLight,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$p',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? AppColors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
            color: AppColors.teal,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text('Erreur de chargement', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
