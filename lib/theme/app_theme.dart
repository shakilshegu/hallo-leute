import 'package:flutter/material.dart';

import 'app_colors.dart';

export 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'PlusJakartaSans';

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.poppy,
      primary: AppColors.poppy,
      onPrimary: Colors.white,
      secondary: AppColors.sunrise,
      tertiary: AppColors.lavender,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.error,
      outline: AppColors.outline,
    );

    const textTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      displayMedium: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      // Main actions are Ink black pills (Poppy is kept for brand moments).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(58),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(58),
          shape: const StadiumBorder(),
          side: const BorderSide(color: AppColors.outline, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
