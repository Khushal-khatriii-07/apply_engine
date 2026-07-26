import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle appTextStyle({
  required TextStyle fallback,
  required TextStyle Function() googleFontBuilder,
}) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return fallback;
  }
  try {
    return googleFontBuilder();
  } catch (_) {
    return fallback;
  }
}

class AppTheme {
  // Brand Colors
  static const Color primaryLight = Color(0xFF4F46E5); // Indigo
  static const Color secondaryLight = Color(0xFF0F766E); // Deep Teal
  static const Color accentLight = Color(0xFFF43F5E); // Rose
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate-50
  static const Color surfaceLight = Colors.white;

  static const Color primaryDark = Color(0xFF6366F1); // Indigo lightened for dark mode
  static const Color secondaryDark = Color(0xFF14B8A6); // Bright Teal
  static const Color accentDark = Color(0xFFFB7185); // Rose lightened
  static const Color backgroundDark = Color(0xFF0F172A); // Slate-900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate-800

  // Status Colors (consistent across themes)
  static const Color statusReady = Color(0xFF3B82F6); // Blue
  static const Color statusSending = Color(0xFFF59E0B); // Amber
  static const Color statusSent = Color(0xFF10B981); // Emerald
  static const Color statusFailed = Color(0xFFEF4444); // Red
  static const Color statusInvalid = Color(0xFF8B5CF6); // Violet
  static const Color statusSkipped = Color(0xFF6B7280); // Gray
  static const Color statusDuplicate = Color(0xFFD946EF); // Fuchsia

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryLight,
        brightness: Brightness.light,
        primary: primaryLight,
        secondary: secondaryLight,
        error: accentLight,
        background: backgroundLight,
        surface: surfaceLight,
      ),
      textTheme: Platform.environment.containsKey('FLUTTER_TEST')
          ? ThemeData.light().textTheme
          : GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryDark,
        brightness: Brightness.dark,
        primary: primaryDark,
        secondary: secondaryDark,
        error: accentDark,
        background: backgroundDark,
        surface: surfaceDark,
      ),
      textTheme: Platform.environment.containsKey('FLUTTER_TEST')
          ? ThemeData.dark().textTheme
          : GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: const BorderSide(color: primaryDark, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ready':
        return statusReady;
      case 'sending':
        return statusSending;
      case 'sent':
        return statusSent;
      case 'failed':
        return statusFailed;
      case 'invalid':
        return statusInvalid;
      case 'skipped':
        return statusSkipped;
      case 'duplicate':
        return statusDuplicate;
      default:
        return Colors.blueGrey;
    }
  }
}
