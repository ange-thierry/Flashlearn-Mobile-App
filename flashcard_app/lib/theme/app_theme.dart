import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand palette ──────────────────────────────────────────────────────────
  static const Color primary     = Color(0xFF16A34A);  // vibrant green
  static const Color primaryDark = Color(0xFF15803D);  // deep green
  static const Color accent      = Color(0xFF22C55E);  // light green
  static const Color bg          = Color(0xFFF0FDF4);  // soft green white
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color dark        = Color(0xFF0F0E17);

  // ── Semantic colors ────────────────────────────────────────────────────────
  static const Color easy    = Color(0xFF22C55E);  // success green
  static const Color normal  = Color(0xFFF97316);  // streak/warning orange
  static const Color hard    = Color(0xFFEF4444);  // error red
  static const Color achieve = Color(0xFFEAB308);  // achievement yellow
  static const Color cyan    = Color(0xFF06B6D4);  // cyan accent

  // ── Field gradients ────────────────────────────────────────────────────────
  static const Map<String, List<Color>> fieldGradients = {
    'math':       [Color(0xFF3730A3), Color(0xFF5B5FEF)],
    'science':    [Color(0xFF0D3D2A), Color(0xFF1A6B4A)],
    'history':    [Color(0xFF7C2D12), Color(0xFFC2410C)],
    'geography':  [Color(0xFF1E3A5F), Color(0xFF2563EB)],
    'literature': [Color(0xFF6B21A8), Color(0xFF9333EA)],
    'cs':         [Color(0xFF064E3B), Color(0xFF059669)],
  };

  // ── Typography helper ──────────────────────────────────────────────────────
  static TextStyle _t({
    required double size,
    required FontWeight weight,
    Color color = const Color(0xFF0F0E17),
    double? height,
    double? spacing,
  }) => GoogleFonts.poppins(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: spacing,
  );

  // ── Dark theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: accent,
      secondary: accent,
      error: hard,
      surface: const Color(0xFF161B22),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFFF0F6FC),
    ),
    scaffoldBackgroundColor: const Color(0xFF0D1117),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge:  _t(size: 30, weight: FontWeight.w800, color: const Color(0xFFF0F6FC), spacing: -0.5),
      displayMedium: _t(size: 24, weight: FontWeight.w800, color: const Color(0xFFF0F6FC), spacing: -0.3),
      titleLarge:    _t(size: 18, weight: FontWeight.w700, color: const Color(0xFFF0F6FC)),
      titleMedium:   _t(size: 15, weight: FontWeight.w600, color: const Color(0xFFF0F6FC)),
      bodyLarge:     _t(size: 15, weight: FontWeight.w400, color: const Color(0xFFCDD5E0), height: 1.6),
      bodyMedium:    _t(size: 13, weight: FontWeight.w400, color: const Color(0xFF8B949E), height: 1.5),
      labelSmall:    _t(size: 10, weight: FontWeight.w700, color: const Color(0xFF8B949E), spacing: 0.5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF161B22),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: Color(0xFFF0F6FC),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: const BorderSide(color: accent, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF161B22),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF30363D), width: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0D1117),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF30363D), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF30363D), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color(0xFF8B949E)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF161B22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
  );

  // ── Light theme ────────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      error: hard,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: dark,
    ),
    scaffoldBackgroundColor: bg,
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge:  _t(size: 30, weight: FontWeight.w800, spacing: -0.5),
      displayMedium: _t(size: 24, weight: FontWeight.w800, spacing: -0.3),
      titleLarge:    _t(size: 18, weight: FontWeight.w700),
      titleMedium:   _t(size: 15, weight: FontWeight.w600),
      bodyLarge:     _t(size: 15, weight: FontWeight.w400, height: 1.6),
      bodyMedium:    _t(size: 13, weight: FontWeight.w400,
                        color: const Color(0xFF6B7280), height: 1.5),
      labelSmall:    _t(size: 10, weight: FontWeight.w700,
                        color: const Color(0xFF6B7280), spacing: 0.5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFBBF7D0), width: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0FDF4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFBBF7D0), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFBBF7D0), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
  );
}
