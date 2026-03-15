import 'package:flutter/material.dart';

/// Centralizes brand colors and derived tones.
class AppColors {
  AppColors._();
  // Light mode colors
  static const Color primaryLight = Color(0xFFBDAC9C);
  static const Color secondaryLight = Color(0xFFA99A8C);
  static const Color tertiaryLight = Color(0xFFBD9C9C);
  static const Color errorLight = Color(0xFFBA1A1A);
  static const Color neutralLight = Color(0xFFFBF9F7);
  static const Color neutralVariantLight = Color(0xFFE8E2DC);

  // Dark mode colors
  static const Color primaryDark = Color(0xFFD4C3B3);
  static const Color secondaryDark = Color(0xFFBEB0A2);
  static const Color tertiaryDark = Color(0xFFD4B3B3);
  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color neutralDark = Color(0xFF1D1B19);
  static const Color neutralVariantDark = Color(0xFF4A4642);

  // Surface / on colors (shared defaults)
  static const Color surfaceLight = Colors.white;
  static const Color onPrimaryLight = Colors.white;
  static const Color onSurfaceLight = Color(0xFF2C2624);

  static const Color surfaceDark = Color(0xFF121212);
  static const Color onPrimaryDark = Color(0xFF1D1B19);
  static const Color onSurfaceDark = Color(0xFFEDEBE9);

  static ColorScheme buildLightScheme() {
    return ColorScheme(
      brightness: Brightness.light,
      primary: primaryLight,
      onPrimary: onPrimaryLight,
      secondary: secondaryLight,
      onSecondary: onPrimaryLight,
      tertiary: tertiaryLight,
      onTertiary: onPrimaryLight,
      error: errorLight,
      onError: Colors.white,
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      inversePrimary: primaryDark,
      shadow: Colors.black,
      outline: neutralVariantLight,
      surfaceTint: primaryLight,
    );
  }

  static ColorScheme buildDarkScheme() {
    return ColorScheme(
      brightness: Brightness.dark,
      primary: primaryDark,
      onPrimary: onPrimaryDark,
      secondary: secondaryDark,
      onSecondary: onPrimaryDark,
      tertiary: tertiaryDark,
      onTertiary: onPrimaryDark,
      error: errorDark,
      onError: Colors.black,
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      inversePrimary: primaryLight,
      shadow: Colors.black,
      outline: neutralVariantDark,
      surfaceTint: primaryDark,
    );
  }
}
