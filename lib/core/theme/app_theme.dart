import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// COULEURS
// ══════════════════════════════════════════════════════════════════════════════
class AppColors {
  AppColors._();
  static const Color teal        = Color(0xFF007B83);
  static const Color orange      = Color(0xFFF97316);
  static const Color dark        = Color(0xFF1A2B3C);
  static const Color darkNavy    = Color(0xFF021D33);
  static const Color bgLight     = Color(0xFFF8F6F2);
  static const Color bgTealLight = Color(0xFFF0F9FA);
  static const Color white       = Color(0xFFFFFFFF);
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted     = Color(0xFF9CA3AF);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);
  static const Color border      = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
}

// ══════════════════════════════════════════════════════════════════════════════
// THÈME GLOBAL — corrigé pour Flutter 3.19+ (CardThemeData)
// ══════════════════════════════════════════════════════════════════════════════
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(
      seedColor:  AppColors.teal,
      primary:    AppColors.teal,
      secondary:  AppColors.orange,
      surface:    AppColors.white,
      error:      AppColors.error,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.bgLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.dark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.dark,
        letterSpacing: -0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w800,
          fontSize: 15,
          letterSpacing: 0.5,
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.teal,
        side: const BorderSide(color: AppColors.teal, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.teal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 14,
        fontFamily: 'Inter',
      ),
    ),
    // ✅ CORRIGÉ : CardThemeData (pas CardTheme) pour Flutter 3.19+
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderLight),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.dark,
      contentTextStyle: const TextStyle(
          color: AppColors.white, fontFamily: 'Inter'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.teal,
      unselectedItemColor: AppColors.textMuted,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 11),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 11),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// TEXT STYLES
// ══════════════════════════════════════════════════════════════════════════════
class AppTextStyles {
  AppTextStyles._();
  static const TextStyle displayLarge = TextStyle(fontFamily:'Inter',fontSize:36,fontWeight:FontWeight.w900,color:AppColors.white,height:1.1,letterSpacing:-1);
  static const TextStyle displayMedium = TextStyle(fontFamily:'Inter',fontSize:28,fontWeight:FontWeight.w800,color:AppColors.dark,letterSpacing:-0.5);
  static const TextStyle heading1 = TextStyle(fontFamily:'Inter',fontSize:22,fontWeight:FontWeight.w800,color:AppColors.dark,letterSpacing:-0.3);
  static const TextStyle heading2 = TextStyle(fontFamily:'Inter',fontSize:18,fontWeight:FontWeight.w700,color:AppColors.dark);
  static const TextStyle heading3 = TextStyle(fontFamily:'Inter',fontSize:16,fontWeight:FontWeight.w700,color:AppColors.dark);
  static const TextStyle body = TextStyle(fontFamily:'Inter',fontSize:14,fontWeight:FontWeight.w400,color:AppColors.textPrimary,height:1.5);
  static const TextStyle bodyMedium = TextStyle(fontFamily:'Inter',fontSize:14,fontWeight:FontWeight.w600,color:AppColors.textPrimary);
  static const TextStyle caption = TextStyle(fontFamily:'Inter',fontSize:12,fontWeight:FontWeight.w400,color:AppColors.textSecondary);
  static const TextStyle captionBold = TextStyle(fontFamily:'Inter',fontSize:11,fontWeight:FontWeight.w800,color:AppColors.textSecondary,letterSpacing:0.8);
  static const TextStyle price = TextStyle(fontFamily:'Inter',fontSize:18,fontWeight:FontWeight.w900,color:AppColors.orange);
  static const TextStyle label = TextStyle(fontFamily:'Inter',fontSize:11,fontWeight:FontWeight.w800,color:AppColors.textSecondary,letterSpacing:0.8);
  static const TextStyle buttonLabel = TextStyle(fontFamily:'Inter',fontSize:15,fontWeight:FontWeight.w800,letterSpacing:0.3);
}

// ══════════════════════════════════════════════════════════════════════════════
// DÉCORATIONS
// ══════════════════════════════════════════════════════════════════════════════
class AppDecorations {
  AppDecorations._();

  static BoxDecoration card = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.borderLight),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration heroBanner = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withOpacity(0.2),
        Colors.black.withOpacity(0.75),
      ],
    ),
  );
}

class AppDimensions {
  AppDimensions._();
  static const double paddingXS = 4;
  static const double paddingS  = 8;
  static const double paddingM  = 16;
  static const double paddingL  = 24;
  static const double paddingXL = 32;
  static const double radiusS  = 8;
  static const double radiusM  = 14;
  static const double radiusL  = 20;
  static const double radiusXL = 28;
  static const double cardBorderRadius   = 20;
  static const double buttonBorderRadius = 14;
  static const double inputBorderRadius  = 14;
  static const double bottomNavHeight    = 70;
}
