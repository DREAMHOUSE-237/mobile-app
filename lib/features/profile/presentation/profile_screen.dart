import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/data/user_model.dart';
import '../data/profile_repository.dart';
import '../../../shared/widgets/main_scaffold.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PROFILE SCREEN — Équivalent de Profil.jsx
// FIX : le dropdown région utilise les clés minuscules alignées sur le backend
//       (centre, littoral, nord_ouest…) comme dans register_screen.dart
// FIX : après déconnexion, currentRoleProvider est invalidé pour que la
//       bottom nav se remette à jour immédiatement
// ══════════════════════════════════════════════════════════════════════════════
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(userProfileProvider.future),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const _ProfileShimmer(),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(userProfileProvider.future),
        ),
        data: (user) => _ProfileContent(user: user),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CONTENU PROFIL
// ══════════════════════════════════════════════════════════════════════════════
class _ProfileContent extends ConsumerWidget {
  final UserModel user;
  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = user.isOwnerRole
        ? ref.watch(identityStatusProvider)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ProfileHero(user: user),
          const SizedBox(height: 16),

          if (user.isOwnerRole && identityAsync != null)
            identityAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (status) => status != null
                  ? _IdentityBadge(status: status)
                  : const SizedBox(),
            ),

          if (user.isOwnerRole) const SizedBox(height: 12),

          _InfoCard(user: user),
          const SizedBox(height: 16),

          if (user.isOwnerRole && !user.identityVerified)
            _CNIUploadCard(onSubmit: (recto, verso) async {
              try {
                await ref
                    .read(profileRepositoryProvider)
                    .submitIdentity(cniRecto: recto, cniVerso: verso);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('CNI soumise ! En cours de validation.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  ref.refresh(identityStatusProvider.future);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur : $e')),
                  );
                }
              }
            }),

          if (user.isOwnerRole && !user.identityVerified)
            const SizedBox(height: 16),

          _EditProfileCard(user: user),
          const SizedBox(height: 16),

          // FIX : on invalide currentRoleProvider à la déconnexion
          // pour que la bottom nav passe immédiatement en mode "non connecté"
          _LogoutButton(onLogout: () async {
            await ref.read(authNotifierProvider.notifier).logout();
            ref.invalidate(currentRoleProvider);
            ref.invalidate(userProfileProvider);
            if (context.mounted) context.go(AppRoutes.login);
          }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Hero card profil ──────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final UserModel user;
  const _ProfileHero({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.dark, Color(0xFF0D3B4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.teal, width: 2),
            ),
            child: Center(
              child: Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 28,
                  fontWeight: FontWeight.w900, color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            user.fullName.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter', fontSize: 16,
              fontWeight: FontWeight.w900, color: AppColors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          Text(
            user.email,
            style: const TextStyle(
              fontFamily: 'Inter', fontSize: 12, color: Colors.white60,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _HeroBadge(
                label: '● ${user.displayRole.toUpperCase()}',
                color: AppColors.teal,
              ),
              if (user.isActive)
                const _HeroBadge(label: '✓ COMPTE ACTIF', color: AppColors.success),
              if (user.identityVerified)
                const _HeroBadge(label: '✓ IDENTITÉ VÉRIFIÉE', color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _HeroBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter', fontSize: 9,
          fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Badge statut CNI ──────────────────────────────────────────────────────────
class _IdentityBadge extends StatelessWidget {
  final Map<String, dynamic> status;
  const _IdentityBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final statusKey = (status['status'] ?? '').toString().toLowerCase();
    Color color;
    IconData icon;
    String label;

    switch (statusKey) {
      case 'approved':
        color = AppColors.success; icon = Icons.verified_rounded;
        label = 'Identité vérifiée';
        break;
      case 'pending':
        color = AppColors.warning; icon = Icons.hourglass_top_rounded;
        label = 'Vérification en cours';
        break;
      case 'rejected':
        color = AppColors.error; icon = Icons.cancel_rounded;
        label = 'Vérification refusée';
        break;
      default:
        color = AppColors.textMuted; icon = Icons.info_outline_rounded;
        label = 'Statut inconnu';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              fontFamily: 'Inter', fontSize: 13,
              fontWeight: FontWeight.w700, color: color,
            )),
          ]),
          if (statusKey == 'rejected' && status['reason'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Motif : ${status['reason']}',
              style: const TextStyle(
                fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Card infos personnelles ───────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final UserModel user;
  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('INFORMATIONS PERSONNELLES', style: AppTextStyles.label),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _InfoField(label: 'NOM',    value: user.nom    ?? '—')),
            const SizedBox(width: 16),
            Expanded(child: _InfoField(label: 'PRÉNOM', value: user.prenom ?? '—')),
          ]),
          const SizedBox(height: 14),
          _InfoField(
            label: 'EMAIL', value: user.email,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 14),
          _InfoField(
            label: 'TÉLÉPHONE',
            value: user.telephone ?? '—',
            icon: Icons.phone_outlined,
            trailing: user.telephone != null
                ? const Icon(Icons.verified_rounded,
                    size: 14, color: AppColors.success)
                : null,
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _InfoField(label: 'VILLE',  value: user.ville  ?? '—')),
            const SizedBox(width: 16),
            Expanded(child: _InfoField(label: 'RÉGION', value: user.region ?? '—')),
          ]),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Widget? trailing;
  const _InfoField({
    required this.label, required this.value,
    this.icon, this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 4),
        Row(children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) trailing!,
        ]),
      ],
    );
  }
}

// ── Upload CNI ────────────────────────────────────────────────────────────────
class _CNIUploadCard extends StatefulWidget {
  final Future<void> Function(File recto, File verso) onSubmit;
  const _CNIUploadCard({required this.onSubmit});

  @override
  State<_CNIUploadCard> createState() => _CNIUploadCardState();
}

class _CNIUploadCardState extends State<_CNIUploadCard> {
  File? _recto;
  File? _verso;
  bool  _loading = false;

  Future<void> _pick(bool isRecto) async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img == null) return;
    setState(() {
      if (isRecto) { _recto = File(img.path); }
      else         { _verso = File(img.path); }
    });
  }

  Future<void> _submit() async {
    if (_recto == null || _verso == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez les deux faces de la CNI')),
      );
      return;
    }
    setState(() => _loading = true);
    await widget.onSubmit(_recto!, _verso!);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.badge_outlined, color: AppColors.warning, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'DOCUMENTS D\'IDENTITÉ',
                style: TextStyle(
                  fontFamily: 'Inter', fontSize: 12,
                  fontWeight: FontWeight.w800, color: AppColors.warning,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          const Text(
            'Soumettez votre CNI pour valider votre compte.',
            style: TextStyle(
              fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _CniPicker(
              label: 'CNI RECTO', hasFile: _recto != null,
              onTap: () => _pick(true),
            )),
            const SizedBox(width: 12),
            Expanded(child: _CniPicker(
              label: 'CNI VERSO', hasFile: _verso != null,
              onTap: () => _pick(false),
            )),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity, height: 44,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.upload_rounded, size: 18),
              label: Text(_loading ? 'Envoi...' : 'Soumettre ma CNI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CniPicker extends StatelessWidget {
  final String label;
  final bool hasFile;
  final VoidCallback onTap;
  const _CniPicker({required this.label, required this.hasFile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: hasFile ? AppColors.teal.withOpacity(0.06) : AppColors.bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? AppColors.teal : AppColors.border,
            width: hasFile ? 2 : 1,
          ),
        ),
        child: Column(children: [
          Icon(
            hasFile ? Icons.check_circle_rounded : Icons.upload_file_rounded,
            color: hasFile ? AppColors.teal : AppColors.textMuted, size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            hasFile ? '✓ Ajouté' : label,
            style: TextStyle(
              fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
              color: hasFile ? AppColors.teal : AppColors.textSecondary,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Modifier profil ───────────────────────────────────────────────────────────
class _EditProfileCard extends ConsumerStatefulWidget {
  final UserModel user;
  const _EditProfileCard({required this.user});

  @override
  ConsumerState<_EditProfileCard> createState() => _EditProfileCardState();
}

class _EditProfileCardState extends ConsumerState<_EditProfileCard> {
  late final _nomCtrl    = TextEditingController(text: widget.user.nom       ?? '');
  late final _prenomCtrl = TextEditingController(text: widget.user.prenom    ?? '');
  late final _telCtrl    = TextEditingController(text: widget.user.telephone ?? '');
  late final _villeCtrl  = TextEditingController(text: widget.user.ville     ?? '');
  String _region = 'centre';
  bool   _loading  = false;
  bool   _expanded = false;

  // FIX : clés en minuscules alignées sur le backend et sur register_screen.dart
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

  @override
  void initState() {
    super.initState();
    final raw = (widget.user.region ?? '').toLowerCase();
    _region = _regionMap.containsKey(raw) ? raw : 'centre';
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _prenomCtrl.dispose();
    _telCtrl.dispose(); _villeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
        nom:    _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        tel:    _telCtrl.text.trim(),
        ville:  _villeCtrl.text.trim(),
        region: _region,
      );
      if (mounted) {
        ref.refresh(userProfileProvider.future);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour !'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _expanded = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.card,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                const Icon(Icons.edit_outlined, color: AppColors.teal, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Modifier mon profil', style: AppTextStyles.heading3),
                ),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.teal,
                ),
              ]),
            ),
          ),

          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(children: [
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 14),

                Row(children: [
                  Expanded(child: _field(_nomCtrl,    'Nom')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_prenomCtrl, 'Prénom')),
                ]),
                const SizedBox(height: 12),
                _field(_telCtrl, 'Téléphone', keyboard: TextInputType.phone),
                const SizedBox(height: 12),
                _field(_villeCtrl, 'Ville'),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _region,
                  items: _regionMap.entries.map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(
                        fontFamily: 'Inter', fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setState(() => _region = v!),
                  decoration: InputDecoration(
                    labelText: 'Région',
                    labelStyle: const TextStyle(
                        fontFamily: 'Inter', fontSize: 12,
                        color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderLight)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.teal, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  dropdownColor: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.teal),
                  style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 13, color: AppColors.dark),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: _loading
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_loading ? 'Enregistrement...' : 'Enregistrer'),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.teal, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ── Bouton déconnexion ────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: OutlinedButton.icon(
        onPressed: onLogout,
        icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
        label: const Text('Déconnexion', style: TextStyle(
          fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppColors.error,
        )),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ── Shimmer chargement ────────────────────────────────────────────────────────
class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(height: 200,
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 16),
          Container(height: 180,
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 16),
          Container(height: 60,
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(14))),
        ]),
      ),
    );
  }
}

// ── Erreur ────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('Impossible de charger le profil',
                style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(message,
                style: AppTextStyles.caption, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}