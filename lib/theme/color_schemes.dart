import 'package:flutter/material.dart';

/// Centralizes brand colors and derived tones.
class AppColors {
  AppColors._();

  // Web brand colors as extension
  static const Color sageBg = Color(0xFFF5EFEB);
  static const Color sageCard = Color(0xFFFAF7F2);
  static const Color sageText = Color(0xFF2D2825);
  static const Color sageMuted = Color(0xFF857F75);
  static const Color sageAccent = Color(0xFFB96144);
  static const Color sageBorder = Color(0xFFE8E2D9);
  static const Color sageDeep = Color(0xFF1C1A1A);
  static const Color sageGreen = Color(0xFF84A98C);
  static const Color sageGold = Color(0xFFD4AF37);

  // Light mode colors
  static const Color primaryLight = Color(0xFFC37153);
  static const Color secondaryLight = Color(0xFF857F75);
  static const Color tertiaryLight = Color(0xFF84A98C);
  static const Color errorLight = Color(0xFFBA1A1A);
  static const Color neutralLight = Color(0xFFF5EFEB);
  static const Color neutralVariantLight = Color(0xFFE8E2D9);

  // Dark mode colors
  static const Color primaryDark = Color(0xFFD48A6F);
  static const Color secondaryDark = Color(0xFFA0988E);
  static const Color tertiaryDark = Color(0xFF6B8C70);
  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color neutralDark = Color(0xFF1D1B19);
  static const Color neutralVariantDark = Color(0xFF4A4642);

  // Surface / on colors (shared defaults)
  static const Color surfaceLight = Color(0xFFF5EFEB);
  static const Color onPrimaryLight = Colors.white;
  static const Color onSurfaceLight = Color(0xFF2D2825);

  static const Color surfaceDark = Color(0xFF1D1B19);
  static const Color onPrimaryDark = Color(0xFF1D1B19);
  static const Color onSurfaceDark = Color(0xFFEDEBE9);

  static ColorScheme buildLightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: primaryLight,
      onPrimary: onPrimaryLight,
      secondary: secondaryLight,
      onSecondary: onPrimaryLight,
      tertiary: tertiaryLight,
      onTertiary: Color(0xFF1C1A1A),
      error: errorLight,
      onError: Colors.white,
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      inversePrimary: Color(0xFFD48A6F),
      shadow: Color(0xFF1C1A1A),
      outline: neutralVariantLight,
      surfaceTint: primaryLight,
      surfaceContainerHighest: Color(0xFFE8E2D9),
      surfaceContainerHigh: Color(0xFFEFE9E3),
      surfaceContainer: Color(0xFFF5F0EA),
      surfaceContainerLow: Color(0xFFFAF7F2),
      surfaceContainerLowest: Colors.white,
      outlineVariant: Color(0xFFD4CEC8),
    );
  }

  static ColorScheme buildDarkScheme() {
    return const ColorScheme(
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
      surfaceContainerHighest: Color(0xFF4A4642),
      surfaceContainerHigh: Color(0xFF3D3A36),
      surfaceContainer: Color(0xFF33302C),
      surfaceContainerLow: Color(0xFF2A2725),
      surfaceContainerLowest: Color(0xFF1D1B19),
      outlineVariant: Color(0xFF5C5955),
    );
  }
}
