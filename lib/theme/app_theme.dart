import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF1E4034);
  static const Color secondary = Color(0xFFDDE5DE);
  static const Color tertiary = Color(0xFF54302C);
  static const Color neutral = Color(0xFF767775);

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onTertiary: Colors.white,
        onSurface: neutral,
      ),
      useMaterial3: true,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.bricolageGrotesque(),
        displayMedium: GoogleFonts.bricolageGrotesque(),
        displaySmall: GoogleFonts.bricolageGrotesque(),
        headlineLarge: GoogleFonts.bricolageGrotesque(),
        headlineMedium: GoogleFonts.bricolageGrotesque(),
        headlineSmall: GoogleFonts.bricolageGrotesque(),
        titleLarge: GoogleFonts.bricolageGrotesque(),
        titleMedium: GoogleFonts.bricolageGrotesque(),
        titleSmall: GoogleFonts.bricolageGrotesque(),
        bodyLarge: GoogleFonts.dmSans(),
        bodyMedium: GoogleFonts.dmSans(),
        bodySmall: GoogleFonts.dmSans(),
        labelLarge: GoogleFonts.spaceMono(),
        labelMedium: GoogleFonts.spaceMono(),
        labelSmall: GoogleFonts.spaceMono(),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9F8), // A slightly off-white for background
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
