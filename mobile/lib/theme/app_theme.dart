import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional cool palette — deep teal + amber accent (no purple / cream clichés).
class AppColors {
  static const Color ink = Color(0xFF0B1F2A);
  static const Color inkSoft = Color(0xFF1A3A4A);
  static const Color teal = Color(0xFF0D9488);
  static const Color tealDeep = Color(0xFF0F766E);
  static const Color tealSoft = Color(0xFFCCFBF1);
  static const Color amber = Color(0xFFE8A317);
  static const Color amberSoft = Color(0xFFFFF4D6);
  static const Color mist = Color(0xFFEFF5F7);
  static const Color mistDeep = Color(0xFFD8E6EC);
  static const Color cloud = Color(0xFFF7FAFB);
  static const Color slate = Color(0xFF64748B);
  static const Color locked = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color danger = Color(0xFFDC2626);
  static const Color pathLine = Color(0xFF9DC4C0);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        primary: AppColors.tealDeep,
        secondary: AppColors.amber,
        surface: AppColors.cloud,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.mist,
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        centerTitle: true,
        titleTextStyle: GoogleFonts.vazirmatn(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tealDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.vazirmatn(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkSoft,
          side: const BorderSide(color: AppColors.teal, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.vazirmatn(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
