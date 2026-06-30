import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/catalogue/presentation/catalogue_screen.dart';
import '../../features/detail/presentation/detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/owner/presentation/owner_home_screen.dart';
import '../../features/owner/presentation/publish/publish_screen.dart';
import '../../features/owner/presentation/my_publications_screen.dart';
import '../../features/owner/presentation/edit_publication_screen.dart';
import '../storage/secure_storage.dart';
import '../../shared/widgets/main_scaffold.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NOMS DES ROUTES — Centralisés pour éviter les fautes de frappe
// Équivalent des paths dans App.jsx
// ══════════════════════════════════════════════════════════════════════════════
class AppRoutes {
  AppRoutes._();
  static const String splash          = '/';
  static const String login           = '/connexion';
  static const String register        = '/inscription';
  static const String home            = '/accueil';
  static const String catalogue       = '/catalogue';
  static const String detail          = '/detail/:id';
  static const String profile         = '/profile';
  static const String ownerHome       = '/accueil2';
  static const String publish         = '/publication';
  static const String myPublications  = '/mes-publications';
  static const String editPublication = '/modif/:id';

  static String detailPath(String id)   => '/detail/$id';
  static String editPath(String id)     => '/modif/$id';
}

// Rôles autorisés pour l'espace propriétaire
const _ownerRoles = ['proprietaire', 'pending_proprietaire', 'agence', 'pending_agent'];

// ══════════════════════════════════════════════════════════════════════════════
// ROUTER PROVIDER
// ══════════════════════════════════════════════════════════════════════════════
final appRouterProvider = Provider<GoRouter>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return _buildRouter(storage);
});

GoRouter _buildRouter(SecureStorage storage) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final isOnAuth   = state.matchedLocation == AppRoutes.login ||
                         state.matchedLocation == AppRoutes.register;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;

      // Routes publiques toujours accessibles
      if (isOnSplash || isOnAuth) return null;

      final hasSession = await storage.hasValidSession();
      if (!hasSession) return AppRoutes.login;

      final role = (await storage.getUserRole())?.toLowerCase() ?? '';

      // Routes réservées propriétaire/agence
      final ownerRoutes = [
        AppRoutes.ownerHome, AppRoutes.publish,
        AppRoutes.myPublications,
      ];
      final isOwnerRoute = ownerRoutes.contains(state.matchedLocation) ||
          state.matchedLocation.startsWith('/modif/');

      if (isOwnerRoute && !_ownerRoles.contains(role)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // ── Splash ───────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Auth (sans bottom nav) ───────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Pages avec bottom nav (ShellRoute) ──────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.catalogue,
            name: 'catalogue',
            builder: (_, __) => const CatalogueScreen(),
          ),
          GoRoute(
            path: AppRoutes.detail,
            name: 'detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return DetailScreen(id: id);
            },
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          // ── Espace propriétaire ──────────────────────────────────────────────
          GoRoute(
            path: AppRoutes.ownerHome,
            name: 'ownerHome',
            builder: (_, __) => const OwnerHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.publish,
            name: 'publish',
            builder: (_, __) => const PublishScreen(),
          ),
          GoRoute(
            path: AppRoutes.myPublications,
            name: 'myPublications',
            builder: (_, __) => const MyPublicationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.editPublication,
            name: 'editPublication',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EditPublicationScreen(id: id);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Page introuvable', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
}
