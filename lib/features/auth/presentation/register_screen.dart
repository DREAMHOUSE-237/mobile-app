import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../auth_notifier.dart';
import 'auth_widgets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// REGISTER SCREEN — Aligné avec Inscription.jsx du nouveau frontend
// FIX 1 : valeurs region en minuscules (centre, littoral...) comme le web
// FIX 2 : champs supplémentaires pour le rôle 'agence' (nomAgence, nomPDG, etc.)
// ══════════════════════════════════════════════════════════════════════════════
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nomCtrl      = TextEditingController();
  final _prenomCtrl   = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _telCtrl      = TextEditingController();
  final _villeCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();

  // Champs spécifiques agence (Inscription.jsx ligne 62-66)
  final _nomAgenceCtrl           = TextEditingController();
  final _nomPDGCtrl              = TextEditingController();
  final _numeroIdentificationCtrl = TextEditingController();
  final _contactPrincipalCtrl    = TextEditingController();
  final _quartierCtrl            = TextEditingController();

  String _role   = 'client';
  // FIX : valeurs minuscules alignées sur Inscription.jsx (option value="centre" etc.)
  String _region = 'centre';
  File?  _cniRecto;
  File?  _cniVerso;
  bool   _success = false;

  final _roles = ['client', 'proprietaire', 'agence'];

  // FIX : map région — clés en minuscules comme dans Inscription.jsx
  final Map<String, String> _regionMap = const {
    'centre':      'Centre',
    'littoral':    'Littoral',
    'nord_ouest':  'Nord-Ouest',
    'sud_ouest':   'Sud-Ouest',
    'ouest':       'Ouest',
    'sud':         'Sud',
    'est':         'Est',
    'nord':        'Nord',
    'extreme_nord':'Extrême-Nord',
    'adamaoua':    'Adamaoua',
  };

  String _roleLabel(String r) {
    switch (r) {
      case 'client':       return 'Client';
      case 'proprietaire': return 'Propriétaire';
      case 'agence':       return 'Agence Immobilière';
      default:             return r;
    }
  }

  bool get _needsCni     => _role == 'proprietaire' || _role == 'agence';
  bool get _isAgence     => _role == 'agence';

  @override
  void dispose() {
    _nomCtrl.dispose(); _prenomCtrl.dispose(); _emailCtrl.dispose();
    _telCtrl.dispose(); _villeCtrl.dispose(); _passCtrl.dispose();
    _nomAgenceCtrl.dispose(); _nomPDGCtrl.dispose();
    _numeroIdentificationCtrl.dispose(); _contactPrincipalCtrl.dispose();
    _quartierCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCni(bool isRecto) async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img == null) return;
    setState(() {
      if (isRecto) { _cniRecto = File(img.path); }
      else         { _cniVerso = File(img.path); }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_needsCni && (_cniRecto == null || _cniVerso == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez uploader les deux faces de votre CNI')),
      );
      return;
    }
    FocusScope.of(context).unfocus();

    final success = await ref
        .read(authNotifierProvider.notifier)
        .register(
          nom:       _nomCtrl.text.trim(),
          prenom:    _prenomCtrl.text.trim(),
          email:     _emailCtrl.text.trim(),
          tel:       _telCtrl.text.trim(),
          ville:     _villeCtrl.text.trim(),
          region:    _region,
          password:  _passCtrl.text,
          role:      _role,
          cniRecto:  _cniRecto,
          cniVerso:  _cniVerso,
          // Champs agence (ignorés si role != 'agence')
          nomAgence:            _isAgence ? _nomAgenceCtrl.text.trim() : null,
          nomPDG:               _isAgence ? _nomPDGCtrl.text.trim() : null,
          numeroIdentification: _isAgence ? _numeroIdentificationCtrl.text.trim() : null,
          contactPrincipal:     _isAgence ? _contactPrincipalCtrl.text.trim() : null,
          quartier:             _isAgence ? _quartierCtrl.text.trim() : null,
        );

    if (!mounted) return;
    if (success) setState(() => _success = true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    if (_success) {
      return _SuccessScreen(onLogin: () => context.go(AppRoutes.login));
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _HeroBannerRegister(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DreamHouseLogo(),
                      const SizedBox(height: 20),
                      const Text('Créer un compte', style: AppTextStyles.heading1),
                      const SizedBox(height: 4),
                      const Text('Rejoignez-nous pour gérer vos biens',
                          style: AppTextStyles.caption),
                      const SizedBox(height: 24),

                      if (authState.errorMessage != null) ...[
                        ErrorBanner(message: authState.errorMessage!),
                        const SizedBox(height: 16),
                      ],

                      // Type de compte
                      const Text('TYPE DE COMPTE', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      DhDropdown<String>(
                        value: _role,
                        icon: Icons.badge_outlined,
                        items: _roles.map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(_roleLabel(r),
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
                        )).toList(),
                        onChanged: (v) => setState(() => _role = v!),
                      ),
                      const SizedBox(height: 16),

                      // ── Champs spécifiques AGENCE ──────────────────────
                      if (_isAgence) ...[
                        DhTextField(
                          hint: 'Nom de l\'agence',
                          icon: Icons.business_outlined,
                          controller: _nomAgenceCtrl,
                          validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null,
                        ),
                        const SizedBox(height: 14),
                        DhTextField(
                          hint: 'Nom du PDG / Directeur',
                          icon: Icons.person_outlined,
                          controller: _nomPDGCtrl,
                          validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null,
                        ),
                        const SizedBox(height: 14),
                        DhTextField(
                          hint: 'Numéro d\'identification (RCCM, etc.)',
                          icon: Icons.numbers_outlined,
                          controller: _numeroIdentificationCtrl,
                          validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null,
                        ),
                        const SizedBox(height: 14),
                        DhTextField(
                          hint: 'Contact principal de l\'agence',
                          icon: Icons.phone_outlined,
                          controller: _contactPrincipalCtrl,
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null,
                        ),
                        const SizedBox(height: 14),
                        DhTextField(
                          hint: 'Quartier',
                          icon: Icons.place_outlined,
                          controller: _quartierCtrl,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Nom + Prénom
                      Row(children: [
                        Expanded(child: DhTextField(
                          hint: 'Nom', icon: Icons.person_outline,
                          controller: _nomCtrl,
                          validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: DhTextField(
                          hint: 'Prénom', icon: Icons.person_outline,
                          controller: _prenomCtrl,
                          validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null,
                        )),
                      ]),
                      const SizedBox(height: 14),

                      DhTextField(
                        hint: 'votre@email.com',
                        icon: Icons.email_outlined,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Requis';
                          if (!v!.contains('@')) return 'Email invalide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      DhTextField(
                        hint: '6XX XX XX XX',
                        icon: Icons.phone_outlined,
                        controller: _telCtrl,
                        prefixText: '+237 ',
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 14),

                      DhTextField(
                        hint: 'Ville',
                        icon: Icons.location_city_outlined,
                        controller: _villeCtrl,
                        validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 14),

                      DhDropdown<String>(
                        value: _region,
                        icon: Icons.map_outlined,
                        label: 'Sélectionnez votre région',
                        items: _regionMap.entries.map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value, style: const TextStyle(
                              fontFamily: 'Inter', fontSize: 14)),
                        )).toList(),
                        onChanged: (v) => setState(() => _region = v!),
                      ),
                      const SizedBox(height: 14),

                      DhTextField(
                        hint: 'Mot de passe (min. 6 caractères)',
                        icon: Icons.lock_outline_rounded,
                        controller: _passCtrl,
                        isPassword: true,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Requis';
                          if (v!.length < 6) return 'Minimum 6 caractères';
                          return null;
                        },
                      ),

                      // CNI
                      if (_needsCni) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'DOCUMENTS D\'IDENTITÉ (OBLIGATOIRE)',
                          style: AppTextStyles.label,
                        ),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: CniUploadButton(
                            label: 'CNI RECTO',
                            fileName: _cniRecto != null ? 'Recto ✓' : null,
                            onTap: () => _pickCni(true),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: CniUploadButton(
                            label: 'CNI VERSO',
                            fileName: _cniVerso != null ? 'Verso ✓' : null,
                            onTap: () => _pickCni(false),
                          )),
                        ]),
                      ],

                      const SizedBox(height: 28),

                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _submit,
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    color: AppColors.white, strokeWidth: 2))
                            : const Text("S'inscrire"),
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: GestureDetector(
                          onTap: () => context.go(AppRoutes.login),
                          child: RichText(
                            text: const TextSpan(children: [
                              TextSpan(
                                text: 'Vous avez déjà un compte ? ',
                                style: TextStyle(fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                              TextSpan(
                                text: 'Connectez-vous',
                                style: TextStyle(fontFamily: 'Inter',
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: AppColors.teal),
                              ),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => context.go(AppRoutes.home),
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: const Text('Retour au site'),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.textMuted),
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

class _HeroBannerRegister extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160, width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.teal, AppColors.dark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("L'excellence\nn'attend pas.",
              style: TextStyle(fontFamily: 'Inter', fontSize: 22,
                  fontWeight: FontWeight.w900, color: AppColors.white,
                  height: 1.2)),
          SizedBox(height: 6),
          Text('Faites briller vos annonces immobilières.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                  color: Colors.white70)),
        ],
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  final VoidCallback onLogin;
  const _SuccessScreen({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('Compte créé !',
                  style: AppTextStyles.heading1, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                'Votre compte a été créé. Vous pouvez maintenant vous connecter.',
                style: AppTextStyles.body, textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onLogin,
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}