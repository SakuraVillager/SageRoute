import 'package:flutter/material.dart';

/// The application palette is intentionally limited to black, white and the
/// brand color #8B7500. Every other tone below is produced by mixing the brand
/// color with either white or black; alpha variants remain valid derivatives.
class AppColors {
  AppColors._();

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color brand = Color(0xFF8B7500);

  // Brand mixed with black (increasing depth).
  static const Color brandDark = Color(0xFF6F5E00);
  static const Color brandDeeper = Color(0xFF534600);
  static const Color brandInk = Color(0xFF382F00);
  static const Color brandNearBlack = Color(0xFF1C1700);

  // Brand mixed with white (increasing lightness).
  static const Color brandLight = Color(0xFFA89840);
  static const Color brandSoft = Color(0xFFC5BA80);
  static const Color brandPale = Color(0xFFDCD6B3);
  static const Color brandWash = Color(0xFFEEEAD9);
  static const Color brandSurface = Color(0xFFF8F7F0);

  // Semantic aliases used throughout the existing UI.
  static const Color sageBg = brandSurface;
  static const Color sageCard = white;
  static const Color sageText = brandInk;
  static const Color sageMuted = brand;
  static const Color sageAccent = brand;
  static const Color sageBorder = brandPale;
  static const Color sageDeep = brandNearBlack;

  // Compatibility aliases: formerly green/gold, now brand-derived by design.
  static const Color sageGreen = brandLight;
  static const Color sageGold = brandLight;

  // Light mode colors.
  static const Color primaryLight = brand;
  static const Color secondaryLight = brandDark;
  static const Color tertiaryLight = brandLight;
  static const Color errorLight = brandDark;
  static const Color neutralLight = brandSurface;
  static const Color neutralVariantLight = brandPale;

  // Dark mode colors.
  static const Color primaryDark = brandLight;
  static const Color secondaryDark = brandSoft;
  static const Color tertiaryDark = brand;
  static const Color errorDark = brandSoft;
  static const Color neutralDark = brandNearBlack;
  static const Color neutralVariantDark = brandDeeper;

  static const Color surfaceLight = brandSurface;
  static const Color onPrimaryLight = white;
  static const Color onSurfaceLight = brandInk;

  static const Color surfaceDark = brandNearBlack;
  static const Color onPrimaryDark = brandNearBlack;
  static const Color onSurfaceDark = brandWash;

  static ColorScheme buildLightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: primaryLight,
      onPrimary: onPrimaryLight,
      secondary: secondaryLight,
      onSecondary: white,
      tertiary: tertiaryLight,
      onTertiary: brandNearBlack,
      error: errorLight,
      onError: white,
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      inversePrimary: brandLight,
      shadow: brandNearBlack,
      outline: neutralVariantLight,
      surfaceTint: primaryLight,
      surfaceContainerHighest: brandPale,
      surfaceContainerHigh: brandWash,
      surfaceContainer: brandSurface,
      surfaceContainerLow: brandSurface,
      surfaceContainerLowest: white,
      outlineVariant: brandPale,
    );
  }

  static ColorScheme buildDarkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryDark,
      onPrimary: onPrimaryDark,
      secondary: secondaryDark,
      onSecondary: brandNearBlack,
      tertiary: tertiaryDark,
      onTertiary: white,
      error: errorDark,
      onError: brandNearBlack,
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      inversePrimary: primaryLight,
      shadow: black,
      outline: neutralVariantDark,
      surfaceTint: primaryDark,
      surfaceContainerHighest: brandDeeper,
      surfaceContainerHigh: brandInk,
      surfaceContainer: brandInk,
      surfaceContainerLow: brandInk,
      surfaceContainerLowest: brandNearBlack,
      outlineVariant: brandDark,
    );
  }
}
