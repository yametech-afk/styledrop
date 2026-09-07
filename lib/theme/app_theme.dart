import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// StyleDrop - Minimalist editorial fashion theme
/// Warm beige / cream base, black accents, thin elegant typography
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF7F3EC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEFE9DE);
  static const Color ink = Color(0xFF1C1B19);
  static const Color inkSoft = Color(0xFF4A463E); // darkened for WCAG AA
  // Muted text darkened from #9C9689 (~2.8:1) to #7A7365 (~4.6:1 on cream)
  // so body-small copy meets WCAG AA contrast.
  static const Color mutedText = Color(0xFF7A7365);
  static const Color line = Color(0xFFE3DCCE);
  static const Color accent = Color(0xFF6B6355); // warm taupe accent
  static const Color gold = Color(0xFFB89664);
  static const Color success = Color(0xFF5F7A4E); // slightly darker for AA
  static const Color warning = Color(0xFFC97A3D);
  static const Color error = Color(0xFFB5533C);
  static const Color chipBg = Color(0xFFEFE9DE);
}

/// Dark ("editorial night") palette. Mirrors [AppColors] roles so the dark
/// theme reads as the same brand in low light.
class AppColorsDark {
  AppColorsDark._();

  static const Color background = Color(0xFF16150F);
  static const Color surface = Color(0xFF201E17);
  static const Color surfaceAlt = Color(0xFF2A281F);
  static const Color ink = Color(0xFFF3EEE2); // "ink" becomes light on dark
  static const Color inkSoft = Color(0xFFCFC8B8);
  static const Color mutedText = Color(0xFF9A9384);
  static const Color line = Color(0xFF35322A);
  static const Color accent = Color(0xFFBFB39C);
  static const Color gold = Color(0xFFCBA870);
  static const Color success = Color(0xFF89A874);
  static const Color warning = Color(0xFFD9924F);
  static const Color error = Color(0xFFD1745C);
  static const Color chipBg = Color(0xFF2A281F);
}

/// Groups the palette roles so the light + dark themes share one builder.
class _Palette {
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color inkSoft;
  final Color mutedText;
  final Color line;
  final Color accent;
  final Color gold;
  final Color chipBg;

  const _Palette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.inkSoft,
    required this.mutedText,
    required this.line,
    required this.accent,
    required this.gold,
    required this.chipBg,
  });
}

class AppTheme {
  AppTheme._();

  static const _Palette _light = _Palette(
    brightness: Brightness.light,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceAlt: AppColors.surfaceAlt,
    ink: AppColors.ink,
    inkSoft: AppColors.inkSoft,
    mutedText: AppColors.mutedText,
    line: AppColors.line,
    accent: AppColors.accent,
    gold: AppColors.gold,
    chipBg: AppColors.chipBg,
  );

  static const _Palette _dark = _Palette(
    brightness: Brightness.dark,
    background: AppColorsDark.background,
    surface: AppColorsDark.surface,
    surfaceAlt: AppColorsDark.surfaceAlt,
    ink: AppColorsDark.ink,
    inkSoft: AppColorsDark.inkSoft,
    mutedText: AppColorsDark.mutedText,
    line: AppColorsDark.line,
    accent: AppColorsDark.accent,
    gold: AppColorsDark.gold,
    chipBg: AppColorsDark.chipBg,
  );

  /// Light theme (default).
  static ThemeData get theme => _build(_light);

  /// Dark ("editorial night") theme.
  static ThemeData get darkTheme => _build(_dark);

  static ThemeData _build(_Palette p) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      scaffoldBackgroundColor: p.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.accent,
        brightness: p.brightness,
        surface: p.surface,
        primary: p.ink,
        secondary: p.gold,
      ),
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        color: p.ink,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: p.ink,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: p.ink,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: p.ink,
        letterSpacing: 0.2,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: p.ink,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 15, color: p.ink, height: 1.4),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        color: p.inkSoft,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.inter(fontSize: 11, color: p.mutedText),
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: p.ink,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: p.ink),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: p.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.line, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.ink,
        unselectedLabelColor: p.mutedText,
        indicatorColor: p.ink,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.ink,
          foregroundColor: p.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          side: BorderSide(color: p.ink, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.ink, width: 1.4),
        ),
        hintStyle: GoogleFonts.inter(color: p.mutedText, fontSize: 13),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: p.chipBg,
        selectedColor: p.ink,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          color: p.ink,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          color: p.background,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: p.line),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.ink,
        unselectedItemColor: p.mutedText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        contentTextStyle: GoogleFonts.inter(color: p.background),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
