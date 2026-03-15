import 'package:flutter/material.dart';
import 'color_schemes.dart';

AppBarTheme buildAppBarTheme() => const AppBarTheme(
  elevation: 0,
  scrolledUnderElevation: 0,
  backgroundColor: AppColors.primary,
  foregroundColor: AppColors.onPrimary,
  centerTitle: true,
);

CardThemeData buildCardTheme() => CardThemeData(
  elevation: 0,
  color: AppColors.surface,
  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: AppColors.borderSubtle, width: 1),
  ),
);

ElevatedButtonThemeData buildElevatedButtonTheme() => ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    elevation: 0,
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    minimumSize: const Size(double.infinity, 48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
);

TextButtonThemeData buildTextButtonTheme() => TextButtonThemeData(
  style: TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
);

InputDecorationTheme buildInputDecorationTheme() => InputDecorationTheme(
  filled: true,
  fillColor: AppColors.surface,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
  ),
  hintStyle: TextStyle(color: Colors.grey.shade400),
);

DividerThemeData buildDividerTheme() =>
    DividerThemeData(space: 1, thickness: 0.5, color: AppColors.dividerSubtle);
