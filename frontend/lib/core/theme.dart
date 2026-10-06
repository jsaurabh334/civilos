import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CivilTheme {
  // Ultra-Premium SaaS Dark Theme (Stripe/Linear Inspired)
  static const Color background = Color(0xFF0B0F19); // Ultra deep slate for pure contrast
  static const Color surface = Color(0xFF131B2C);    // Slightly elevated for sidebar/header
  static const Color card = Color(0xFF1E293B);       // Distinct card color (Level 1)
  static const Color border = Color(0xFF334155);     // Muted border, not distracting
  
  static const Color primary = Color(0xFF0EA5E9);    // High contrast Electric Blue
  static const Color secondary = Color(0xFF10B981);  // Vibrant Emerald Green (Success/Action)
  
  static const Color textPrimary = Color(0xFFF8FAFC); // Pure white for readability
  static const Color textSecondary = Color(0xFF94A3B8); // Muted slate gray for secondary info
  
  static const Color error = Color(0xFFEF4444);      // Crimson for destructive actions
  static const Color warning = Color(0xFFF59E0B);    // Amber for warnings/alerts

  // Spacing System (Strict 4pt grid)
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s48 = 48.0;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textPrimary, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1.0),
          titleLarge: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          titleMedium: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
          labelSmall: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get lightTheme {
    const lightBackground = Color(0xFFF8FAFC);
    const lightSurface = Color(0xFFFFFFFF);
    const lightCard = Color(0xFFFFFFFF);
    const lightBorder = Color(0xFFE2E8F0);
    const lightTextPrimary = Color(0xFF0F172A);
    const lightTextSecondary = Color(0xFF64748B);

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: lightSurface,
        error: error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: lightTextPrimary, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1.0),
          titleLarge: TextStyle(color: lightTextPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          titleMedium: TextStyle(color: lightTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: lightTextPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: lightTextSecondary, fontSize: 14),
          labelSmall: TextStyle(color: lightTextSecondary, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        hintStyle: const TextStyle(color: lightTextSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: lightTextSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightTextPrimary,
          side: const BorderSide(color: lightBorder, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: lightTextPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
