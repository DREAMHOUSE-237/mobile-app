import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/property_card.dart';
import '../data/bien_model.dart';
import '../data/bien_repository.dart';
import '../../auth/auth_notifier.dart';

// ══════════════════════════════════════════════════════════════════════════════
// HOME PROVIDER
// ══════════════════════════════════════════════════════════════════════════════
final homeBiensProvider = FutureProvider<List<BienModel>>((ref) async {
  final repo = ref.watch(bienRepositoryProvider);
  return repo.getAll();
});

// ══════════════════════════════════════════════════════════════════════════════
// HOME SCREEN — Équivalent de Accueil.jsx
// Route : /accueil
// ══════════════════════════════════════════════════════════════════════════════
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _typingController;
  int _typingIndex = 0;

  final List<String> _phrases = [
    'L\'immobilier qui vous\ndonne le sourire.',
    'Trouvez votre maison\nde rêve au Cameroun.',
    'Location, vente,\nsans intermédiaire.',
  ];

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _typingController.reset();
        setState(() => _typingIndex = (_typingIndex + 1) % _phrases.length);
        _typingController.forward();
      }
    });
    _typingController.forward();
  }

  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final biensAsync = ref.watch(homeBiensProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () => ref.refresh(homeBiensProvider.future),
        child: CustomScrollView(
          slivers: [
            // ── AppBar transparent ───────────────────────────────────────
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              backgroundColor: AppColors.white,
              elevation: 0,
              title: RichText(
                text: const TextSpan(children: [
                  TextSpan(
                    text: 'Dream',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 20,
                      fontWeight: FontWeight.w900, color: AppColors.teal,
                    ),
                  ),
                  TextSpan(
                    text: 'House',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 20,
                      fontWeight: FontWeight.w900, color: AppColors.orange,
                    ),
                  ),
                ]),
              ),
              actions: [
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _UserAvatar(name: user.fullName),
                  )
                else
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text(
                      'Se connecter',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Banner ──────────────────────────────────────────
                  _HeroBanner(
                    phrase: _phrases[_typingIndex],
                    controller: _typingController,
                  ),

                  // ── Section annonces récentes ────────────────────────────
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Annonces Récentes', style: AppTextStyles.heading2),
                        biensAsync.when(
                          data: (list) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${list.length} disponibles',
                              style: const TextStyle(
                                fontFamily: 'Inter', fontSize: 11,
                                fontWeight: FontWeight.w700, color: AppColors.teal,
                              ),
                            ),
                          ),
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Grille biens ─────────────────────────────────────────
                  biensAsync.when(
                    loading: () => _buildShimmerGrid(),
                    error: (e, _) => _ErrorWidget(
                      message: e.toString(),
                      onRetry: () => ref.refresh(homeBiensProvider.future),
                    ),
                    data: (biens) => _buildGrid(biens.take(4).toList()),
                  ),

                  const SizedBox(height: 20),

                  // ── Bouton "Découvrir tous les biens" ────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.catalogue),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: biensAsync.when(
                        data: (l) => Text('Découvrir les ${l.length} biens'),
                        loading: () => const Text('Voir le catalogue'),
                        error: (_, __) => const Text('Voir le catalogue'),
                      ),
                    ),
                  ),

                  // ── CTA Propriétaire ─────────────────────────────────────
                  const SizedBox(height: 32),
                  _ProprietaireBanner(),

                  // ── Footer ───────────────────────────────────────────────
                  const SizedBox(height: 24),
                  _FooterSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<BienModel> biens) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.68,
        ),
        itemCount: biens.length,
        itemBuilder: (_, i) => PropertyCard(bien: biens[i], compact: true),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.68,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => const PropertyCardShimmer(),
      ),
    );
  }
}

// ── Hero Banner avec animation texte ─────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final String phrase;
  final AnimationController controller;
  const _HeroBanner({required this.phrase, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.dark, Color(0xFF0D3B4F)],
        ),
      ),
      child: Stack(
        children: [
          // Overlay décoratif
          Positioned(
            right: -40, top: -40,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            left: -20, bottom: -30,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withOpacity(0.06),
              ),
            ),
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.teal.withOpacity(0.3)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.home_outlined, size: 12, color: AppColors.teal),
                    SizedBox(width: 4),
                    Text(
                      'CHEZ DREAMHOUSE',
                      style: TextStyle(
                        fontFamily: 'Inter', fontSize: 10,
                        fontWeight: FontWeight.w800, color: AppColors.teal,
                        letterSpacing: 1,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation, child: child,
                  ),
                  child: Text(
                    phrase,
                    key: ValueKey(phrase),
                    style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 28,
                      fontWeight: FontWeight.w900, color: AppColors.white,
                      height: 1.15, letterSpacing: -0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Row(children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Rechercher'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      backgroundColor: AppColors.teal,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar utilisateur ────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String name;
  const _UserAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.teal.withOpacity(0.15),
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: 'Inter', fontSize: 14,
          fontWeight: FontWeight.w800, color: AppColors.teal,
        ),
      ),
    );
  }
}

// ── CTA Propriétaire ──────────────────────────────────────────────────────────
class _ProprietaireBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.teal, Color(0xFF005F65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VOUS ÊTES PROPRIÉTAIRE ?',
            style: TextStyle(
              fontFamily: 'Inter', fontSize: 18,
              fontWeight: FontWeight.w900, color: AppColors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Maximisez la visibilité de vos biens en quelques clics.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          const Text(
            'Connectez-vous pour publier et être contacté directement.',
            style: TextStyle(
              fontFamily: 'Inter', fontSize: 13,
              fontWeight: FontWeight.w700, color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.login),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Commencer maintenant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.teal,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              textStyle: const TextStyle(
                fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────
class _FooterSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkNavy,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                AppAssets.logo,
                width: 28, height: 28, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Text('D',
                    style: TextStyle(fontFamily:'Inter',fontSize:16,
                      fontWeight:FontWeight.w900,color:Colors.white))),
                ),
              ),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(children: [
                TextSpan(text: 'Dream',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 18,
                    fontWeight: FontWeight.w900, color: AppColors.teal)),
                TextSpan(text: 'House',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 18,
                    fontWeight: FontWeight.w900, color: AppColors.orange)),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          const Text(
            'DreamHouse est une plateforme innovante dédiée à simplifier l\'accès au logement au Cameroun.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white54, height: 1.5),
          ),
          const SizedBox(height: 20),
          const Text('NAVIGATION', style: TextStyle(
            fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w800,
            color: AppColors.teal, letterSpacing: 1,
          )),
          const SizedBox(height: 8),
          ...[
            ('Qui sommes-nous ?', () {}),
            ('Catalogue', () => context.go(AppRoutes.catalogue)),
            ('Nous contacter', () {}),
          ].map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onTap: item.$2,
              child: Text(item.$1, style: const TextStyle(
                fontFamily: 'Inter', fontSize: 13, color: Colors.white70,
              )),
            ),
          )),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          const Text(
            '© 2026 DREAMHOUSE TOUS DROITS RÉSERVÉS',
            style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.white38, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

// ── Widget erreur ─────────────────────────────────────────────────────────────
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text('Impossible de charger les annonces', style: AppTextStyles.body, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: TextButton.styleFrom(foregroundColor: AppColors.teal),
          ),
        ],
      ),
    );
  }
}
