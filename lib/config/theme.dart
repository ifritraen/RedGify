import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme Color Palette
  static const Color background = Color(0xFF09070F); // Deep space dark
  static const Color cardBg = Color(0x1F2A1B3D);      // Glassmorphic purple overlay
  static const Color primaryNeon = Color(0xFFFF007F);  // Hot Pink
  static const Color secondaryNeon = Color(0xFF8F00FF); // Vivid Violet
  static const Color accentNeon = Color(0xFF00F0FF);    // Neon Cyan
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E98B3);
  static const Color borderHighlight = Color(0x33FF007F); // Low opacity hot pink border

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryNeon,
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        secondary: secondaryNeon,
        surface: background,
      ),
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
    );
  }
}
