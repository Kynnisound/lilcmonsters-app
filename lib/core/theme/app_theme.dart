import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  /// Boutons de l'espace parents (texte adulte) : plum2 + blanc (8.5:1).
  static final parentButton = FilledButton.styleFrom(
    backgroundColor: AppColors.plum2,
    foregroundColor: Colors.white,
    minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
    textStyle: const TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w700,
      fontSize: 18,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.m),
    ),
  );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.lagoon,
      primary: AppColors.coral,
      onPrimary: AppColors.plum,
      secondary: AppColors.lagoon,
      onSecondary: AppColors.plum,
      tertiary: AppColors.sun,
      surface: AppColors.cream,
      onSurface: AppColors.plum,
      error: AppColors.bitsy,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppFonts.body,
      scaffoldBackgroundColor: AppColors.cream,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.comfortable,
    );
    return base.copyWith(
      textTheme: base.textTheme
          .apply(bodyColor: AppColors.plum, displayColor: AppColors.plum)
          .copyWith(
            displayLarge: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 56,
              color: AppColors.plum,
            ),
            displayMedium: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 40,
              color: AppColors.plum,
            ),
            headlineMedium: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 28,
              color: AppColors.plum,
            ),
            titleLarge: const TextStyle(
              fontFamily: AppFonts.body,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppColors.plum,
            ),
            bodyLarge: const TextStyle(
              fontFamily: AppFonts.body,
              fontWeight: FontWeight.w500,
              fontSize: 18,
              color: AppColors.plum,
            ),
          ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
          backgroundColor: AppColors.coral,
          foregroundColor: AppColors.plum,
          textStyle: const TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.m),
            side: const BorderSide(
              color: AppColors.plum,
              width: AppSizes.outline,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
          foregroundColor: AppColors.plum,
          side: const BorderSide(color: AppColors.plum, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.m),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
        ),
      ),
    );
  }
}
