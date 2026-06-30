import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_assets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS RÉUTILISABLES AUTH
// ══════════════════════════════════════════════════════════════════════════════

/// Logo DreamHouse centré (utilisé sur les deux écrans auth)
class DreamHouseLogo extends StatelessWidget {
  final double size;
  const DreamHouseLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Image.asset(
              AppAssets.logo,
              width: size, height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  'D',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: size * 0.55,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        RichText(
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
      ],
    );
  }
}

/// Champ de texte stylisé DreamHouse
class DhTextField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final String? prefixText;

  const DhTextField({
    super.key,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.prefixText,
  });

  @override
  State<DhTextField> createState() => _DhTextFieldState();
}

class _DhTextFieldState extends State<DhTextField> {
  bool _obscure = true;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword && _obscure,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        style: const TextStyle(
          fontFamily: 'Inter', fontSize: 14,
          fontWeight: FontWeight.w500, color: AppColors.dark,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: Icon(
            widget.icon,
            color: _focused ? AppColors.teal : AppColors.textMuted,
            size: 20,
          ),
          prefixText: widget.prefixText,
          prefixStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 14,
            fontWeight: FontWeight.w600, color: AppColors.dark,
          ),
          suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textMuted, size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        ),
      ),
    );
  }
}

/// Dropdown stylisé DreamHouse
class DhDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? label;
  final IconData? icon;

  const DhDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Inter', fontSize: 14,
        fontWeight: FontWeight.w500, color: AppColors.dark,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null
          ? Icon(icon, color: AppColors.textMuted, size: 20)
          : null,
        labelStyle: const TextStyle(
          fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary,
        ),
      ),
      dropdownColor: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.teal),
    );
  }
}

/// Bouton d'upload CNI (recto/verso)
class CniUploadButton extends StatelessWidget {
  final String label;
  final String? fileName;
  final VoidCallback onTap;

  const CniUploadButton({
    super.key,
    required this.label,
    this.fileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: hasFile ? AppColors.teal.withOpacity(0.06) : AppColors.bgLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFile ? AppColors.teal : AppColors.border,
            width: hasFile ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              hasFile ? Icons.check_circle_rounded : Icons.upload_file_rounded,
              color: hasFile ? AppColors.teal : AppColors.textMuted,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              hasFile ? fileName! : label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: hasFile ? FontWeight.w700 : FontWeight.w500,
                color: hasFile ? AppColors.teal : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bannière d'erreur (équivalent du toast rouge)
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter', fontSize: 13,
                fontWeight: FontWeight.w500, color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Divider avec texte centré ("ou")
class DhDivider extends StatelessWidget {
  final String text;
  const DhDivider({super.key, this.text = 'ou'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderLight, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter', fontSize: 12,
              color: AppColors.textMuted, fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderLight, thickness: 1)),
      ],
    );
  }
}
