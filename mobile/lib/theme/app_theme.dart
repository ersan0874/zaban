import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Neutral and tint colors that change between light and dark mode.
class Palette {
  const Palette({
    required this.snow,
    required this.mist,
    required this.line,
    required this.lineDark,
    required this.ink,
    required this.inkSoft,
    required this.slate,
    required this.locked,
    required this.leafSoft,
    required this.skySoft,
    required this.skyBorder,
    required this.sunSoft,
    required this.coralSoft,
    required this.flameSoft,
  });

  final Color snow;
  final Color mist;
  final Color line;
  final Color lineDark;
  final Color ink;
  final Color inkSoft;
  final Color slate;
  final Color locked;
  final Color leafSoft;
  final Color skySoft;
  final Color skyBorder;
  final Color sunSoft;
  final Color coralSoft;
  final Color flameSoft;
}

/// Playful learning palette (Duolingo-inspired): white ground, bright
/// semantic colors, each with a darker "edge" used for 3D buttons.
///
/// Meaning is fixed: leaf = progress/correct, sky = selection, sun = reward/XP,
/// flame = streak, coral = hearts/wrong, grape = gems/Super.
///
/// Brand colors are constant; neutrals and soft tints follow [current],
/// which the app switches for dark mode (see `main.dart`).
class AppColors {
  static const Palette lightPalette = Palette(
    snow: Color(0xFFFFFFFF),
    mist: Color(0xFFF6F8F9),
    line: Color(0xFFE3E8EC),
    lineDark: Color(0xFFC9D1D7),
    ink: Color(0xFF2B3A45),
    inkSoft: Color(0xFF4B5C68),
    slate: Color(0xFF6E7F8B),
    locked: Color(0xFFAEB8C0),
    leafSoft: Color(0xFFE6F8D9),
    skySoft: Color(0xFFDDF2FD),
    skyBorder: Color(0xFF9AD7FA),
    sunSoft: Color(0xFFFFF6D6),
    coralSoft: Color(0xFFFFE3E3),
    flameSoft: Color(0xFFFFEBD3),
  );

  static const Palette darkPalette = Palette(
    snow: Color(0xFF131F24),
    mist: Color(0xFF1B2A31),
    line: Color(0xFF37464F),
    lineDark: Color(0xFF2A373E),
    ink: Color(0xFFF1F7FB),
    inkSoft: Color(0xFFC9D6DD),
    slate: Color(0xFF93A6B0),
    locked: Color(0xFF56676F),
    leafSoft: Color(0xFF1E3818),
    skySoft: Color(0xFF12324A),
    skyBorder: Color(0xFF1F6493),
    sunSoft: Color(0xFF3A3013),
    coralSoft: Color(0xFF3E1D20),
    flameSoft: Color(0xFF3D2810),
  );

  static Palette current = lightPalette;
  static bool get isDark => identical(current, darkPalette);

  // Core semantic colors
  static const Color leaf = Color(0xFF58C322);
  static const Color leafDark = Color(0xFF46A012);
  static Color get leafSoft => current.leafSoft;
  static const Color sky = Color(0xFF2BA8F0);
  static const Color skyDark = Color(0xFF1A8BD0);
  static Color get skySoft => current.skySoft;
  static Color get skyBorder => current.skyBorder;
  static const Color sun = Color(0xFFFFC930);
  static const Color sunDark = Color(0xFFE0A800);
  static Color get sunSoft => current.sunSoft;
  static const Color flame = Color(0xFFFF9A1F);
  static const Color flameDark = Color(0xFFE07F00);
  static Color get flameSoft => current.flameSoft;
  static const Color coral = Color(0xFFFF5A5F);
  static const Color coralDark = Color(0xFFE0383E);
  static Color get coralSoft => current.coralSoft;
  static const Color grape = Color(0xFFA570FF);
  static const Color grapeDark = Color(0xFF8A4FE8);

  // Neutrals
  static Color get snow => current.snow;
  static Color get line => current.line;
  static Color get lineDark => current.lineDark;

  // Legacy names kept so every screen picks up the new palette.
  static Color get ink => current.ink;
  static Color get inkSoft => current.inkSoft;
  static const Color teal = leaf;
  static const Color tealDeep = leafDark;
  static Color get tealSoft => leafSoft;
  static const Color amber = Color(0xFFF5A400);
  static Color get amberSoft => sunSoft;
  static Color get mist => current.mist;
  static Color get mistDeep => line;
  static Color get cloud => snow;
  static Color get slate => current.slate;
  static Color get locked => current.locked;
  static const Color success = leaf;
  static const Color danger = Color(0xFFEA3A40);
  static Color get pathLine => line;
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

  static ThemeData get light =>
      _build(AppColors.lightPalette, Brightness.light);

  static ThemeData get dark => _build(AppColors.darkPalette, Brightness.dark);

  static ThemeData _build(Palette p, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.leaf,
        primary: AppColors.leaf,
        onPrimary: Colors.white,
        secondary: AppColors.sky,
        error: AppColors.danger,
        surface: p.snow,
        onSurface: p.ink,
        outline: p.line,
        brightness: brightness,
      ),
    );

    final buttonText = GoogleFonts.vazirmatn(
      fontSize: 16,
      fontWeight: FontWeight.w800,
    );

    return base.copyWith(
      scaffoldBackgroundColor: p.snow,
      textTheme: GoogleFonts.vazirmatnTextTheme(base.textTheme).apply(
        bodyColor: p.ink,
        displayColor: p.ink,
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 2),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.leaf,
        linearTrackColor: p.line,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: p.snow,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.ink,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(color: p.line, width: 2),
        ),
        titleTextStyle: GoogleFonts.vazirmatn(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: p.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.snow,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.line, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: GoogleFonts.vazirmatn(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.snow,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.snow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.mist,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: p.line, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: p.line, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.sky, width: 2),
        ),
        labelStyle: GoogleFonts.vazirmatn(color: p.slate),
        hintStyle: GoogleFonts.vazirmatn(color: p.locked),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: p.snow,
        selectedColor: p.skySoft,
        side: BorderSide(color: p.line, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: GoogleFonts.vazirmatn(
          fontWeight: FontWeight.w700,
          color: p.ink,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.snow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.skySoft,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.skyBorder, width: 2),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.vazirmatn(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: states.contains(WidgetState.selected)
                ? AppColors.skyDark
                : p.slate,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.skyDark,
        unselectedLabelColor: p.slate,
        indicatorColor: AppColors.sky,
        dividerColor: p.line,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
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
      filledButtonTheme: FilledButtonThemeData(
        style: chunkyStyle(
          face: AppColors.leaf,
          edge: AppColors.leafDark,
          foreground: Colors.white,
          textStyle: buttonText,
        ).copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: chunkyStyle(
          face: p.snow,
          edge: p.line,
          foreground: AppColors.sky,
          border: p.line,
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
