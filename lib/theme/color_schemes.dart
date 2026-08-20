import 'package:flutter/material.dart';

/// The application palette is intentionally limited to black, white and the
/// brand color #FFE4B5. Every other tone below is produced by mixing the brand
/// color with either white or black; alpha variants remain valid derivatives.
class AppColors {
  AppColors._();

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color brand = Color(0xFFFFE4B5);

  // Brand mixed with black (increasing depth).
  static const Color brandDark = Color(0xFFCCB691);
  static const Color brandDeeper = Color(0xFF99896D);
  static const Color brandInk = Color(0xFF665B48);
  static const Color brandNearBlack = Color(0xFF332E24);

  // Brand mixed with white (increasing lightness).
  static const Color brandLight = Color(0xFFFFEBC8);
  static const Color brandSoft = Color(0xFFFFF2DA);
  static const Color brandPale = Color(0xFFFFF8ED);
  static const Color brandWash = Color(0xFFFFFCF6);
  static const Color brandSurface = brandSoft;

  // Semantic aliases used throughout the existing UI.
  static const Color sageBg = brandSurface;
  static const Color sageCard = brandPale;
  static const Color sageText = brandNearBlack;
  static const Color sageMuted = brandInk;
  static const Color sageAccent = brandInk;
  static const Color sageBorder = brand;
  static const Color sageDeep = brandNearBlack;

  // Compatibility aliases: formerly green/gold, now brand-derived by design.
  static const Color sageGreen = brandDeeper;
  static const Color sageGold = brandDark;

  // Light mode colors.
  static const Color primaryLight = brandInk;
  static const Color secondaryLight = brandDeeper;
  static const Color tertiaryLight = brand;
  static const Color errorLight = brandInk;
  static const Color neutralLight = brandSurface;
  static const Color neutralVariantLight = brand;

  // Dark mode colors.
  static const Color primaryDark = brand;
  static const Color secondaryDark = brandLight;
  static const Color tertiaryDark = brandDark;
  static const Color errorDark = brandLight;
  static const Color neutralDark = brandNearBlack;
  static const Color neutralVariantDark = brandInk;

  static const Color surfaceLight = brandSurface;
  static const Color onPrimaryLight = white;
  static const Color onSurfaceLight = brandNearBlack;

  static const Color surfaceDark = brandNearBlack;
  static const Color onPrimaryDark = brandNearBlack;
  static const Color onSurfaceDark = brandPale;

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
      inversePrimary: brand,
      shadow: brandNearBlack,
      outline: neutralVariantLight,
      surfaceTint: primaryLight,
      surfaceContainerHighest: brand,
      surfaceContainerHigh: brandLight,
      surfaceContainer: brandSurface,
      surfaceContainerLow: brandPale,
      surfaceContainerLowest: brandWash,
      outlineVariant: brandLight,
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
      onTertiary: brandNearBlack,
      error: errorDark,
      onError: brandNearBlack,
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      inversePrimary: primaryLight,
      shadow: black,
      outline: neutralVariantDark,
      surfaceTint: primaryDark,
      surfaceContainerHighest: brandInk,
      surfaceContainerHigh: brandNearBlack,
      surfaceContainer: brandInk,
      surfaceContainerLow: brandInk,
      surfaceContainerLowest: brandNearBlack,
      outlineVariant: brandDark,
    );
  }
}
