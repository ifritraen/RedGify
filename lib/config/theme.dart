import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Global theme mode state tracker
  static bool isDark = true;

  // Theme Neon Color Palette
  static const Color primaryNeon = Color(0xFFFF007F);  // Hot Pink
  static const Color secondaryNeon = Color(0xFF8F00FF); // Vivid Violet
  static const Color accentNeon = Color(0xFF00F0FF);    // Neon Cyan
  
  // Dynamic color getters based on current theme state to avoid refactoring call-sites
  static Color get background => isDark ? const Color(0xFF09070F) : const Color(0xFFF5F3FA);
  static Color get cardBg => isDark ? const Color(0x1F2A1B3D) : const Color(0x99FFFFFF);
  static Color get textSecondary => isDark ? const Color(0xFF9E98B3) : const Color(0xFF6C6580);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF130F26);

  static Color get textPrimary => isDark ? textPrimaryDark : textPrimaryLight;
  static Color get border => isDark ? const Color(0x2BFFFFFF) : const Color(0x1A000000);
  static Color get borderLight => isDark ? const Color(0x17FFFFFF) : const Color(0x0D000000);
  static Color get glassBg => isDark ? const Color(0x1F2A1B3D) : const Color(0x66FFFFFF);
  static Color get glassBgSolid => isDark ? const Color(0xFF09070F) : const Color(0xFFF5F3FA);

  static List<BoxShadow> get cardGlow => [
    BoxShadow(
      color: (isDark ? primaryNeon : secondaryNeon).withOpacity(isDark ? 0.08 : 0.05),
      blurRadius: 10,
      spreadRadius: 0.5,
    )
  ];

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF09070F),
      primaryColor: primaryNeon,
      cardColor: const Color(0x1F2A1B3D),
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        secondary: secondaryNeon,
        surface: Color(0xFF09070F),
      ),
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryDark,
          letterSpacing: 0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textPrimaryDark,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF9E98B3),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F3FA),
      primaryColor: primaryNeon,
      cardColor: const Color(0x99FFFFFF),
      colorScheme: const ColorScheme.light(
        primary: primaryNeon,
        secondary: secondaryNeon,
        surface: Color(0xFFF5F3FA),
      ),
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
          letterSpacing: 0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textPrimaryLight,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF6C6580),
        ),
      ),
    );
  }
}
