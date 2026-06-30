import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../auth/auth_notifier.dart';

// ══════════════════════════════════════════════════════════════════════════════
// OWNER HOME SCREEN — Équivalent de Accueil2.jsx
// Route : /accueil2  (propriétaire / agence uniquement)
// ══════════════════════════════════════════════════════════════════════════════
class OwnerHomeScreen extends ConsumerWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () async {},
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────────────────
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
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _UserAvatar(name: user?.fullName ?? ''),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                children: [
                  // ── Hero Banner ────────────────────────────────────────
                  _HeroBanner(user: user),

                  // ── Cartes avantages ───────────────────────────────────
                  const SizedBox(height: 28),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Vos avantages', style: AppTextStyles.heading2),
                  ),
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(child: _AdvantageCard(
                            icon: Icons.bolt_rounded,
                            title: 'Maximisez votre visibilité',
                            description: 'Facilitez la propagation de votre bien auprès de milliers de locataires potentiels chaque jour.',
                          )),
                          SizedBox(width: 12),
                          Expanded(child: _AdvantageCard(
                            icon: Icons.add_circle_outline_rounded,
                            title: 'Publication simplifiée',
                            description: 'Ajoutez vos photos, descriptions et prix en quelques clics.',
                            highlighted: true,
                          )),
                        ]),
                        SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _AdvantageCard(
                            icon: Icons.check_circle_outline_rounded,
                            title: 'Transparence tarifaire',
                            description: 'Frais de service fixes : payez seulement 5% du prix du loyer lors de la publication.',
                          )),
                          SizedBox(width: 12),
                          Expanded(child: _AdvantageCard(
                            icon: Icons.edit_outlined,
                            title: 'Contrôle total',
                            description: 'Modifiez vos tarifs ou supprimez votre bien instantanément.',
                          )),
                        ]),
                        SizedBox(height: 12),
                        _AdvantageCard(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Lien direct via WhatsApp',
                          description: 'Pas d\'intermédiaires inutiles. Le client intéressé vous contacte directement sur votre messagerie WhatsApp pour conclure l\'affaire.',
                          fullWidth: true,
                        ),
                      ],
                    ),
                  ),

                  // ── CTA Publication ───────────────────────────────────
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => context.go(AppRoutes.publish),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                            label: const Text('COMMENCER UNE PUBLICATION'),
                            style: ElevatedButton.styleFrom(
                              textStyle: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => context.go(AppRoutes.myPublications),
                            icon: const Icon(Icons.list_alt_rounded, size: 18),
                            label: const Text('Voir mes publications'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Compteur social ────────────────────────────────────
                  const SizedBox(height: 24),
                  _SocialProof(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Banner ───────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final dynamic user;
  const _HeroBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    final displayName = user?.fullName ?? 'Partenaire';
    final role        = user?.displayRole ?? '';

    return Container(
      height: 240,
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
          // Cercles décoratifs
          Positioned(
            right: -30, top: -30,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            left: -20, bottom: -20,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withOpacity(0.05),
              ),
            ),
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge espace partenaire
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.teal.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'ESPACE PARTENAIRE',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 9,
                      fontWeight: FontWeight.w800, color: AppColors.teal,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Bienvenue dans votre',
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 22,
                    fontWeight: FontWeight.w800, color: AppColors.white,
                  ),
                ),
                const Text(
                  'Lieu de Travail',
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 26,
                    fontWeight: FontWeight.w900, color: AppColors.teal,
                    letterSpacing: -0.5,
                  ),
                ),

                const Spacer(),

                // Badge utilisateur (bas du hero)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.orange.withOpacity(0.3),
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase() : 'P',
                        style: const TextStyle(
                          fontFamily: 'Inter', fontSize: 13,
                          fontWeight: FontWeight.w900, color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Inter', fontSize: 8,
                            fontWeight: FontWeight.w800, color: AppColors.orange,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          displayName.toLowerCase(),
                          style: const TextStyle(
                            fontFamily: 'Inter', fontSize: 12,
                            fontWeight: FontWeight.w700, color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte avantage ────────────────────────────────────────────────────────────
class _AdvantageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool highlighted;
  final bool fullWidth;

  const _AdvantageCard({
    required this.icon,
    required this.title,
    required this.description,
    this.highlighted = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.teal.withOpacity(0.06)
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? AppColors.teal.withOpacity(0.3) : AppColors.borderLight,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: highlighted
                  ? AppColors.teal.withOpacity(0.12)
                  : AppColors.bgTealLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: highlighted ? AppColors.teal : AppColors.teal, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter', fontSize: 12,
              fontWeight: FontWeight.w800, color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'Inter', fontSize: 11,
              color: AppColors.textSecondary, height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Social proof ──────────────────────────────────────────────────────────────
class _SocialProof extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.bgTealLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.teal.withOpacity(0.15)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: '500+', label: 'Propriétaires'),
          _Divider(),
          _StatItem(value: '1 200+', label: 'Annonces actives'),
          _Divider(),
          _StatItem(value: '98%', label: 'Satisfaction'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(
        fontFamily: 'Inter', fontSize: 18,
        fontWeight: FontWeight.w900, color: AppColors.teal,
      )),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(
        fontFamily: 'Inter', fontSize: 10,
        color: AppColors.textSecondary, fontWeight: FontWeight.w500,
      )),
    ]);
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.teal.withOpacity(0.2));
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String name;
  const _UserAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.teal.withOpacity(0.15),
      child: Text(initial, style: const TextStyle(
        fontFamily: 'Inter', fontSize: 14,
        fontWeight: FontWeight.w800, color: AppColors.teal,
      )),
    );
  }
}
