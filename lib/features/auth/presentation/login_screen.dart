import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../profile/data/profile_repository.dart';
import '../auth_notifier.dart';
import '../../home/presentation/home_screen.dart';
import '../../../shared/widgets/main_scaffold.dart';
import 'auth_widgets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// LOGIN SCREEN — Équivalent de Connexion.jsx
// FIX : après un login réussi, on invalide currentRoleProvider pour que
// la bottom nav lise le rôle du NOUVEL utilisateur et non celui de la
// session précédente encore en cache Riverpod.
// ══════════════════════════════════════════════════════════════════════════════
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await ref.read(authNotifierProvider.notifier).login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    if (success) {
      // FIX : invalider le cache du rôle pour forcer la bottom nav
      // à relire le rôle du nouvel utilisateur depuis SecureStorage
      ref.invalidate(currentRoleProvider);
      // Également invalider le profil en cache si présent
      ref.invalidate(userProfileProvider);

      final user = ref.read(currentUserProvider);
      context.go(user?.isOwnerRole == true ? AppRoutes.ownerHome : AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _HeroBanner(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DreamHouseLogo(),
                      const SizedBox(height: 24),

                      const Text('Bienvenue', style: AppTextStyles.heading1),
                      const SizedBox(height: 4),
                      const Text(
                        'Connectez-vous pour explorer le monde',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 28),

                      if (authState.errorMessage != null) ...[
                        ErrorBanner(message: authState.errorMessage!),
                        const SizedBox(height: 16),
                      ],

                      DhTextField(
                        hint: 'votre@email.com',
                        icon: Icons.email_outlined,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email requis';
                          if (!v.contains('@')) return 'Email invalide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      DhTextField(
                        hint: 'Mot de passe',
                        icon: Icons.lock_outline_rounded,
                        controller: _passCtrl,
                        isPassword: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Mot de passe requis';
                          if (v.length < 6) return 'Minimum 6 caractères';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _submit,
                        child: authState.isLoading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.white, strokeWidth: 2,
                              ),
                            )
                          : const Text('Se Connecter'),
                      ),
                      const SizedBox(height: 18),

                      Center(
                        child: GestureDetector(
                          onTap: () => context.go(AppRoutes.register),
                          child: RichText(
                            text: const TextSpan(children: [
                              TextSpan(
                                text: "Vous n'avez pas de compte ? ",
                                style: TextStyle(
                                  fontFamily: 'Inter', fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextSpan(
                                text: 'Inscrivez-vous',
                                style: TextStyle(
                                  fontFamily: 'Inter', fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.teal,
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: TextButton.icon(
                          onPressed: () => context.go(AppRoutes.home),
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: const Text('Retour au site'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textMuted,
                            textStyle: const TextStyle(
                              fontFamily: 'Inter', fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.dark, AppColors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.1),
              Colors.black.withOpacity(0.5),
            ],
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "L'excellence\nn'attend pas.",
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 40, height: 3,
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rejoignez la communauté DreamHouse.',
              style: TextStyle(
                fontFamily: 'Inter', fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}