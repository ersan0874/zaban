import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Playful learning palette (Duolingo-inspired): white ground, bright
/// semantic colors, each with a darker "edge" used for 3D buttons.
///
/// Meaning is fixed: leaf = progress/correct, sky = selection, sun = reward/XP,
/// flame = streak, coral = hearts/wrong, grape = gems/Super.
class AppColors {
  // Core semantic colors
  static const Color leaf = Color(0xFF58C322);
  static const Color leafDark = Color(0xFF46A012);
  static const Color leafSoft = Color(0xFFE6F8D9);
  static const Color sky = Color(0xFF2BA8F0);
  static const Color skyDark = Color(0xFF1A8BD0);
  static const Color skySoft = Color(0xFFDDF2FD);
  static const Color skyBorder = Color(0xFF9AD7FA);
  static const Color sun = Color(0xFFFFC930);
  static const Color sunDark = Color(0xFFE0A800);
  static const Color sunSoft = Color(0xFFFFF6D6);
  static const Color flame = Color(0xFFFF9A1F);
  static const Color coral = Color(0xFFFF5A5F);
  static const Color coralDark = Color(0xFFE0383E);
  static const Color coralSoft = Color(0xFFFFE3E3);
  static const Color grape = Color(0xFFA570FF);
  static const Color grapeDark = Color(0xFF8A4FE8);

  // Neutrals
  static const Color snow = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFE3E8EC);
  static const Color lineDark = Color(0xFFC9D1D7);

  // Legacy names kept so every screen picks up the new palette.
  static const Color ink = Color(0xFF2B3A45);
  static const Color inkSoft = Color(0xFF4B5C68);
  static const Color teal = leaf;
  static const Color tealDeep = leafDark;
  static const Color tealSoft = leafSoft;
  static const Color amber = Color(0xFFF5A400);
  static const Color amberSoft = sunSoft;
  static const Color mist = Color(0xFFF6F8F9);
  static const Color mistDeep = line;
  static const Color cloud = snow;
  static const Color slate = Color(0xFF6E7F8B);
  static const Color locked = Color(0xFFAEB8C0);
  static const Color success = leaf;
  static const Color danger = Color(0xFFEA3A40);
  static const Color pathLine = line;
}

class AppTheme {
  static const double radius = 16;

  /// Text style for Latin words and numbers (counters, XP, scores).
  static TextStyle latin({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w900,
    Color? color,
  }) =>
      GoogleFonts.nunito(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.leaf,
        primary: AppColors.leaf,
        onPrimary: Colors.white,
        secondary: AppColors.sky,
        error: AppColors.danger,
        surface: AppColors.snow,
        onSurface: AppColors.ink,
        outline: AppColors.line,
        brightness: Brightness.light,
      ),
    );

    final buttonText = GoogleFonts.vazirmatn(
      fontSize: 16,
      fontWeight: FontWeight.w800,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.snow,
      textTheme: GoogleFonts.vazirmatnTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 2),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.leaf,
        linearTrackColor: AppColors.line,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.snow,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: AppColors.line, width: 2),
        ),
        titleTextStyle: GoogleFonts.vazirmatn(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.snow,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.line, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: GoogleFonts.vazirmatn(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.snow,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.snow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.mist,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.line, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.line, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.sky, width: 2),
        ),
        labelStyle: GoogleFonts.vazirmatn(color: AppColors.slate),
        hintStyle: GoogleFonts.vazirmatn(color: AppColors.locked),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.snow,
        selectedColor: AppColors.skySoft,
        side: const BorderSide(color: AppColors.line, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: GoogleFonts.vazirmatn(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.snow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.skySoft,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.skyBorder, width: 2),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.vazirmatn(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: states.contains(WidgetState.selected)
                ? AppColors.skyDark
                : AppColors.slate,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.skyDark,
        unselectedLabelColor: AppColors.slate,
        indicatorColor: AppColors.sky,
        dividerColor: AppColors.line,
        labelStyle: GoogleFonts.vazirmatn(fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.sky,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: chunkyStyle(
          face: AppColors.leaf,
          edge: AppColors.leafDark,
          foreground: Colors.white,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: chunkyStyle(
          face: AppColors.snow,
          edge: AppColors.line,
          foreground: AppColors.sky,
          border: AppColors.line,
          textStyle: buttonText,
        ),
      ),
    );
  }

  /// A 3D "chunky" button: a darker edge under the face that disappears
  /// when pressed, so the button looks pushed in.
  static ButtonStyle chunkyStyle({
    required Color face,
    required Color edge,
    required Color foreground,
    Color? border,
    TextStyle? textStyle,
  }) {
    const edgeDepth = 4.0;
    return ButtonStyle(
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      side: const WidgetStatePropertyAll(BorderSide.none),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.locked
            : foreground,
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.locked
            : foreground,
      ),
      textStyle: WidgetStatePropertyAll(textStyle),
      minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      backgroundBuilder: (context, states, child) {
        final disabled = states.contains(WidgetState.disabled);
        final pressed = states.contains(WidgetState.pressed);
        final faceColor = disabled ? AppColors.line : face;
        final edgeColor = disabled ? AppColors.lineDark : edge;
        final r = BorderRadius.circular(radius);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          padding: EdgeInsets.only(
            top: pressed ? edgeDepth : 0,
            bottom: pressed ? 0 : edgeDepth,
          ),
          decoration: BoxDecoration(
            color: pressed ? Colors.transparent : edgeColor,
            borderRadius: r,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: r,
              border: border == null || disabled
                  ? null
                  : Border.all(color: border, width: 2),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
