import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import 'error_widgets.dart';

// ── Provider rôle courant ─────────────────────────────────────────────────────
final currentRoleProvider = FutureProvider<String>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return (await storage.getUserRole())?.toLowerCase() ?? '';
});

// ══════════════════════════════════════════════════════════════════════════════
// MAIN SCAFFOLD — Bottom nav + bannière offline
// ══════════════════════════════════════════════════════════════════════════════
class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentRoleProvider);

    return roleAsync.when(
      loading: () => Scaffold(body: child),
      error: (_, __) => Scaffold(body: child),
      data: (role) {
        final isOwner = ['proprietaire', 'pending_proprietaire',
                         'agence', 'pending_agent'].contains(role);
        final isLoggedIn = role.isNotEmpty;
        final currentPath = GoRouterState.of(context).matchedLocation;

        return Scaffold(
          body: Column(
            children: [
              // Bannière offline en haut
              const NoConnectionBanner(),
              Expanded(child: child),
            ],
          ),
          bottomNavigationBar: _DreamHouseBottomNav(
            currentPath: currentPath,
            isOwner: isOwner,
            isLoggedIn: isLoggedIn,
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BOTTOM NAVIGATION
// ══════════════════════════════════════════════════════════════════════════════
class _DreamHouseBottomNav extends StatelessWidget {
  final String currentPath;
  final bool isOwner;
  final bool isLoggedIn;

  const _DreamHouseBottomNav({
    required this.currentPath,
    required this.isOwner,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    final currentIndex = _getCurrentIndex(items);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: _NavItem(
                  icon: isActive ? item.activeIcon : item.icon,
                  label: item.label,
                  isActive: isActive,
                  onTap: () => context.go(item.route),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  List<_NavItemData> _buildItems() {
    if (isOwner) {
      return [
        const _NavItemData(Icons.home_outlined, Icons.home_rounded, 'Accueil',   AppRoutes.ownerHome),
        const _NavItemData(Icons.search_outlined, Icons.search_rounded, 'Catalogue', AppRoutes.catalogue),
        const _NavItemData(Icons.add_circle_outline, Icons.add_circle_rounded, 'Publier', AppRoutes.publish),
        const _NavItemData(Icons.list_alt_outlined, Icons.list_alt_rounded, 'Mes biens', AppRoutes.myPublications),
        const _NavItemData(Icons.person_outline, Icons.person_rounded, 'Profil', AppRoutes.profile),
      ];
    } else if (isLoggedIn) {
      return [
        const _NavItemData(Icons.home_outlined, Icons.home_rounded, 'Accueil',    AppRoutes.home),
        const _NavItemData(Icons.search_outlined, Icons.search_rounded, 'Catalogue', AppRoutes.catalogue),
        const _NavItemData(Icons.person_outline, Icons.person_rounded, 'Profil',   AppRoutes.profile),
      ];
    } else {
      return [
        const _NavItemData(Icons.home_outlined, Icons.home_rounded, 'Accueil',    AppRoutes.home),
        const _NavItemData(Icons.search_outlined, Icons.search_rounded, 'Catalogue', AppRoutes.catalogue),
        const _NavItemData(Icons.person_outline, Icons.person_rounded, 'Connexion', AppRoutes.login),
      ];
    }
  }

  int _getCurrentIndex(List<_NavItemData> items) {
    for (int i = 0; i < items.length; i++) {
      if (currentPath.startsWith(items[i].route)) return i;
    }
    return 0;
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  const _NavItemData(this.icon, this.activeIcon, this.label, this.route);
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon, required this.label,
    required this.isActive, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.teal.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon,
                  color: isActive ? AppColors.teal : AppColors.textMuted,
                  size: 22),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              fontFamily: 'Inter', fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.teal : AppColors.textMuted,
            )),
          ],
        ),
      ),
    );
  }
}
