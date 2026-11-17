import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.cream,
      onPrimary: AppColors.navy,
      secondary: AppColors.mustard,
      onSecondary: AppColors.navy,
      surface: AppColors.navy,
      onSurface: AppColors.cream,
      surfaceContainerHighest: AppColors.navy800,
      outline: AppColors.navyLine,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.navy,
      fontFamily: 'Nunito',
      textTheme: TextTheme(
        displaySmall: AppText.display(34, color: AppColors.cream),
        titleLarge: AppText.display(22, color: AppColors.cream),
        bodyLarge: AppText.body(16, color: AppColors.cream),
        bodyMedium: AppText.body(14, color: AppColors.cream),
        labelLarge: AppText.body(16, weight: FontWeight.w800),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cream,
        contentTextStyle: AppText.body(14, color: AppColors.navy),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
